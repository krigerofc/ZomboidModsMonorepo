MVR_RepairConfig = {}

-- conditionGain ADDS to current part condition (clamped at conditionCap).
-- The option is hidden when current condition is already >= conditionCap.
MVR_RepairConfig.Parts = {
    Engine = {
        materials   = { ["Base.ScrapMetal"] = 20, ["Base.SheetMetal"] = 8, ["Base.DuctTape"] = 3 },
        tools       = { "Base.PipeWrench", "Base.Screwdriver" },
        conditionGain = 18,
        conditionCap  = 60,
        breakChance   = 0.20,
        repairTime    = 450,
        requiresHeat  = true,
    },
    Brake = {
        materials   = { ["Base.ScrapMetal"] = 9, ["Base.SheetMetal"] = 1, ["Base.DuctTape"] = 1 },
        tools       = { "Base.Screwdriver", "Base.PipeWrench" },
        conditionGain = 15,
        conditionCap  = 60,
        breakChance   = 0.20,
        repairTime    = 250,
        requiresHeat  = false,
    },
    Suspension = {
        materials   = { ["Base.ScrapMetal"] = 9, ["Base.SheetMetal"] = 2, ["Base.DuctTape"] = 1 },
        tools       = { "Base.Screwdriver", "Base.PipeWrench" },
        conditionGain = 15,
        conditionCap  = 60,
        breakChance   = 0.20,
        repairTime    = 280,
        requiresHeat  = false,
    },
    Tire = {
        materials   = { ["Base.ScrapMetal"] = 3, ["Base.DuctTape"] = 2 },
        tools       = { "Base.PipeWrench" },
        conditionGain = 12,
        conditionCap  = 50,
        breakChance   = 0.15,
        repairTime    = 200,
        requiresHeat  = false,
    },
    Door = {
        materials   = { ["Base.ScrapMetal"] = 5, ["Base.DuctTape"] = 2 },
        tools       = { "Base.Screwdriver" },
        conditionGain = 15,
        conditionCap  = 65,
        breakChance   = 0.10,
        repairTime    = 180,
        requiresHeat  = false,
    },
    Window = {
        materials   = { ["Base.DuctTape"] = 2 },
        tools       = {},
        conditionGain = 10,
        conditionCap  = 40,
        breakChance   = 0.30,
        repairTime    = 150,
        requiresHeat  = false,
    },
    Hood = {
        materials   = { ["Base.ScrapMetal"] = 6, ["Base.DuctTape"] = 2 },
        tools       = { "Base.Screwdriver" },
        conditionGain = 15,
        conditionCap  = 60,
        breakChance   = 0.15,
        repairTime    = 200,
        requiresHeat  = false,
    },
    TrunkLid = {
        materials   = { ["Base.ScrapMetal"] = 5, ["Base.DuctTape"] = 2 },
        tools       = { "Base.Screwdriver" },
        conditionGain = 15,
        conditionCap  = 60,
        breakChance   = 0.15,
        repairTime    = 190,
        requiresHeat  = false,
    },
    Muffler = {
        materials   = { ["Base.ScrapMetal"] = 7, ["Base.SheetMetal"] = 3, ["Base.DuctTape"] = 3 },
        tools       = { "Base.PipeWrench" },
        conditionGain = 15,
        conditionCap  = 55,
        breakChance   = 0.20,
        repairTime    = 240,
        requiresHeat  = true,
    },
    GasTank = {
        materials   = { ["Base.ScrapMetal"] = 10, ["Base.SheetMetal"] = 4, ["Base.DuctTape"] = 4 },
        tools       = { "Base.Screwdriver", "Base.PipeWrench" },
        conditionGain = 12,
        conditionCap  = 50,
        breakChance   = 0.25,
        repairTime    = 320,
        requiresHeat  = true,
    },
    Battery = {
        materials   = { ["Base.ScrapMetal"] = 5, ["Base.SheetMetal"] = 2, ["Base.DuctTape"] = 2 },
        tools       = { "Base.Screwdriver" },
        conditionGain = 12,
        conditionCap  = 45,
        breakChance   = 0.30,
        repairTime    = 220,
        requiresHeat  = false,
    },
    Seat = {
        materials   = { ["Base.DuctTape"] = 3 },
        tools       = {},
        conditionGain = 15,
        conditionCap  = 70,
        breakChance   = 0.05,
        repairTime    = 120,
        requiresHeat  = false,
    },
    Radio = {
        materials   = { ["Base.ScrapMetal"] = 4, ["Base.SheetMetal"] = 2, ["Base.DuctTape"] = 1 },
        tools       = { "Base.Screwdriver" },
        conditionGain = 12,
        conditionCap  = 45,
        breakChance   = 0.35,
        repairTime    = 220,
        requiresHeat  = false,
    },
    Headlight = {
        materials   = { ["Base.DuctTape"] = 2 },
        tools       = { "Base.Screwdriver" },
        conditionGain = 12,
        conditionCap  = 55,
        breakChance   = 0.20,
        repairTime    = 150,
        requiresHeat  = false,
    },
    Default = {
        materials   = { ["Base.ScrapMetal"] = 5, ["Base.DuctTape"] = 1 },
        tools       = { "Base.Screwdriver" },
        conditionGain = 12,
        conditionCap  = 50,
        breakChance   = 0.25,
        repairTime    = 200,
        requiresHeat  = false,
    },
}

-- Each Mechanics level above SkillThreshold reduces breakChance by SkillBreakReduction (min MinBreakChance)
MVR_RepairConfig.SkillBreakReduction = 0.02
MVR_RepairConfig.MinBreakChance      = 0.05
MVR_RepairConfig.SkillThreshold      = 2

MVR_RepairConfig.RandomEvents = {
    { id = "injury",        chance = 0.05 },
    { id = "burn",          chance = 0.03 },  -- only fires when config.requiresHeat = true
    { id = "toolBreak",     chance = 0.05 },
    { id = "extraMaterial", chance = 0.10 },
    { id = "critSuccess",   chance = 0.05 },
    { id = "stress",        chance = 0.10 },
}

-- Ordered alias list (most specific first). Avoids greedy matches like "Door" eating "EngineDoor"/"TrunkDoor".
-- Patterns are matched case-insensitively against vehiclePart:getId().
MVR_RepairConfig.PartAliases = {
    -- Specific compound names first (must come before generic prefixes they contain)
    { pattern = "EngineDoor",   config = "Hood"      },   -- vanilla b41/b42: hood IS EngineDoor
    { pattern = "TrunkDoor",    config = "TrunkLid"  },   -- vanilla b41/b42: trunk lid IS TrunkDoor
    { pattern = "Trunk",        config = "TrunkLid"  },
    { pattern = "Windshield",   config = "Window"    },
    { pattern = "FrontLight",   config = "Headlight" },
    { pattern = "RearLight",    config = "Headlight" },
    { pattern = "BackLight",    config = "Headlight" },
    { pattern = "TailLight",    config = "Headlight" },
    { pattern = "BrakeLight",   config = "Headlight" },
    { pattern = "Headlight",    config = "Headlight" },
    { pattern = "Lightbar",     config = "Headlight" },
    { pattern = "FuelTank",     config = "GasTank"   },
    { pattern = "GasTank",      config = "GasTank"   },
    -- Generic prefixes
    { pattern = "Engine",       config = "Engine"     },
    { pattern = "Brake",        config = "Brake"      },
    { pattern = "Suspension",   config = "Suspension" },
    { pattern = "Shock",        config = "Suspension" },
    { pattern = "Tire",         config = "Tire"       },
    { pattern = "Wheel",        config = "Tire"       },
    { pattern = "Door",         config = "Door"       },
    { pattern = "Window",       config = "Window"     },
    { pattern = "Hood",         config = "Hood"       },
    { pattern = "Muffler",      config = "Muffler"    },
    { pattern = "Exhaust",      config = "Muffler"    },
    { pattern = "Battery",      config = "Battery"    },
    { pattern = "Seat",         config = "Seat"       },
    { pattern = "Radio",        config = "Radio"      },
    -- Cosmetic / cheap parts (use Default)
    { pattern = "Bumper",       config = "Default"    },
    { pattern = "Mirror",       config = "Default"    },
    { pattern = "Wiper",        config = "Default"    },
    { pattern = "Antenna",      config = "Default"    },
    { pattern = "License",      config = "Default"    },
    { pattern = "Heater",       config = "Default"    },
    { pattern = "GloveBox",     config = "Default"    },
    { pattern = "Cargo",        config = "Default"    },
    { pattern = "Bed",          config = "Default"    },
    { pattern = "Roof",         config = "Default"    },
    { pattern = "Steering",     config = "Default"    },
    { pattern = "Visor",        config = "Default"    },
}

-- Diagnostic: tracks part IDs that fell through to Default. Logged once per ID to avoid spam.
MVR_RepairConfig._loggedUnknownParts = {}

-- Returns config for a given VehiclePart by matching getId() against ordered aliases.
-- Falls back to Default if no alias matches.
function MVR_RepairConfig.getConfigForPart(vehiclePart)
    if not vehiclePart then return MVR_RepairConfig.Parts.Default end
    local partId = vehiclePart:getId()
    if not partId then return MVR_RepairConfig.Parts.Default end
    local lowerId = string.lower(partId)
    for _, alias in ipairs(MVR_RepairConfig.PartAliases) do
        if string.find(lowerId, string.lower(alias.pattern), 1, true) then
            return MVR_RepairConfig.Parts[alias.config] or MVR_RepairConfig.Parts.Default
        end
    end
    -- Log once per unmatched partId so we know what to add
    if not MVR_RepairConfig._loggedUnknownParts[partId] then
        MVR_RepairConfig._loggedUnknownParts[partId] = true
        print("[MVR_RepairConfig] Unmatched partId='" .. partId .. "' — using Default. Add to PartAliases if you want a custom config.")
    end
    return MVR_RepairConfig.Parts.Default
end
