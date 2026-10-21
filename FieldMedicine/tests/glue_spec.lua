-- Integration spec: Game.lua + KFM_ProcedureAction + server tick + client menu against a mocked engine.
-- Runner globals: TR (EN translation map), SANDBOX_NAMES (option names), MODLUA (lua dir). Returns failures.
local realPrint = print
local failures = 0
local function check(cond, msg)
    if not cond then failures = failures + 1; realPrint("  FAIL [glue]: " .. msg) end
end
local function near(a, b) return math.abs(a - b) < 1e-6 end

local missingText = {}
_G.getText = function(key, a1)
    local s = TR[key]
    if s == nil then missingText[#missingText + 1] = key; return key end
    if a1 ~= nil then s = string.gsub(s, "%%1", (string.gsub(tostring(a1), "%%", "%%%%"))) end
    return s
end

-- ------------------------------------------------------------ engine mocks
local function jlist(t)
    return { size = function() return #t end, get = function(_, i) return t[i + 1] end, raw = t }
end

local PARTS = { "Hand_L", "Hand_R", "ForeArm_L", "ForeArm_R", "UpperArm_L", "UpperArm_R", "Torso_Upper", "Torso_Lower",
    "Head", "Neck", "Groin", "UpperLeg_L", "UpperLeg_R", "LowerLeg_L", "LowerLeg_R", "Foot_L", "Foot_R" }
_G.BodyPartType = { MAX = { name = "MAX", index = #PARTS } }
for i, n in ipairs(PARTS) do BodyPartType[n] = { name = n, index = i - 1 } end
BodyPartType.ToString = function(t) return t.name end
BodyPartType.ToIndex = function(t) return t.index end
BodyPartType.FromIndex = function(i) return BodyPartType[PARTS[i + 1]] end
BodyPartType.getDisplayName = function(t) return "<" .. t.name .. ">" end

local knoxCalls = 0
local function newPart(name)
    local p = { name = name, health = 100, bleedingTime = 0, bleeding = false, scratched_ = false, cut = false, deep = false, deepTime = 0,
        bitten_ = false, bandaged_ = false, stitched_ = false, infLevel = 0, infected = false, fracture = 0, burn = 0, burnWash = false, pain = 0 }
    function p:getType() return BodyPartType[self.name] end
    function p:getIndex() return BodyPartType[self.name].index end
    function p:scratched() return self.scratched_ end
    function p:isCut() return self.cut end
    function p:isDeepWounded() return self.deep end
    function p:bitten() return self.bitten_ end
    function p:bandaged() return self.bandaged_ end
    function p:stitched() return self.stitched_ end
    function p:isInfectedWound() return self.infected end
    function p:setInfectedWound(b) self.infected = b end
    function p:getWoundInfectionLevel() return self.infLevel end
    function p:setWoundInfectionLevel(v) self.infLevel = v end
    function p:getBleedingTime() return self.bleedingTime end
    function p:setBleedingTime(v) self.bleedingTime = v end
    function p:setBleeding(b) self.bleeding = b end
    function p:getFractureTime() return self.fracture end
    function p:setFractureTime(v) self.fracture = v end
    function p:getBurnTime() return self.burn end
    function p:setBurnTime(v) self.burn = v end
    function p:setNeedBurnWash(b) self.burnWash = b end
    function p:setDeepWounded(b) self.deep = b end
    function p:setDeepWoundTime(v) self.deepTime = v end
    function p:getAdditionalPain() return self.pain end
    function p:setAdditionalPain(v) self.pain = v end
    function p:getHealth() return self.health end
    function p:SetHealth(v) self.health = v end
    -- zombie infection: must never be touched
    function p:IsInfected() knoxCalls = knoxCalls + 1; return true end
    function p:isInfected() knoxCalls = knoxCalls + 1; return true end
    return p
end

local log
local world = {}
local function newItem(fullType, opts)
    opts = opts or {}
    local it = { ft = fullType, id = math.random(1, 1e9), uses = opts.uses or 10, tags = opts.tags or {}, water = opts.water }
    function it:getFullType() return self.ft end
    function it:getType() return (string.gsub(self.ft, "^Base%.", "")) end
    function it:getName() return self.ft end
    function it:getID() return self.id end
    function it:IsInventoryContainer() return false end
    function it:hasTag(t) return self.tags[t] == true end
    function it:getCurrentUses() return self.uses end
    function it:UseAndSync() self.uses = self.uses - 1; log.used[#log.used + 1] = self.ft end
    function it:isWorn() return opts.worn == true end
    function it:getContainer() return self.container end
    function it:getFluidContainer()
        if not self.water then return nil end
        local w = self.water
        return {
            isEmpty = function() return w.amount <= 0 end,
            getAmount = function() return w.amount end,
            adjustAmount = function(_, v) w.amount = v end,
            isPureFluid = function(_, f) return f == Fluid.Water and w.kind == "Water" end,
            contains = function(_, f) return f == Fluid.TaintedWater and w.kind == "TaintedWater" end,
            getPrimaryFluid = function() return { getFluidTypeString = function() return w.kind end } end,
        }
    end
    return it
end

local function newInventory()
    local inv = { items = {} }
    function inv:getItems() return jlist(self.items) end
    function inv:contains(item) for _, i in ipairs(self.items) do if i == item then return true end end; return false end
    function inv:containsID(id) for _, i in ipairs(self.items) do if i.id == id then return true end end; return false end
    function inv:getItemById(id) for _, i in ipairs(self.items) do if i.id == id then return i end end end
    function inv:Remove(item) for k, i in ipairs(self.items) do if i == item then table.remove(self.items, k); return end end end
    function inv:AddItem(item) item.container = self; self.items[#self.items + 1] = item; return item end
    function inv:has(ft) local n = 0; for _, i in ipairs(self.items) do if i.ft == ft then n = n + 1 end end; return n end
    return inv
end

local nextId = 0
local function newPlayer(opts)
    opts = opts or {}
    nextId = nextId + 1
    local pl = { id = nextId, level = opts.level or 0, x = opts.x or 10, y = opts.y or 10, z = 0, md = {}, inv = newInventory(),
        parts = {}, stats = opts.stats or {}, sitting = opts.sitting or false, worn = opts.worn or {}, traits = opts.traits or {},
        name = opts.name or ("P" .. nextId), health = opts.health or 100, said = {} }
    for _, n in ipairs(PARTS) do pl.parts[#pl.parts + 1] = newPart(n) end
    function pl:part(n) for _, p in ipairs(self.parts) do if p.name == n then return p end end end
    function pl:getBodyDamage()
        local me = self
        return {
            getBodyParts = function() return jlist(me.parts) end,
            getOverallBodyHealth = function() return me.health end,
            getPainReductionFromMeds = function() return opts.pills and 10 or 0 end,
            isHasACold = function() return opts.cold == true end,
            isInfected = function() knoxCalls = knoxCalls + 1; return true end,
            getInfectionLevel = function() knoxCalls = knoxCalls + 1; return 50 end,
        }
    end
    function pl:getStats()
        local me = self
        return { get = function(_, s) return me.stats[s] end, add = function(_, s, v) me.stats[s] = (me.stats[s] or 0) + v end }
    end
    function pl:getNutrition() return { getWeight = function() return opts.weight or 80 end } end
    function pl:getModData() return self.md end
    function pl:getPerkLevel(perk) return self.level end
    function pl:getInventory() return self.inv end
    function pl:getX() return self.x end
    function pl:getY() return self.y end
    function pl:getZ() return self.z end
    function pl:isDead() return false end
    function pl:isDriving() return false end
    function pl:getVehicle() return nil end
    function pl:getDisplayName() return self.name end
    function pl:getUsername() return self.name end
    function pl:getOnlineID() return self.id end
    function pl:hasTrait(t) return self.traits[t] == true end
    function pl:getWornItem(loc) return self.worn[loc] end
    function pl:isEquipped(item) return false end
    function pl:isSitOnGround() return self.sitting end
    function pl:isSittingOnFurniture() return false end
    function pl:isAsleep() return false end
    function pl:isTimedActionInstant() return false end
    function pl:getPlayerNum() return 0 end
    function pl:Say(t) self.said[#self.said + 1] = t end
    function pl:getDescriptor() return { getCharacterProfession = function() return opts.profession or "base:unemployed" end } end
    function pl:getCharacterTraits() return { getKnownTraits = function() return jlist(opts.traitIds or {}) end } end
    function pl:getRole() return { hasCapability = function() return opts.cheat == true end } end
    world.players[#world.players + 1] = pl
    return pl
end

local rngValue = 0.99
local function resetWorld(opts)
    opts = opts or {}
    log = { sync = {}, xp = {}, cmds = {}, used = {}, stats = {}, itemStats = 0, removed = {}, added = {} }
    world.players = {}
    world.hours = 100
    rngValue = 0.99
    knoxCalls = 0
    for k in pairs(package.loaded) do
        if string.find(k, "KFM", 1, true) then package.loaded[k] = nil end
    end
    _G.KFM = nil
    _G.print = function() end
    _G.Perks = { Doctor = "Doctor" }
    _G.CharacterStat = { TEMPERATURE = "TEMPERATURE", THIRST = "THIRST", HUNGER = "HUNGER", PANIC = "PANIC", ENDURANCE = "ENDURANCE" }
    _G.CharacterTrait = { HEMOPHOBIC = "HEMOPHOBIC" }
    _G.ItemBodyLocation = { HANDS = "HANDS", MASK = "MASK" }
    _G.Fluid = { Water = "Water", TaintedWater = "TaintedWater" }
    _G.ItemTag = { SHARP_KNIFE = "base:sharpknife", START_FIRE = "base:startfire" }
    _G.Capability = { CanMedicalCheat = "CanMedicalCheat" }
    _G.Metabolics = { LightDomestic = 1 }
    _G.CharacterActionAnims = { Bandage = "Bandage" }
    _G.SandboxVars = { KFM = opts.sandbox or {} }
    _G.getGameTime = function() return { getWorldAgeHours = function() return world.hours end } end
    _G.ZombRandFloat = function(a, b) return a + (b - a) * rngValue end
    _G.isClient = function() return opts.client == true end
    _G.isServer = function() return opts.server == true end
    _G.isMultiplayer = function() return opts.client == true or opts.server == true end
    _G.syncBodyPart = function(bp, flags) log.sync[#log.sync + 1] = { part = bp.name, flags = flags } end
    _G.syncPlayerStats = function(chr, flags) log.stats[#log.stats + 1] = flags end
    _G.addXp = function(chr, perk, n) log.xp[#log.xp + 1] = { chr = chr, perk = perk, n = n } end
    _G.sendServerCommand = function(player, module, command, args) log.cmds[#log.cmds + 1] = { player = player, module = module, command = command, args = args } end
    _G.sendClientCommand = function(player, module, command, args) log.cmds[#log.cmds + 1] = { player = player, module = module, command = command, args = args, client = true } end
    _G.sendItemStats = function() log.itemStats = log.itemStats + 1 end
    _G.sendRemoveItemFromContainer = function(c, item) log.removed[#log.removed + 1] = item.ft end
    _G.sendAddItemToContainer = function(c, item) log.added[#log.added + 1] = item.ft end
    _G.instanceItem = function(ft) return newItem(ft) end
    _G.getOnlinePlayers = function() return jlist(world.players) end
    _G.getNumActivePlayers = function() return #world.players end
    _G.getSpecificPlayer = function(i) return world.players[i + 1] end
    _G.getPlayerByOnlineID = function(id) for _, p in ipairs(world.players) do if p.id == id then return p end end end
    _G.getPlayer = function() return world.players[1] end
    _G.Events = setmetatable({}, { __index = function(t, k) local ev = { fns = {} }; ev.Add = function(fn) ev.fns[#ev.fns + 1] = fn end; rawset(t, k, ev); return ev end })
    _G.ISHealthPanel = nil
    package.preload["TimedActions/ISBaseTimedAction"] = function()
        ISBaseTimedAction = {}
        ISBaseTimedAction.__index = ISBaseTimedAction
        function ISBaseTimedAction:derive(name) local c = setmetatable({}, { __index = self }); c.__index = c; c.Type = name; return c end
        function ISBaseTimedAction.new(self, character) local o = setmetatable({}, self); o.character = character; o.maxTime = -1; return o end
        function ISBaseTimedAction.perform(self) end
        function ISBaseTimedAction.stop(self) end
        return ISBaseTimedAction
    end
    package.preload["TimedActions/ISInventoryTransferUtil"] = function()
        ISInventoryTransferUtil = { newInventoryTransferAction = function(chr, item, from, to) return { transfer = item } end }
    end
    _G.ISTimedActionQueue = { queue = {}, add = function(a) table.insert(ISTimedActionQueue.queue, a) end }
    _G.ISInventoryPaneContextMenu = { addToolTip = function() return { description = "" } end }
    package.preload["TimedActions/ISBaseTimedAction"]()
    local Core = require "KFM/Core"
    local Game = require "KFM/Game"
    dofile(MODLUA .. "/shared/TimedActions/KFM_ProcedureAction.lua")
    dofile(MODLUA .. "/server/KFM/KFM_Server.lua")
    return Core, Game
end

local function loadClient()
    _G.ISModalRichText = { new = function(_, x, y, w, h, text) _G.LAST_MODAL = text; return { initialise = function() end, addToUIManager = function() end } end }
    _G.getCore = function() return { getScreenWidth = function() return 1920 end, getScreenHeight = function() return 1080 end } end
    return dofile(MODLUA .. "/client/KFM/KFM_Client.lua")
end

local function act(doctor, patient, partName, procId, item, item2)
    local bp = patient:part(partName)
    local a = KFM_ProcedureAction:new(doctor, patient, bp, procId, item, item2)
    return a, bp
end
local function fire(name) for _, fn in ipairs(Events[name].fns) do fn() end end
local function cmd(name) for _, c in ipairs(log.cmds) do if c.command == name then return c end end end

-- ============================================================ scenarios
-- 1. exam SP: report content, tongue depressor consumed, XP anti-farm, Knox never read
do
    local Core, Game = resetWorld({})
    local Client = loadClient()
    local doc = newPlayer({ level = 3 })
    local pat = newPlayer({ stats = { TEMPERATURE = 38.9, THIRST = 0.5, PANIC = 10, ENDURANCE = 0.9 }, health = 70, cold = true })
    pat:part("LowerLeg_L").fracture = 25
    pat:part("Hand_R").infLevel = 2
    local steth = doc.inv:AddItem(newItem("Base.Stethoscope"))
    local tongue = doc.inv:AddItem(newItem("Base.TongueDepressor"))
    local a = act(doc, pat, "Torso_Upper", "exam", steth, tongue)
    check(a.effLevel == 4, "stethoscope +1 effective level")
    check(a.maxTime == Core.duration("exam", 3), "exam duration by real level")
    check(a:isValid(), "exam valid")
    a:complete()
    check(LAST_MODAL ~= nil, "report shown in SP")
    check(LAST_MODAL and string.find(LAST_MODAL, "High fever", 1, true), "fever line")
    check(LAST_MODAL and string.find(LAST_MODAL, "<LowerLeg_L>: fracture", 1, true), "fracture line with translated part")
    check(LAST_MODAL and string.find(LAST_MODAL, "<Hand_R>: the wound looks inflamed", 1, true), "early infection line (L4)")
    check(LAST_MODAL and string.find(LAST_MODAL, "Throat red", 1, true), "throat via tongue depressor")
    check(LAST_MODAL and not string.find(string.lower(LAST_MODAL), "zombie", 1, true), "no zombie mention")
    check(doc.inv:has("Base.TongueDepressor") == 0 and doc.inv:has("Base.Stethoscope") == 1, "tongue consumed, stethoscope kept")
    check(#log.xp == 1 and log.xp[1].n == 2, "exam xp 2")
    local tongue2 = doc.inv:AddItem(newItem("Base.TongueDepressor"))
    world.hours = world.hours + 3
    act(doc, pat, "Torso_Upper", "exam", steth, tongue2):complete()
    check(#log.xp == 1, "no exam xp again within 6h")
    world.hours = world.hours + 4
    act(doc, pat, "Torso_Upper", "exam", nil, nil):complete()
    check(#log.xp == 2, "exam xp after 6h")
    check(knoxCalls == 0, "zombie infection API never called")
    -- every possible exam key exists in EN
    for _, st in ipairs({ "Good", "Stable", "Serious", "Critical" }) do check(TR["IGUI_KFM_Exam_General_" .. st], "key General_" .. st) end
    for _, b in ipairs({ "VeryLong", "Long", "Medium", "Short", "AlmostHealed" }) do check(TR["IGUI_KFM_Exam_Fracture_" .. b], "key Fracture_" .. b) end
    -- healthy patient: no XP
    local healthy = newPlayer({ stats = { TEMPERATURE = 36.8 } })
    local before = #log.xp
    act(doc, healthy, "Torso_Upper", "exam"):complete()
    check(#log.xp == before, "no xp examining a healthy patient")
end

-- 2. exam MP server: report goes to the doctor by server command
do
    resetWorld({ server = true })
    local doc = newPlayer({ level = 1 })
    local pat = newPlayer({ stats = { TEMPERATURE = 37.8 } })
    act(doc, pat, "Torso_Upper", "exam"):complete()
    local c = cmd("exam")
    check(c and c.player == doc and c.module == "KFM", "exam report sent to doctor")
    check(c and c.args.lines[2].key == "IGUI_KFM_Exam_Fever", "fever in MP report")
end

-- 3. irrigation clean/dirty
do
    local Core, Game = resetWorld({})
    local doc = newPlayer({ level = 0 })
    local bp = doc:part("ForeArm_L")
    bp.cut = true; bp.infLevel = 5
    local bottle = doc.inv:AddItem(newItem("Base.WaterBottle", { water = { amount = 1, kind = "Water" } }))
    local a = act(doc, doc, "ForeArm_L", "irrigate", bottle)
    check(a:isValid(), "irrigation valid on open wound")
    a:complete()
    check(near(bp.infLevel, 3.5), "infection 5 -> 3.5 at L0")
    check(near(bottle.water.amount, 0.75) and log.itemStats == 1, "0.25 L used + item synced")
    check(bp.pain == 5, "irrigation pain +5")
    check(log.sync[#log.sync].flags == Core.SYNC_ALL, "full body part sync")
    check(#log.xp == 1 and log.xp[1].n == 3, "irrigation xp")
    local dirty = doc.inv:AddItem(newItem("Base.WaterBottle", { water = { amount = 1, kind = "TaintedWater" } }))
    act(doc, doc, "ForeArm_L", "irrigate", dirty):complete()
    check(near(bp.infLevel, 5.5) and bp.infected == true, "tainted water infects")
    bp.bandaged_ = true
    check(not act(doc, doc, "ForeArm_L", "irrigate", bottle):isValid(), "bandaged wound not irrigable")
end

-- 4. tourniquet lifecycle: gating, apply, pause bleeding, ischemia, damage, removal
do
    local Core, Game = resetWorld({})
    local novice = newPlayer({ level = 0 })
    local pat = newPlayer({ sitting = true })
    pat:part("ForeArm_L").deep = true
    pat:part("ForeArm_L").bleedingTime = 10
    local tq = novice.inv:AddItem(newItem("Base.KFM_ImprovisedTourniquet"))
    act(novice, pat, "UpperArm_L", "tourniquet", tq):complete()
    check(pat:part("ForeArm_L").bleedingTime == 10 and novice.inv:has("Base.KFM_ImprovisedTourniquet") == 1, "level 0 cannot apply (server-side gate)")
    local medic = newPlayer({ level = 2, x = 30 })
    local tq2 = medic.inv:AddItem(newItem("Base.KFM_ImprovisedTourniquet"))
    rngValue = 0.0 -- forced failure (chance 4%)
    act(medic, pat, "UpperArm_L", "tourniquet", tq2):complete()
    check(Game.md(pat).tq.UpperArm_L == nil and medic.inv:has("Base.KFM_ImprovisedTourniquet") == 1, "failed tourniquet keeps item, no effect")
    rngValue = 0.99
    act(medic, pat, "UpperArm_L", "tourniquet", tq2):complete()
    local st = Game.md(pat).tq.UpperArm_L
    check(st ~= nil and st.item == "Base.KFM_ImprovisedTourniquet", "tourniquet state stored on patient")
    check(medic.inv:has("Base.KFM_ImprovisedTourniquet") == 0, "item moved onto the limb")
    check(pat:part("ForeArm_L").bleedingTime == 0 and st.saved.ForeArm_L == 10, "distal bleeding paused and saved")
    check(not act(medic, pat, "ForeArm_L", "tourniquet", tq):isValid(), "one tourniquet per limb")
    pat:part("Hand_L").cut = true; pat:part("Hand_L").bleedingTime = 3
    pat:part("Hand_R").bleedingTime = 4
    fire("EveryOneMinute")
    check(pat:part("Hand_L").bleedingTime == 0 and st.saved.Hand_L == 3, "new distal bleeding paused by tick")
    check(pat:part("Hand_R").bleedingTime == 4, "other arm untouched")
    fire("EveryTenMinutes")
    check(pat:part("UpperArm_L").health == 100, "safe window: no damage")
    world.hours = world.hours + 3
    fire("EveryTenMinutes")
    check(pat:part("UpperArm_L").health == 99 and pat:part("UpperArm_L").pain > 0, "ischemia after safe hours")
    world.hours = world.hours + 4
    fire("EveryTenMinutes")
    check(pat:part("UpperArm_L").fracture == Core.TOURNIQUET_DAMAGE_FRACTURE and st.dmg, "lasting damage after 3x safe hours")
    pat:part("Hand_L").stitched_ = true
    local off = act(medic, pat, "UpperArm_L", "tourniquetOff")
    check(off:isValid(), "removal valid")
    off:complete()
    check(Game.md(pat).tq.UpperArm_L == nil and medic.inv:has("Base.KFM_ImprovisedTourniquet") == 1, "removed and returned")
    check(pat:part("ForeArm_L").bleedingTime == 10, "untreated wound bleeds again")
    check(pat:part("Hand_L").bleedingTime == 0, "stitched wound does not bleed again")
    check(not act(medic, pat, "Torso_Upper", "tourniquet", tq2):isValid(), "no tourniquet on torso")
end

-- 5. tourniquet in MP server: removal/sync commands
do
    local Core, Game = resetWorld({ server = true })
    local medic = newPlayer({ level = 1 })
    local pat = newPlayer({})
    local belt = medic.inv:AddItem(newItem("Base.Belt2"))
    act(medic, pat, "UpperLeg_R", "tourniquet", belt):complete()
    check(log.removed[1] == "Base.Belt2", "belt removal synced")
    local n = 0
    for _, c in ipairs(log.cmds) do if c.command == "tq" then n = n + 1; check(c.args.tq.UpperLeg_R ~= nil, "tq snapshot sent") end end
    check(n == 2, "tq state pushed to patient and doctor")
    check(cmd("result") and cmd("result").args.key == "IGUI_KFM_Result_TourniquetOk", "result feedback to doctor")
    for _, fn in ipairs(Events.OnClientCommand.fns) do fn("KFM", "tqSync", medic, { id = pat.id }) end
    check(log.cmds[#log.cmds].player == medic and log.cmds[#log.cmds].args.id == pat.id, "tqSync answers with patient state")
end

-- 6. cauterization (helper rule), 7. fracture reduction, 8. debridement
do
    local Core, Game = resetWorld({})
    local doc = newPlayer({ level = 2, traits = { HEMOPHOBIC = true } })
    local pat = newPlayer({})
    local bp = pat:part("LowerLeg_R")
    bp.deep = true; bp.bleedingTime = 8
    local knife = doc.inv:AddItem(newItem("Base.KitchenKnife", { tags = { ["base:sharpknife"] = true } }))
    local lighter = doc.inv:AddItem(newItem("Base.Lighter", { tags = { ["base:startfire"] = true }, uses = 5 }))
    act(doc, pat, "LowerLeg_R", "cauterize", knife, lighter):complete()
    check(bp.deep == true, "level 2 without helper cannot cauterize")
    newPlayer({ x = 11, y = 11 }) -- helper next to the patient
    local a = act(doc, pat, "LowerLeg_R", "cauterize", knife, lighter)
    check(a.maxTime == Core.duration("cauterize", 2, Core.EXTRA_HEAT_TICKS), "heat ticks added")
    a:complete()
    check(bp.deep == false and bp.bleedingTime == 0, "helper: deep wound sealed")
    check(bp.burn >= 15 and bp.burn <= 25 and bp.burnWash, "cauterization burn")
    check(lighter.uses == 4, "lighter use consumed")
    check(doc.stats.PANIC == Core.HEMOPHOBIC_PANIC and log.stats[1] == Core.SYNC_STAT_PANIC, "hemophobic panic synced")
    bp.bitten_ = true; bp.deep = true
    check(not act(doc, pat, "LowerLeg_R", "cauterize", knife, lighter):isValid(), "never cauterize a bite")

    local surgeon = newPlayer({ level = 5, x = 50 })
    local leg = pat:part("UpperLeg_L"); leg.fracture = 20
    pat.sitting = false
    check(not act(surgeon, pat, "UpperLeg_L", "reduceFracture"):isValid(), "patient must rest")
    pat.sitting = true
    act(surgeon, pat, "UpperLeg_L", "reduceFracture"):complete()
    check(near(leg.fracture, 13), "fracture 20 -> 13 at L5")
    check(not act(surgeon, pat, "UpperLeg_L", "reduceFracture"):isValid(), "once per fracture")
    leg.fracture = 0
    fire("EveryTenMinutes")
    check(Game.md(pat).reduced.UpperLeg_L == nil, "flag cleared when healed")

    local doc6 = newPlayer({ level = 6, x = 70, worn = { HANDS = newItem("Base.Gloves_Surgical") } })
    local scalpel = doc6.inv:AddItem(newItem("Base.Scalpel"))
    local hand = pat:part("Hand_L"); hand.cut = true; hand.infected = true; hand.infLevel = 8
    act(doc6, pat, "Hand_L", "debride", scalpel):complete()
    check(hand.infLevel == 0 and hand.infected == false, "debride clears wound infection")
    check(hand.bleedingTime >= 5 and hand.bleedingTime <= 10 and hand.pain > 0, "debride bleeds and hurts")
    check(doc6.inv:has("Base.Scalpel") == 1, "scalpel kept")
    check(knoxCalls == 0, "no zombie infection API in procedures")
end

-- 9. sandbox disabled + offset + profession soft hook
do
    resetWorld({ sandbox = { Enabled = false } })
    local doc = newPlayer({ level = 10 })
    local bp = doc:part("Hand_R"); bp.cut = true; bp.infLevel = 5
    local bottle = doc.inv:AddItem(newItem("Base.WaterBottle", { water = { amount = 1, kind = "Water" } }))
    act(doc, doc, "Hand_R", "irrigate", bottle):complete()
    check(bp.infLevel == 5, "disabled mod does nothing")
    local Core, Game = resetWorld({})
    local s = newPlayer({ level = 4, traitIds = { "KRjobs:Surgeon" } })
    check(Game.effectiveLevel(s, "debride", 0) == 6, "soft profession/trait bonus via KFM.registerProfessionBonus")
    check(type(KFM.registerProfessionBonus) == "function", "public API exported")
    check(Game.doctorLevel(newPlayer({ level = 1, cheat = true })) == 1, "cheat capability ignored in SP")
    for _, n in ipairs(SANDBOX_NAMES) do check(Core.DEFAULTS[n] ~= nil, "sandbox option known to Core: " .. n) end
    local cnt = 0; for _ in pairs(Core.DEFAULTS) do cnt = cnt + 1 end
    check(cnt == #SANDBOX_NAMES, "every Core default has a sandbox option")
end

-- 10. client: health panel hook chains vanilla menu and adds gated options
do
    resetWorld({})
    local origCalls = 0
    local function newMenu()
        local m = { numOptions = 1, options = {}, visible = true }
        function m:addOption(name, target, fn) local o = { name = name, fn = fn, target = target }; self.options[self.numOptions] = o; self.numOptions = self.numOptions + 1; return o end
        function m:getNew() return newMenu() end
        function m:addSubMenu(o, sub) o.sub = sub end
        function m:removeLastOption() self.numOptions = self.numOptions - 1; self.options[self.numOptions] = nil end
        function m:getIsVisible() return self.visible end
        function m:setVisible(v) self.visible = v end
        return m
    end
    local ctx = newMenu()
    _G.getPlayerContextMenu = function() return ctx end
    _G.ISHealthPanel = { doBodyPartContextMenu = function(self, bp) origCalls = origCalls + 1; ctx.visible = false end }
    loadClient()
    local doc = newPlayer({ level = 0 })
    doc.inv:AddItem(newItem("Base.KFM_ImprovisedTourniquet"))
    local bp = doc:part("UpperArm_R"); bp.cut = true; bp.bleedingTime = 5
    local panel = { character = doc, otherPlayer = nil }
    ISHealthPanel.doBodyPartContextMenu(panel, bp, 0, 0)
    check(origCalls == 1, "vanilla menu still built")
    local root = ctx.options[1]
    check(root and root.name == TR.ContextMenu_KFM_Root and ctx.visible, "Field Medicine submenu added and shown")
    local names = {}
    for i = 1, root.sub.numOptions - 1 do names[root.sub.options[i].name] = root.sub.options[i] end
    check(names[TR.ContextMenu_KFM_Exam] ~= nil, "exam option")
    local tqSub = names[TR.ContextMenu_KFM_Tourniquet]
    check(tqSub and tqSub.sub.options[1].notAvailable == true, "tourniquet shown disabled at level 0")
    check(tqSub and string.find(tqSub.sub.options[1].toolTip.description, "level 1", 1, true), "requirement in tooltip")
    names[TR.ContextMenu_KFM_Exam].fn()
    check(#ISTimedActionQueue.queue == 1 and ISTimedActionQueue.queue[1].procId == "exam", "exam queued")
    -- inventory menu on stethoscope
    local ictx = newMenu()
    for _, fn in ipairs(Events.OnFillInventoryObjectContextMenu.fns) do fn(0, ictx, { newItem("Base.Stethoscope") }) end
    check(ictx.options[1] and ictx.options[1].name == TR.ContextMenu_KFM_ExamSelf, "examine yourself on stethoscope")
    -- MP mirror
    for _, fn in ipairs(Events.OnServerCommand.fns) do fn("KFM", "tq", { id = 7, tq = { ForeArm_L = { t = 1 } } }) end
    check(KFM.Game.mirror["7"].ForeArm_L ~= nil, "client mirror updated from server")
end


-- Review regressions: successful debridement can contaminate a wound; disabled exams stay disabled.
do
    local Core, Game = resetWorld({})
    local doc = newPlayer({ level = 10 })
    local bp = doc:part("Hand_L")
    bp.cut = true; bp.infected = true; bp.infLevel = 8
    local scalpel = doc.inv:AddItem(newItem("Base.Scalpel"))
    local calls = 0
    Game.rng = function() calls = calls + 1; if calls == 1 then return 0.99 end; return 0 end
    act(doc, doc, "Hand_L", "debride", scalpel):complete()
    check(bp.infLevel > 0 and bp.infected == true, "procedure-caused infection must set infected flag")
end
do
    resetWorld({ server = true, sandbox = { ExamEnabled = false } })
    local doc = newPlayer({ level = 3 })
    local pat = newPlayer({ health = 70 })
    act(doc, pat, "Torso_Upper", "exam"):complete()
    check(cmd("exam") == nil, "server must reject exam when ExamEnabled false")
end


do
    resetWorld({server = true})
    local doc = newPlayer({level = 10})
    local bp = doc:part("Hand_L")
    bp.cut = true; bp.infected = true; bp.infLevel = 8
    local a = act(doc, doc, "Hand_L", "debride", nil)
    check(not a:isValid(), "debridement requires a scalpel even when a reconstructed item is nil")
    a:complete()
    check(bp.infLevel == 8 and bp.infected, "missing scalpel cannot change wound state")
end
do
    resetWorld({server = true})
    local doc = newPlayer({level = 10})
    local bp = doc:part("UpperArm_L")
    bp.cut = true; bp.bleedingTime = 10
    local a = act(doc, doc, "UpperArm_L", "tourniquet", nil)
    check(not a:isValid(), "tourniquet action requires the item")
    local ok = pcall(function() a:complete() end)
    check(ok and bp.bleedingTime == 10, "missing tourniquet must not crash or change bleeding")
end
do
    resetWorld({server = true})
    local doc = newPlayer({level = 10})
    local bp = doc:part("Hand_L")
    bp.deep = true; bp.bleedingTime = 10
    local a = act(doc, doc, "Hand_L", "cauterize", nil, nil)
    check(not a:isValid(), "cauterization requires a blade and a usable fire source")
    a:complete()
    check(bp.deep and bp.bleedingTime == 10, "missing tools cannot cauterize")
end

do
    resetWorld({server = true})
    local doc = newPlayer({level = 10})
    local bp = doc:part("Hand_L")
    bp.cut = true; bp.infected = true; bp.infLevel = 8
    local scalpel = doc.inv:AddItem(newItem("Base.Scalpel"))
    local a = act(doc, doc, "Hand_L", "debride", scalpel)
    doc.inv:Remove(scalpel)
    a:complete()
    check(bp.infLevel == 8, "scalpel removed during action prevents completion")
end
do
    resetWorld({server = true})
    local doc = newPlayer({level = 10})
    local bp = doc:part("UpperArm_L")
    bp.cut = true; bp.bleedingTime = 10
    local belt = doc.inv:AddItem(newItem("Base.Belt2", {worn = true}))
    local a = act(doc, doc, "UpperArm_L", "tourniquet", belt)
    check(not a:isValid(), "worn belt cannot become a tourniquet")
    a:complete()
    check(bp.bleedingTime == 10 and doc.inv:has("Base.Belt2") == 1, "worn belt is not consumed")
end
do
    resetWorld({server = true})
    local doc = newPlayer({level = 10})
    local bp = doc:part("Hand_L")
    bp.deep = true; bp.bleedingTime = 10
    local knife = doc.inv:AddItem(newItem("Base.KitchenKnife", {tags = {["base:sharpknife"] = true}}))
    local lighter = doc.inv:AddItem(newItem("Base.Lighter", {uses = 0}))
    local a = act(doc, doc, "Hand_L", "cauterize", knife, lighter)
    check(not a:isValid(), "empty lighter cannot heat a blade")
    a:complete()
    check(bp.deep and lighter.uses == 0, "empty lighter does not cauterize or use negative charges")
end

check(#missingText == 0, "missing translation keys: " .. table.concat(missingText, ","))
_G.print = realPrint
return failures
