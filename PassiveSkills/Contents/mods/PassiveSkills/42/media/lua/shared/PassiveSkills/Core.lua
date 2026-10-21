-- Passive Skills v2 - pure logic (no game API calls). Identical copy in B41 (media/) and B42 (42/media/).
-- Unit-tested in fengari by tests/run.js; the engine glue lives in PassiveSkills/Game.lua.
local Core = {}

Core.MODDATA_KEY = "PassiveSkills"
Core.ITEM_PREFIX = "Base.Magazine"
Core.DEFAULT_SPAWN_CHANCE = 12
Core.DEFAULT_XP_PERCENT = 100

-- ---------------------------------------------------------------------------
-- Container eligibility (OnFillContainer roomName / containerType).
-- Mapped from vanilla 42.19.2 Distributions.lua: room/container pairs whose loot
-- lists are books or magazines (bookshelves, magazine racks, desks, postboxes...).
-- ---------------------------------------------------------------------------
local ANY_ROOM = { postbox = true, shelvesmag = true, desk = true, schooldesk = true }
local SHELF_ROOMS = {
    livingroom = true, bookstore = true, library = true, universitylibrary = true,
    policelibrary = true, office = true, medicaloffice = true, medical = true, mayorwestpointoffice = true,
    furnitureworkshop = true, potteryworkshop = true, knappingworkshop = true, tailoringworkshop = true,
    toolstore = true, hunting = true, camping = true, rangerhall = true, pawnshop = true, cafe = true,
    joanstudio = true, electronicstore = true, comicstore = true,
}
local METAL_SHELF_ROOMS = {
    mechanic = true, garagestorage = true, toolstore = true, storageunit = true,
    schoolstorage = true, universitystorage = true,
}
local COUNTER_ROOMS = { bookstore = true, library = true, universitylibrary = true, comicstore = true }

function Core.isEligibleContainer(roomName, containerType)
    if type(containerType) ~= "string" then return false end
    if ANY_ROOM[containerType] then return true end
    local room = type(roomName) == "string" and roomName or ""
    if containerType == "shelves" then
        return SHELF_ROOMS[room] == true or string.sub(room, 1, 9) == "classroom"
    elseif containerType == "metal_shelves" then
        return METAL_SHELF_ROOMS[room] == true
    elseif containerType == "counter" then
        return COUNTER_ROOMS[room] == true
    end
    return false
end

-- ---------------------------------------------------------------------------
-- Sandbox settings (defensive: missing/invalid values fall back to defaults)
-- ---------------------------------------------------------------------------
local function clampNumber(v, lo, hi, default)
    v = tonumber(v)
    if v == nil then return default end
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

function Core.settings(sandboxVars)
    local s = type(sandboxVars) == "table" and sandboxVars.PassiveSkills or nil
    if type(s) ~= "table" then s = {} end
    return {
        spawnChance = clampNumber(s.SpawnChance, 0, 100, Core.DEFAULT_SPAWN_CHANCE),
        xpPercent = clampNumber(s.XpPercent, 0, 1000, Core.DEFAULT_XP_PERCENT),
    }
end

-- ---------------------------------------------------------------------------
-- Per-character read-once record: character modData.PassiveSkills.read[key] = true
-- key = "<skillId>_<tier>" (legacy items share the key of the skill they alias).
-- ---------------------------------------------------------------------------
local function record(modData, create)
    if type(modData) ~= "table" then return nil end
    local r = modData[Core.MODDATA_KEY]
    if type(r) ~= "table" then
        if not create then return nil end
        r = {}
        modData[Core.MODDATA_KEY] = r
    end
    if type(r.read) ~= "table" then
        if not create then return nil end
        r.read = {}
    end
    return r
end

function Core.hasRead(modData, key)
    local r = record(modData, false)
    return r ~= nil and r.read[key] == true
end

function Core.markRead(modData, key)
    if type(key) ~= "string" then return end
    local r = record(modData, true)
    if r then r.read[key] = true end
end

function Core.readKeys(modData)
    local out = {}
    local r = record(modData, false)
    if r then
        for k, v in pairs(r.read) do
            if v == true then out[#out + 1] = k end
        end
    end
    table.sort(out)
    return out
end

-- ---------------------------------------------------------------------------
-- Catalog instance (per build)
-- ---------------------------------------------------------------------------
local Instance = {}
Instance.__index = Instance

function Core.fullType(itemId, tier, catalog)
    return Core.ITEM_PREFIX .. itemId .. "_" .. catalog.TIERS[tier]
end

-- catalog: PassiveSkills/Catalog; build: 41 or 42; exists(perkName, fullType) -> bool (optional)
function Core.new(catalog, build, exists)
    local self = setmetatable({}, Instance)
    self.catalog = catalog
    self.build = build
    self.skills = {}
    self.byId = {}
    self.byFullType = {}
    self.count = 0
    local function allExist(perk, itemId)
        if not exists then return true end
        for t = 1, #catalog.TIERS do
            if not exists(perk, Core.fullType(itemId, t, catalog)) then return false end
        end
        return true
    end
    local function register(itemId, skill, legacy)
        for t = 1, #catalog.TIERS do
            self.byFullType[Core.fullType(itemId, t, catalog)] = {
                skill = skill.id, perk = skill.perk, tier = t, key = skill.id .. "_" .. t, legacy = legacy or false,
            }
            self.count = self.count + 1
        end
    end
    for _, s in ipairs(catalog.SKILLS) do
        if (build >= 42 or s.b41) and allExist(s.perk, s.id) then
            self.skills[#self.skills + 1] = s
            self.byId[s.id] = s
            register(s.id, s, false)
        end
    end
    for _, l in ipairs(catalog.LEGACY) do
        local target = self.byId[l.aliasOf]
        if target and (build >= 42 or l.b41) and allExist(target.perk, l.id) then
            register(l.id, target, true)
        end
    end
    local w = 0
    for i = 1, #catalog.TIERS do w = w + catalog.TIER_WEIGHTS[i] end
    self.totalWeight = w
    return self
end

function Instance:entryFor(fullType)
    return self.byFullType[fullType]
end

-- XP for one volume. 100% -> vanilla per-level XP (75/150/300/750/1500, sum 2775 = level 5).
function Instance:xpFor(tier, xpPercent)
    local base = self.catalog.TIER_XP[tier] or 0
    local pct = tonumber(xpPercent) or Core.DEFAULT_XP_PERCENT
    if pct <= 0 then return 0 end
    return math.floor(base * pct / 100 + 0.5)
end

-- Decide the outcome of finishing a read. Marks the volume as read for THIS character.
-- returns nil (not one of ours) | "learned", entry | "already", entry
function Instance:resolveRead(modData, fullType)
    local entry = self.byFullType[fullType]
    if not entry then return nil end
    if Core.hasRead(modData, entry.key) then return "already", entry end
    Core.markRead(modData, entry.key)
    return "learned", entry
end

-- rng(n) must return an integer in [0, n-1] (ZombRand semantics).
function Instance:pickMagazine(rng)
    local n = #self.skills
    if n == 0 then return nil end
    local skill = self.skills[rng(n) + 1]
    local r = rng(self.totalWeight)
    local acc = 0
    local tier = #self.catalog.TIERS
    for i = 1, #self.catalog.TIERS do
        acc = acc + self.catalog.TIER_WEIGHTS[i]
        if r < acc then tier = i; break end
    end
    return Core.fullType(skill.id, tier, self.catalog)
end

-- One roll per filled container: chancePct (0..100) of adding exactly one magazine.
function Instance:rollSpawn(roomName, containerType, chancePct, rng)
    chancePct = tonumber(chancePct) or 0
    if chancePct <= 0 or #self.skills == 0 then return nil end
    if not Core.isEligibleContainer(roomName, containerType) then return nil end
    if rng(10000) >= chancePct * 100 then return nil end
    return self:pickMagazine(rng)
end

return Core
