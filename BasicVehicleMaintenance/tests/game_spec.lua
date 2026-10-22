-- Glue tests: Game.lua, MVR_RepairAction and the client menu against a mocked B42 API.
-- Globals from run.js: TR (EN translations, key -> text), ACTIONFILE, MENUFILE.
local failures = 0
local checks = 0
local function check(cond, msg)
    checks = checks + 1
    if not cond then
        failures = failures + 1
        print("  FAIL game: " .. msg)
    end
end

-- ---------------------------------------------------------------- mock world
local calls
local function resetCalls()
    calls = { removed = {}, itemStats = 0, bodySync = 0, statSync = 0, server = {}, xp = {}, client = {}, transmitCond = 0, transmitMd = 0 }
end
resetCalls()

local RANDS = {}
function ZombRand(n, m)
    local f = table.remove(RANDS, 1) or 0.999999
    if m then return n + math.floor(f * (m - n)) end
    return math.floor(f * n)
end
local SERVER = false
function isServer() return SERVER end
function isClient() return false end
function getDebug() return false end
function instanceof(o, cls)
    if type(o) ~= "table" then return false end
    if cls == "InventoryItem" then return o._item == true end
    return o._class == cls
end
local NOW = 1000000
function getGameTime() return { getCalender = function() return { getTimeInMillis = function() return NOW end } end } end
function sendRemoveItemFromContainer(c, i) calls.removed[#calls.removed + 1] = { c = c, i = i } end
function sendItemStats() calls.itemStats = calls.itemStats + 1 end
function syncBodyPart() calls.bodySync = calls.bodySync + 1 end
function syncPlayerStats() calls.statSync = calls.statSync + 1 end
function sendServerCommand(p, mod, cmd, args) calls.server[#calls.server + 1] = { mod = mod, cmd = cmd, args = args } end
function addXp(chr, perk, n) calls.xp[#calls.xp + 1] = n end
SandboxVars = { MVR = {} }
VehicleUtils = { CheckForUnlockedDoorsWindows = function() return false end, RequiredKeyNotFound = function(part) return part.needKey == true end }
ItemTag = { WRENCH = "wrench", SCREWDRIVER = "screwdriver", SEWING_NEEDLE = "sewingneedle" }
Perks = { Mechanics = "Mechanics", MetalWelding = "MetalWelding", Electricity = "Electricity" }
BodyPartType = { Hand_L = "Hand_L", Hand_R = "Hand_R" }
CharacterStat = { UNHAPPINESS = "UNHAPPINESS" }
ItemBodyLocation = { HANDS = "Hands", HANDS_LEFT = "Hands_L", HANDS_RIGHT = "Hands_R" }
IsoObjectChange = { MECHANIC_ACTION_DONE = 1 }
Metabolics = { MediumWork = 1 }
FixingManager = { getFixes = function() return { isEmpty = function() return true end, size = function() return 0 end } end }

local function jlist(t)
    return { size = function() return #t end, get = function(_, i) return t[i + 1] end, isEmpty = function() return #t == 0 end }
end

local nextId = 1
local Container = {}
Container.__index = Container
local function newContainer() return setmetatable({ list = {} }, Container) end
function Container:getItems() return jlist(self.list) end
function Container:add(item) self.list[#self.list + 1] = item; item.container = self; return item end
function Container:DoRemoveItem(item)
    for i, v in ipairs(self.list) do if v == item then table.remove(self.list, i); item.container = nil; return end end
end
local function walk(c, fn)
    for _, it in ipairs(c.list) do
        local r = fn(it)
        if r then return r end
        if it.inv then
            r = walk(it.inv, fn)
            if r then return r end
        end
    end
end
function Container:getFirstTagEvalRecurse(tag, pred) return walk(self, function(it) if it.tags[tag] and pred(it) then return it end end) end
function Container:getFirstTypeRecurse(t) return walk(self, function(it) if it.t == t then return it end end) end
function Container:haveThisKeyId() return self.key end
function Container:containsTypeRecurse(t) return self:getFirstTypeRecurse(t) ~= nil end

local function newItem(t, opt)
    opt = opt or {}
    nextId = nextId + 1
    local it = { _item = true, t = t, id = nextId, tags = opt.tags or {}, cond = opt.cond or 10, uses = opt.uses, md = {} }
    if opt.uses then it._class = "DrainableComboItem" end
    if opt.bag then it._class = "InventoryContainer"; it.inv = newContainer() end
    function it:getModData() return self.md end
    function it:getFullType() return self.t end
    function it:getID() return self.id end
    function it:isBroken() return self.cond <= 0 end
    function it:getContainer() return self.container end
    function it:getInventory() return self.inv end
    function it:getCurrentUses() return self.uses end
    function it:UseAndSync()
        self.uses = self.uses - 1
        if self.uses <= 0 and self.container then self.container:DoRemoveItem(self) end
    end
    function it:getCondition() return self.cond end
    function it:setCondition(c) self.cond = c end
    function it:setJobDelta() end
    function it:setJobType() end
    return it
end

local function newPlayer(levels)
    local inv = newContainer()
    local p = { inv = inv, levels = levels or {}, worn = {}, said = {}, stats = 0, mech = {}, body = {} }
    function p:getInventory() return self.inv end
    function p:getPerkLevel(perk) return self.levels[perk] or 0 end
    function p:getWornItem(loc) return self.worn[loc] end
    function p:tooDarkToRead() return false end
    function p:getBodyDamage()
        local me = self
        return { getBodyPart = function(_, bt)
            me.body[bt] = me.body[bt] or { setScratched = function(s) s.scratched = true end, setCut = function(s) s.cut = true end,
                setBurnTime = function(s, v) s.burn = v end, setNeedBurnWash = function(s, v) s.wash = v end }
            return me.body[bt]
        end }
    end
    function p:getStats() local me = self; return { add = function(_, _, v) me.stats = me.stats + v end } end
    function p:getMechanicsItem(k) return self.mech[k] end
    function p:addMechanicsItem(k, _, t) self.mech[k] = t end
    function p:sendObjectChange() end
    function p:getOnlineID() return 7 end
    function p:Say(t) self.said[#self.said + 1] = t end
    function p:getVehicle() return nil end
    function p:getZ() return self.z or 0 end
    function p:isTimedActionInstant() return false end
    function p:DistTo() return 1 end
    function p:getPlayerNum() return 0 end
    return p
end

local function newVehicle(outside)
    local v = { parts = {}, outside = outside ~= false }
    function v:getSquare() local me = self; return { isOutside = function() return me.outside end } end
    function v:getRust() return 0 end
    function v:isDoColor() return false end
    function v:getEnginePower() return 1000 end
    function v:getKeyId() return 42 end
    function v:getMechanicalID() return 42 end
    function v:transmitPartCondition() calls.transmitCond = calls.transmitCond + 1 end
    function v:transmitPartModData() calls.transmitMd = calls.transmitMd + 1 end
    function v:updatePartStats() end
    function v:getX() return 0 end
    function v:getY() return 0 end
    function v:getZ() return self.z or 0 end
    function v:getCurrentSpeedKmHour() return self.speed or 0 end
    function v:isEngineRunning() return self.running == true end
    function v:isInArea() return self.inArea ~= false end
    function v:getPartById(id) return self.parts[id] end
    function v:getPartCount() local n = 0; for _ in pairs(self.parts) do n = n + 1 end; return n end
    function v:getPartByIndex(i) local n = 0; for _, p in pairs(self.parts) do if n == i then return p end; n = n + 1 end end
    function v:getScript() return { getName = function() return "CarNormal" end } end
    return v
end

local function newPart(vehicle, id, cond, installed)
    local item = installed ~= false and newItem("Base.PartItem") or nil
    local p = { id = id, cond = cond, item = item, vehicle = vehicle, md = {} }
    function p:getId() return self.id end
    function p:getCondition() return self.cond end
    function p:setCondition(c) self.cond = c end
    function p:getInventoryItem() return self.item end
    function p:getVehicle() return self.vehicle end
    function p:getModData() return self.md end
    function p:getItemContainer() return nil end
    function p:getScriptPart() return { isRepairMechanic = function() return true end, isMechanicRequireKey = function() return self.needKey == true end } end
    function p:doInventoryItemStats() end
    function p:getMechanicSkillInstaller() return 0 end
    function p:isContainer() return false end
    function p:getWheelIndex() return -1 end
    function p:getArea() return "Engine" end
    function p:getCategory() return "brakes" end
    vehicle.parts[id] = p
    return p
end

-- ---------------------------------------------------------------- load mod code
MVR = nil
require "MVR/Game"
local Game, Core = MVR.Game, MVR.Core

local function setupBrake(opt)
    opt = opt or {}
    local chr = newPlayer(opt.levels)
    local inv = chr.inv
    local bag = inv:add(newItem("Base.Bag_Schoolbag", { bag = true }))
    local inner = bag.inv:add(newItem("Base.Bag_FannyPack", { bag = true }))
    inv:add(newItem("Base.ScrapMetal"))
    bag.inv:add(newItem("Base.ScrapMetal"))
    inner.inv:add(newItem("Base.ScrapMetal"))
    bag.inv:add(newItem("Base.RippedSheets"))
    inner.inv:add(newItem("Base.RippedSheets"))
    local tape = inner.inv:add(newItem("Base.DuctTape", { uses = 2 }))
    inv:add(newItem("Base.Wrench", { tags = { wrench = true }, cond = 0 })) -- broken: ignored
    local wrench = bag.inv:add(newItem("Base.PipeWrench", { tags = { wrench = true }, cond = 9 }))
    local v = newVehicle(opt.outside)
    local part = newPart(v, opt.partId or "BrakeFrontLeft", opt.cond or 20)
    return chr, part, { bag = bag, inner = inner, tape = tape, wrench = wrench }
end

local function countType(c, t)
    local n = 0
    walk(c, function(it) if it.t == t then n = n + 1 end end)
    return n
end

-- evaluate: statuses
do
    local chr, part = setupBrake()
    local ev = Game.evaluate(chr, part, "patch", false)
    check(ev.status == "ok", "brake with materials in nested bags is ok (got " .. tostring(ev.status) .. ")")
    check(ev.fail > 0.19 and ev.fail < 0.21 and ev.cap == 55 and ev.gain == 15, "brake numbers at Mechanics 0")
    check(ev.tools[1].item and ev.tools[1].item.t == "Base.PipeWrench", "broken wrench skipped, bag wrench found")

    local chr2, part2 = setupBrake()
    for _, it in ipairs(chr2.inv.list) do if it.inv then it.inv.list = {} end end
    check(Game.evaluate(chr2, part2, "patch", false).status == "missing_tools", "no working wrench -> missing_tools")

    local chr3, part3 = setupBrake({ partId = "HeadlightLeft" })
    check(Game.evaluate(chr3, part3, "patch", false).status == "not_repairable", "headlight -> not_repairable, no crash")
    local v = newVehicle()
    check(Game.evaluate(chr, newPart(v, "DoorFrontLeft", 20, false), "patch", false).status == "not_installed", "uninstalled -> not_installed")
    check(Game.evaluate(chr, newPart(v, "BrakeRearLeft", 100), "patch", false).status == "undamaged", "100 -> undamaged")
    check(Game.evaluate(chr, newPart(v, "BrakeRearRight", 55), "patch", false).status == "above_cap", "at cap -> above_cap")
    check(Game.evaluate(chr, part, "overhaul", false).status == "skill", "overhaul at Mechanics 0 -> skill")
    SandboxVars.MVR.Enabled = false
    check(Game.evaluate(chr, part, "patch", false).status == "disabled", "sandbox disabled")
    SandboxVars.MVR.Enabled = true
    SandboxVars.MVR.QualityTiersEnabled = false
    check(Game.evaluate(chr, part, "overhaul", false).tier.id == "patch", "tiers disabled -> patch only")
    SandboxVars.MVR.QualityTiersEnabled = true

    local chr4, part4 = setupBrake({ outside = false })
    local e4 = Game.evaluate(chr4, part4, "patch", true)
    check(e4.ctx.indoors and e4.ctx.dark and e4.fail > 0.21 and e4.fail < 0.23, "indoors -3 and dark +5 points")
    chr4.worn.Hands = newItem("Base.Gloves_LeatherGloves")
    check(Game.evaluate(chr4, part4, "patch", false).ctx.gloves, "gloves detected")
end

-- applyRepair: success on server
do
    resetCalls()
    SERVER = true
    local chr, part, refs = setupBrake()
    RANDS = { 0.5, 0.99, 0.99, 0.99 } -- success, no injury, no tool wear, no waste
    local res = Game.applyRepair(chr, part, "patch", false)
    check(res.status == "done" and res.outcome == "success", "success outcome")
    check(part.cond == 35 and res.before == 20 and res.after == 35, "condition 20 -> 35")
    check(countType(chr.inv, "Base.ScrapMetal") == 0 and countType(chr.inv, "Base.RippedSheets") == 0, "materials removed from nested bags")
    check(refs.tape.uses == 1 and refs.tape.container ~= nil, "one tape use consumed (drainable)")
    check(#calls.removed == 5, "sendRemoveItemFromContainer for each removed item (got " .. #calls.removed .. ")")
    local okCont = true
    for _, r in ipairs(calls.removed) do if r.c == nil or r.c == chr.inv and r.i.t == "Base.RippedSheets" then okCont = false end end
    check(okCont, "removal synced with the item's own container")
    check(calls.transmitCond == 1 and calls.transmitMd == 1, "part condition + modData transmitted")
    check(part.md.MVR and part.md.MVR.patches == 1, "patch history recorded")
    check(#calls.xp == 1 and calls.xp[1] == 3, "3 XP on success")
    Game.feedback(chr, res)
    check(#calls.server == 1 and calls.server[1].cmd == "result", "server sends result to client")

    -- same part again, same day: no XP, cap lowered by history
    for _ = 1, 3 do chr.inv:add(newItem("Base.ScrapMetal")) end
    chr.inv:add(newItem("Base.RippedSheets")); chr.inv:add(newItem("Base.RippedSheets"))
    RANDS = { 0.5, 0.99, 0.99, 0.99 }
    local res2 = Game.applyRepair(chr, part, "patch", false)
    check(res2.after == 50 and #calls.xp == 1, "second repair: cap 52 after one patch (35+15=50), no XP same day")
    RANDS = { 0.5, 0.99, 0.99, 0.99 }
    NOW = NOW + MVR.Config.Rules.xpCooldownMs
    for _ = 1, 3 do chr.inv:add(newItem("Base.ScrapMetal")) end
    chr.inv:add(newItem("Base.RippedSheets")); chr.inv:add(newItem("Base.RippedSheets")); chr.inv:add(newItem("Base.DuctTape", { uses = 4 }))
    part.cond = 20
    Game.applyRepair(chr, part, "patch", false)
    check(#calls.xp == 2, "XP again on the next game day")
end

-- applyRepair: severe failure + side effects on server
do
    resetCalls()
    SERVER = true
    local chr, part, refs = setupBrake({ cond = 30 })
    -- outcome 0.01 (severe), injury 0.01 -> cut? 0.1 (<0.3 cut), hand 0.9 (R), tool wear 0.05 -> amount 0.5 (=2), waste 0.99, frustration 0.01, tool pick 0
    RANDS = { 0.01, 0.01, 0.1, 0.9, 0.05, 0.5, 0.99, 0.01, 0.0 }
    local res = Game.applyRepair(chr, part, "patch", false)
    check(res.outcome == "severe" and part.cond == 10, "severe failure: -20 (30 -> 10)")
    check(part.md.MVR == nil, "no patch recorded on failure")
    check(chr.body.Hand_R and chr.body.Hand_R.cut, "cut on right hand")
    check(calls.bodySync == 1, "body part synced")
    check(refs.wrench.cond == 7 and calls.itemStats == 1, "tool wear -2 + sendItemStats")
    check(chr.stats == 5 and calls.statSync == 1, "frustration +5 synced")
    check(#calls.xp == 1 and calls.xp[1] == 1, "1 XP on failure")
    check(countType(chr.inv, "Base.ScrapMetal") == 0, "materials lost on failure")
end

-- applyRepair: SP (no network sync calls), missing materials at complete
do
    resetCalls()
    SERVER = false
    local shown = {}
    MVR.Client = { showResult = function(_, r) shown[#shown + 1] = r end }
    local chr, part = setupBrake()
    RANDS = { 0.5, 0.99, 0.99, 0.99 }
    local res = Game.applyRepair(chr, part, "patch", false)
    Game.feedback(chr, res)
    check(res.outcome == "success" and #calls.removed == 0 and #calls.server == 0, "SP: no network sync calls")
    check(#shown == 1, "SP: feedback shown locally")
    local res2 = Game.applyRepair(chr, part, "patch", false)
    check(res2.status == "missing_materials" and part.cond == 35, "revalidation in complete: nothing changes without materials")
    MVR.Client = nil
end

-- ---------------------------------------------------------------- TimedAction (MP serialization contract)
package.loaded["TimedActions/ISBaseTimedAction"] = true
ISBaseTimedAction = {}
ISBaseTimedAction.__index = ISBaseTimedAction
function ISBaseTimedAction:derive(name)
    local cls = setmetatable({}, { __index = self })
    cls.Type = name
    cls.__index = cls
    return cls
end
function ISBaseTimedAction.new(cls, character)
    local o = setmetatable({}, cls)
    o.character = character
    o.maxTime = -1
    return o
end
function ISBaseTimedAction:perform() self.performed = true end
function ISBaseTimedAction:stop() end
function getText(k, ...) return TR[k] or k end
dofile(ACTIONFILE)
check(MVR_RepairAction and MVR_RepairAction.Type == "MVR_RepairAction", "action class is a global named like its Type")
do
    local chr, part = setupBrake()
    local a = MVR_RepairAction:new(chr, part, "patch", true)
    local i = 1
    while true do
        local name = debug.getlocal(MVR_RepairAction.new, i)
        if not name then break end
        if name ~= "self" then check(a[name] ~= nil, "new() parameter '" .. name .. "' stored under the same field (B42 MP rebuild)") end
        i = i + 1
    end
    check(a.maxTime == 250 and a:isValid(), "action duration and validity")
    for _, k in ipairs({ "isValid", "waitToStart", "update", "start", "stop", "perform", "complete", "getDuration" }) do
        check(type(MVR_RepairAction[k]) == "function", "action defines " .. k)
    end
    SERVER = true
    resetCalls()
    RANDS = { 0.5, 0.99, 0.99, 0.99 }
    check(a:complete() == true and part.cond == 35 and calls.server[1].args.onlineId == 7, "complete() repairs and reports to the owner")
    SERVER = false
end

-- ---------------------------------------------------------------- client menu smoke test
local missing = {}
function getText(k, ...)
    if TR[k] then
        local s = TR[k]
        local args = { ... }
        for n = 1, #args do s = string.gsub(s, "%%" .. n, tostring(args[n])) end
        return s
    end
    if not (string.find(k, "^IGUI_VehiclePart") or string.find(k, "^IGUI_VehicleName")) then missing[k] = true end
    return k
end
function getItemDisplayName(t) return t end
local function newMenu()
    local m = { options = {}, numOptions = 1, visible = true }
    function m:addOption(name, target, fn, a, b)
        local o = { name = name, target = target, fn = fn, a = a, b = b }
        self.options[#self.options + 1] = o
        self.numOptions = self.numOptions + 1
        return o
    end
    function m:addSubMenu(opt, sub) opt.sub = sub end
    function m:getIsVisible() return self.visible end
    function m:setVisible(v) self.visible = v end
    return m
end
ISContextMenu = { getNew = function() return newMenu() end }
ISToolTip = { new = function() return { initialise = function() end, setVisible = function() end } end }
package.loaded["Vehicles/TimedActions/ISWashVehicle"] = true
ISWashVehicle = { hasBlood = function() return false end, getWaterAmountForPlayer = function() return 0 end }
local paused = false
ISVehicleMechanics = {}
function ISVehicleMechanics:doPartContextMenu(part, x, y)
    if paused then return end
    self.context = newMenu()
end
local listeners = {}
Events = { OnServerCommand = { Add = function(fn) listeners[#listeners + 1] = fn end } }
local thePlayer
function getSpecificPlayer() return thePlayer end
function getNumActivePlayers() return 1 end
HaloTextHelper = { addGoodText = function(p, t) p.halo = t end, addBadText = function(p, t) p.halo = t end }
dofile(MENUFILE)
check(#listeners == 1, "client registers OnServerCommand")
do
    local chr, part = setupBrake()
    thePlayer = chr
    local win = { playerNum = 0, chr = chr }
    setmetatable(win, { __index = ISVehicleMechanics })
    win:doPartContextMenu(part, 0, 0)
    local opts = win.context.options
    check(#opts == 3 and opts[1].sub and #opts[1].sub.options == 3, "repair submenu with 3 tiers + inspect option")
    local patch = opts[1].sub.options[1]
    check(patch.notAvailable == false and patch.toolTip.description:find("<LINE>", 1, true), "patch available, rich-text tooltip")
    check(opts[1].sub.options[3].notAvailable == true, "overhaul locked at Mechanics 0")
    paused = true
    win.context = { stale = true }
    win:doPartContextMenu(part, 0, 0)
    check(win.context == nil, "no options added to a stale menu when vanilla returns early")
    paused = false

    local chr2, light = setupBrake({ partId = "HeadlightRight" })
    thePlayer = chr2
    win.chr = chr2
    win:doPartContextMenu(light, 0, 0)
    check(win.context.options[1].notAvailable == true and win.context.options[1].toolTip.description:find("replace", 1, true), "headlight option disabled with hint")

    SandboxVars.MVR.QualityTiersEnabled = false
    win:doPartContextMenu(part, 0, 0)
    check(win.context.options[1].sub == nil and win.context.options[1].fn ~= nil, "tiers off -> single option")
    SandboxVars.MVR.QualityTiersEnabled = true

    listeners[1]("MVR", "result", { status = "done", outcome = "crit", before = 10, after = 30, events = { "Injury" }, onlineId = 7 })
    check(#chr2.said == 1 and chr2.halo ~= nil, "feedback: Say + halo text")
    listeners[1]("MVR", "result", { status = "missing_materials", onlineId = 7 })
    check(chr2.said[2] == TR.IGUI_MVR_Fail_missing_materials, "failure feedback text")
    MVR.Client.inspectionText(chr, part:getVehicle())
end

-- Intrinsic vanilla Engine has no InventoryItem; removable missing parts still fail.
do
    local chr = newPlayer()
    local v = newVehicle()
    local engine = newPart(v, "Engine", 20, false)
    for i = 1, 4 do
        chr.inv:add(newItem("Base.ScrapMetal"))
        chr.inv:add(newItem("Base.Screws"))
    end
    chr.inv:add(newItem("Base.SheetMetal"))
    chr.inv:add(newItem("Base.DuctTape", { uses = 2 }))
    chr.inv:add(newItem("Base.Wrench", { tags = { wrench = true } }))
    chr.inv:add(newItem("Base.Screwdriver", { tags = { screwdriver = true } }))
    check(Game.evaluate(chr, engine, "patch", false).status == "ok", "Engine without item evaluates ok")
    check(MVR_RepairAction:new(chr, engine, "patch", false):isValid(), "Engine action valid")
    thePlayer = chr
    local win = setmetatable({ playerNum = 0, chr = chr }, { __index = ISVehicleMechanics })
    win:doPartContextMenu(engine, 0, 0)
    check(#win.context.options == 3, "Engine menu repair + inspect + workshop")
    check(MVR.Client.inspectionText(chr, v):find("Engine", 1, true) ~= nil, "inspection includes Engine")
    SERVER = true
    resetCalls()
    RANDS = { 0.5, 0.99, 0.99, 0.99 }
    local result = Game.applyRepair(chr, engine, "patch", false)
    check(result.status == "done" and engine.cond == 35 and #calls.removed == 9
        and countType(chr.inv, "Base.DuctTape") == 0, "Engine repair consumes exact materials")
    check(Game.evaluate(chr, newPart(v, "DoorFrontLeft", 20, false), "patch", false).status == "not_installed",
        "absent removable door rejected")
    SERVER = false
end


-- A queued repair belongs to the originally selected installed item.
do
    local chr, part = setupBrake()
    local a = MVR_RepairAction:new(chr, part, "patch", false)
    part.item = newItem("Base.PartItem")
    check(not a:isValid(), "replaced item cancels queued repair")
    local rebuilt = MVR_RepairAction:new(chr, part, a.tierId, a.dark, a.expectedItemId)
    check(not rebuilt:isValid(), "server reconstruction keeps original item identity")
    SERVER = true
    resetCalls()
    RANDS = { 0.5, 0.99, 0.99, 0.99 }
    local result = a:complete()
    check(result == false and part.cond == 20 and #calls.removed == 0
        and #calls.xp == 0 and part.md.MVR == nil,
        "replacement is not repaired, charged, awarded XP or patch history")
    SERVER = false
end




-- Work location and vehicle state are rechecked where server effects happen.
do
    local chr, part = setupBrake()
    local vehicle = part:getVehicle()
    chr.z = 1
    check(not MVR_RepairAction:new(chr, part, "patch", false):isValid(), "different floor cannot repair")
    chr.z = 0
    vehicle.speed = 2
    check(not MVR_RepairAction:new(chr, part, "patch", false):isValid(), "moving vehicle cannot be repaired")
    vehicle.speed = 0
    vehicle.running = true
    check(not MVR_RepairAction:new(chr, part, "patch", false):isValid(), "running engine blocks work")
    vehicle.running = false
    vehicle.z = 0.2
    check(MVR_RepairAction:new(chr, part, "patch", false):isValid(), "same-floor fractional physics height allowed")
    vehicle.z = 1
    check(not MVR_RepairAction:new(chr, part, "patch", false):isValid(), "vehicle on another floor rejected")
    vehicle.z = 0
    vehicle.inArea = false
    check(not MVR_RepairAction:new(chr, part, "patch", false):isValid(), "outside actual part area blocks work")
    resetCalls()
    local result = Game.applyRepair(chr, part, "patch", false)
    check(result.status == "work_area" and #calls.removed == 0, "direct server repair rejects unsafe work before consuming")
end

local function workshopFixture(kind)
    local chr = newPlayer({ Mechanics = 10, MetalWelding = 10, Electricity = 10 })
    local v = newVehicle(false)
    function v:isDoColor() return true end
    function v:getAnimalTrailerSize() return 0 end
    v.power, v.quality, v.loud, v.rust, v.h, v.s, v.val = 1000, 72, 31, 0.6, 0, 0, 0.5
    function v:getEnginePower() return self.power end
    function v:getEngineQuality() return self.quality end
    function v:getEngineLoudness() return self.loud end
    function v:setEngineFeature(q, l, p) self.quality, self.loud, self.power = q, math.floor(l / 2.7), p end
    function v:transmitEngine() self.enginePackets = (self.enginePackets or 0) + 1 end
    function v:getRust() return self.rust end
    function v:setRust(r) self.rust = r end
    function v:transmitRust() self.rustPackets = (self.rustPackets or 0) + 1 end
    function v:getColorHue() return self.h end
    function v:getColorSaturation() return self.s end
    function v:getColorValue() return self.val end
    function v:setColorHSV(h, s, val) self.h, self.s, self.val = h, s, val end
    function v:transmitColorHSV() self.colorPackets = (self.colorPackets or 0) + 1 end
    function v:transmitPartItem() self.itemPackets = (self.itemPackets or 0) + 1 end
    function v:transmitPartUsedDelta() end
    function v:getScript() return { getName = function() return "Mod.UnknownModel" end, getHasLightbar = function() return false end } end
    local part = newPart(v, kind == "power" and "Engine" or "RenamedCargo", 100, kind ~= "power")
    local box = { capacity = kind == "glove" and 10 or 100, occupied = 0 }
    function box:getCapacity() return self.capacity end
    function box:setCapacity(c) self.capacity = c end
    function box:getCapacityWeight() return self.occupied end
    function part:getItemContainer() return kind ~= "power" and box or nil end
    function part:isContainer() return kind ~= "power" end
    function part:getContainerCapacity() return box.capacity end
    function part:setContainerCapacity(n) box.capacity = n end
    if part.item then
        part.item.t = kind == "glove" and "Base.GloveBox1" or "Base.NormalTrunk1"
        part.item.maxCapacity, part.item.md = kind == "glove" and 10 or 100, {}
        function part.item:getMaxCapacity() return self.maxCapacity end
        function part.item:setMaxCapacity(n) self.maxCapacity = n end
        function part.item:getModData() return self.md end
    end
    function part:doInventoryItemStats(item)
        box.capacity = math.floor(math.max(5, item:getMaxCapacity() * (self.cond + 20 * (100 - self.cond) / 100) / 100))
    end
    function part:getScriptPart() return { isRepairMechanic = function() return true end, isMechanicRequireKey = function() return self.needKey == true end } end
    for _, t in ipairs({ "Base.Wrench", "Base.Screwdriver", "Base.Paintbrush" }) do
        chr.inv:add(newItem(t, { tags = { wrench = true, screwdriver = true } }))
    end
    for i = 1, 60 do
        for _, t in ipairs({ "Base.ScrapMetal", "Base.Screws", "Base.SheetMetal", "Base.RippedSheets" }) do chr.inv:add(newItem(t)) end
    end
    chr.inv:add(newItem("Base.DuctTape", { uses = 60 }))
    chr.inv:add(newItem("Base.PaintRed", { uses = 20 }))
    return chr, part, v, box
end

-- New production surface must exist before the behavioral checks can run.
check(type(Game.evaluateWorkshop) == "function" and type(Game.applyWorkshop) == "function", "production workshop adapter exists")
if Game.applyWorkshop then
    SERVER = true
    VehicleUtils = { CheckForUnlockedDoorsWindows = function() return false end, RequiredKeyNotFound = function(part) return part.needKey == true end }
    do
        local chr, part, v, box = workshopFixture("cargo")
        local ev = Game.evaluateWorkshop(chr, part, "upgrade", 1)
        check(ev.status == "ok" and ev.target == 110, "unknown model and renamed generic cargo offer +10%")
        local r = Game.applyWorkshop(chr, part, "upgrade", 1, tostring(part.item.id), Game.workshopRevision(part))
        check(r.status == "customized" and part.item.maxCapacity == 110 and box.capacity == 110, "upgrade applies item and native capacity")
        check(part.item.md.MVRUpgrade.base == 100 and v.itemPackets > 0, "physical item owns saved immutable baseline and replicates")
        local consumed = #calls.removed
        check(Game.applyWorkshop(chr, part, "upgrade", 1, tostring(part.item.id), 0).status == "stale", "second actor with old revision rejected")
        check(#calls.removed == consumed, "stale action consumes no resources")
        check(Game.evaluateWorkshop(chr, part, "upgrade", 1).status == "already", "same tier cannot stack")
        part.cond = 50; part:doInventoryItemStats(part.item); Game.reapplyUpgrade(part)
        check(box.capacity == 66, "native condition reduction still applies to upgraded cargo")
        part.cond = 100; Game.setPartCondition(part, 100)
        check(box.capacity == 110, "repair reapplies capacity")
        box.occupied = 108
        check(Game.evaluateWorkshop(chr, part, "upgrade", 0).status == "overloaded", "occupied downgrade refused")
        box.occupied = 0
        check(Game.applyWorkshop(chr, part, "upgrade", 2, tostring(part.item.id), Game.workshopRevision(part)).status == "customized" and box.capacity == 120, "tier2 uses base100 not current110")
        check(Game.applyWorkshop(chr, part, "upgrade", 0, tostring(part.item.id), Game.workshopRevision(part)).status == "customized" and box.capacity == 100, "removal restores original")
    end
    do
        local a, p, v, box = workshopFixture("cargo")
        Game.applyWorkshop(a, p, "upgrade", 2, tostring(p.item.id), Game.workshopRevision(p))
        local old = p.item
        local b, other, v2, box2 = workshopFixture("cargo")
        check(box2.capacity == 100 and not other.item.md.MVRUpgrade, "same model second instance unaffected")
        p.item = other.item
        p:doInventoryItemStats(p.item)
        Game.reapplyUpgrade(p)
        check(box.capacity == 100, "replacement does not inherit former upgrade")
        p.item = old
        p:doInventoryItemStats(old)
        Game.reapplyUpgrade(p)
        check(box.capacity == 120, "reinstall same physical part keeps upgrade")
        old.maxCapacity = 137
        check(Game.evaluateWorkshop(a, p, "upgrade", 1).status == "conflict", "foreign capacity changes are refused")
    end
    do
        local chr, part, v = workshopFixture("power")
        check(Game.applyWorkshop(chr, part, "upgrade", 2, "", Game.workshopRevision(part)).status == "customized", "intrinsic engine upgrade")
        check(v.power == 1100 and v.quality == 72 and v.loud == 31 and v.enginePackets == 1, "power packet preserves quality and loudness")
        v.power = 1000; Game.reapplyUpgrade(part)
        check(v.power == 1100, "engine power reapplied after load")
        check(Game.applyWorkshop(chr, part, "upgrade", 0, "", Game.workshopRevision(part)).status == "customized" and v.power == 1000, "engine restore uses baseline")
    end
    do
        local chr, part, v, box = workshopFixture("glove")
        check(Game.applyWorkshop(chr, part, "upgrade", 2, tostring(part.item.id), Game.workshopRevision(part)).status == "customized" and box.capacity == 15, "glove +50% cap5")
        part.item.t = "Base.SmallGasTank1"
        check(Game.evaluateWorkshop(chr, part, "upgrade", 1).status == "unsupported", "liquid container never treated as cargo")
    end
    do
        local chr, part, v = workshopFixture("power")
        local initial = part.cond
        check(Game.applyWorkshop(chr, part, "paint", "red", "", Game.workshopRevision(part)).status == "customized" and v.s > 0 and v.colorPackets == 1, "palette paint changes native instance HSV")
        check(part.cond == initial, "paint does not repair/protect body")
        check(Game.applyWorkshop(chr, part, "rust", 1, "", Game.workshopRevision(part)).status == "customized" and math.abs(v.rust - 0.4) < 0.001 and v.rustPackets == 1, "rust removal is gradual and replicated")
        check(Game.evaluateWorkshop(chr, part, "paint", "injected").status == "unsupported", "server rejects unregistered pigment or arbitrary HSV")
        part.needKey = true
        check(Game.evaluateWorkshop(chr, part, "upgrade", 1).status == "access", "native key access required")
        part.needKey = false; v.running = true
        local count = #calls.removed
        check(Game.applyWorkshop(chr, part, "upgrade", 1, "", Game.workshopRevision(part)).status == "work_area" and #calls.removed == count, "server rechecks moving/running vehicle before charge")
        v.running = false
        local result = Game.applyWorkshop(chr, part, "upgrade", 1, "changed", Game.workshopRevision(part))
        check(result.status == "stale", "installed identity checked by authoritative apply")
    end
    SERVER = false
end


-- B42 serializes constructor-named fields, then rebuilds the shared action server-side.
dofile(WORKSHOPACTIONFILE)
check(type(MVR_WorkshopAction) == "table", "workshop action class is available to both simulations")
do
    local chr, part, v = workshopFixture("power")
    local a = MVR_WorkshopAction:new(chr, part, "upgrade", 1)
    local other = MVR_WorkshopAction:new(chr, part, "upgrade", 1)
    for _, name in ipairs({ "character", "part", "operation", "choice", "expectedItemId", "expectedRevision" }) do
        check(a[name] ~= nil, "workshop constructor field serialized: " .. name)
    end
    local rebuilt = MVR_WorkshopAction:new(chr, part, a.operation, a.choice, a.expectedItemId, a.expectedRevision)
    check(rebuilt:isValid() and rebuilt:getDuration() == 450, "server-rebuilt intent has valid duration")
    local n = #calls.removed
    rebuilt:stop()
    check(#calls.removed == n and v.power == 1000, "cancel consumes nothing and applies no upgrade")
    SERVER = true
    check(rebuilt:complete() and v.power == 1050, "server-rebuilt action applies authoritative target")
    n = #calls.removed
    check(not other:complete() and #calls.removed == n and v.power == 1050, "concurrent stale action cannot charge twice")
    for i = 1, 100 do v.power = 1000; Game.reapplyUpgrade(part) end
    check(v.loud == 31 and v.quality == 72 and v.power == 1050, "100 load/reapply cycles preserve engine quality and noise")
    SERVER = false
end
check(type(MVR.Client.addWorkshopOptions) == "function", "production workshop is discoverable in mechanics menu")


-- Native install/repair completion and the loaded-vehicle scan both call the production adapter.
check(type(MVR.Client.addWorkshopOptions) == "function", "workshop menu extension exists")
do
    local chr, part, v, box = workshopFixture("cargo")
    SERVER = true
    Game.applyWorkshop(chr, part, "upgrade", 1, tostring(part.item.id), Game.workshopRevision(part))
    local callbacks = {}
    Events.OnTick = { Add = function(fn) callbacks[#callbacks + 1] = fn end }
    function getCell() return { getVehicles = function() return jlist({ v }) end } end
    package.loaded["Vehicles/TimedActions/ISInstallVehiclePart"] = true
    package.loaded["Vehicles/TimedActions/ISRepairEngine"] = true
    local originals = 0
    ISInstallVehiclePart = { complete = function() originals = originals + 1; box.capacity = 100; return true end }
    ISRepairEngine = { complete = function() originals = originals + 1; return true end }
    if EVENTFILE then dofile(EVENTFILE) end
    check(#callbacks == 1, "loaded authoritative scan hook registered once")
    if #callbacks > 0 then
        box.capacity = 100
        for i = 1, 60 do callbacks[1]() end
        check(box.capacity == 110, "loaded native recalculation is restored by scan")
        local packets = v.itemPackets
        for i = 1, 120 do callbacks[1]() end
        check(v.itemPackets == packets, "unchanged loaded scan sends no packet storm")
        check(ISInstallVehiclePart.complete({ vehicle = v }) == true and box.capacity == 110 and originals == 1, "install wrapper preserves native completion and reapplies physical-part state")
    end
    SERVER = false
end
do
    local chr, part, v = workshopFixture("power")
    SERVER = true
    part.md.MVR = { patches = 2 }
    chr.inv:add(newItem("Base.BlowTorch", { uses = 20 }))
    local ev = Game.evaluate(chr, part, "overhaul", false)
    check(ev.status == "ok" and ev.restorationOnly, "overhaul can remove patch history even at full condition")
    if ev.status == "ok" then
        RANDS = { 0.5, 0.99, 0.99, 0.99 }
        local result = Game.applyRepair(chr, part, "overhaul", false)
        check(result.status == "done" and part.cond == 100 and part.md.MVR.patches == 1, "professional history restoration conserves current condition")
    end
    local glass = newPart(v, "WindowFrontLeft", 0)
    check(Game.evaluate(chr, glass, "patch", false).status == "destroyed", "destroyed windows require replacement")
    part.needKey = true
    check(Game.applyRepair(chr, part, "patch", false).status == "access", "repair completion validates native key access")
    SERVER = false
end


do
    local chr, part, v = workshopFixture("cargo")
    chr.levels.Mechanics = 0
    local ev = Game.evaluateWorkshop(chr, part, "upgrade", 1)
    check(ev.status == "skill" and #ev.report > 0 and #ev.tools > 0, "locked skill preview still shows tools and materials")
    chr.levels.Mechanics = 10; v.outside = true
    ev = Game.evaluateWorkshop(chr, part, "upgrade", 2)
    check(ev.status == "workshop" and #ev.report > 0, "shelter failure still shows all upgrade costs")
    v.outside = false
    local original = VehicleUtils.RequiredKeyNotFound
    VehicleUtils.RequiredKeyNotFound = function() error("client mechanics UI is unavailable on dedicated server") end
    check(Game.evaluateWorkshop(chr, part, "upgrade", 1).status == "ok", "dedicated access does not depend on client mechanics UI")
    VehicleUtils.RequiredKeyNotFound = original
end
do
    local chr, part, v = workshopFixture("power")
    local old = v.isDoColor
    v.isDoColor = function() return false end
    check(Game.evaluateWorkshop(chr, part, "paint", "red").status == "unpaintable" and Game.evaluateWorkshop(chr, part, "rust", 1).status == "ok", "unsupported tint disables only paint")
    v.isDoColor = old
    local ev = Game.evaluateWorkshop(chr, part, "paint", "red")
    local paint
    for _, pick in ipairs(ev.picks) do if pick.entry.type == "Base.PaintRed" then paint = pick.entry.item end end
    local uses = paint and paint.uses
    SERVER = true
    local xpBefore = #calls.xp
    Game.applyWorkshop(chr, part, "paint", "red", "", Game.workshopRevision(part))
    check(paint.uses == uses - 4 and #calls.xp == xpBefore, "paint consumes exactly four uses and grants no XP")
    for _, color in ipairs(Game.Palette) do check(ITEMS[color.item], "palette paint is a real native item: " .. color.item) end
    check(ITEMS["Base.Paintbrush"], "paintbrush is a real native item")
    SERVER = false
end


do
    local chr, part, v, box = workshopFixture("cargo")
    SERVER = true
    Game.applyWorkshop(chr, part, "upgrade", 1, tostring(part.item.id), Game.workshopRevision(part))
    box.capacity = 117
    check(Game.evaluateWorkshop(chr, part, "upgrade", 2).status == "conflict", "foreign container-only recalculation is refused")
    check(not Game.reapplyUpgrade(part) and box.capacity == 117, "scan preserves foreign container capacity")
    SERVER = false
end
do
    local chr, part, v = workshopFixture("power")
    part.needKey = true
    chr.inv.key = false
    check(not Game.workAccess(chr, part), "false key lookup is not access")
    chr.inv.key = newItem("Base.CarKey")
    check(Game.workAccess(chr, part), "native key item grants access")
end
do
    local chr, part = workshopFixture("cargo")
    part.item.t = "Base.NormalBrake1"
    part.id = "RenamedAxlePad"
    local ev = Game.evaluate(chr, part, "patch", false)
    check(ev.key == "Brake", "renamed generic brake uses its native item family repair rules")
end


do
    local chr, part, v, box = workshopFixture("cargo")
    local context = newMenu()
    MVR.Client.addWorkshopOptions(context, chr, part)
    local sub = context.options[1].sub
    check(sub and #sub.options == 6 and #sub.options[4].sub.options == 10, "workshop menu exposes two upgrade tiers, removal, ten paints, rust and native wash")
    check(not sub.options[1].notAvailable and sub.options[3].notAvailable, "upgrade preview available while empty baseline removal disabled")
    check(not sub.options[4].sub.options[1].notAvailable and sub.options[4].sub.options[2].notAvailable, "paint palette exposes resource availability per color")
    local washed
    ISVehicleMenu = { onWash = function(p, vehicle) washed = p == chr and vehicle == v end }
    MVR.Client.onWash(chr, part)
    check(washed, "wash invokes the original native water-consuming action")
    SERVER = true
    Game.applyWorkshop(chr, part, "upgrade", 1, tostring(part.item.id), Game.workshopRevision(part))
    SandboxVars.MVR.UpgradesEnabled = false
    box.occupied = 108
    Game.reapplyVehicle(v)
    check(part.item.maxCapacity == 110 and box.capacity == 110, "disabling waits for unloading rather than discarding cargo")
    box.occupied = 0
    Game.reapplyVehicle(v)
    check(part.item.maxCapacity == 100 and box.capacity == 100, "disabled upgrades restore baseline when cargo permits")
    SandboxVars.MVR.UpgradesEnabled = true
    Game.reapplyVehicle(v)
    check(box.capacity == 110 and part.item.md.MVRUpgrade.base == 100, "re-enable uses the saved original baseline")
    local clientOriginal = isClient
    function isClient() return true end
    local n = #calls.removed
    check(Game.applyWorkshop(chr, part, "upgrade", 2, tostring(part.item.id), Game.workshopRevision(part)).status == "disabled"
        and #calls.removed == n and box.capacity == 110, "client cannot author workshop effects")
    isClient = clientOriginal
    SERVER = false
end


do
    local chr, part, v, box = workshopFixture("cargo")
    part.id, part.item.t = "TrailerTrunk", "Base.TrailerTrunk1"
    -- Exact installed native setCondition special case overrides container capacity after stats.
    function part:doInventoryItemStats(item) box.capacity = math.max(80, self.cond) end
    check(Game.partRole(part) == "cargo", "ordinary native trailer is generic cargo")
    SERVER = true
    local result = Game.applyWorkshop(chr, part, "upgrade", 1, tostring(part.item.id), Game.workshopRevision(part))
    check(result.status == "customized" and box.capacity == 110, "ordinary trailer reapplies capacity after native hard-coded reset")
    if result.status == "customized" then
        part.cond, box.capacity = 50, 80
        Game.reapplyUpgrade(part)
        check(box.capacity == 90, "trailer retains native damaged floor plus bounded original bonus")
        local snapshot = part.item.md.MVRUpgrade
        local clientOriginal = isClient
        function isClient() return true end
        box.capacity = 80
        if Game.refreshReplica then Game.refreshReplica(v) end
        check(box.capacity == 90 and part.item.md.MVRUpgrade == snapshot, "client reconstructs trailer capacity from published item state without authoring upgrades")
        isClient = clientOriginal
    end
    part.id = "TrailerAnimalFood"
    check(Game.partRole(part) == nil, "animal-food container reusing TrailerTrunk item is excluded")
    part.id = "TrailerAnimalEggs"
    check(Game.partRole(part) == nil, "animal-egg container reusing TrailerTrunk item is excluded")
    SERVER = false
end

do
    local chr, part, v, box = workshopFixture("cargo")
    box.capacity = 137
    check(Game.evaluateWorkshop(chr, part, "upgrade", 1).status == "conflict", "first upgrade refuses an existing foreign container-only recalculation")
end


-- Early rejection is rendered by the actual menu builder, including both risk display branches.
do
    for _, case in ipairs({
        { status = "destroyed", id = "WindowFrontLeft", condition = 0 },
        { status = "access", id = "BrakeFrontLeft", condition = 20, locked = true },
    }) do
        for _, level in ipairs({ 0, 6 }) do
            local chr, part = setupBrake({ partId = case.id, cond = case.condition, levels = { Mechanics = level } })
            part.needKey = case.locked
            local ev = Game.evaluate(chr, part, "patch", false)
            check(ev.status == case.status and ev.ctx == nil, case.status .. ": evaluator rejects before a repair plan")
            local ok, description = pcall(MVR.Client.buildTooltip, ev, part)
            check(ok and description:find(TR["Tooltip_MVR_Status_" .. case.status], 1, true),
                case.status .. ": actual tooltip renders the correct localized disabled reason at Mechanics " .. level)
            check(ok and not description:find(TR.Tooltip_MVR_Time_short, 1, true)
                and not description:find(TR.Tooltip_MVR_Risk_low, 1, true),
                case.status .. ": no invented repair time or risk for a rejected operation")
            thePlayer = chr
            for _, tiers in ipairs({ true, false }) do
                SandboxVars.MVR.QualityTiersEnabled = tiers
                local context = newMenu()
                local built = pcall(MVR.Client.addOptions, { context = context, playerNum = 0 }, part)
                check(built and #context.options == 3, case.status .. ": actual menu retains repair, inspection and workshop with tiers " .. tostring(tiers))
                local repair = context.options[1]
                if repair and repair.sub then repair = repair.sub.options[1] end
                check(repair and repair.notAvailable == true and repair.toolTip
                    and repair.toolTip.description:find(TR["Tooltip_MVR_Status_" .. case.status], 1, true),
                    case.status .. ": disabled repair retains the reason in the menu")
            end
            SandboxVars.MVR.QualityTiersEnabled = true
            local window = setmetatable({ playerNum = 0, chr = chr }, { __index = ISVehicleMechanics })
            window:doPartContextMenu(part, 0, 0)
            check(window.context and #window.context.options == 3, case.status .. ": original menu hook completes all extensions")
        end
    end
end

for k in pairs(missing) do check(false, "getText key missing from EN translations: " .. k) end
print("  game_spec.lua: " .. checks .. " checks")
return failures
