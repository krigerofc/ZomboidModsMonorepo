-- Basic Vehicle Maintenance - client: mechanics-window context menu, tooltips, inspection,
-- and feedback for results computed by the server (MP) or locally (SP).
require "MVR/Game"
require "TimedActions/MVR_RepairAction"
require "TimedActions/MVR_WorkshopAction"
require "Vehicles/TimedActions/ISWashVehicle"

local Core = MVR.Core
local Game = MVR.Game
local Config = MVR.Config

local Client = {}
MVR.Client = Client

local GOOD = " <RGB:0.4,0.9,0.4> "
local BAD = " <RGB:0.95,0.35,0.35> "
local INFO = " <RGB:0.85,0.85,0.85> "
local NOTE = " <RGB:0.9,0.8,0.4> "
local LINE = " <LINE> "

local function itemName(fullType)
    local ok, name = pcall(getItemDisplayName, fullType)
    if ok and name then return name end
    return fullType
end

local function partName(part)
    local key = "IGUI_VehiclePart" .. part:getId()
    local t = getText(key)
    if t == key then return part:getId() end
    return t
end

local function pct(x)
    return tostring(math.floor(x * 100 + 0.5))
end

local function timeBand(ticks)
    if ticks < 220 then return getText("Tooltip_MVR_Time_short") end
    if ticks < 380 then return getText("Tooltip_MVR_Time_medium") end
    return getText("Tooltip_MVR_Time_long")
end

-- ---------------------------------------------------------------- tooltip

function Client.buildTooltip(ev, part)
    local s = INFO .. getText("Tooltip_MVR_Title", partName(part)) .. LINE
    if ev.status == "not_repairable" then
        return s .. BAD .. getText("Tooltip_MVR_Status_not_repairable")
    end
    local cur = ev.current or 0
    s = s .. INFO .. getText("Tooltip_MVR_Condition", cur, ev.cap) .. LINE
    if ev.status ~= "ok" and ev.status ~= "missing_materials" and ev.status ~= "missing_tools" then
        s = s .. BAD .. getText("Tooltip_MVR_Status_" .. ev.status, ev.cap) .. LINE
    end

    if ev.reqs and #ev.reqs > 0 then
        s = s .. INFO .. getText("Tooltip_MVR_Requirements") .. LINE
        for _, r in ipairs(ev.reqs) do
            s = s .. (r.ok and GOOD or BAD) .. getText("Tooltip_MVR_Req_" .. r.key, r.need, r.have) .. LINE
        end
    end

    s = s .. INFO .. getText("Tooltip_MVR_Materials") .. LINE
    for _, r in ipairs(ev.report or {}) do
        local line = itemName(r.type) .. " " .. r.have .. "/" .. r.need
        if #r.alternatives > 0 then
            local alts = {}
            for _, a in ipairs(r.alternatives) do alts[#alts + 1] = itemName(a.type) .. " x" .. a.need end
            line = line .. INFO .. " (" .. getText("Tooltip_MVR_Or") .. " " .. table.concat(alts, ", ") .. ")"
        end
        s = s .. (r.ok and GOOD or BAD) .. line .. LINE
    end

    if ev.tools and #ev.tools > 0 then
        s = s .. INFO .. getText("Tooltip_MVR_Tools") .. LINE
        for _, t in ipairs(ev.tools) do
            s = s .. (t.item and GOOD or BAD) .. getText("Tooltip_MVR_Tool_" .. t.tag) .. LINE
        end
    end

    if ev.restorationOnly then s = s .. NOTE .. getText("Tooltip_MVR_HistoryRestoration") .. LINE end
    s = s .. INFO .. getText("Tooltip_MVR_Gain", ev.gain, ev.cap) .. LINE
    if (ev.ctx and ev.ctx.mech or 0) >= 4 then
        s = s .. NOTE .. getText("Tooltip_MVR_FailExact", pct(ev.fail)) .. LINE
    else
        s = s .. NOTE .. getText("Tooltip_MVR_FailBand", getText("Tooltip_MVR_Risk_" .. Core.riskBand(ev.fail))) .. LINE
    end
    if ev.opts.SevereFailEnabled then s = s .. INFO .. getText("Tooltip_MVR_Severe") .. LINE end
    s = s .. INFO .. getText("Tooltip_MVR_Time", timeBand(ev.time)) .. LINE
    if ev.opts.PatchHistoryEnabled and (ev.patches or 0) > 0 then
        s = s .. NOTE .. getText("Tooltip_MVR_Patches", ev.patches) .. LINE
    end
    if ev.opts.WorkshopBonusEnabled and ev.ctx then
        if ev.ctx.indoors then s = s .. GOOD .. getText("Tooltip_MVR_Indoors") .. LINE end
        if ev.ctx.dark then s = s .. BAD .. getText("Tooltip_MVR_Dark") .. LINE end
        if ev.ctx.hasJack and ev.cfg.jack then s = s .. GOOD .. getText("Tooltip_MVR_Jack") .. LINE end
    end
    if ev.vanilla == "available" then
        s = s .. NOTE .. getText("Tooltip_MVR_VanillaAvailable") .. LINE
    elseif ev.vanilla == "exists" then
        s = s .. INFO .. getText("Tooltip_MVR_VanillaExists") .. LINE
    end
    return s
end

local function newTooltip(text)
    local tooltip = ISToolTip:new()
    tooltip:initialise()
    tooltip:setVisible(false)
    tooltip.description = text
    return tooltip
end

-- ---------------------------------------------------------------- actions

local function queueTransfers(playerObj, ev)
    local inv = playerObj:getInventory()
    local moved = {}
    local function move(item)
        if item and not moved[item] and item:getContainer() and item:getContainer() ~= inv then
            moved[item] = true
            ISVehiclePartMenu.toPlayerInventory(playerObj, item)
        end
    end
    for _, pick in ipairs(ev.picks or {}) do move(pick.entry.item) end
    for _, t in ipairs(ev.tools or {}) do move(t.item) end
end

function Client.onRepair(playerObj, part, tierId)
    if playerObj:getVehicle() then ISVehicleMenu.onExit(playerObj) end
    local dark = Game.isDark(playerObj)
    local ev = Game.evaluate(playerObj, part, tierId, dark)
    if ev.status ~= "ok" then return end
    local vehicle = part:getVehicle()
    queueTransfers(playerObj, ev)
    ISTimedActionQueue.add(ISPathFindAction:pathToVehicleArea(playerObj, vehicle, part:getArea()))

    -- Engine work happens under the hood, like vanilla "Repair engine".
    local cover = nil
    if ev.key == "Engine" then
        local door = vehicle:getPartById("EngineDoor")
        if door and door:getDoor() and door:getInventoryItem() and not door:getDoor():isOpen() then cover = door end
    end
    if cover then
        if cover:getDoor():isLocked() and VehicleUtils.RequiredKeyNotFound(cover, playerObj) then
            ISTimedActionQueue.add(ISUnlockVehicleDoor:new(playerObj, cover))
        end
        ISTimedActionQueue.add(ISOpenVehicleDoor:new(playerObj, vehicle, cover))
        ISTimedActionQueue.add(MVR_RepairAction:new(playerObj, part, tierId, dark))
        ISTimedActionQueue.add(ISCloseVehicleDoor:new(playerObj, vehicle, cover))
    else
        ISTimedActionQueue.add(MVR_RepairAction:new(playerObj, part, tierId, dark))
    end
end

local function addRepairOption(menu, label, playerObj, part, tierId, ev)
    local option = menu:addOption(label, playerObj, Client.onRepair, part, tierId)
    option.toolTip = newTooltip(Client.buildTooltip(ev, part))
    option.notAvailable = ev.status ~= "ok"
    return option
end


-- Workshop entries share the original mechanics menu and the standard transfer/path queues.
function Client.workshopTooltip(ev, part)
    local text = INFO .. getText("Tooltip_MVR_Workshop", partName(part)) .. LINE
        .. (ev.status == "ok" and GOOD or BAD) .. getText("Tooltip_MVR_WorkshopStatus_" .. ev.status) .. LINE
    if ev.target then
        text = text .. INFO .. getText("Tooltip_MVR_WorkshopBenefit", ev.base, ev.target) .. LINE
        local keys = { cargo = "Tooltip_MVR_WorkshopCargo", glove = "Tooltip_MVR_WorkshopGlove", power = "Tooltip_MVR_WorkshopPower" }
        if keys[ev.role] then text = text .. INFO .. getText(keys[ev.role]) .. LINE end
    elseif ev.operation == "paint" or ev.operation == "rust" then
        text = text .. NOTE .. getText("Tooltip_MVR_CosmeticOnly") .. LINE
        if ev.operation == "rust" then text = text .. INFO .. getText("Tooltip_MVR_RustStep") .. LINE end
    end
    for _, req in ipairs(ev.reqs or {}) do
        text = text .. (req.ok and GOOD or BAD) .. getText("Tooltip_MVR_Req_" .. req.key, req.need, req.have) .. LINE
    end
    for _, t in ipairs(ev.tools or {}) do
        text = text .. (t.item and GOOD or BAD) .. itemName(t.type) .. LINE
    end
    for _, r in ipairs(ev.report or {}) do
        text = text .. (r.ok and GOOD or BAD) .. itemName(r.type) .. " " .. r.have .. "/" .. r.need .. LINE
    end
    return text .. INFO .. getText("Tooltip_MVR_WorkshopTime", ev.time) .. LINE
        .. INFO .. getText("Tooltip_MVR_WorkshopRisk") .. LINE .. getText("Tooltip_MVR_WorkshopCost")
end

function Client.onWorkshop(playerObj, part, operation, choice)
    local ev = Game.evaluateWorkshop(playerObj, part, operation, choice)
    if ev.status ~= "ok" then return end
    if playerObj:getVehicle() then ISVehicleMenu.onExit(playerObj) end
    queueTransfers(playerObj, ev)
    local vehicle = part:getVehicle()
    ISTimedActionQueue.add(ISPathFindAction:pathToVehicleArea(playerObj, vehicle, part:getArea()))
    local cover = part:getId() == "Engine" and vehicle:getPartById("EngineDoor") or nil
    if cover and cover:getDoor() and cover:getInventoryItem() and not cover:getDoor():isOpen() then
        if cover:getDoor():isLocked() then ISTimedActionQueue.add(ISUnlockVehicleDoor:new(playerObj, cover)) end
        ISTimedActionQueue.add(ISOpenVehicleDoor:new(playerObj, vehicle, cover))
        ISTimedActionQueue.add(MVR_WorkshopAction:new(playerObj, part, operation, choice))
        ISTimedActionQueue.add(ISCloseVehicleDoor:new(playerObj, vehicle, cover))
    else
        ISTimedActionQueue.add(MVR_WorkshopAction:new(playerObj, part, operation, choice))
    end
end

function Client.onWash(playerObj, part)
    if playerObj:getVehicle() then ISVehicleMenu.onExit(playerObj) end
    ISVehicleMenu.onWash(playerObj, part:getVehicle())
end

function Client.addWorkshopOptions(context, playerObj, part)
    local parent = context:addOption(getText("ContextMenu_MVR_Workshop"), nil, nil)
    local sub = ISContextMenu:getNew(context)
    context:addSubMenu(parent, sub)
    local function add(menu, key, operation, choice)
        local ev = Game.evaluateWorkshop(playerObj, part, operation, choice)
        -- Closure carries two explicit intent parameters; no client-computed final statistics.
        local option = menu:addOption(getText(key), playerObj, function(chr)
            Client.onWorkshop(chr, part, operation, choice)
        end)
        option.toolTip = newTooltip(Client.workshopTooltip(ev, part))
        option.notAvailable = ev.status ~= "ok"
        return option
    end
    if Game.partRole(part) then
        add(sub, "ContextMenu_MVR_Upgrade1", "upgrade", 1)
        add(sub, "ContextMenu_MVR_Upgrade2", "upgrade", 2)
        add(sub, "ContextMenu_MVR_Restore", "upgrade", 0)
    else
        add(sub, "ContextMenu_MVR_Unsupported", "upgrade", 1)
    end
    local paint = sub:addOption(getText("ContextMenu_MVR_Paint"), nil, nil)
    local colors = ISContextMenu:getNew(sub)
    sub:addSubMenu(paint, colors)
    for _, c in ipairs(Game.Palette) do add(colors, "ContextMenu_MVR_Color_" .. c.id, "paint", c.id) end
    add(sub, "ContextMenu_MVR_Rust", "rust", 1)
    local wash = sub:addOption(getText("ContextMenu_MVR_Wash"), playerObj, Client.onWash, part)
    wash.notAvailable = not ISWashVehicle.hasBlood(part:getVehicle())
        or ISWashVehicle.getWaterAmountForPlayer(playerObj) < 1
    wash.toolTip = newTooltip(INFO .. getText("Tooltip_MVR_Wash"))
end

-- ---------------------------------------------------------------- inspection (v1.1)

MVR_InspectAction = ISBaseTimedAction:derive("MVR_InspectAction")

function MVR_InspectAction:isValid()
    return self.vehicle ~= nil and not self.character:getVehicle()
        and self.character:DistTo(self.vehicle:getX(), self.vehicle:getY()) <= 6
end

function MVR_InspectAction:waitToStart()
    self.character:faceThisObject(self.vehicle)
    return self.character:shouldBeTurning()
end

function MVR_InspectAction:update()
    self.character:faceThisObject(self.vehicle)
end

function MVR_InspectAction:start()
    self:setActionAnim("VehicleWorkOnMid")
end

function MVR_InspectAction:stop()
    ISBaseTimedAction.stop(self)
end

function MVR_InspectAction:perform()
    Client.showInspection(self.character, self.vehicle)
    ISBaseTimedAction.perform(self)
end

function MVR_InspectAction:new(character, vehicle)
    local o = ISBaseTimedAction.new(self, character)
    o.vehicle = vehicle
    o.stopOnWalk = true
    o.stopOnRun = true
    o.forceProgressBar = true
    o.maxTime = character:isTimedActionInstant() and 1 or 300
    return o
end

function Client.inspectionText(playerObj, vehicle)
    local opts = Game.opts()
    local mech = playerObj:getPerkLevel(Perks.Mechanics)
    local lines, critical = {}, {}
    for i = 0, vehicle:getPartCount() - 1 do
        local part = vehicle:getPartByIndex(i)
        if Game.isPartPresent(part) and part:getCategory() ~= "nodisplay" then
            local cfg = Game.partConfig(part)
            local cond = part:getCondition()
            local col = cond < 25 and BAD or (cond < 60 and NOTE or GOOD)
            local s = col .. getText("IGUI_MVR_Inspect_Line", partName(part), cond)
            if cfg.notRepairable then
                s = s .. INFO .. " - " .. getText("IGUI_MVR_Inspect_Replace")
            else
                local patches = Game.patches(part, opts)
                if patches > 0 then s = s .. INFO .. " - " .. getText("IGUI_MVR_Inspect_Patches", patches) end
                local fail = Core.failChance(cfg, mech, 0, opts)
                local risk = mech >= 4 and (pct(fail) .. "%") or getText("Tooltip_MVR_Risk_" .. Core.riskBand(fail))
                s = s .. INFO .. " - " .. getText("IGUI_MVR_Inspect_Risk", risk)
            end
            if Game.vanillaFix(playerObj, part) == "available" then
                s = s .. GOOD .. " - " .. getText("IGUI_MVR_Inspect_Vanilla")
            end
            lines[#lines + 1] = s
            if cond < 25 then critical[#critical + 1] = partName(part) end
        end
    end
    local name = vehicle:getScript() and getText("IGUI_VehicleName" .. vehicle:getScript():getName()) or ""
    local head = " <H2> " .. getText("IGUI_MVR_Inspect_Title", name) .. LINE .. " <TEXT> "
    if #critical > 0 then
        head = head .. BAD .. getText("IGUI_MVR_Inspect_Critical", table.concat(critical, ", ")) .. LINE
    else
        head = head .. GOOD .. getText("IGUI_MVR_Inspect_NoCritical") .. LINE
    end
    return head .. LINE .. table.concat(lines, LINE)
end

function Client.showInspection(playerObj, vehicle)
    local text = Client.inspectionText(playerObj, vehicle)
    local w, h = 640, 520
    local modal = ISModalRichText:new(getCore():getScreenWidth() / 2 - w / 2, getCore():getScreenHeight() / 2 - h / 2, w, h, text, false)
    modal:initialise()
    modal:addToUIManager()
    if JoypadState.players[playerObj:getPlayerNum() + 1] then
        setJoypadFocus(playerObj:getPlayerNum(), modal)
    end
end

function Client.onInspect(playerObj, part)
    local vehicle = part:getVehicle()
    if playerObj:getVehicle() then ISVehicleMenu.onExit(playerObj) end
    ISTimedActionQueue.add(ISPathFindAction:pathToVehicleArea(playerObj, vehicle, part:getArea()))
    ISTimedActionQueue.add(MVR_InspectAction:new(playerObj, vehicle))
end

-- ---------------------------------------------------------------- context menu hook

function Client.addOptions(mechanics, part)
    local context = mechanics.context
    if not context or not part or not part:getId() then return end
    local opts = Game.opts()
    if not opts.Enabled then return end
    local playerObj = getSpecificPlayer(mechanics.playerNum)
    if not playerObj or not Game.isPartPresent(part) then return end

    local dark = Game.isDark(playerObj)
    local cfg = Game.partConfig(part)
    local label = getText("ContextMenu_MVR_Repair")
    if cfg.notRepairable then
        local ev = Game.evaluate(playerObj, part, "patch", dark, opts)
        local option = context:addOption(label, nil, nil)
        option.toolTip = newTooltip(Client.buildTooltip(ev, part))
        option.notAvailable = true
    elseif opts.QualityTiersEnabled then
        local parent = context:addOption(label, nil, nil)
        local sub = ISContextMenu:getNew(context)
        context:addSubMenu(parent, sub)
        local vanilla = Game.vanillaFix(playerObj, part)
        for _, tier in ipairs(Config.Tiers) do
            local ev = Game.evaluate(playerObj, part, tier.id, dark, opts)
            ev.vanilla = vanilla
            addRepairOption(sub, getText("ContextMenu_MVR_Tier_" .. tier.id), playerObj, part, tier.id, ev)
        end
    else
        local ev = Game.evaluate(playerObj, part, "patch", dark, opts)
        ev.vanilla = Game.vanillaFix(playerObj, part)
        addRepairOption(context, label, playerObj, part, "patch", ev)
    end

    local inspect = context:addOption(getText("ContextMenu_MVR_Inspect"), playerObj, Client.onInspect, part)
    if dark then
        inspect.notAvailable = true
        inspect.toolTip = newTooltip(BAD .. getText("Tooltip_MVR_InspectDark"))
    else
        inspect.toolTip = newTooltip(INFO .. getText("Tooltip_MVR_Inspect"))
    end

    Client.addWorkshopOptions(context, playerObj, part)

    if context.numOptions > 1 and not context:getIsVisible() then context:setVisible(true) end
end

if ISVehicleMechanics and ISVehicleMechanics.doPartContextMenu then
    local original = ISVehicleMechanics.doPartContextMenu
    function ISVehicleMechanics:doPartContextMenu(part, x, y)
        -- The original returns early (paused game, player inside the vehicle) without building a
        -- menu; clearing the field first means we never add options to a stale menu.
        self.context = nil
        original(self, part, x, y)
        if not self.context then return end
        local ok, err = pcall(Client.addOptions, self, part)
        if not ok then print("[MVR] context menu error: " .. tostring(err)) end
    end
end

-- ---------------------------------------------------------------- feedback

local VARIANTS = { success = 3, crit = 3, light = 3, severe = 3 }

local function say(chr, base, key)
    local n = VARIANTS[key] or 1
    chr:Say(getText(base .. key .. "_" .. tostring(ZombRand(n) + 1)))
end

function Client.showResult(chr, result)
    if not chr or type(result) ~= "table" then return end
    if result.status == "customized" then
        HaloTextHelper.addGoodText(chr, getText("IGUI_MVR_WorkshopDone"))
        return
    end
    if result.status ~= "done" then
        chr:Say(getText("IGUI_MVR_Fail_" .. tostring(result.status)))
        return
    end
    say(chr, "IGUI_MVR_Say_", result.outcome)
    local text = getText("IGUI_MVR_Halo_Condition", result.before, result.after)
    if Core.isSuccess(result.outcome) then
        HaloTextHelper.addGoodText(chr, text)
    else
        HaloTextHelper.addBadText(chr, text)
    end
    for _, key in ipairs(result.events or {}) do
        HaloTextHelper.addBadText(chr, getText("IGUI_MVR_Event_" .. key))
    end
end

local function localPlayerByOnlineId(id)
    for i = 0, getNumActivePlayers() - 1 do
        local p = getSpecificPlayer(i)
        if p and (id == nil or p:getOnlineID() == id) then return p end
    end
    return nil
end

local function onServerCommand(module, command, args)
    if module ~= Game.MODULE or command ~= "result" then return end
    local chr = localPlayerByOnlineId(args and args.onlineId)
    if chr then Client.showResult(chr, args) end
end
Events.OnServerCommand.Add(onServerCommand)

return Client
