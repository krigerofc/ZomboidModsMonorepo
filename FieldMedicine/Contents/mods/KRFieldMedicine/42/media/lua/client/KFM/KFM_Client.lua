-- Field Medicine '93 - client: health panel body-part menu (chained onto vanilla, never replaced),
-- inventory "examine yourself", exam report window and server command handling.
require "TimedActions/ISInventoryTransferUtil"
require "TimedActions/KFM_ProcedureAction"
local Core = require "KFM/Core"
local Game = require "KFM/Game"

KFM = KFM or {}
local Client = {}
KFM.Client = Client

-- ------------------------------------------------------------ text helpers
function Client.partDisplayName(name)
    if not name then return "" end
    local ok, text = pcall(function()
        for i = 0, BodyPartType.ToIndex(BodyPartType.MAX) - 1 do
            local t = BodyPartType.FromIndex(i)
            if BodyPartType.ToString(t) == name then return BodyPartType.getDisplayName(t) end
        end
        return name
    end)
    if ok and text then return text end
    return name
end

function Client.say(chr, key)
    pcall(function() chr:Say(getText(key)) end)
end

function Client.reportText(payload)
    local title = payload.self and getText("IGUI_KFM_Exam_TitleSelf") or getText("IGUI_KFM_Exam_Title", tostring(payload.patient or ""))
    local text = " <H2> " .. title .. " <LINE> <TEXT> "
    local lines = payload.lines or {}
    local n = 0
    for _, l in pairs(lines) do n = n + 1 end
    for i = 1, n do
        local l = lines[i]
        if l and l.key then
            local a = l.args or {}
            local a1 = a[1] and Client.partDisplayName(a[1]) or nil
            text = text .. " <LINE> - " .. getText(l.key, a1)
        end
    end
    text = text .. " <LINE> <LINE> " .. getText("IGUI_KFM_Exam_Disclaimer")
    return text
end

function Client.showExam(payload)
    local w, h = 460, 380
    local x = getCore():getScreenWidth() / 2 - w / 2
    local y = getCore():getScreenHeight() / 2 - h / 2
    local modal = ISModalRichText:new(x, y, w, h, Client.reportText(payload), false)
    modal:initialise()
    modal:addToUIManager()
    modal.moveWithMouse = true
end

-- ------------------------------------------------------------ server commands (MP)
function Client.onServerCommand(module, command, args)
    if module ~= Game.MODULE then return end
    if command == "exam" then
        Client.showExam(args)
    elseif command == "result" then
        local p = getPlayer()
        if p and args and args.key then Client.say(p, args.key) end
    elseif command == "tq" then
        if args and args.id ~= nil then Game.mirror[tostring(args.id)] = args.tq or {} end
    end
end
Events.OnServerCommand.Add(Client.onServerCommand)

function Client.onCreatePlayer(playerNum, player)
    if isClient() and player then sendClientCommand(player, Game.MODULE, "tqSync", {}) end
end
Events.OnCreatePlayer.Add(Client.onCreatePlayer)

-- ------------------------------------------------------------ item scan (doctor's inventory + bags)
local function scanContainer(container, out, depth)
    local items = container:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item:IsInventoryContainer() then
            if depth < 3 then scanContainer(item:getInventory(), out, depth + 1) end
        else
            out[#out + 1] = item
        end
    end
end

function Client.scan(doctor)
    local all = {}
    scanContainer(doctor:getInventory(), all, 0)
    local found = { waters = {}, tourniquets = {}, blades = {}, fires = {} }
    for _, item in ipairs(all) do
        local ft = item:getFullType()
        if ft == Game.ITEM_STETHOSCOPE then found.steth = found.steth or item end
        if ft == Game.ITEM_TONGUE then found.tongue = found.tongue or item end
        if ft == Game.ITEM_SCALPEL then found.scalpel = found.scalpel or item end
        if ft == Game.ITEM_TOURNIQUET then table.insert(found.tourniquets, item) end
        if ft == Game.ITEM_BELT and not doctor:isEquipped(item) then
            local worn = false
            pcall(function() worn = item:isWorn() end)
            if not worn then table.insert(found.tourniquets, item) end
        end
        if Game.isBlade(item) then table.insert(found.blades, item) end
        if Game.isFireSource(item) then table.insert(found.fires, item) end
        local kind = Game.waterKind(item)
        if kind then table.insert(found.waters, { item = item, kind = kind }) end
    end
    return found
end

-- Queue: move items to the main inventory if needed, then the procedure.
function Client.queue(doctor, patient, bodyPart, procId, item, item2)
    for _, it in ipairs({ item, item2 }) do
        if it and it:getContainer() ~= doctor:getInventory() then
            ISTimedActionQueue.add(ISInventoryTransferUtil.newInventoryTransferAction(doctor, it, it:getContainer(), doctor:getInventory()))
        end
    end
    ISTimedActionQueue.add(KFM_ProcedureAction:new(doctor, patient, bodyPart, procId, item, item2))
end

local function addTooltip(option, text)
    local tt = ISInventoryPaneContextMenu.addToolTip()
    tt.description = text
    option.toolTip = tt
end

-- Adds an option; when the doctor lacks the level it is shown disabled with the requirement.
local function addProc(menu, doctor, patient, bodyPart, procId, labelKey, cfg, item, item2, tooltipKey)
    local level = Game.effectiveLevel(doctor, procId, 0)
    local helper = Game.hasHelper(doctor, patient)
    local req = Core.requiredLevel(procId, cfg, helper)
    local opt = menu:addOption(getText(labelKey), doctor, function() Client.queue(doctor, patient, bodyPart, procId, item, item2) end)
    local desc = tooltipKey and getText(tooltipKey) or ""
    if level < req then
        opt.notAvailable = true
        desc = desc .. " <LINE> <RGB:1,0.3,0.3> " .. getText("IGUI_KFM_RequiresLevel", tostring(req))
    else
        local fail = Core.failChance(procId, Game.doctorLevel(doctor), cfg)
        if fail > 0 then desc = desc .. " <LINE> " .. getText("IGUI_KFM_FailChance", tostring(math.floor(fail * 100 + 0.5))) end
    end
    if req > 0 and Core.PROCEDURES[procId].helper > 0 and not helper then
        desc = desc .. " <LINE> " .. getText("IGUI_KFM_HelperHint", tostring(Core.PROCEDURES[procId].helper))
    end
    addTooltip(opt, desc)
    return opt
end

local function subMenu(context, labelKey)
    local opt = context:addOption(getText(labelKey), nil)
    local sub = context:getNew(context)
    context:addSubMenu(opt, sub)
    return sub
end

-- ------------------------------------------------------------ body-part menu
function Client.addBodyPartOptions(panel, bodyPart, context)
    local cfg = Game.cfg()
    if not cfg.Enabled then return 0 end
    local doctor = panel.otherPlayer or panel.character
    local patient = panel.character
    if not doctor or not patient then return 0 end
    if isClient() and patient ~= doctor and Game.mirror[Game.mirrorKey(patient)] == nil then
        sendClientCommand(doctor, Game.MODULE, "tqSync", { id = patient:getOnlineID() })
    end
    local found = Client.scan(doctor)
    local w = Game.wound(bodyPart)
    local part = Game.partName(bodyPart)
    local before = context.numOptions
    local root = context:getNew(context)
    local rootOpt = context:addOption(getText("ContextMenu_KFM_Root"), nil)
    context:addSubMenu(rootOpt, root)

    if cfg.ExamEnabled then
        addProc(root, doctor, patient, bodyPart, "exam", "ContextMenu_KFM_Exam", cfg, found.steth, found.tongue, "Tooltip_KFM_Exam")
    end
    if Core.canIrrigate(w) and #found.waters > 0 then
        local sub = subMenu(root, "ContextMenu_KFM_Irrigate")
        for _, wv in ipairs(found.waters) do
            local opt = addProc(sub, doctor, patient, bodyPart, "irrigate", "ContextMenu_KFM_Irrigate", cfg, wv.item, nil, "Tooltip_KFM_Irrigate")
            opt.name = wv.item:getName()
            opt.itemForTexture = wv.item
        end
    end
    local tq = Game.tqView(patient)
    if tq[part] then
        addProc(root, doctor, patient, bodyPart, "tourniquetOff", "ContextMenu_KFM_TourniquetRemove", cfg, nil, nil, "Tooltip_KFM_TourniquetRemove")
    elseif Core.canTourniquet(part) and Core.tourniquetOnLimb(tq, part) == nil and #found.tourniquets > 0 then
        local sub = subMenu(root, "ContextMenu_KFM_Tourniquet")
        local done = {}
        for _, it in ipairs(found.tourniquets) do
            if not done[it:getFullType()] then
                done[it:getFullType()] = true
                local opt = addProc(sub, doctor, patient, bodyPart, "tourniquet", "ContextMenu_KFM_Tourniquet", cfg, it, nil, "Tooltip_KFM_Tourniquet")
                opt.name = it:getName()
                opt.itemForTexture = it
            end
        end
    end
    if Core.canCauterize(w) and #found.blades > 0 and #found.fires > 0 then
        addProc(root, doctor, patient, bodyPart, "cauterize", "ContextMenu_KFM_Cauterize", cfg, found.blades[1], found.fires[1], "Tooltip_KFM_Cauterize")
    end
    if w.fractureTime > 0 and not Game.md(patient).reduced[part] then
        local opt = addProc(root, doctor, patient, bodyPart, "reduceFracture", "ContextMenu_KFM_ReduceFracture", cfg, nil, nil, "Tooltip_KFM_ReduceFracture")
        if not Game.isResting(patient) then
            opt.notAvailable = true
            opt.toolTip.description = opt.toolTip.description .. " <LINE> <RGB:1,0.3,0.3> " .. getText("IGUI_KFM_MustRest")
        end
    end
    if Core.canDebride(w) and found.scalpel then
        addProc(root, doctor, patient, bodyPart, "debride", "ContextMenu_KFM_Debride", cfg, found.scalpel, nil, "Tooltip_KFM_Debride")
    end
    if root.numOptions <= 1 then
        context:removeLastOption()
        return 0
    end
    return context.numOptions - before
end

function Client.installHealthPanelHook()
    if not ISHealthPanel or ISHealthPanel.KFM_hooked then return end
    ISHealthPanel.KFM_hooked = true
    local original = ISHealthPanel.doBodyPartContextMenu
    ISHealthPanel.doBodyPartContextMenu = function(self, bodyPart, x, y)
        original(self, bodyPart, x, y)
        local ok, err = pcall(function()
            local playerNum = self.otherPlayer and self.otherPlayer:getPlayerNum() or self.character:getPlayerNum()
            local context = getPlayerContextMenu(playerNum)
            if not context or self.blockingMessage then return end
            local added = Client.addBodyPartOptions(self, bodyPart, context)
            if added > 0 and not context:getIsVisible() then context:setVisible(true) end
        end)
        if not ok then print("[KFM] health menu error: " .. tostring(err)) end
    end
end

-- ------------------------------------------------------------ inventory: examine yourself
function Client.onInventoryMenu(playerNum, context, items)
    local cfg = Game.cfg()
    if not cfg.Enabled or not cfg.ExamEnabled then return end
    local player = getSpecificPlayer(playerNum)
    if not player then return end
    local hit = false
    for _, v in ipairs(items) do
        local item = v
        if type(v) == "table" and v.items then item = v.items[1] end
        if item and (item:getFullType() == Game.ITEM_STETHOSCOPE or item:getFullType() == Game.ITEM_TONGUE) then hit = true end
    end
    if not hit then return end
    local found = Client.scan(player)
    local bp = Game.partByName(player, "Torso_Upper")
    if not bp then return end
    local opt = context:addOption(getText("ContextMenu_KFM_ExamSelf"), player, function()
        Client.queue(player, player, bp, "exam", found.steth, found.tongue)
    end)
    addTooltip(opt, getText("Tooltip_KFM_Exam"))
end
Events.OnFillInventoryObjectContextMenu.Add(Client.onInventoryMenu)

Events.OnGameStart.Add(Client.installHealthPanelHook)
Client.installHealthPanelHook()

return Client
