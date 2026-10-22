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
    function p:getStiffness() return self.stiffness or 0 end
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
    function pl:getSquare() return {canReachTo=function() return true end,isSomethingTo=function() return false end} end
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
    _G.CharacterStat = { TEMPERATURE = "TEMPERATURE", THIRST = "THIRST", HUNGER = "HUNGER", PANIC = "PANIC", WETNESS="WETNESS", FATIGUE="FATIGUE", UNHAPPINESS="UNHAPPINESS", ENDURANCE = "ENDURANCE" }
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
    _G.getRandomUUID = function() nextId=nextId+1;return "fixture-uuid-"..nextId end
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
    package.preload["TimedActions/ISEatFoodAction"]=function() ISEatFoodAction={complete=function() return true end} end
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
    -- This helper models the pre-action walk and patient acceptance. Authority-denial tests construct directly.
    if doctor~=patient then
        doctor.x=patient.x;doctor.y=patient.y;doctor.z=patient.z
        local H=KFM.Health;H.leases[patient]=H.leases[patient] or {};H.leases[patient][doctor]=world.hours+1
    end
    local bp = patient:part(partName)
    local a = KFM_ProcedureAction:new(doctor, patient, bp, procId, item, item2)
    return a, bp
end
local function fire(name,...) for _, fn in ipairs(Events[name].fns) do fn(...) end end
local function cmd(name) for _, c in ipairs(log.cmds) do if c.command == name then return c end end end

-- Exercise the public opaque protocol while retaining native-state assertions below.
local function care(H,doctor,patient,key,treatment,item)
 local dynamic=string.match(key,"^trait:(%w+)$")
 local raw=dynamic and H.dynamic(patient).states[dynamic]or H.state(patient).episodes[key]
 if not raw then return false end
 H.examine(patient,doctor,nil,nil)
 return H.treat(doctor,patient,(dynamic and "d"or "e")..raw.id,treatment,item,raw.id)
end

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
    check(LAST_MODAL and string.find(LAST_MODAL, "(LowerLeg_L): fracture", 1, true), "fracture line with translated part")
    check(LAST_MODAL and string.find(LAST_MODAL, "(Hand_R): the wound looks inflamed", 1, true), "early infection line (L4)")
    check(LAST_MODAL and string.find(LAST_MODAL, "Throat red", 1, true), "throat via tongue depressor")
    local diagnosticText=""
    for _,line in ipairs(Core.buildExamReport(Game.collectVitals(pat),a.effLevel,Game.cfg(),{tongue=true}))do diagnosticText=diagnosticText..getText(line.key)end
    check(not string.find(string.lower(diagnosticText),"zombie",1,true),"diagnostic findings never identify zombie infection; prevention guide may discuss contact")
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
    for n=1,13 do world.hours=world.hours+1/6;fire("EveryTenMinutes")end
    check(pat:part("UpperArm_L").health < 100 and pat:part("UpperArm_L").pain > 0, "ischemia after safe hours")
    for n=1,30 do world.hours=world.hours+1/6;fire("EveryTenMinutes")end
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


-- Overhaul audit: five permanent reproductions.
do
 local Core, Game = resetWorld({sandbox={Enabled=false}})
 local doc=newPlayer({level=10}); local bp=doc:part("UpperArm_L")
 bp.cut=true; Game.md(doc).tq.UpperArm_L={t=90,item="Base.Belt2",saved={UpperArm_L=8}}
 fire("EveryTenMinutes")
 check(bp.health==100 and bp.fracture==0,"disabled old tourniquet cannot damage")
 act(doc,doc,"UpperArm_L","tourniquetOff"):complete()
 check(Game.md(doc).tq.UpperArm_L==nil,"disabled tourniquet remains removable")
end
do
 resetWorld({}); local Client=loadClient(); local doc=newPlayer({})
 local tongue=newItem("Base.TongueDepressor"); tongue.container=newInventory()
 Client.queue(doc,doc,doc:part("Head"),"exam",nil,tongue)
 check(#ISTimedActionQueue.queue==2 and ISTimedActionQueue.queue[1].transfer==tongue,"nil-first optional item transferred")
end
do
 local Core,Game=resetWorld({});local doc=newPlayer({level=10})
 local belt=doc.inv:AddItem(newItem("Base.Belt2"));belt.condition=7;belt.customName="Rescued belt"
 act(doc,doc,"UpperArm_L","tourniquet",belt):complete()
 act(doc,doc,"UpperArm_L","tourniquetOff"):complete()
 check(doc.inv:contains(belt) and doc.inv:has("Base.Belt2")==1 and belt.condition==7 and belt.customName=="Rescued belt","actual belt object identity and properties returned")
end
do
 resetWorld({});local doc=newPlayer({});local bp=doc:part("Hand_L");bp.cut=true
 local bottle=doc.inv:AddItem(newItem("Base.WaterBottle",{water={amount=1,kind="Water"}}))
 act(doc,doc,"Hand_L","irrigate",bottle):complete()
 check(#log.xp==0,"zero benefit clean irrigation grants no XP")
end
do
 local Core,Game=resetWorld({});local Client=loadClient()
 check(type(Client.procedureFailChance)=="function","menu exposes same procedure chance policy")
 if Client.procedureFailChance then
  local doc=newPlayer({level=1});local belt=newItem("Base.Belt2")
  check(near(Client.procedureFailChance(doc,"tourniquet",Game.cfg(),belt),Core.failChance("tourniquet",1,Game.cfg(),Core.BELT_EXTRA_FAIL)),"belt tooltip includes belt failure penalty")
 end
end


-- Health adapter is authoritative, usable, and bounded; no fixed symptom assignments.
do
 local Core,Game=resetWorld({});local doc=newPlayer({level=10})
 local loaded,H=pcall(require,"KFM/Health")
 check(loaded,"health engine has production observation and care adapter")
 if loaded then
  check(KFM.Exposure and KFM.Exposure.version==1,"server-only shared exposure API")
  local bp=doc:part("Hand_L");bp.cut=true
  H.registerExposure(doc,"disguise:1",{Hand_L=1})
  H.registerExposure(doc,"disguise:1",{Hand_L=1})
  local I=require "KFM/Illness"
  check(I.count(Game.md(doc).health.sources)==1,"disguise exposure API registers once")
  for i=1,13 do H.tick(doc,1/6,function()return 0 end) end
  check(I.count(Game.md(doc).health.episodes)==1,"registered blood has production disease path")
  H.removeExposure(doc,"disguise:1","Hand_L")
  check(I.count(Game.md(doc).health.sources)==0,"explicit source removal")
  Game.md(doc).health=I.seed(I.new(),"flu","fixture",nil,false)
  local ep=Game.md(doc).health.episodes["resp:general"];ep.age=8;ep.phase="symptomatic"
  doc.stats.THIRSt=0.6
  H.applyEffects(doc,{health=0,thirst=0.001,endurance=0,pain={},warnings={}})
  check(doc.stats.THIRSt==0.6,"unrelated existing stats retained")
  local supplies=doc.inv:AddItem(newItem("Base.KFM_SupportSachet"))
  local ok=care(H,doc,doc,"resp:general","support",supplies)
  check(ok and not doc.inv:contains(supplies),"real treatment consumes one supply on success")
  local repeated=doc.inv:AddItem(newItem("Base.KFM_SupportSachet"))
  local before=#log.xp
  check(not care(H,doc,doc,"resp:general","support",repeated) and doc.inv:contains(repeated) and #log.xp==before,"early repeat consumes nothing or XP")
 end
end
do
 local Core,Game=resetWorld({});local doc=newPlayer({level=10});local other=newPlayer({})
 local belt=doc.inv:AddItem(newItem("Base.Belt2"))
 act(doc,doc,"UpperArm_L","tourniquet",belt):complete()
 doc.inv:Remove(belt);other.inv:AddItem(belt)
 fire("EveryOneMinute")
 check(Game.md(doc).tq.UpperArm_L==nil,"missing/transferred real belt releases tourniquet")
end


do
 local Core,Game=resetWorld({server=true});local H=require "KFM/Health"
 local doctor=newPlayer({level=10});local patient=newPlayer({});local impostor=newPlayer({})
 check(type(H.requestConsent)=="function","server issues patient-bound consent nonce")
 if H.requestConsent then
  local nonce=H.requestConsent(doctor,patient)
  check(nonce and not H.consent(doctor,patient),"request is not consent")
  check(not H.answerConsent(impostor,nonce,true),"other actor cannot grant consent")
  check(H.answerConsent(patient,nonce,true) and H.consent(doctor,patient),"actual patient grants scoped lease")
  H.revokeConsent(patient)
  check(not H.consent(doctor,patient),"revocation blocks subsequent effects")
  check(not H.answerConsent(patient,nonce,true),"answered/revoked nonce cannot replay")
 end
end


do
 local Core,Game=resetWorld({server=true});local H=require "KFM/Health";local I=require "KFM/Illness"
 local doctor=newPlayer({level=10});local patient=newPlayer({})
 local nonce=H.requestConsent(doctor,patient);world.players={patient}
 check(not H.answerConsent(patient,nonce,true),"disconnected doctor cannot receive stale-session consent")
 world.players={doctor,patient};nonce=H.requestConsent(doctor,patient)
 H.answerConsent(patient,nonce,true)
 local bp=patient:part("UpperLeg_L");bp.fracture=30;patient.sitting=true
 Game.md(patient).health=I.seed(I.new(),"fracture","native",bp.name,true)
 local splint=doctor.inv:AddItem(newItem("Base.Splint"))
 check(type(H.recoveryReduction)=="function","native recovery budget shared")
 if H.recoveryReduction then
  local one=H.recoveryReduction(patient,bp,"fracture",10)
  local two=H.recoveryReduction(patient,bp,"fracture",10)
  check(one+two<=12,"native recovery reductions never exceed 40 percent baseline")
 end
 local Client=loadClient()
 check(type(Client.addEpisodeOptions)=="function" and type(Client.episodeReport)=="function","episode care and follow-up are discoverable")
end


do
 local Core,Game=resetWorld({});local H=require "KFM/Health";local doc=newPlayer({})
 local bp=doc:part("Hand_L");bp.pain=12
 H.applyEffects(doc,{health=0,thirst=0,endurance=0,pain={Hand_L=3},warnings={}})
 check(bp.pain==12,"native/foreign stronger regional pain is not stacked or overwritten")
 check(type(H.afterEating)=="function","dirty-hand ingestion has production viral cause")
 if H.afterEating then
  local item=newItem("Base.Apple")
  local old=Game.rng;Game.rng=function()return 0 end
  H.afterEating(doc,item,1,true)
  check(next(H.state(doc).episodes)~=nil,"dirty ingestion creates one observable gastro episode")
  Game.rng=old
 end
end


do
 local Core,Game=resetWorld({server=true});local H=require "KFM/Health";local I=require "KFM/Illness"
 local source=newPlayer({});local target=newPlayer({})
 Game.md(source).health=I.seed(I.new(),"flu","native",nil,true)
 local ep=H.state(source).episodes["resp:general"];ep.phase="symptomatic";ep.age=12
 H.contact(world.players);H.contact(world.players)
 check(I.count(H.state(target).sources)==1,"sustained same-floor contact source created")
 source.x=100;H.contact(world.players)
 check(I.count(H.state(target).sources)==0 and next(Game.md(target).contacts)==nil,"walking away removes exposure source and contact clock")
 source.x=10;H.contact(world.players);H.contact(world.players)
 world.players={target};H.contact(world.players)
 check(I.count(H.state(target).sources)==0,"source logout removes contact exposure")
 world.players={source,target};H.contact(world.players);H.contact(world.players)
 H.state(source).episodes["resp:general"].phase="resolved";H.contact(world.players)
 check(I.count(H.state(target).sources)==0,"source recovery removes contact exposure")
end
do
 local Core,Game=resetWorld({server=true});local H=require "KFM/Health";local I=require "KFM/Illness"
 local doctor=newPlayer({level=10});local patient=newPlayer({})
 H.answerConsent(patient,H.requestConsent(doctor,patient),true)
 Game.md(patient).health=I.seed(I.new(),"viral","dirtyMeal",nil,false)
 H.state(patient).episodes["gastro:general"].phase="symptomatic"
 local supply=doctor.inv:AddItem(newItem("Base.KFM_SupportSachet"))
 Game.rng=function()return 0 end
 care(H,doctor,patient,"gastro:general","support",supply)
 check(H.state(doctor).episodes["gastro:general"]~=nil and H.state(doctor).episodes["resp:general"]==nil,"viral care contact creates gastro episode, never flu")
end
do
 local Core,Game=resetWorld({});local H=require "KFM/Health";local doc=newPlayer({})
 local bp=doc:part("UpperLeg_L");bp.fracture=20
 H.observe(doc);H.recoveryReduction(doc,bp,"fracture",8)
 bp.fracture=0;H.observe(doc);bp.fracture=30;H.observe(doc)
 check(H.recoveryReduction(doc,bp,"fracture",12)>0,"new fracture gets fresh capped allowance after healing")
end


do
 local Core,Game=resetWorld({server=true});local H=require "KFM/Health"
 local doctor=newPlayer({level=10});local patient=newPlayer({})
 local bp=patient:part("Hand_L");bp.cut=true;bp.infLevel=5
 local bottle=doctor.inv:AddItem(newItem("Base.WaterBottle",{water={amount=1,kind="Water"}}))
 local a=KFM_ProcedureAction:new(doctor,patient,bp,"irrigate",bottle)
 a:complete()
 check(bp.infLevel==5,"legacy procedures also require server patient consent")
 H.answerConsent(patient,H.requestConsent(doctor,patient),true)
 doctor.x=100
 a:complete()
 check(bp.infLevel==5,"legacy procedures reject distant doctor")
end
do
 local Core,Game=resetWorld({});local doc=newPlayer({level=10})
 local bp=doc:part("UpperArm_L");bp.cut=true;bp.bleedingTime=8
 local belt=doc.inv:AddItem(newItem("Base.Belt2"))
 act(doc,doc,"UpperArm_L","tourniquet",belt):complete()
 SandboxVars.KFM.Enabled=false
 fire("EveryOneMinute")
 check(Game.md(doc).tq.UpperArm_L==nil and bp.bleedingTime==8 and doc.inv:contains(belt),"disable releases owned tourniquet support and keeps actual item")
end

do
 resetWorld({server=true});local doc=newPlayer({level=10});local bp=doc:part("Hand_L");bp.cut=true;bp.infLevel=5
 local bottle=doc.inv:AddItem(newItem("Base.WaterBottle",{water={amount=1,kind="Water"}}))
 local a=KFM_ProcedureAction:new(doc,doc,bp,"irrigate",bottle);doc.level=0;a:complete()
 check(near(bp.infLevel,3.5),"server recomputes actual doctor skill at completion")
end


do
 local Core,Game=resetWorld({server=true});local H=require "KFM/Health";local I=require "KFM/Illness"
 local doc=newPlayer({level=10})
 check(type(H.environment)=="function" and type(H.dynamic)=="function","production climate and reversible-state adapters exist")
 if H.environment then
  _G.getClimateManager=function()return {getAirTemperatureForCharacter=function()return -8 end,getWindIntensity=function()return 0.6 end,getHumidity=function()return 0.8 end}end
  _G.getGameTime=function()return {getWorldAgeHours=function()return world.hours end,getMonth=function()return 0 end}end
  doc.getSquare=function()return {isOutside=function()return true end}end
  doc.stats.WETNESS=80
  H.observe(doc)
  check(H.state(doc).sources["env:cold:Hand_L"]~=nil,"actual cold/wet observation creates hand risk source")
  local snapshot=H.snapshot(doc)
  check(snapshot.environment.month==1 and snapshot.environment.temperature==-8 and snapshot.exposures,"exam receives verified context and exposure details")
  Game.md(doc).health=I.seed(I.new(),"coldHands","cold:1","Hand_L",false)
  H.state(doc).episodes["coldHands:Hand_L"].age=3
  H.tick(doc,1/6)
  check(doc:part("Hand_L").pain>=10 and doc:part("Hand_R").pain==0,"cold injury applies actual native hand pain, preserving other hand")
 end
 if H.dynamic then
  local D=require "KFM/Dynamics"
  Game.md(doc).dynamic=D.seed(D.new(),"lowMood","fixture")
  check(H.medicalTime(doc)>1,"active low mood has an actual bounded procedure penalty")
  doc.sitting=true
  local journal=doc.inv:AddItem(newItem("Base.KFM_RecoveryJournal"))
  check(care(H,doc,doc,"trait:lowMood","journaling",journal),"actual dynamic-state care path commits finite item")
 end
end


do
 local Core,Game=resetWorld({server=true});local H=require "KFM/Health";local I=require "KFM/Illness"
 local doc=newPlayer({level=10});local flags={THIRST=1,ENDURANCE=2,FATIGUE=4}
 SyncPlayerStatsPacket={getBitMaskForStat=function(stat)return flags[stat]or 0 end}
 H.applyEffects(doc,{health=0,thirst=0,endurance=0,fatigue=0.02,enduranceRecovery=0.01,pain={}})
 check(doc.stats.FATIGUE==0.02 and log.stats[1]==6,"native stat bit masks synchronize fatigue and recovery to owning client")
 local empty=doc.inv:AddItem(newItem("Base.Pills",{uses=0}))
 Game.md(doc).health=I.seed(I.new(),"mosquitoFever","fixture",nil,false)
 check(not care(H,doc,doc,"mosquito:general","feverCare",empty) and empty.uses==0,"empty medicine cannot grant care or negative charges")
end
do
 local Core,Game=resetWorld({});local H=require "KFM/Health";local doc=newPlayer({})
 local mask=newItem("Base.Hat_SurgicalMask")
 function mask:getCondition()return 10 end
 doc.worn.MASK=mask
 H.registerExposure(doc,"masked",{Head=1,Hand_L=1})
 local head=H.state(doc).sources["masked:Head"];local hand=H.state(doc).sources["masked:Hand_L"]
 check(head.intensity>0 and head.intensity<hand.intensity,"appropriate mask partially reduces face blood exposure without shielding hands/eyes completely")
 doc.worn.MASK=nil
 H.registerExposure(doc,"masked",{Head=1})
 check(H.state(doc).sources["masked:Head"].intensity==1,"removing mask updates continuing blood exposure")
end

do
 local Core,Game=resetWorld({server=true});local H=require "KFM/Health";local I=require "KFM/Illness"
 local doc=newPlayer({stats={ENDURANCE=0.1},sitting=true,level=3})
 function doc:isRunning()return false end;function doc:isSprinting()return false end;function doc:isPlayerMoving()return false end
 function doc:getInventoryWeight()return 2 end;function doc:getMaxWeight()return 12 end
 local axe={getType=function()return "Axe"end,isRanged=function()return false end}
 function doc:getPrimaryHandItem()return axe end;function doc:getSecondaryHandItem()return axe end
 for window=1,4 do
  for hit=1,16 do world.hours=world.hours+1/600;fire("OnWeaponHitTree",doc,axe);fire("OnWeaponHitTree",doc,axe)end
  H.observe(doc,1/6)
 end
 check(H.state(doc).episodes["muscle:ForeArm_R"] and H.state(doc).episodes["muscle:ForeArm_L"],"native exhausted tool-hit events reach bounded bilateral forearm strain")
 local e=H.state(doc).episodes["muscle:ForeArm_R"];e.age=3
 H.tick(doc,1/6)
 check(doc:part("ForeArm_R").pain>10 and doc.stats.FATIGUE>0,"regional episode reaches native pain and actual effort-fatigue channels")
 check(H.snapshot(doc).episodes["muscle:ForeArm_R"].symptoms.toolEffort,"authoritative examination includes regional function")
 doc:part("ForeArm_R").stiffness=20
 H.tick(doc,1/6)
 check(doc:part("ForeArm_R").pain==0,"ordinary native stiffness supersedes additional true-strain symptoms without duplication")
 doc:part("ForeArm_R").stiffness=0
 H.tick(doc,1/6)
 check(doc:part("ForeArm_R").pain>10,"recoverable true strain remains after ordinary native stiffness subsides")
 local no=care(H,doc,doc,"muscle:ForeArm_R","rehab",nil)
 check(not no,"rehabilitation requires its actual wrap")
 doc.sitting=false
 check(not care(H,doc,doc,"muscle:ForeArm_R","muscleRest",nil),"rest care cannot be claimed while active")
 doc.sitting=true
 check(care(H,doc,doc,"muscle:ForeArm_R","muscleRest",nil),"real resting patient may start rest care")
 check(not care(H,doc,doc,"muscle:ForeArm_R","muscleRest",nil),"rest care interval blocks repeated XP/treatment")
 doc:part("ForeArm_R").fracture=10
 H.tick(doc,1/6)
 check(doc:part("ForeArm_R").pain==0,"native fracture supersedes owned regional strain pain")
 local other=newPlayer({stats={ENDURANCE=0.1}})
 function other:isRunning()return true end;function other:isSprinting()return false end;function other:isPlayerMoving()return true end
 function other:getInventoryWeight()return 20 end;function other:getMaxWeight()return 12 end
 H.observe(other,0)
 check(next(H.state(other).episodes)==nil,"first observation after reconnect has no workload catch-up")
end


do
 local Core,Game=resetWorld({server=true});local H=require "KFM/Health";local I=require "KFM/Illness"
 local patient=newPlayer({level=0,sitting=true});local doc=newPlayer({level=8,sitting=true});local stranger=newPlayer({level=8})
 Game.md(patient).health=I.seed(I.new(),"respiratory","secretCause","Torso_Upper",false)
 local e=H.state(patient).episodes["resp:Torso_Upper"];e.phase="symptomatic"
 check(type(H.project)=="function"and type(H.examine)=="function","observer protocol is wired into health adapter")
 if H.project and H.examine then
  local function first(v)for key,x in pairs(v.episodes or {})do return key,x end end
  local low=H.project(patient,patient);local key,f=first(low)
  check(low.version==3 and key~="resp:Torso_Upper"and not f.condition and not f.phase and not f.remaining and not low.exposures,"routine sync is opaque and observation-only")
  check(next(H.project(patient,doc).episodes)==nil,"unconsented other player cannot obtain health/history")
  local nonce=H.requestConsent(doc,patient);check(H.answerConsent(patient,nonce,true),"clinical observer consent accepted")
  local guessed=H.project(patient,doc);local _,unknown=first(guessed)
  check(not unknown.condition,"high skill alone on ordinary sync cannot diagnose")
  local basic=H.examine(patient,doc,nil,nil);local _,b=first(basic)
  check(b.confidence=="suspected"and not b.condition,"genuine missing-tool examination downgraded")
  local steth=doc.inv:AddItem(newItem(Game.ITEM_STETHOSCOPE))
  local high=H.examine(patient,doc,steth,nil);local highKey,clinical=first(high)
  check(clinical.condition=="respiratory"and clinical.confidence=="clinical","skill and owned instrument obtain clinical findings")
  local _,patientFinding=first(H.project(patient,patient));check(not patientFinding.condition,"patient does not inherit doctor assessment")
  check(#H.project(patient,patient).history==0 and #high.history==2,"exam history uses observer visibility")
  local antibiotics=doc.inv:AddItem(newItem("Base.Antibiotics"))
  check(not H.treat(stranger,patient,highKey,"antibacterial",antibiotics,clinical.id),"forged actor cannot use doctor offer")
  doc.inv:Remove(steth)
  check(not H.treat(doc,patient,highKey,"antibacterial",antibiotics,clinical.id)and doc.inv:contains(antibiotics),"removed instrument downgrades offer before resource mutation")
  doc.inv:AddItem(steth)
  check(not H.treat(doc,patient,"resp:Torso_Upper","antibacterial",antibiotics,clinical.id),"raw condition key cannot bypass clinical protocol")
  check(not H.treat(doc,patient,highKey,"antibacterial",antibiotics,999),"stale episode fails before mutation")
  check(H.treat(doc,patient,highKey,"antibacterial",antibiotics,clinical.id),"filtered clinical care targets real authoritative episode")
  local count=#Game.md(patient).medicalHistory.events;local xp=#log.xp
  local second=doc.inv:AddItem(newItem("Base.Antibiotics"))
  check(not H.treat(doc,patient,highKey,"antibacterial",second,clinical.id)and doc.inv:contains(second)and #log.xp==xp and #Game.md(patient).medicalHistory.events==count,"replay consumes no resources/XP/history")
  local own=H.project(patient,patient);check(own.history[1].kind=="care"and not own.history[1].condition,"successful care history shared without diagnosis")
  H.revokeConsent(patient)
  check(next(H.project(patient,doc).episodes)==nil and #H.project(patient,doc).history==0,"revocation removes observer data and history")
  check(not H.treat(doc,patient,highKey,"support",nil,clinical.id),"revoked care fails")
  local n=H.requestConsent(doc,patient);H.answerConsent(patient,n,true);world.hours=world.hours+2
  check(next(H.project(patient,doc).episodes)==nil,"expired consent removes data")
  Game.md(patient).health.episodes["resp:Torso_Upper"].phase="latent"
  check(next(H.project(patient,patient).episodes)==nil,"routine hidden latent episode absent")
 end
end


-- Exam knowledge belongs to an examined episode/condition and the observer character.
do
 local _,Game=resetWorld({server=true});local H=require "KFM/Health";local I=require "KFM/Illness"
 local patient=newPlayer({sitting=true});local doctor=newPlayer({level=8,name="SameAccount"})
 local n=H.requestConsent(doctor,patient);H.answerConsent(patient,n,true)
 Game.md(patient).health=I.seed(I.new(),"flu","old","Torso_Upper",false)
 local e=H.state(patient).episodes["resp:Torso_Upper"];e.phase="symptomatic"
 local steth=doctor.inv:AddItem(newItem(Game.ITEM_STETHOSCOPE));H.examine(patient,doctor,steth,nil)
 check(H.project(patient,doctor).episodes["e"..e.id].condition=="flu","current examined episode has supported finding")
 e=H.state(patient).episodes["resp:Torso_Upper"];e.condition="respiratory";e.phase="complication"
 check(H.project(patient,doctor).episodes["e"..e.id].condition==nil,"old assessment cannot identify a later complication without re-examination")
 Game.md(patient).health=I.seed(H.state(patient),"dermatitis","new","Hand_L",false)
 local skin=H.state(patient).episodes["skin:Hand_L"];skin.phase="symptomatic"
 check(H.project(patient,doctor).episodes["e"..skin.id].condition==nil,"old assessment cannot identify a new episode")
 local replacement=newPlayer({level=8,name="SameAccount"})
 local nonce=H.requestConsent(replacement,patient);H.answerConsent(patient,nonce,true)
 check(#H.project(patient,replacement).history==0,"new character on same account cannot inherit another character's medical observations")
end

-- A disposable diagnostic tool is validated before use, not required to reappear after consumption.
do
 local _,Game=resetWorld({});local Client=loadClient();local H=require "KFM/Health";local I=require "KFM/Illness"
 local patient=newPlayer({level=8,sitting=true})
 Game.md(patient).health=I.seed(I.new(),"soreThroat","throat","Head",false)
 local e=H.state(patient).episodes["throat:Head"];e.phase="symptomatic"
 local tongue=patient.inv:AddItem(newItem(Game.ITEM_TONGUE))
 act(patient,patient,"Head","exam",nil,tongue):complete()
 local offer=H.project(patient,patient).episodes["e"..e.id]
 check(not patient.inv:contains(tongue)and offer.condition=="soreThroat","disposable tool records a completed valid examination")
 local lozenges=patient.inv:AddItem(newItem(H.ITEMS.throatRemedy))
 check(H.treat(patient,patient,"e"..e.id,"throatRemedy",lozenges,e.id),"completed throat assessment permits actual finite care after disposable use")
end

-- Revocation/expiry closes every matching window without walking deleted entries.
do
 resetWorld({client=true});local Client=loadClient();local doctor=newPlayer({});local patient=newPlayer({})
 local closed=0
 local function win()return {setVisible=function()end,removeFromUIManager=function()closed=closed+1 end,getIsVisible=function()return true end}end
 for n=1,3 do Client.reports[n]={window=win(),payload={self=false,doctorId=doctor.id,patientId=patient.id,accessUntil=world.hours-1}}end
 local ok=pcall(Client.expireReports)
 check(ok and #Client.reports==0 and closed==3,"expiry clears multiple report windows without nil dereference")
end


-- Reconstructed procedures must bind the body part to the consented patient.
do
 local _,Game=resetWorld({server=true});local H=require "KFM/Health"
 local doctor=newPlayer({level=8});local nearby=newPlayer({});local remote=newPlayer({x=100,y=100})
 H.leases[nearby]={[doctor]=world.hours+1}
 local wrong=remote:part("Hand_R");wrong.cut=true;wrong.infLevel=6
 local water=doctor.inv:AddItem(newItem("Base.WaterBottle",{water={amount=1,kind="Water"}}))
 local action=KFM_ProcedureAction:new(doctor,nearby,wrong,"irrigate",water,nil)
 check(not action:isValid(),"foreign body part cannot be passed as consented nearby patient's limb")
 action:complete()
 check(wrong.infLevel==6 and water.water.amount==1 and #log.xp==0,"mismatched patient/limb cannot mutate remote health or resources/XP")
end


-- A disconnected patient is not simulated: tourniquet age must not jump on return.
do
 local _,Game=resetWorld({server=true});local player=newPlayer({level=8})
 local belt=player.inv:AddItem(newItem("Base.Belt2"));act(player,player,"UpperArm_L","tourniquet",belt):complete()
 fire("EveryTenMinutes");local st=Game.md(player).tq.UpperArm_L
 local all=world.players;world.players={};world.hours=world.hours+8;fire("EveryTenMinutes")
 world.players=all;fire("EveryTenMinutes")
 check(player:part("UpperArm_L").health==100 and player:part("UpperArm_L").fracture==0,"offline tourniquet duration does not apply ischemia or fracture on reconnection")
 check(near(st.elapsedHours or 0,0),"offline duration is excluded from persistent active tourniquet clock")
 for n=1,13 do world.hours=world.hours+1/6;fire("EveryTenMinutes")end
 check(player:part("UpperArm_L").health<100,"online active tourniquet hours still cause ischemia")
end

check(#missingText == 0, "missing translation keys: " .. table.concat(missingText, ","))
_G.print = realPrint
return failures
