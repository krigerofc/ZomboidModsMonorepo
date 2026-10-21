-- Basic Vehicle Maintenance (mod id MoreVehiclesRepairs) - balance data. No game API here.
-- materials: list of requirement groups. A group is a flat list of alternatives
--   { "Base.TypeA", qtyA, "Base.TypeB", qtyB, ... } - the first alternative the player can
--   fully pay is used. For drainable items (DuctTape, Glue, Wire, Thread, BlowTorch) qty means
--   "uses" (one UseDelta step each), for normal items it means item count.
-- tools: ItemTag enum names (resolved at runtime with ItemTag[name]); the item must not be broken.
-- gain / cap / fail: base condition gain, base condition cap, base failure chance (0..1).
-- time: base action time in ticks. heat: welding-like job (burn risk, Metalworking for tiers).
-- jack: a Base.Jack in the inventory speeds this job up (workshop bonus).
-- electric: Electrical skill gate for the Overhaul tier.
MVR = MVR or {}

local Config = {}
MVR.Config = Config

Config.Parts = {
    Engine = {
        materials = { { "Base.ScrapMetal", 4 }, { "Base.SheetMetal", 1, "Base.SmallSheetMetal", 2 }, { "Base.Screws", 4 }, { "Base.DuctTape", 2 } },
        tools = { "WRENCH", "SCREWDRIVER" }, gain = 15, cap = 50, fail = 0.25, time = 450, heat = true,
    },
    Brake = {
        materials = { { "Base.ScrapMetal", 3 }, { "Base.RippedSheets", 2, "Base.DenimStrips", 2 }, { "Base.DuctTape", 1 } },
        tools = { "WRENCH" }, gain = 15, cap = 55, fail = 0.20, time = 250, jack = true,
    },
    Suspension = {
        materials = { { "Base.ScrapMetal", 3 }, { "Base.Wire", 2 }, { "Base.Screws", 4 }, { "Base.DuctTape", 1 } },
        tools = { "WRENCH" }, gain = 15, cap = 55, fail = 0.20, time = 280, jack = true,
    },
    Tire = {
        materials = { { "Base.DuctTape", 2 }, { "Base.Glue", 1 } },
        tools = {}, gain = 12, cap = 45, fail = 0.15, time = 200, jack = true,
    },
    Door = {
        materials = { { "Base.SheetMetal", 2, "Base.SmallSheetMetal", 4 }, { "Base.Screws", 4 }, { "Base.DuctTape", 1 } },
        tools = { "SCREWDRIVER" }, gain = 15, cap = 60, fail = 0.12, time = 200,
    },
    Hood = {
        materials = { { "Base.SheetMetal", 2, "Base.SmallSheetMetal", 4 }, { "Base.Screws", 4 }, { "Base.DuctTape", 1 } },
        tools = { "SCREWDRIVER" }, gain = 15, cap = 60, fail = 0.12, time = 200,
    },
    TrunkLid = {
        materials = { { "Base.SheetMetal", 2, "Base.SmallSheetMetal", 4 }, { "Base.Screws", 4 }, { "Base.DuctTape", 1 } },
        tools = { "SCREWDRIVER" }, gain = 15, cap = 60, fail = 0.12, time = 200,
    },
    Window = {
        materials = { { "Base.RippedSheets", 3, "Base.DenimStrips", 3 }, { "Base.DuctTape", 2 } },
        tools = {}, gain = 10, cap = 35, fail = 0.30, time = 150,
    },
    Muffler = {
        materials = { { "Base.SheetMetal", 1, "Base.SmallSheetMetal", 2 }, { "Base.ScrapMetal", 2 }, { "Base.Wire", 2 }, { "Base.DuctTape", 1 } },
        tools = { "WRENCH" }, gain = 15, cap = 50, fail = 0.20, time = 240, heat = true,
    },
    GasTank = {
        materials = { { "Base.SheetMetal", 2, "Base.SmallSheetMetal", 4 }, { "Base.ScrapMetal", 2 }, { "Base.Glue", 2 }, { "Base.DuctTape", 2 } },
        tools = { "WRENCH", "SCREWDRIVER" }, gain = 12, cap = 45, fail = 0.25, time = 320, heat = true,
    },
    Battery = {
        materials = { { "Base.ElectronicsScrap", 3 }, { "Base.ElectricWire", 2 }, { "Base.DuctTape", 1 } },
        tools = { "SCREWDRIVER" }, gain = 12, cap = 45, fail = 0.30, time = 220, electric = true,
    },
    Seat = {
        materials = { { "Base.LeatherStrips", 3, "Base.RippedSheets", 4, "Base.DenimStrips", 4 }, { "Base.Thread", 1 } },
        tools = { "SEWING_NEEDLE" }, gain = 15, cap = 70, fail = 0.10, time = 180,
    },
    Radio = {
        materials = { { "Base.ElectronicsScrap", 2 }, { "Base.ElectricWire", 2 }, { "Base.Screws", 2 } },
        tools = { "SCREWDRIVER" }, gain = 12, cap = 45, fail = 0.35, time = 220, electric = true,
    },
    -- Bulbs are replaced, not patched (v1 design decision). Shown disabled with a hint.
    Light = { notRepairable = true, reason = "light" },
    -- Anything else (bumpers, mirrors, truck beds, glove boxes, trailers, mod parts...).
    Default = {
        materials = { { "Base.ScrapMetal", 2 }, { "Base.DuctTape", 1 } },
        tools = { "SCREWDRIVER" }, gain = 12, cap = 50, fail = 0.20, time = 200,
    },
}

-- Ordered, case-insensitive substring aliases: most specific first.
Config.PartAliases = {
    { "HoodOrnament", "Default" },
    { "EngineDoor", "Hood" },
    { "TrunkDoor", "TrunkLid" },
    { "TrunkLid", "TrunkLid" },
    { "TruckBed", "Default" },
    { "Trailer", "Default" },
    { "GloveBox", "Default" },
    { "Windshield", "Window" },
    { "Headlight", "Light" },
    { "Lightbar", "Light" },
    { "Light", "Light" },
    { "Lamp", "Light" },
    { "Bulb", "Light" },
    { "FuelTank", "GasTank" },
    { "GasTank", "GasTank" },
    { "Engine", "Engine" },
    { "Brake", "Brake" },
    { "Suspension", "Suspension" },
    { "Shock", "Suspension" },
    { "Tire", "Tire" },
    { "Tyre", "Tire" },
    { "Wheel", "Tire" },
    { "Window", "Window" },
    { "Door", "Door" },
    { "Hood", "Hood" },
    { "Trunk", "TrunkLid" },
    { "Muffler", "Muffler" },
    { "Exhaust", "Muffler" },
    { "Battery", "Battery" },
    { "Seat", "Seat" },
    { "Radio", "Radio" },
}

-- Outcome / progression constants (PRD 6.2, 6.3). Sandbox multipliers apply on top.
Config.Rules = {
    failPerLevel = 0.025,      -- per Mechanics level above 1
    failMin = 0.03, failMax = 0.60,
    critBase = 0.05, critPerLevel = 0.005, critGainMult = 1.5,
    severeShare = 0.40,        -- share of failures that are severe
    lightFailLoss = 5, severeFailLoss = 20,
    gainPerLevel = 0.05,
    capPerLevel = 2, capPerPatch = 3, capFloor = 30,
    xpSuccess = 3, xpCrit = 5, xpFail = 1,
    xpCooldownMs = 24 * 60 * 60 * 1000, -- one full-XP repair per part per vehicle per game day
    -- side effects
    injuryBase = 0.05, injuryPerLevel = 0.004, injuryGloves = 0.5, cutShare = 0.30,
    burnBase = 0.04, burnGloves = 0.25, burnMin = 10, burnMax = 20,
    toolWearChance = 0.15, toolWearMin = 1, toolWearMax = 3,
    wasteChance = 0.10,
    frustrationChance = 0.10, frustrationAmount = 5,
    -- workshop (v1.1)
    indoorBonus = 0.03, darkPenalty = 0.05, bonusLimit = 0.08, jackTimeMult = 0.85,
}

-- Quality tiers (PRD 6.7). capBonus adds to the cap, hardCap is the absolute ceiling.
Config.Tiers = {
    { id = "patch", mech = 0, capBonus = 0, hardCap = 75, matMult = 1.0, timeMult = 1.0 },
    { id = "repair", mech = 3, heatMetal = 2, needsShelterOrJack = true, capBonus = 10, hardCap = 78, matMult = 1.5, timeMult = 1.5 },
    { id = "overhaul", mech = 6, heatMetal = 4, heatTorchUses = 3, electricSkill = 3, capBonus = 20, hardCap = 80, matMult = 2.0, timeMult = 2.0 },
}

return Config
