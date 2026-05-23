MVR_RepairConfig = {}

-- Debug flag: set to true while developing to log unmatched parts / context-menu hits.
-- Leave false for production to keep console.txt clean.
MVR_RepairConfig.DEBUG = false

-- conditionGain ADDS to current part condition (clamped at conditionCap).
-- The option is hidden when current condition is already >= conditionCap.
-- Recipes follow real-world repair logic mapped to B42 items.
-- Materials lean "cheap/common" (ScrapMetal, DuctTape, RippedSheets, Screws) for
-- entry-level parts; specialized materials (LeatherStrips, ElectricWire, Glue)
-- appear where the IRL repair would actually demand them. Quantities are tuned so
-- repairs feel like a meaningful investment — not trivial — without locking
-- survivors out behind rare loot.
-- Heavy parts (engine, muffler, gas tank) need solda → requiresHeat=true also
-- gates the "burn" cosmetic event.
-- Headlight is non-repairable by design: a blown bulb gets replaced, not patched.
MVR_RepairConfig.Parts = {
    -- Motor: solda + sucata + chapa pra remendos + parafusos + fita
    Engine = {
        materials   = { ["Base.ScrapMetal"] = 4, ["Base.SheetMetal"] = 2, ["Base.Screws"] = 4, ["Base.DuctTape"] = 2 },
        tools       = { "Base.Screwdriver", "Base.PipeWrench" },
        conditionGain = 18,
        conditionCap  = 60,
        breakChance   = 0.20,
        repairTime    = 450,
        requiresHeat  = true,
    },
    -- Freios: pastilha improvisada (sucata + tecido) + fita pra mangueira
    Brake = {
        materials   = { ["Base.ScrapMetal"] = 3, ["Base.RippedSheets"] = 2, ["Base.DuctTape"] = 1 },
        tools       = { "Base.Screwdriver", "Base.PipeWrench" },
        conditionGain = 15,
        conditionCap  = 60,
        breakChance   = 0.20,
        repairTime    = 250,
        requiresHeat  = false,
    },
    -- Suspensão: sucata + arame reforço + parafusos + fita
    Suspension = {
        materials   = { ["Base.ScrapMetal"] = 3, ["Base.Wire"] = 2, ["Base.Screws"] = 4, ["Base.DuctTape"] = 1 },
        tools       = { "Base.Screwdriver", "Base.PipeWrench" },
        conditionGain = 15,
        conditionCap  = 60,
        breakChance   = 0.20,
        repairTime    = 280,
        requiresHeat  = false,
    },
    -- Pneu: kit de remendo caseiro = fita + cola (borracha + cola IRL)
    Tire = {
        materials   = { ["Base.DuctTape"] = 2, ["Base.Glue"] = 1 },
        tools       = {},
        conditionGain = 12,
        conditionCap  = 50,
        breakChance   = 0.15,
        repairTime    = 200,
        requiresHeat  = false,
    },
    -- Lataria — porta: 2 chapas + parafusos + fita pra vedar
    Door = {
        materials   = { ["Base.SheetMetal"] = 2, ["Base.Screws"] = 4, ["Base.DuctTape"] = 1 },
        tools       = { "Base.Screwdriver" },
        conditionGain = 15,
        conditionCap  = 65,
        breakChance   = 0.10,
        repairTime    = 200,
        requiresHeat  = false,
    },
    -- Vidro: vidro não conserta, é gambiarra de tapar com lençol + fita
    Window = {
        materials   = { ["Base.DuctTape"] = 2, ["Base.RippedSheets"] = 3 },
        tools       = {},
        conditionGain = 10,
        conditionCap  = 40,
        breakChance   = 0.30,
        repairTime    = 150,
        requiresHeat  = false,
    },
    -- Lataria — capô: igual a porta
    Hood = {
        materials   = { ["Base.SheetMetal"] = 2, ["Base.Screws"] = 4, ["Base.DuctTape"] = 1 },
        tools       = { "Base.Screwdriver" },
        conditionGain = 15,
        conditionCap  = 60,
        breakChance   = 0.15,
        repairTime    = 200,
        requiresHeat  = false,
    },
    -- Lataria — porta-malas: igual a porta
    TrunkLid = {
        materials   = { ["Base.SheetMetal"] = 2, ["Base.Screws"] = 4, ["Base.DuctTape"] = 1 },
        tools       = { "Base.Screwdriver" },
        conditionGain = 15,
        conditionCap  = 60,
        breakChance   = 0.15,
        repairTime    = 190,
        requiresHeat  = false,
    },
    -- Escapamento: chapa pra remendo + arame de abraçadeira + solda
    Muffler = {
        materials   = { ["Base.SheetMetal"] = 2, ["Base.ScrapMetal"] = 2, ["Base.Wire"] = 2, ["Base.DuctTape"] = 1 },
        tools       = { "Base.PipeWrench" },
        conditionGain = 15,
        conditionCap  = 55,
        breakChance   = 0.20,
        repairTime    = 240,
        requiresHeat  = true,
    },
    -- Tanque: chapa + cola/selante + fita + solda — buracos de combustível são sérios
    GasTank = {
        materials   = { ["Base.SheetMetal"] = 3, ["Base.ScrapMetal"] = 2, ["Base.Glue"] = 2, ["Base.DuctTape"] = 2 },
        tools       = { "Base.Screwdriver", "Base.PipeWrench" },
        conditionGain = 12,
        conditionCap  = 50,
        breakChance   = 0.25,
        repairTime    = 320,
        requiresHeat  = true,
    },
    -- Bateria: componentes eletrônicos + fio elétrico (ElectricWire, não Wire) + fita
    Battery = {
        materials   = { ["Base.ElectronicsScrap"] = 3, ["Base.ElectricWire"] = 2, ["Base.DuctTape"] = 1 },
        tools       = { "Base.Screwdriver" },
        conditionGain = 12,
        conditionCap  = 45,
        breakChance   = 0.30,
        repairTime    = 220,
        requiresHeat  = false,
    },
    -- Banco: estofado caseiro real — couro + linha + agulha (tool) + fita
    Seat = {
        materials   = { ["Base.LeatherStrips"] = 3, ["Base.Thread"] = 1, ["Base.DuctTape"] = 1 },
        tools       = { "Base.Needle" },
        conditionGain = 15,
        conditionCap  = 70,
        breakChance   = 0.10,
        repairTime    = 180,
        requiresHeat  = false,
    },
    -- Rádio: componentes + fio elétrico + parafusos + fita; solda gambiarra
    Radio = {
        materials   = { ["Base.ElectronicsScrap"] = 2, ["Base.ElectricWire"] = 2, ["Base.Screws"] = 2, ["Base.DuctTape"] = 1 },
        tools       = { "Base.Screwdriver" },
        conditionGain = 12,
        conditionCap  = 45,
        breakChance   = 0.35,
        repairTime    = 220,
        requiresHeat  = false,
    },
    -- Farol/lâmpada: NÃO É REPARÁVEL — uma lâmpada estourada se substitui, não conserta.
    -- O menu honra notRepairable e não mostra opção pra qualquer alias que aponte aqui.
    Headlight = {
        notRepairable = true,
    },
    -- Fallback: peças cosméticas (bumper, mirror, antenna, etc.) — reparo trivial caseiro
    Default = {
        materials   = { ["Base.ScrapMetal"] = 2, ["Base.DuctTape"] = 1 },
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
-- Returns nil when the matched config has notRepairable=true (e.g. Headlight) —
-- callers MUST early-return on nil to keep "non-repairable" parts out of the menu.
-- Falls back to Default if no alias matches.
function MVR_RepairConfig.getConfigForPart(vehiclePart)
    if not vehiclePart then return MVR_RepairConfig.Parts.Default end
    local partId = vehiclePart:getId()
    if not partId then return MVR_RepairConfig.Parts.Default end
    local lowerId = string.lower(partId)
    for _, alias in ipairs(MVR_RepairConfig.PartAliases) do
        if string.find(lowerId, string.lower(alias.pattern), 1, true) then
            local matched = MVR_RepairConfig.Parts[alias.config]
            if matched and matched.notRepairable then return nil end
            return matched or MVR_RepairConfig.Parts.Default
        end
    end
    -- Log once per unmatched partId so we know what to add (debug only)
    if MVR_RepairConfig.DEBUG and not MVR_RepairConfig._loggedUnknownParts[partId] then
        MVR_RepairConfig._loggedUnknownParts[partId] = true
        print("[MVR_RepairConfig] Unmatched partId='" .. partId .. "' — using Default. Add to PartAliases if you want a custom config.")
    end
    return MVR_RepairConfig.Parts.Default
end
