-- Field Medicine '93 - game glue shared by client, server and timed actions. Every game API call that is not
-- verified in vanilla 42.19.2 Lua is wrapped in pcall. Zombie infection (Knox) is never read here.
local Core = require "KFM/Core"

KFM = KFM or {}
KFM.Core = Core
-- Public soft-dependency API for other mods (e.g. KRjobs professions):
--   if KFM and KFM.registerProfessionBonus then KFM.registerProfessionBonus("mymod:surgeon", {...}) end
KFM.registerProfessionBonus = Core.registerProfessionBonus

local Game = {}
KFM.Game = Game

Game.MODULE = "KFM"
Game.HELPER_RANGE = 3
Game.ITEM_TOURNIQUET = "Base.KFM_ImprovisedTourniquet"
Game.ITEM_BELT = "Base.Belt2"
Game.ITEM_STETHOSCOPE = "Base.Stethoscope"
Game.ITEM_TONGUE = "Base.TongueDepressor"
Game.ITEM_SCALPEL = "Base.Scalpel"
Game.ITEM_GLOVES = "Base.Gloves_Surgical"
Game.ITEM_MASK = "Base.Hat_SurgicalMask"

function Game.cfg()
    return Core.config(SandboxVars and SandboxVars.KFM)
end

function Game.nowHours()
    return getGameTime():getWorldAgeHours()
end

function Game.rng()
    local r = ZombRandFloat(0, 1)
    if r >= 1 then r = 0.999999 end
    return r
end

function Game.partName(bp)
    return BodyPartType.ToString(bp:getType())
end

function Game.partByName(chr, name)
    local parts = chr:getBodyDamage():getBodyParts()
    for i = 0, parts:size() - 1 do
        local p = parts:get(i)
        if BodyPartType.ToString(p:getType()) == name then return p end
    end
    return nil
end

function Game.isCheatDoctor(chr)
    if not isMultiplayer() then return false end
    local ok, v = pcall(function() return chr:getRole():hasCapability(Capability.CanMedicalCheat) end)
    return ok and v == true
end

function Game.doctorLevel(chr)
    if Game.isCheatDoctor(chr) then return 10 end
    return chr:getPerkLevel(Perks.Doctor)
end

-- Profession + trait ids of a character, as lowercase strings (soft: any failure -> empty list).
function Game.identityIds(chr)
    local ids = {}
    pcall(function()
        local prof = chr:getDescriptor():getCharacterProfession()
        if prof then ids[#ids + 1] = string.lower(tostring(prof)) end
    end)
    pcall(function()
        local known = chr:getCharacterTraits():getKnownTraits()
        for i = 0, known:size() - 1 do ids[#ids + 1] = string.lower(tostring(known:get(i))) end
    end)
    return ids
end

-- Effective level for gating/diagnosis (+ stethoscope etc. via extra). Returns level, noHeatPenalty.
function Game.effectiveLevel(chr, procId, extra)
    local bonus, noHeat = Core.bonusFor(Game.identityIds(chr), procId)
    local focus=(procId=="exam" and KFM.Health and KFM.Health.focusBonus(chr)) or 0
    return Core.effectiveLevel(Game.doctorLevel(chr), bonus + (extra or 0) + focus), noHeat
end

function Game.players()
    local list = {}
    if isClient() or isServer() then
        local online = getOnlinePlayers()
        if online then
            for i = 0, online:size() - 1 do list[#list + 1] = online:get(i) end
        end
    else
        for i = 0, getNumActivePlayers() - 1 do
            local p = getSpecificPlayer(i)
            if p then list[#list + 1] = p end
        end
    end
    return list
end

-- A helper is a third living character (not the doctor, not the patient) standing next to the patient.
function Game.hasHelper(doctor, patient)
    for _, p in ipairs(Game.players()) do
        if p ~= doctor and p ~= patient and not p:isDead() and p:getZ() == patient:getZ() then
            local dx, dy = p:getX() - patient:getX(), p:getY() - patient:getY()
            if dx * dx + dy * dy <= Game.HELPER_RANGE * Game.HELPER_RANGE then return true end
        end
    end
    return false
end

-- Same rule as vanilla ISHealthPanel.DidPatientMove (re-implemented here because ISHealthPanel is client-only).
function Game.patientMoved(doctor, patient, x, y)
    if doctor == patient then return patient:isDriving() end
    if patient:getX() == x and patient:getY() == y then return false end
    if doctor:isDriving() then return true end
    if patient:getVehicle() then return false end
    return true
end

function Game.wound(bp)
    return {
        scratched = bp:scratched(),
        cut = bp:isCut(),
        deepWounded = bp:isDeepWounded(),
        bitten = bp:bitten(),
        bandaged = bp:bandaged(),
        stitched = bp:stitched(),
        infectedWound = bp:isInfectedWound(),
        infectionLevel = bp:getWoundInfectionLevel(),
        bleeding = bp:getBleedingTime() > 0,
        fractureTime = bp:getFractureTime(),
    }
end

function Game.wearing(chr, location, fullType)
    local ok, item = pcall(function() return chr:getWornItem(location) end)
    return ok and item ~= nil and item:getFullType() == fullType
end

function Game.surgicalProtection(doctor)
    return Game.wearing(doctor, ItemBodyLocation.HANDS, Game.ITEM_GLOVES), Game.wearing(doctor, ItemBodyLocation.MASK, Game.ITEM_MASK)
end

function Game.painkillers(patient)
    local ok, v = pcall(function() return patient:getBodyDamage():getPainReductionFromMeds() end)
    return ok and (tonumber(v) or 0) > 0
end

function Game.isResting(patient)
    local ok, v = pcall(function()
        return patient:isSitOnGround() or patient:isSittingOnFurniture() or patient:getVehicle() ~= nil or patient:isAsleep()
    end)
    return ok and v == true
end

-- Persistent per-character state (lives on the patient for tourniquets/fracture flags, on the doctor for XP).
function Game.md(chr)
    local md = chr:getModData()
    md.KFM = md.KFM or {}
    md.KFM.tq = md.KFM.tq or {}
    md.KFM.reduced = md.KFM.reduced or {}
    md.KFM.xp = md.KFM.xp or {}
    return md.KFM
end

function Game.patientKey(patient)
    local ok, name = pcall(function() return patient:getUsername() end)
    if ok and name and name ~= "" then return name end
    return tostring(patient:getDisplayName())
end

-- Adds pain unless the doctor is a MP medical cheater (same rule as vanilla ISStitch).
function Game.addPain(doctor, bp, amount)
    if amount <= 0 or Game.isCheatDoctor(doctor) then return end
    bp:setAdditionalPain(bp:getAdditionalPain() + amount)
end

function Game.sync(bp)
    syncBodyPart(bp, Core.SYNC_ALL)
end

function Game.hemophobia(chr)
    local ok, has = pcall(function() return chr:hasTrait(CharacterTrait.HEMOPHOBIC) end)
    if ok and has then
        chr:getStats():add(CharacterStat.PANIC, Core.HEMOPHOBIC_PANIC)
        syncPlayerStats(chr, Core.SYNC_STAT_PANIC)
    end
end

-- XP with anti-farm cooldown keyed by patient + procedure (+ part). Returns amount granted.
function Game.grantXp(doctor, patient, procId, partName, cooldown)
    local cfg = Game.cfg()
    local amount = Core.xpAmount(procId, cfg)
    if amount <= 0 then return 0 end
    local md = Game.md(doctor)
    local key = Game.patientKey(patient) .. "|" .. procId .. "|" .. tostring(partName or "")
    local now = Game.nowHours()
    if not Core.canGainXp(md.xp[key], now, cooldown or Core.XP_COOLDOWN_HOURS) then return 0 end
    md.xp[key] = now
    addXp(doctor, Perks.Doctor, amount)
    return amount
end

-- ------------------------------------------------------------ items
function Game.removeItem(chr, item)
    chr:getInventory():Remove(item)
    if isServer() then sendRemoveItemFromContainer(chr:getInventory(), item) end
end

-- Keep the actual item in an engine-serialized inventory, never a Java object in ModData.
function Game.moveItem(from, to, item)
 if from == to then return end
 Game.removeItem(from, item)
 to:getInventory():AddItem(item)
 if isServer() then sendAddItemToContainer(to:getInventory(), item) end
end
function Game.boundItem(item)
 for _, patient in ipairs(Game.players()) do
  for _, st in pairs(Game.md(patient).tq) do
   if st.itemId == item:getID() then return true end
  end
 end
 return false
end
function Game.giveItem(chr, fullType)
    local item = instanceItem(fullType)
    if not item then return nil end
    chr:getInventory():AddItem(item)
    if isServer() then sendAddItemToContainer(chr:getInventory(), item) end
    return item
end

-- Water source for irrigation: returns "clean", "dirty" or nil.
function Game.waterKind(item)
    local ok, kind = pcall(function()
        local fc = item:getFluidContainer()
        if not fc or fc:isEmpty() or fc:getAmount() < Core.IRRIGATION_WATER then return nil end
        if fc:isPureFluid(Fluid.Water) then return "clean" end
        if fc:contains(Fluid.TaintedWater) then
            local pf = fc:getPrimaryFluid()
            if pf and (pf:getFluidTypeString() == "TaintedWater" or pf:getFluidTypeString() == "Water") then return "dirty" end
        end
        return nil
    end)
    if ok then return kind end
    return nil
end

function Game.useWater(item)
    local fc = item:getFluidContainer()
    fc:adjustAmount(fc:getAmount() - Core.IRRIGATION_WATER)
    sendItemStats(item)
end

function Game.isBlade(item)
    if item:getFullType() == Game.ITEM_SCALPEL then return true end
    local ok, v = pcall(function() return item:hasTag(ItemTag.SHARP_KNIFE) end)
    return ok and v == true
end

function Game.isFireSource(item)
    local ok, v = pcall(function()
        return (item:hasTag(ItemTag.START_FIRE) or item:getType() == "Lighter" or item:getType() == "Matches") and item:getCurrentUses() > 0
    end)
    return ok and v == true
end

-- ------------------------------------------------------------ tourniquet state (authoritative on server/SP)
-- md.tq[partName] = { t = worldHours applied, item = fullType, itemId = itemId, saved = { [part] = bleedingTime }, dmg = bool }
function Game.tqSnapshot(patient)
    local out = {}
    for part, st in pairs(Game.md(patient).tq) do out[part] = { t = st.t, item = st.item } end
    return out
end

-- Client-side mirror: in MP the client does not receive the server's player modData, so the server pushes
-- tourniquet state with sendServerCommand; the menu reads it from here.
Game.mirror = Game.mirror or {}

function Game.mirrorKey(patient)
    if isClient() then return tostring(patient:getOnlineID()) end
    return "local"
end

function Game.tqView(patient)
    if isClient() then return Game.mirror[Game.mirrorKey(patient)] or {} end
    return Game.md(patient).tq
end

function Game.pushTq(patient, doctor)
    if not isServer() then return end
    local args = { id = patient:getOnlineID(), tq = Game.tqSnapshot(patient) }
    sendServerCommand(patient, Game.MODULE, "tq", args)
    if doctor and doctor ~= patient then sendServerCommand(doctor, Game.MODULE, "tq", args) end
end

-- Bleeding of covered parts is paused: the remaining bleeding time is saved and restored on removal.
function Game.suppressBleeding(patient, part, st)
    local changed = false
    for _, name in ipairs(Core.TOURNIQUET_PARTS[part] or {}) do
        local bp = Game.partByName(patient, name)
        if bp and bp:getBleedingTime() > 0 then
            st.saved[name] = (st.saved[name] or 0) + bp:getBleedingTime()
            bp:setBleedingTime(0)
            bp:setBleeding(false)
            Game.sync(bp)
            changed = true
        end
    end
    return changed
end

function Game.applyTourniquet(patient, bp, fullType, itemId)
    local part = Game.partName(bp)
    local st = { t = Game.nowHours(), item = fullType, itemId = itemId, saved = {}, dmg = false }
    Game.md(patient).tq[part] = st
    Game.suppressBleeding(patient, part, st)
end

-- Removes the tourniquet on `part`; paused bleeding resumes on parts that were not treated meanwhile.
function Game.removeTourniquet(patient, part)
    local md = Game.md(patient)
    local st = md.tq[part]
    if not st then return nil end
    for name, t in pairs(st.saved or {}) do
        local bp = Game.partByName(patient, name)
        if bp and t > 0 and not bp:bandaged() and not bp:stitched() and (bp:isDeepWounded() or bp:isCut() or bp:scratched() or bp:bitten()) then
            bp:setBleedingTime(math.max(bp:getBleedingTime(), t))
            bp:setBleeding(true)
            Game.sync(bp)
        end
    end
    md.tq[part] = nil
    return st.item, st.itemId
end

-- ------------------------------------------------------------ exam vitals (never reads zombie infection)
local function stat(chr, s)
    local ok, v = pcall(function() return chr:getStats():get(s) end)
    if ok then return tonumber(v) end
    return nil
end

function Game.collectVitals(patient)
    local bd = patient:getBodyDamage()
    local v = { fractures = {}, woundInfections = {}, bleedingParts = 0, visibleSevere = false }
    v.health = bd:getOverallBodyHealth()
    v.temperature = stat(patient, CharacterStat.TEMPERATURE)
    v.thirst = stat(patient, CharacterStat.THIRST)
    v.hunger = stat(patient, CharacterStat.HUNGER)
    v.panic = stat(patient, CharacterStat.PANIC)
    v.endurance = stat(patient, CharacterStat.ENDURANCE)
    pcall(function() v.weight = patient:getNutrition():getWeight() end)
    pcall(function() v.hasCold = bd:isHasACold() end)
    local parts = bd:getBodyParts()
    for i = 0, parts:size() - 1 do
        local bp = parts:get(i)
        local name = Game.partName(bp)
        if bp:getBleedingTime() > 0 then v.bleedingParts = v.bleedingParts + 1 end
        if bp:isDeepWounded() or bp:getFractureTime() > 0 or bp:bitten() or bp:getBurnTime() > 0 then v.visibleSevere = true end
        if bp:getFractureTime() > 0 then v.fractures[#v.fractures + 1] = { part = name, time = bp:getFractureTime() } end
        if bp:getWoundInfectionLevel() > 0 then
            v.woundInfections[#v.woundInfections + 1] = { part = name, level = bp:getWoundInfectionLevel(), visible = bp:isInfectedWound() }
        end
    end
    return v
end

function Game.hasSomethingToDiagnose(v)
    return (v.health or 100) < 100 or #v.fractures > 0 or #v.woundInfections > 0 or v.bleedingParts > 0
        or (v.temperature or 37) >= Core.FEVER_TEMP or (v.thirst or 0) > 0.4
end

return Game
