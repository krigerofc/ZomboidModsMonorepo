-- Unit tests for MVR/Core.lua (pure logic). Globals from run.js: PARTIDS (array), ITEMS (set).
local failures = 0
local checks = 0
local function check(cond, msg)
    checks = checks + 1
    if not cond then
        failures = failures + 1
        print("  FAIL core: " .. msg)
    end
end
local function near(a, b) return math.abs(a - b) < 1e-9 end

MVR = nil
require "MVR/Core"
local Core, Config = MVR.Core, MVR.Config
local Rules = Config.Rules
local opts = Core.readSandbox(nil)

-- ---------------------------------------------------------------- sandbox
check(opts.Enabled == true and opts.FailChanceMultiplier == 1 and opts.CapOffset == 0, "sandbox defaults when SandboxVars is nil")
local o2 = Core.readSandbox({ MVR = { FailChanceMultiplier = 99, CapOffset = -100, XPMultiplier = "2", SevereFailEnabled = false, TimeMultiplier = "x" } })
check(o2.FailChanceMultiplier == 3 and o2.CapOffset == -30, "sandbox values are clamped")
check(o2.XPMultiplier == 2 and o2.SevereFailEnabled == false and o2.TimeMultiplier == 1, "sandbox coercion / fallback")
check(Core.readSandbox({}).QualityTiersEnabled == true, "missing MVR page uses defaults")

-- ---------------------------------------------------------------- part config
local expect = {
    EngineDoor = "Hood", TrunkDoor = "TrunkLid", TrunkDoorOpened = "TrunkLid", Engine = "Engine",
    DoorFrontLeft = "Door", DoorRear = "Door", WindowFrontLeft = "Window", Windshield = "Window", WindshieldRear = "Window",
    HeadlightLeft = "Light", HeadlightRearRight = "Light", lightbar = "Light", GasTank = "GasTank",
    BrakeFrontLeft = "Brake", SuspensionRearRight = "Suspension", TireFrontLeft = "Tire", Muffler = "Muffler",
    Battery = "Battery", SeatFrontLeft = "Seat", Radio = "Radio", HoodOrnament = "Default", TruckBed = "Default",
    TrailerTrunk = "Default", GloveBox = "Default", PassengerCompartment = "Default", Heater = "Default", TestPart1 = "Default",
}
for id, key in pairs(expect) do
    check(Core.getConfigKey(id) == key, "alias " .. id .. " -> " .. key .. " (got " .. Core.getConfigKey(id) .. ")")
end
check(#PARTIDS >= 50, "fixture has vanilla part ids")
for _, id in ipairs(PARTIDS) do
    local cfg, key = Core.getConfig(id)
    check(cfg ~= nil and key ~= nil, "config for vanilla part " .. id)
    if cfg and not cfg.notRepairable then
        check(type(cfg.materials) == "table" and cfg.gain and cfg.cap and cfg.fail and cfg.time, "complete config for " .. id)
    end
end
check(Core.getConfig(nil) == Config.Parts.Default and Core.getConfig("") == Config.Parts.Default, "nil/empty id -> Default")
check(Core.getConfigKey("ModdedSpoilerXYZ") == "Default", "unknown modded id -> Default")
check(Core.getConfig("HeadlightLeft").notRepairable == true, "lights are not repairable but not nil")

-- every material/tool referenced exists in vanilla
for key, cfg in pairs(Config.Parts) do
    for _, group in ipairs(cfg.materials or {}) do
        check(#group >= 2 and #group % 2 == 0, key .. " group shape")
        for i = 1, #group, 2 do
            check(ITEMS[group[i]], key .. " material exists in vanilla: " .. tostring(group[i]))
            check(type(group[i + 1]) == "number" and group[i + 1] >= 1, key .. " qty")
        end
    end
    for _, t in ipairs(cfg.tools or {}) do
        check(t == "WRENCH" or t == "SCREWDRIVER" or t == "SEWING_NEEDLE", key .. " tool tag " .. tostring(t))
    end
end
check(ITEMS["Base.BlowTorch"] and ITEMS["Base.Jack"], "BlowTorch and Jack exist")

-- ---------------------------------------------------------------- formulas (PRD 6.2 examples)
local brake = Config.Parts.Brake
check(near(Core.failChance(brake, 0, 0, opts), 0.20), "brake fail at Mechanics 0 = 20%")
check(near(Core.failChance(brake, 8, 0, opts), 0.03), "brake fail at Mechanics 8 = floor 3%")
check(Core.gain(brake, 0, opts) == 15 and Core.gain(brake, 8, opts) == 21, "brake gain 15 / 21")
check(Core.cap(brake, 0, 0, nil, opts) == 55 and Core.cap(brake, 8, 0, nil, opts) == 71, "brake cap 55 / 71")
check(near(Core.failChance(Config.Parts.Radio, 0, -0.5, opts), 0.60), "fail ceiling 60%")
check(near(Core.failChance(brake, 0, 0, Core.readSandbox({ MVR = { FailChanceMultiplier = 0 } })), 0), "multiplier 0 -> never fails")
check(near(Core.failChance(Config.Parts.Radio, 0, 0, Core.readSandbox({ MVR = { FailChanceMultiplier = 3 } })), 0.95), "final clamp 95%")
for m = 0, 10 do
    for _, cfg in pairs(Config.Parts) do
        if not cfg.notRepairable then
            local f = Core.failChance(cfg, m, 0, opts)
            check(f >= Rules.failMin - 1e-9 and f <= Rules.failMax + 1e-9, "fail within [3%,60%]")
            check(Core.cap(cfg, m, 0, Config.Tiers[1], opts) <= 75, "patch never above 75")
            check(Core.cap(cfg, m, 0, Config.Tiers[3], Core.readSandbox({ MVR = { CapOffset = 20 } })) <= 80, "overhaul never above 80")
        end
    end
    check(Core.critChance(m) >= 0.05 and Core.critChance(m) <= 0.5, "crit chance clamp")
end
check(Core.cap(Config.Parts.Window, 0, 10, nil, opts) == 30, "cap floor 30 with many patches")
check(Core.cap(brake, 0, 2, nil, opts) == 49, "each patch lowers cap by 3")
check(Core.cap(brake, 0, 0, Config.Tiers[2], opts) == 65, "repair tier +10")
check(Core.cap(brake, 10, 0, Config.Tiers[3], opts) == 80, "overhaul hard cap 80")
check(Core.cap(brake, 0, 0, nil, Core.readSandbox({ MVR = { CapOffset = -30 } })) == 30, "cap offset still floored")
check(Core.gain(brake, 0, Core.readSandbox({ MVR = { ConditionGainMultiplier = 0.25 } })) == 4, "gain multiplier")

-- ---------------------------------------------------------------- outcome roll
check(Core.rollOutcome(0.2, 0.05, true, 0.00) == "severe", "r below 40% of fail = severe")
check(Core.rollOutcome(0.2, 0.05, true, 0.079) == "severe", "severe boundary")
check(Core.rollOutcome(0.2, 0.05, true, 0.081) == "light", "light after severe share")
check(Core.rollOutcome(0.2, 0.05, false, 0.00) == "light", "severe disabled -> light")
check(Core.rollOutcome(0.2, 0.05, true, 0.21) == "crit", "crit band")
check(Core.rollOutcome(0.2, 0.05, true, 0.25) == "success", "success")
check(Core.rollOutcome(0, 0.05, true, 0) == "crit", "no fail chance never fails")
check(Core.rollOutcome(0.95, 0.5, true, 0.99) == "crit", "crit limited to remaining space")

-- ---------------------------------------------------------------- condition math
check(Core.applyOutcome(20, "success", 15, 55) == 35, "success adds gain")
check(Core.applyOutcome(50, "success", 15, 55) == 55, "success clamps to cap")
check(Core.applyOutcome(60, "success", 15, 55) == 60, "success never lowers condition")
check(Core.applyOutcome(20, "crit", 15, 55) == 43, "crit gain x1.5 (rounded)")
check(Core.applyOutcome(50, "crit", 15, 55) == 55, "crit respects cap")
check(Core.applyOutcome(20, "light", 15, 55) == 15, "light fail -5")
check(Core.applyOutcome(3, "light", 15, 55) == 1, "light fail keeps at least 1")
check(Core.applyOutcome(0, "light", 15, 55) == 0, "light fail at 0 stays 0")
check(Core.applyOutcome(30, "severe", 15, 55) == 10, "severe -20")
check(Core.applyOutcome(12, "severe", 15, 55) == 0, "severe floors at 0")
check(Core.applyOutcome(95, "success", 15, 200) == 100, "never above 100")

-- ---------------------------------------------------------------- XP / anti-farm
check(Core.xpFor("success", opts) == 3 and Core.xpFor("crit", opts) == 5 and Core.xpFor("light", opts) == 1 and Core.xpFor("severe", opts) == 1, "xp values")
check(Core.xpFor("crit", Core.readSandbox({ MVR = { XPMultiplier = 2 } })) == 10, "xp multiplier")
local DAY = Rules.xpCooldownMs
check(Core.xpAllowed(nil, 1000), "first repair gives xp")
check(not Core.xpAllowed(1000, 1000 + DAY - 1), "same day no xp")
check(Core.xpAllowed(1000, 1000 + DAY), "next day xp again")
check(not Core.xpAllowed(true, 5), "non-number marker blocks xp")

-- ---------------------------------------------------------------- materials scaling
local scaled = Core.materialsFor(Config.Parts.Door, Config.Tiers[2], opts)
check(scaled[1][2] == 3 and scaled[1][4] == 6 and scaled[2][2] == 6 and scaled[3][2] == 2, "repair tier x1.5 materials")
local cheap = Core.materialsFor(Config.Parts.Tire, nil, Core.readSandbox({ MVR = { MaterialCostMultiplier = 0.25 } }))
check(cheap[1][2] == 1 and cheap[2][2] == 1, "scaled qty never below 1")
local ovh = Core.materialsFor(Config.Parts.Engine, Config.Tiers[3], opts)
check(ovh[#ovh][1] == "Base.BlowTorch" and ovh[#ovh][2] == 3, "overhaul on heat part needs blowtorch uses")
check(#Core.materialsFor(Config.Parts.Brake, Config.Tiers[3], opts) == 3, "no torch for non-heat part")

-- ---------------------------------------------------------------- inventory walk (mocks)
local function item(t, units, opt)
    opt = opt or {}
    return { t = t, u = units or 1, broken = opt.broken, inv = opt.inv }
end
local function bag(children) return item("Base.Bag_Schoolbag", 1, { inv = { items = children } }) end
local adapter = {
    items = function(c) return c.items end,
    child = function(i) return i.inv end,
    fullType = function(i) return i.t end,
    units = function(i) return i.u end,
    usable = function(i) return not i.broken and i.u > 0 end,
}
local tapeMain = item("Base.DuctTape", 1)
local tapeDeep = item("Base.DuctTape", 3)
local root = { items = {
    item("Base.ScrapMetal"), item("Base.ScrapMetal", 1, { broken = true }), tapeMain,
    bag({ item("Base.ScrapMetal"), bag({ item("Base.ScrapMetal"), tapeDeep, item("Base.DuctTape", 0) }) }),
} }
local entries = Core.collectItems(root, adapter)
local idx = Core.indexByType(entries)
check(Core.countType(idx, "Base.ScrapMetal") == 3, "counts scrap in main + nested bags, skips broken")
check(Core.countType(idx, "Base.DuctTape") == 4, "drainable uses summed across bags, empty skipped")
check(Core.countType(idx, "Base.Bag_Schoolbag") == 2, "bags themselves are items")

local ok, picks, report = Core.planMaterials({ { "Base.ScrapMetal", 3 }, { "Base.DuctTape", 2 } }, idx)
check(ok and #report == 2 and report[1].ok and report[2].ok, "plan succeeds with bag materials")
local tapeUnits = 0
for _, p in ipairs(picks) do if p.entry.type == "Base.DuctTape" then tapeUnits = tapeUnits + p.units end end
check(tapeUnits == 2, "plans exactly 2 tape uses")
check(picks[#picks].entry.item == tapeMain or picks[#picks - 1].entry.item == tapeMain, "emptiest roll is used first")
local ok2, _, rep2 = Core.planMaterials({ { "Base.ScrapMetal", 4 } }, idx)
check(not ok2 and rep2[1].have == 3 and rep2[1].need == 4, "missing material reported with have/need")
local ok3, _, rep3 = Core.planMaterials({ { "Base.SheetMetal", 1, "Base.ScrapMetal", 2 } }, idx)
check(ok3 and rep3[1].type == "Base.ScrapMetal" and rep3[1].altIndex == 2 and rep3[1].alternatives[1].type == "Base.SheetMetal", "substitute material chosen")
local ok4 = Core.planMaterials({ { "Base.ScrapMetal", 2 }, { "Base.ScrapMetal", 2 } }, idx)
check(not ok4, "the same item is never counted twice across groups")
local okw, _, repw, usedw = Core.planMaterials({ { "Base.ScrapMetal", 2 } }, idx)
local extra = Core.planWaste(repw, idx, usedw)
check(okw and extra and extra.entry.type == "Base.ScrapMetal" and extra.units == 1, "waste takes one extra unit")
local _, _, repw2, usedw2 = Core.planMaterials({ { "Base.ScrapMetal", 3 } }, idx)
check(Core.planWaste(repw2, idx, usedw2) == nil, "waste skipped when nothing left")

-- ---------------------------------------------------------------- tiers
local ctx = { mech = 3, metal = 1, elec = 0, indoors = false, hasJack = false }
local okT, reqs = Core.tierRequirements(Config.Parts.Engine, Config.Tiers[2], ctx)
check(not okT and #reqs == 3, "repair tier on engine: mech + metal + shelter/jack")
ctx.metal, ctx.hasJack = 2, true
check((Core.tierRequirements(Config.Parts.Engine, Config.Tiers[2], ctx)), "repair tier ok with metal 2 + jack")
check((Core.tierRequirements(Config.Parts.Engine, Config.Tiers[1], { mech = 0 })), "patch always allowed")
local okE, reqE = Core.tierRequirements(Config.Parts.Battery, Config.Tiers[3], { mech = 6, elec = 2 })
check(not okE and reqE[2].key == "Electricity", "overhaul battery needs Electrical 3")
check(Core.getTier("nope").id == "patch", "unknown tier -> patch")

-- ---------------------------------------------------------------- workshop / duration
check(near(Core.workshopBonus({ indoors = true }, opts), 0.03), "indoors bonus")
check(near(Core.workshopBonus({ indoors = true, dark = true }, opts), -0.02), "dark penalty")
check(Core.workshopBonus({ indoors = true }, Core.readSandbox({ MVR = { WorkshopBonusEnabled = false } })) == 0, "workshop disabled")
check(Core.duration(Config.Parts.Tire, nil, opts, true) == 170, "jack 15% faster on tires")
check(Core.duration(Config.Parts.Door, nil, opts, true) == 200, "jack ignored on doors")
check(Core.duration(Config.Parts.Engine, Config.Tiers[3], opts, false) == 900, "overhaul x2 time")

-- ---------------------------------------------------------------- side effects
local function seq(list)
    local i = 0
    return function() i = i + 1; return list[i] or 0.99 end
end
local ev = Core.rollSideEffects({ mech = 0, gloves = false, heat = true, failed = true, hasTools = true }, opts, seq({ 0.01, 0.9, 0.1, 0.01, 0.5, 0.1, 0.01, 0.99, 0.05, 0.05 }))
check(ev.injury == "scratch" and ev.hand == "L", "injury scratch on left hand")
check(ev.burn and ev.burn >= 10 and ev.burn <= 20 and ev.burnHand == "L", "burn time 10-20")
check(ev.toolWear == 3, "tool wear 1-3")
check(ev.waste == true and ev.frustration == 5, "waste + frustration on failure")
local none = Core.rollSideEffects({ mech = 0, heat = true, failed = true, hasTools = true }, Core.readSandbox({ MVR = { SideEffectsEnabled = false } }), seq({}))
check(next(none) == nil, "side effects disabled")
local gl = Core.rollSideEffects({ mech = 0, gloves = true, heat = false, failed = false }, opts, seq({ 0.03 }))
check(gl.injury == nil, "gloves halve injury chance (3% roll misses 2.5%)")
local hi = Core.rollSideEffects({ mech = 20, gloves = false }, opts, seq({ 0.0 }))
check(hi.injury == nil, "high skill removes injury chance")

-- ---------------------------------------------------------------- patch history
local md = {}
check(Core.getPatches(md, 7, opts) == 0, "no history")
check(Core.addPatch(md, 7, "patch", opts) == 1 and Core.addPatch(md, 7, "repair", opts) == 2, "history counts")
check(Core.getPatches(md, 7, opts) == 2 and md.MVR.last == "repair", "history read back")
check(Core.getPatches(md, 8, opts) == 0, "new part item resets history")
check(Core.addPatch(md, 8, "patch", opts) == 1, "history restarts for new item")
check(Core.getPatches(md, 8, Core.readSandbox({ MVR = { PatchHistoryEnabled = false } })) == 0, "history disabled")
check(Core.riskBand(0.05) == "low" and Core.riskBand(0.2) == "medium" and Core.riskBand(0.3) == "high", "risk bands")

print("  core_spec.lua: " .. checks .. " checks")
return failures
