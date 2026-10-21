--[[
    Build & Haul - pure classification logic.

    NO engine calls in this file. It only receives plain Lua tables, so it can be
    unit-tested outside the game (see tests/run.js) and is shared verbatim by the
    B41 (root media/) and B42 (42/media/) builds.

    Input  (info table):
        module          string   e.g. "Base"
        name            string   e.g. "Plank"
        displayCategory string   e.g. "Material" (may be nil)
        tags            table    list of tag strings, any case, with or without "base:" prefix
        metalValue      number   MetalValue script property (0 / nil when absent)

    Output: material ("wood" | "metal" | "ore" | "construction" | nil), included, reason

    Exact vanilla inclusions precede conservative category/tag rules. Ores are a
    separate family; construction buckets are exact full-type opt-ins only.
    Explicit exclusion always wins over inclusion. Recipe use alone is not evidence.
]]

local Classifier = {}

Classifier.VERSION = "2.1.0"

Classifier.MATERIAL_CATEGORIES = {
    Material = true,
    MaterialWeapon = true,
}

-- exact (normalized, lowercase, prefix stripped) metal tags
Classifier.METAL_TAGS = {
    hasmetal = true, ironmaterial = true, steelmaterial = true,
    ingot = true, piercedingot = true, block = true, chunk = true,
    piercedblock = true, piercedchunk = true, metalpiece = true,
    wire = true, aluminum = true, sawblade = true,
}
-- metal tag prefixes / substrings
Classifier.METAL_TAG_PREFIXES = { "smeltable", "barstock" }
Classifier.METAL_TAG_SUBSTRINGS = { "scrap" }

Classifier.WOOD_TAGS = {
    log = true, plank = true, woodhandle = true, longstick = true, carvelongstick = true,
}
Classifier.WOOD_TAG_PREFIXES = { "makewoodcharcoal" }

-- Case-sensitive plain substrings searched in the item name
Classifier.METAL_NAME_PARTS = {
    "Iron", "Steel", "Copper", "Brass", "Gold", "Silver", "Alumin", "Metal",
    "Nail", "Screw", "Wire", "Hinge", "Bolt", "Pipe", "Ingot", "Scrap",
}
-- names starting with these are not metal even if a metal word appears (ClayPipe, CeramicIngotCast...)
Classifier.NON_METAL_NAME_PREFIXES = { "Clay", "Ceramic", "Glass", "Smoking", "Wooden" }

-- Lua patterns
Classifier.WOOD_NAME_PATTERNS = {
    "Plank", "^Log", "Branch", "Firewood", "Twig", "Sapling", "Lumber",
    "Board", "Beam", "Handle$", "Stick",
}

-- Conservative fallback exclusions; exact vanilla ore/construction opt-ins precede these.
Classifier.EXCLUDE_NAME_PATTERNS = {
    "Mold",            -- casting molds are tools (used mode:keep)
    "Anvil",           -- workstations
    "Crucible",        -- containers holding molten metal
    "^Bucket",         -- unknown buckets require explicit full-type inclusion
    "Charcoal", "^Coke", -- fuel, not wood
    "Door$", "Machine$", "Hammer$", "Tool$", -- finished products with misleading material metadata
}
Classifier.EXCLUDE_TAGS = {
    charcoal = true,
    concrete = true, plasterbucket = true, wallpaperpaste = true,
}

-- Explicit lists, keyed by full type (Module.Name) so they never hit other mods by accident.
Classifier.EXPLICIT_EXCLUDE = {
    ["Base.BenchAnvilUntreated"] = "finished workstation (anvil)",
    ["Base.BlacksmithAnvilUntreated"] = "finished workstation (anvil)",
    ["Base.BlockAnvilUntreated"] = "finished workstation (anvil)",
    ["Base.BlowerFan"] = "appliance part",
    ["Base.BucketWallpaperPaste"] = "paste in a bucket",
    ["Base.CeramicCrucible_Iron"] = "crucible (container)",
    ["Base.CeramicCrucible_Steel"] = "crucible (container)",
    ["Base.CeramicCrucibleSmall_Iron"] = "crucible (container)",
    ["Base.CeramicCrucibleSmall_Steel"] = "crucible (container)",
    ["Base.PackFrame"] = "bag component",
    ["Base.PackFrameLarge"] = "bag component",
    ["Base.Paperclip"] = "household item",
    ["Base.PaperclipBox"] = "household item",
    ["Base.HatchetHead_Bone"] = "bone, not metal",
    ["Base.Charcoal"] = "fuel",
    ["Base.CharcoalCrafted"] = "fuel",
    ["Base.Coke"] = "fuel",
    ["Base.PercedWood"] = "camping firestarter",
    ["Base.ElectronicsScrap"] = "electronics",
    ["Base.HeavyChain"] = "tool",
    ["Base.PropaneTank"] = "finished container (gas tank)",
    ["Base.PlankNail"] = "finished weapon (B41 plank with nails)",
}

Classifier.EXPLICIT_INCLUDE = {
    ["Base.CopperOre"] = "ore",
    ["Base.Hematite"] = "ore",
    ["Base.HematiteLarge"] = "ore",
    ["Base.IronOre"] = "ore",
    ["Base.Malachite"] = "ore",
    ["Base.MalachiteLarge"] = "ore",
    ["Base.BucketCarvedClayCement"] = "construction",
    ["Base.BucketCarvedConcreteFull"] = "construction",
    ["Base.BucketCarvedPlasterFull"] = "construction",
    ["Base.BucketClayCement"] = "construction",
    ["Base.BucketConcreteFull"] = "construction",
    ["Base.BucketPlasterFull"] = "construction",
    ["Base.Clay"] = "construction",
    ["Base.ClayBrick"] = "construction",
    ["Base.ClayBrickUnfired"] = "construction",
    ["Base.ClayShingle"] = "construction",
    ["Base.ClayShingleUnfired"] = "construction",
    ["Base.ClayTile"] = "construction",
    ["Base.ClayTileUnfired"] = "construction",
    ["Base.Claybag"] = "construction",
    ["Base.ConcretePowder"] = "construction",
    ["Base.FlintNodule"] = "construction",
    ["Base.Gravelbag"] = "construction",
    ["Base.Limestone"] = "construction",
    ["Base.PlasterPowder"] = "construction",
    ["Base.Sandbag"] = "construction",
    ["Base.Stone2"] = "construction",
    ["Base.StoneBlock"] = "construction",
    ["Base.UnusableMetal"] = "metal",
    ["Base.WeldingRods"] = "metal", -- script Item may not expose getMetalValue (B41/B42)
    ["Base.UnusableWood"] = "wood",
    ["Base.MetalPipe_Broken"] = "metal",
    ["Base.SpadeHead"] = "metal",
    ["Base.ElectricWire"] = "metal",
    ["Base.Doorknob"] = "metal",
    ["Base.Plank_Broken"] = "wood",
    ["Base.Branch_Broken"] = "wood",
    ["Base.LongHandle_Broken"] = "wood",
    ["Base.LongStick_Broken"] = "wood",
    ["Base.WoodenStick_Broken"] = "wood",
    ["Base.TwigsBundle"] = "wood",
    ["Base.Splinters"] = "wood",
    -- B41: these raw stocks use DisplayCategory Weapon / Material without B42 tags
    ["Base.MetalBar"] = "metal",
    ["Base.MetalPipe"] = "metal",
    ["Base.LeadPipe"] = "metal",
    ["Base.TreeBranch"] = "wood",
    ["Base.WoodenStick"] = "wood",
}

--- Normalize one tag: lowercase and strip a "namespace:" prefix ("base:HasMetal" -> "hasmetal").
function Classifier.normalizeTag(tag)
    if tag == nil then return nil end
    local s = string.lower(tostring(tag))
    s = string.gsub(s, "^%s+", "")
    s = string.gsub(s, "%s+$", "")
    local colon = string.find(s, ":", 1, true)
    if colon then s = string.sub(s, colon + 1) end
    if s == "" then return nil end
    return s
end

local function startsWith(s, prefix)
    return string.sub(s, 1, string.len(prefix)) == prefix
end

local function tagSet(tags)
    local set = {}
    if type(tags) ~= "table" then return set end
    for i = 1, #tags do
        local t = Classifier.normalizeTag(tags[i])
        if t then set[t] = true end
    end
    return set
end

local function isMetalTag(t)
    if Classifier.METAL_TAGS[t] then return true end
    for i = 1, #Classifier.METAL_TAG_PREFIXES do
        if startsWith(t, Classifier.METAL_TAG_PREFIXES[i]) then return true end
    end
    for i = 1, #Classifier.METAL_TAG_SUBSTRINGS do
        if string.find(t, Classifier.METAL_TAG_SUBSTRINGS[i], 1, true) then return true end
    end
    return false
end

local function isWoodTag(t)
    if Classifier.WOOD_TAGS[t] then return true end
    for i = 1, #Classifier.WOOD_TAG_PREFIXES do
        if startsWith(t, Classifier.WOOD_TAG_PREFIXES[i]) then return true end
    end
    return false
end

local function metalNameMatch(name)
    for i = 1, #Classifier.NON_METAL_NAME_PREFIXES do
        if startsWith(name, Classifier.NON_METAL_NAME_PREFIXES[i]) then return false end
    end
    for i = 1, #Classifier.METAL_NAME_PARTS do
        if string.find(name, Classifier.METAL_NAME_PARTS[i], 1, true) then return true end
    end
    return false
end

local function woodNameMatch(name)
    for i = 1, #Classifier.WOOD_NAME_PATTERNS do
        if string.find(name, Classifier.WOOD_NAME_PATTERNS[i]) then return true end
    end
    return false
end

--- Classify one item description.
-- @return material ("wood"|"metal"|"ore"|"construction"|nil), included (boolean), reason (string)
function Classifier.classify(info)
    if type(info) ~= "table" or type(info.name) ~= "string" then
        return nil, false, "invalid input"
    end
    local module = info.module or "Base"
    local name = info.name
    local fullType = module .. "." .. name

    local why = Classifier.EXPLICIT_EXCLUDE[fullType]
    if why then return nil, false, "explicit exclude: " .. why end

    local forced = Classifier.EXPLICIT_INCLUDE[fullType]
    if forced then return forced, true, "explicit include" end

    local tags = tagSet(info.tags)
    for i = 1, #Classifier.EXCLUDE_NAME_PATTERNS do
        if string.find(name, Classifier.EXCLUDE_NAME_PATTERNS[i]) then
            return nil, false, "excluded name pattern " .. Classifier.EXCLUDE_NAME_PATTERNS[i]
        end
    end

    for t, _ in pairs(tags) do
        if Classifier.EXCLUDE_TAGS[t] then return nil, false, "excluded tag " .. t end
    end

    if not Classifier.MATERIAL_CATEGORIES[info.displayCategory or ""] then
        return nil, false, "not a material DisplayCategory"
    end

    if Classifier.MATERIAL_CATEGORIES[info.displayCategory or ""] then
        if tags.ironore or tags.copperore or tags.orematerial then
            return "ore", true, "rule: ore material tag"
        end
        if tags.constructionmaterial then
            return "construction", true, "rule: construction material tag"
        end
    end

    if string.find(name, "%lOre$") or string.find(name, "%lOre[%u_]") then
        return nil, false, "unknown ore-like name without an ore material tag"
    end

    local metalTag, woodTag = nil, nil
    for t, _ in pairs(tags) do
        if not metalTag and isMetalTag(t) then metalTag = t end
        if not woodTag and isWoodTag(t) then woodTag = t end
    end
    local mv = tonumber(info.metalValue) or 0

    if metalTag then return "metal", true, "rule: tag " .. metalTag end
    if mv > 0 then return "metal", true, "rule: MetalValue" end
    if metalNameMatch(name) then return "metal", true, "rule: metal name" end
    if woodTag then return "wood", true, "rule: tag " .. woodTag end
    if woodNameMatch(name) then return "wood", true, "rule: wood name" end
    return nil, false, "not an eligible material"
end

--- Reduced weight for a given original weight and reduction percent (0..99).
-- Rounded to 4 decimals; never negative.
function Classifier.computeWeight(original, percent)
    local w = tonumber(original) or 0
    local p = tonumber(percent) or 0
    if p < 0 then p = 0 end
    if p > 99 then p = 99 end
    local r = w * (100 - p) / 100
    if r < 0 then r = 0 end
    return math.floor(r * 10000 + 0.5) / 10000
end

return Classifier
