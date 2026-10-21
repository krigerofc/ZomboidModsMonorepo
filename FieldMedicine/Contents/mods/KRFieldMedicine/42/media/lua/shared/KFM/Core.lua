-- Field Medicine '93 - pure logic (no game API). Every formula, table and clamp lives here so it can be
-- unit-tested in fengari (tests/core_spec.lua). Game glue: KFM/Game.lua. Lua 5.1 subset (Kahlua).
local Core = {}

Core.VERSION = "1.1.0"

-- ---------------------------------------------------------------- sandbox
Core.DEFAULTS = {
    Enabled = true,
    ExamEnabled = true,
    ShowFeverInExam = true,
    SkillRequirementOffset = 0,
    FailChanceMultiplier = 1.0,
    ProcedurePainMultiplier = 1.0,
    IrrigationStrength = 1.0,
    TourniquetSafeHours = 2,
    FractureReductionMax = 0.40,
    XPMultiplier = 1.0,
}
Core.RANGES = {
    SkillRequirementOffset = { -3, 3 },
    FailChanceMultiplier = { 0, 3 },
    ProcedurePainMultiplier = { 0, 2 },
    IrrigationStrength = { 0, 2 },
    TourniquetSafeHours = { 1, 8 },
    FractureReductionMax = { 0, 0.6 },
    XPMultiplier = { 0, 5 },
}

function Core.clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

-- Merges SandboxVars.KFM (may be nil or partial) over the defaults, coercing types and clamping ranges.
function Core.config(sv)
    local cfg = {}
    for k, def in pairs(Core.DEFAULTS) do
        local v = sv and sv[k]
        if type(def) == "boolean" then
            if type(v) ~= "boolean" then v = def end
        else
            v = tonumber(v)
            if v == nil or v ~= v then v = def end
            local r = Core.RANGES[k]
            if r then v = Core.clamp(v, r[1], r[2]) end
            if k == "SkillRequirementOffset" or k == "TourniquetSafeHours" then v = math.floor(v + 0.5) end
        end
        cfg[k] = v
    end
    return cfg
end

-- ---------------------------------------------------------------- procedures (PRD 6.3)
-- minLevel: First Aid (Doctor) level; helper: requirement reduction when a helper is present;
-- baseFail/perLevel/floor: failure chance = max(floor, baseFail - perLevel * level) (0 when baseFail = 0);
-- pain/painPerLevel: added pain = max(pain / 2, pain - painPerLevel * level); xp: First Aid XP on a real treatment;
-- time: base duration in ticks (minus timePerLevel * level, never below minTime); infect: chance that the
-- procedure itself infects the wound (reduced by surgical gloves / mask).
Core.PROCEDURES = {
    exam            = { minLevel = 0, helper = 0, baseFail = 0,    perLevel = 0,     floor = 0,    pain = 0,  painPerLevel = 0, xp = 2,  time = 150, timePerLevel = 5, minTime = 80, infect = 0 },
    irrigate        = { minLevel = 0, helper = 0, baseFail = 0,    perLevel = 0,     floor = 0,    pain = 5,  painPerLevel = 0, xp = 3,  time = 120, timePerLevel = 3, minTime = 80, infect = 0 },
    tourniquet      = { minLevel = 1, helper = 1, baseFail = 0.05, perLevel = 0.005, floor = 0,    pain = 10, painPerLevel = 0.5, xp = 4, time = 90, timePerLevel = 3, minTime = 50, infect = 0 },
    tourniquetOff   = { minLevel = 0, helper = 0, baseFail = 0,    perLevel = 0,     floor = 0,    pain = 0,  painPerLevel = 0, xp = 0,  time = 40,  timePerLevel = 0, minTime = 40, infect = 0 },
    cauterize       = { minLevel = 3, helper = 1, baseFail = 0.20, perLevel = 0.02,  floor = 0.03, pain = 60, painPerLevel = 2, xp = 10, time = 180, timePerLevel = 4, minTime = 120, infect = 0.05 },
    reduceFracture  = { minLevel = 5, helper = 2, baseFail = 0.30, perLevel = 0.03,  floor = 0.05, pain = 80, painPerLevel = 0, xp = 15, time = 250, timePerLevel = 5, minTime = 180, infect = 0 },
    debride         = { minLevel = 6, helper = 1, baseFail = 0.25, perLevel = 0.03,  floor = 0.05, pain = 70, painPerLevel = 2, xp = 15, time = 220, timePerLevel = 4, minTime = 150, infect = 0.15 },
}
Core.PROCEDURE_IDS = { "exam", "irrigate", "tourniquet", "tourniquetOff", "cauterize", "reduceFracture", "debride" }
Core.MAX_FAIL = 0.95
Core.EXTRA_HEAT_TICKS = 60          -- heating the blade for cauterization
Core.BELT_EXTRA_FAIL = 0.05         -- a belt is a worse tourniquet than a windlass one
Core.GLOVES_INFECT_FACTOR = 0.7     -- surgical gloves: -30% procedure-caused infection
Core.MASK_INFECT_FACTOR = 0.9       -- surgical mask: -10%
Core.HEMOPHOBIC_PANIC = 50          -- same as vanilla ISStitch
Core.XP_COOLDOWN_HOURS = 1          -- per patient + procedure + body part
Core.EXAM_XP_COOLDOWN_HOURS = 6     -- per patient (PRD 6.1)

function Core.levelClamp(l)
    return Core.clamp(math.floor((tonumber(l) or 0) + 0.0001), 0, 10)
end

-- Effective level for gating / diagnosis: real level + bonus (stethoscope, profession soft hooks), 0..10.
function Core.effectiveLevel(doctorLevel, bonus)
    return Core.levelClamp((tonumber(doctorLevel) or 0) + (tonumber(bonus) or 0))
end

-- Minimum First Aid level. The sandbox offset only moves procedures that already need skill (>= 1), so the
-- exam, irrigation and tourniquet removal stay available to everyone.
function Core.requiredLevel(id, cfg, hasHelper)
    local p = Core.PROCEDURES[id]
    if not p then return 99 end
    local req = p.minLevel
    if req >= 1 then req = req + ((cfg and cfg.SkillRequirementOffset) or 0) end
    if hasHelper then req = req - p.helper end
    return Core.clamp(req, 0, 10)
end

function Core.canPerform(id, level, cfg, hasHelper)
    return Core.levelClamp(level) >= Core.requiredLevel(id, cfg, hasHelper)
end

function Core.failChance(id, level, cfg, extra)
    local p = Core.PROCEDURES[id]
    if not p or p.baseFail <= 0 then return 0 end
    local c = p.baseFail - p.perLevel * Core.levelClamp(level)
    if c < p.floor then c = p.floor end
    c = (c + (extra or 0)) * ((cfg and cfg.FailChanceMultiplier) or 1)
    return Core.clamp(c, 0, Core.MAX_FAIL)
end

-- rng(): float in [0, 1). Injected so tests are deterministic (game: ZombRandFloat(0, 1)).
function Core.roll(chance, rng)
    if chance <= 0 then return false end
    if chance >= 1 then return true end
    return rng() < chance
end

function Core.duration(id, level, extraTicks)
    local p = Core.PROCEDURES[id]
    if not p then return 100 end
    local t = p.time - p.timePerLevel * Core.levelClamp(level)
    if t < p.minTime then t = p.minTime end
    return t + (extraTicks or 0)
end

-- Pain added by a procedure. painkillers: patient is under the effect of pills (halves it).
function Core.procedurePain(id, level, cfg, painkillers)
    local p = Core.PROCEDURES[id]
    if not p or p.pain <= 0 then return 0 end
    local v = p.pain - p.painPerLevel * Core.levelClamp(level)
    if v < p.pain / 2 then v = p.pain / 2 end
    if painkillers then v = v * 0.5 end
    return v * ((cfg and cfg.ProcedurePainMultiplier) or 1)
end

function Core.infectionChance(id, gloves, mask)
    local p = Core.PROCEDURES[id]
    if not p then return 0 end
    local c = p.infect
    if gloves then c = c * Core.GLOVES_INFECT_FACTOR end
    if mask then c = c * Core.MASK_INFECT_FACTOR end
    return c
end

function Core.xpAmount(id, cfg)
    local p = Core.PROCEDURES[id]
    if not p then return 0 end
    return p.xp * ((cfg and cfg.XPMultiplier) or 1)
end

-- Anti-farm: lastHours = world hour of the last XP grant for that key (nil = never).
function Core.canGainXp(lastHours, nowHours, cooldownHours)
    if lastHours == nil then return true end
    return (nowHours - lastHours) >= cooldownHours
end

-- ---------------------------------------------------------------- F2 irrigation
Core.IRRIGATION_WATER = 0.25        -- litres per irrigation
Core.IRRIGATION_MAX_REDUCTION = 4
Core.DIRTY_WATER_INFECTION = 2      -- tainted water makes things worse
Core.INFECTION_MAX = 10             -- vanilla cheat uses 10 for "infected"

function Core.irrigationReduction(level, cfg)
    local r = 1.5 + 0.25 * Core.levelClamp(level)
    if r > Core.IRRIGATION_MAX_REDUCTION then r = Core.IRRIGATION_MAX_REDUCTION end
    return r * ((cfg and cfg.IrrigationStrength) or 1)
end

-- Returns new wound infection level and whether the wound must be flagged infected (dirty water).
function Core.irrigate(current, level, cfg, dirty)
    current = tonumber(current) or 0
    if current < 0 then current = 0 end
    if dirty then
        return Core.clamp(current + Core.DIRTY_WATER_INFECTION, 0, Core.INFECTION_MAX), true
    end
    local v = current - Core.irrigationReduction(level, cfg)
    if v < 0 then v = 0 end
    return v, false
end

-- Wound flags -> can this part be irrigated? (open wound, not bandaged, not stitched)
function Core.canIrrigate(w)
    if w.bandaged or w.stitched then return false end
    return (w.scratched or w.cut or w.deepWounded or w.bitten) and true or false
end

-- ---------------------------------------------------------------- F3 tourniquet
-- Body part (BodyPartType.ToString name) -> parts whose bleeding it controls (itself + distal).
Core.TOURNIQUET_PARTS = {
    UpperArm_L = { "UpperArm_L", "ForeArm_L", "Hand_L" },
    ForeArm_L  = { "ForeArm_L", "Hand_L" },
    UpperArm_R = { "UpperArm_R", "ForeArm_R", "Hand_R" },
    ForeArm_R  = { "ForeArm_R", "Hand_R" },
    UpperLeg_L = { "UpperLeg_L", "LowerLeg_L", "Foot_L" },
    LowerLeg_L = { "LowerLeg_L", "Foot_L" },
    UpperLeg_R = { "UpperLeg_R", "LowerLeg_R", "Foot_R" },
    LowerLeg_R = { "LowerLeg_R", "Foot_R" },
}
Core.LIMB = {
    UpperArm_L = "ArmL", ForeArm_L = "ArmL", Hand_L = "ArmL",
    UpperArm_R = "ArmR", ForeArm_R = "ArmR", Hand_R = "ArmR",
    UpperLeg_L = "LegL", LowerLeg_L = "LegL", Foot_L = "LegL",
    UpperLeg_R = "LegR", LowerLeg_R = "LegR", Foot_R = "LegR",
}
Core.TOURNIQUET_DAMAGE_FACTOR = 3        -- permanent-damage risk after safeHours * 3 (default 6 h)
Core.TOURNIQUET_HEALTH_LOSS = 1          -- per 10 game minutes past the safe window
Core.TOURNIQUET_PAIN_GAIN = 2            -- per 10 game minutes past the safe window
Core.TOURNIQUET_DAMAGE_FRACTURE = 30     -- fractureTime set once when the damage threshold is crossed

function Core.canTourniquet(partName)
    return Core.TOURNIQUET_PARTS[partName] ~= nil
end

-- tq: { [partName] = state } -> the part holding a tourniquet on the same limb, if any.
function Core.tourniquetOnLimb(tq, partName)
    local limb = Core.LIMB[partName]
    if not limb or not tq then return nil end
    for p, _ in pairs(tq) do
        if Core.LIMB[p] == limb then return p end
    end
    return nil
end

-- Is `partName` covered (bleeding controlled) by a tourniquet in tq?
function Core.coveredBy(tq, partName)
    if not tq then return nil end
    for p, _ in pairs(tq) do
        for _, d in ipairs(Core.TOURNIQUET_PARTS[p] or {}) do
            if d == partName then return p end
        end
    end
    return nil
end

function Core.tourniquetStage(elapsedHours, cfg)
    local safe = (cfg and cfg.TourniquetSafeHours) or 2
    if elapsedHours < safe then return "safe" end
    if elapsedHours < safe * Core.TOURNIQUET_DAMAGE_FACTOR then return "ischemia" end
    return "damage"
end

-- ---------------------------------------------------------------- F6 cauterization
function Core.canCauterize(w)
    return w.deepWounded and not w.bitten and not w.stitched and not w.bandaged and true or false
end

function Core.cauterizeBurnTime(rng)
    return 15 + rng() * 10
end

-- ---------------------------------------------------------------- F7 fracture reduction
function Core.fractureFactor(level, cfg)
    local maxRed = (cfg and cfg.FractureReductionMax) or 0.40
    local f = 0.75 - 0.02 * Core.levelClamp(level)
    if f < 1 - maxRed then f = 1 - maxRed end
    if f > 1 then f = 1 end
    return f
end

function Core.reduceFracture(fractureTime, level, cfg, failed)
    fractureTime = tonumber(fractureTime) or 0
    if fractureTime <= 0 then return 0 end
    if failed then return fractureTime * 1.10 end
    return fractureTime * Core.fractureFactor(level, cfg)
end

-- ---------------------------------------------------------------- F8 debridement
Core.DEBRIDE_MIN_INFECTION = 4

function Core.canDebride(w)
    return w.infectedWound and (w.infectionLevel or 0) >= Core.DEBRIDE_MIN_INFECTION and not w.bandaged and true or false
end

function Core.debrideResult(infectionLevel, failed)
    if failed then return (tonumber(infectionLevel) or 0) * 0.5, true end
    return 0, false
end

function Core.debrideBleedTime(rng)
    return 5 + rng() * 5
end

-- ---------------------------------------------------------------- F1 exam report
-- Input `v` (vitals) fields, all optional: health (0-100 overall), temperature (C), thirst, hunger (0-1),
-- weight (kg), panic (0-100), endurance (0-1), hasCold, bleedingParts (count),
-- fractures = { {part=, time=} }, woundInfections = { {part=, level=, visible=} }, visibleSevere (bool).
-- The vitals collector never reads zombie infection; and this function has no input for it at all, so a
-- fever is reported the same whatever its cause (PRD 5 anti-goal).
-- Output: list of { key = translation key, args = {...} } (args may hold body part names).
Core.FEVER_TEMP = 37.5
Core.HIGH_FEVER_TEMP = 38.5
Core.HYPOTHERMIA_TEMP = 35.5

local function line(out, key, a1, a2)
    out[#out + 1] = { key = key, args = { a1, a2 } }
end

function Core.generalState(health)
    if health >= 80 then return "Good" end
    if health >= 50 then return "Stable" end
    if health >= 25 then return "Serious" end
    return "Critical"
end

function Core.fractureBand(time, fine)
    if fine then
        if time >= 45 then return "VeryLong" end
        if time >= 30 then return "Long" end
        if time >= 15 then return "Medium" end
        if time >= 5 then return "Short" end
        return "AlmostHealed"
    end
    if time >= 30 then return "Long" end
    if time >= 10 then return "Medium" end
    return "Short"
end

function Core.buildExamReport(v, level, cfg, opts)
    v = v or {}
    opts = opts or {}
    level = Core.levelClamp(level)
    local out = {}
    line(out, "IGUI_KFM_Exam_General_" .. Core.generalState(tonumber(v.health) or 100))

    -- temperature (level 1+)
    if level >= 1 and (not cfg or cfg.ShowFeverInExam ~= false) and v.temperature then
        local t = v.temperature
        if t >= Core.HIGH_FEVER_TEMP then line(out, "IGUI_KFM_Exam_HighFever")
        elseif t >= Core.FEVER_TEMP then line(out, "IGUI_KFM_Exam_Fever")
        elseif t <= Core.HYPOTHERMIA_TEMP then line(out, "IGUI_KFM_Exam_Cold")
        else line(out, "IGUI_KFM_Exam_TempNormal") end
    end

    -- pulse / breathing (level 2+)
    if level >= 2 then
        if (tonumber(v.health) or 100) < 40 then line(out, "IGUI_KFM_Exam_PulseWeak")
        elseif (tonumber(v.panic) or 0) > 50 then line(out, "IGUI_KFM_Exam_PulseFast")
        else line(out, "IGUI_KFM_Exam_PulseCalm") end
        if (tonumber(v.endurance) or 1) < 0.3 then line(out, "IGUI_KFM_Exam_BreathFast")
        else line(out, "IGUI_KFM_Exam_BreathNormal") end
    end

    -- hydration / nutrition (level 2+, or any level with a tongue depressor)
    if level >= 2 or opts.tongue then
        local th = tonumber(v.thirst) or 0
        if th > 0.7 then line(out, "IGUI_KFM_Exam_DehydratedSevere")
        elseif th > 0.4 then line(out, "IGUI_KFM_Exam_Dehydrated")
        else line(out, "IGUI_KFM_Exam_Hydrated") end
        local w = tonumber(v.weight)
        if w and w < 65 then line(out, "IGUI_KFM_Exam_Malnourished")
        elseif (w and w < 75) or (tonumber(v.hunger) or 0) > 0.6 then line(out, "IGUI_KFM_Exam_Underfed") end
    end
    if opts.tongue then
        if v.hasCold then line(out, "IGUI_KFM_Exam_ThroatSore") else line(out, "IGUI_KFM_Exam_ThroatOk") end
    end

    -- fractures (level 3 band, level 6 finer band)
    if level >= 3 and v.fractures then
        for _, f in ipairs(v.fractures) do
            if (f.time or 0) > 0 then
                line(out, "IGUI_KFM_Exam_Fracture_" .. Core.fractureBand(f.time, level >= 6), f.part)
            end
        end
    end

    -- wound infection that vanilla does not show yet (level 4+)
    if level >= 4 and v.woundInfections then
        for _, wi in ipairs(v.woundInfections) do
            if (wi.level or 0) >= 1 and not wi.visible then
                line(out, "IGUI_KFM_Exam_WoundInflamed", wi.part)
            end
        end
    end

    -- weakness not explained by visible wounds (level 5+); wording lists several common causes
    if level >= 5 and (tonumber(v.health) or 100) < 60 and (v.bleedingParts or 0) == 0 and not v.visibleSevere then
        line(out, "IGUI_KFM_Exam_UnexplainedWeakness")
    end

    if level < 3 then line(out, "IGUI_KFM_Exam_MoreSkill") end
    return out
end

-- ---------------------------------------------------------------- soft hooks for other mods (KRjobs)
-- KFM.registerProfessionBonus(id, { effectiveLevel = 1..3, procedures = { "exam", ... } or nil = all,
--   noHeatPenalty = bool }). id is matched (lowercase, exact) against the doctor's profession id and trait
-- ids. Bonus only affects gating and diagnosis (effective level), never failure chance or effect strength.
Core.MAX_PROFESSION_BONUS = 3
Core.bonuses = {}

function Core.registerProfessionBonus(id, spec)
    if type(id) ~= "string" or id == "" or type(spec) ~= "table" then return false end
    local lvl = Core.clamp(math.floor(tonumber(spec.effectiveLevel) or 0), 0, Core.MAX_PROFESSION_BONUS)
    local procs = nil
    if type(spec.procedures) == "table" then
        procs = {}
        for _, p in ipairs(spec.procedures) do
            if Core.PROCEDURES[p] then procs[p] = true end
        end
    end
    Core.bonuses[string.lower(id)] = { effectiveLevel = lvl, procedures = procs, noHeatPenalty = spec.noHeatPenalty == true }
    return true
end

-- ids: list of strings (profession + traits). Returns bonus level (max over matches) and noHeatPenalty.
function Core.bonusFor(ids, procId)
    local best, noHeat = 0, false
    for _, id in ipairs(ids or {}) do
        local b = Core.bonuses[string.lower(tostring(id))]
        if b and (b.procedures == nil or b.procedures[procId]) then
            if b.effectiveLevel > best then best = b.effectiveLevel end
            if b.noHeatPenalty then noHeat = true end
        end
    end
    return best, noHeat
end

-- [PROPOSAL] ids KRjobs is expected to use; harmless if the professions never exist.
Core.registerProfessionBonus("krjobs:surgeon", { effectiveLevel = 2, procedures = { "exam", "cauterize", "reduceFracture", "debride" } })
Core.registerProfessionBonus("krjobs:paramedic", { effectiveLevel = 1, procedures = { "exam", "irrigate", "tourniquet" } })
Core.registerProfessionBonus("krjobs:militarymedic", { effectiveLevel = 1, procedures = { "tourniquet", "cauterize", "irrigate" }, noHeatPenalty = true })
Core.registerProfessionBonus("krjobs:nurse", { effectiveLevel = 1, procedures = { "exam", "irrigate" } })

-- ---------------------------------------------------------------- sync flags
-- Kahlua has no bitwise operators. All procedures sync the whole body part with the same mask vanilla uses
-- in server/ClientCommands.lua (health cheats): no guessing of individual BD_* bits (fractureTime has no
-- known flag). combineFlags is kept for future fine-grained masks: it sums only distinct bits.
Core.SYNC_ALL = 17592186044415 -- = 0xFFFFFFFFFFF (written in decimal: some Lua VMs wrap large hex literals)
Core.SYNC_STAT_PANIC = 0x00000100

local function bitsOf(n)
    local bits, i = {}, 0
    n = math.floor(n)
    while n > 0 do
        local r = n % 2
        if r == 1 then bits[#bits + 1] = i end
        n = (n - r) / 2
        i = i + 1
    end
    return bits
end

function Core.combineFlags(list)
    local seen, total = {}, 0
    for _, f in ipairs(list) do
        for _, b in ipairs(bitsOf(f)) do
            if not seen[b] then
                seen[b] = true
                total = total + 2 ^ b
            end
        end
    end
    return total
end

return Core
