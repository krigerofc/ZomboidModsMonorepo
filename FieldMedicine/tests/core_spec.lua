-- Pure-logic spec for KFM/Core.lua (fengari). Returns the number of failures.
local Core = require "KFM/Core"

local failures = 0
local function check(cond, msg)
    if not cond then failures = failures + 1; print("  FAIL [core]: " .. msg) end
end
local function near(a, b, eps) return math.abs(a - b) <= (eps or 1e-9) end
local function seq(values) local i = 0; return function() i = i + 1; return values[(i - 1) % #values + 1] end end

local cfg = Core.config(nil)

-- ---------- sandbox config: defaults, coercion, clamps
for k, v in pairs(Core.DEFAULTS) do check(cfg[k] == v, "default " .. k) end
local c2 = Core.config({ SkillRequirementOffset = 9, FailChanceMultiplier = -1, TourniquetSafeHours = 0, FractureReductionMax = 5,
    XPMultiplier = "2", Enabled = "yes", IrrigationStrength = 0 / 0, ProcedurePainMultiplier = 1.6 })
check(c2.SkillRequirementOffset == 3, "offset clamped to 3")
check(c2.FailChanceMultiplier == 0, "fail mult clamped to 0")
check(c2.TourniquetSafeHours == 1, "safe hours clamped to 1")
check(near(c2.FractureReductionMax, 0.6), "fracture max clamped to 0.6")
check(c2.XPMultiplier == 2, "numeric string coerced")
check(c2.Enabled == true, "non-boolean bool falls back to default")
check(c2.IrrigationStrength == 1.0, "NaN falls back to default")
check(near(c2.ProcedurePainMultiplier, 1.6), "in-range double kept")
check(Core.config({ SkillRequirementOffset = -2.6 }).SkillRequirementOffset == -3, "offset rounded")

-- ---------- gating table (PRD 6.3)
local expectReq = { exam = 0, irrigate = 0, tourniquet = 1, tourniquetOff = 0, cauterize = 3, reduceFracture = 5, debride = 6 }
local expectHelper = { tourniquet = 0, cauterize = 2, reduceFracture = 3, debride = 5 }
for id, req in pairs(expectReq) do
    check(Core.requiredLevel(id, cfg, false) == req, "required level " .. id)
    if expectHelper[id] then check(Core.requiredLevel(id, cfg, true) == expectHelper[id], "helper level " .. id) end
end
check(Core.requiredLevel("exam", Core.config({ SkillRequirementOffset = 3 }), false) == 0, "offset never gates exam")
check(Core.requiredLevel("irrigate", Core.config({ SkillRequirementOffset = 3 }), false) == 0, "offset never gates irrigation")
check(Core.requiredLevel("debride", Core.config({ SkillRequirementOffset = 3 }), false) == 9, "offset +3 debride")
check(Core.requiredLevel("tourniquet", Core.config({ SkillRequirementOffset = -3 }), true) == 0, "requirement floor 0")
check(Core.requiredLevel("nope", cfg, false) == 99, "unknown procedure is never allowed")
check(Core.canPerform("reduceFracture", 5, cfg, false) and not Core.canPerform("reduceFracture", 4, cfg, false), "canPerform threshold")
for _, id in ipairs(Core.PROCEDURE_IDS) do check(Core.PROCEDURES[id] ~= nil, "procedure listed " .. id) end

-- ---------- failure chance by Doctor level, floors, multiplier, max
local function fc(id, l, c, e) return Core.failChance(id, l, c or cfg, e) end
check(fc("exam", 0) == 0 and fc("irrigate", 0) == 0 and fc("tourniquetOff", 0) == 0, "no-fail procedures")
check(near(fc("tourniquet", 1), 0.045), "tourniquet L1 4.5%")
check(near(fc("tourniquet", 10), 0), "tourniquet L10 0%")
check(near(fc("cauterize", 3), 0.14), "cauterize L3 14%")
check(near(fc("cauterize", 10), 0.03), "cauterize floor 3%")
check(near(fc("reduceFracture", 5), 0.15), "reduce L5 15%")
check(near(fc("reduceFracture", 10), 0.05), "reduce floor 5%")
check(near(fc("debride", 6), 0.07), "debride L6 7%")
check(near(fc("debride", 10), 0.05), "debride floor 5%")
check(near(fc("tourniquet", 1, cfg, Core.BELT_EXTRA_FAIL), 0.095), "belt extra fail")
check(fc("cauterize", 3, Core.config({ FailChanceMultiplier = 0 })) == 0, "multiplier 0 -> never fails")
check(fc("reduceFracture", 0, Core.config({ FailChanceMultiplier = 3 }), 0.1) == Core.MAX_FAIL, "fail capped at 95%")
local prev = 2
for l = 0, 10 do
    local f = fc("debride", l)
    check(f <= prev + 1e-12, "fail chance never increases with level (" .. l .. ")")
    check(f >= 0 and f <= 1, "fail chance in [0,1]")
    prev = f
end
check(Core.levelClamp(14) == 10 and Core.levelClamp(-2) == 0 and Core.levelClamp(3.7) == 3, "level clamp")
check(Core.effectiveLevel(9, 3) == 10 and Core.effectiveLevel(2, 1) == 3, "effective level clamp")

-- ---------- roll with injected rng
check(Core.roll(0.5, function() return 0.49 end) == true, "roll hit")
check(Core.roll(0.5, function() return 0.5 end) == false, "roll miss")
check(Core.roll(0, function() return 0 end) == false, "chance 0 never")
check(Core.roll(1, function() return 0.99 end) == true, "chance 1 always")

-- ---------- durations
check(Core.duration("exam", 0) == 150 and Core.duration("exam", 10) == 100, "exam duration")
check(Core.duration("exam", 10) >= 80, "exam min 80")
check(Core.duration("cauterize", 0, Core.EXTRA_HEAT_TICKS) == 240, "cauterize + heat")
for _, id in ipairs(Core.PROCEDURE_IDS) do
    for l = 0, 10 do check(Core.duration(id, l) >= Core.PROCEDURES[id].minTime, "min time " .. id) end
end

-- ---------- pain
check(Core.procedurePain("cauterize", 0, cfg) == 60, "cauterize pain L0")
check(Core.procedurePain("cauterize", 10, cfg) == 40, "cauterize pain L10")
check(Core.procedurePain("reduceFracture", 7, cfg, true) == 40, "painkillers halve")
check(Core.procedurePain("debride", 10, Core.config({ ProcedurePainMultiplier = 0 })) == 0, "pain multiplier 0")
check(Core.procedurePain("exam", 5, cfg) == 0, "exam painless")
for _, id in ipairs(Core.PROCEDURE_IDS) do
    for l = 0, 10 do check(Core.procedurePain(id, l, cfg) >= Core.PROCEDURES[id].pain / 2, "pain floor " .. id) end
end

-- ---------- infection caused by procedures (gloves/mask)
check(near(Core.infectionChance("debride", false, false), 0.15), "debride infect base")
check(near(Core.infectionChance("debride", true, false), 0.105), "gloves -30%")
check(near(Core.infectionChance("debride", true, true), 0.0945), "gloves + mask")
check(Core.infectionChance("irrigate", false, false) == 0, "irrigation itself does not infect")

-- ---------- XP
check(Core.xpAmount("exam", cfg) == 2, "exam xp 2 (PRD)")
check(Core.xpAmount("debride", Core.config({ XPMultiplier = 2 })) == 30, "xp multiplier")
check(Core.xpAmount("tourniquetOff", cfg) == 0, "no xp for removal")
check(Core.canGainXp(nil, 10, 6), "first xp ok")
check(not Core.canGainXp(5, 10, 6), "cooldown blocks")
check(Core.canGainXp(4, 10, 6), "cooldown elapsed")

-- ---------- irrigation (never negative, cap, dirty water)
check(near(Core.irrigationReduction(0, cfg), 1.5), "irrigation L0 1.5")
check(near(Core.irrigationReduction(4, cfg), 2.5), "irrigation L4 2.5")
check(near(Core.irrigationReduction(10, cfg), 4), "irrigation capped at 4")
check(near(Core.irrigationReduction(10, Core.config({ IrrigationStrength = 2 })), 8), "strength multiplier")
for l = 0, 10 do
    for _, cur in ipairs({ -1, 0, 0.3, 1, 2.5, 7, 10 }) do
        local v, inf = Core.irrigate(cur, l, cfg, false)
        check(v >= 0, "irrigation never negative")
        check(v <= math.max(0, cur), "irrigation never increases with clean water")
        check(inf == false, "clean water does not infect")
    end
end
local dv, dinf = Core.irrigate(9.5, 10, cfg, true)
check(dv == Core.INFECTION_MAX and dinf == true, "dirty water raises infection, capped")
check(Core.canIrrigate({ cut = true }) and Core.canIrrigate({ bitten = true }), "open wounds irrigable")
check(not Core.canIrrigate({ cut = true, bandaged = true }) and not Core.canIrrigate({ deepWounded = true, stitched = true }), "bandaged/stitched not irrigable")
check(not Core.canIrrigate({}), "no wound -> no irrigation")

-- ---------- tourniquet
for part, list in pairs(Core.TOURNIQUET_PARTS) do
    check(list[1] == part, "tourniquet covers its own part " .. part)
    for _, d in ipairs(list) do check(Core.LIMB[d] == Core.LIMB[part], "distal part on same limb " .. d) end
end
check(not Core.canTourniquet("Torso_Upper") and not Core.canTourniquet("Neck") and not Core.canTourniquet("Hand_L"), "no tourniquet on torso/neck/hand")
local tq = { UpperArm_L = {} }
check(Core.tourniquetOnLimb(tq, "ForeArm_L") == "UpperArm_L", "one per limb")
check(Core.tourniquetOnLimb(tq, "ForeArm_R") == nil, "other limb free")
check(Core.coveredBy(tq, "Hand_L") == "UpperArm_L" and Core.coveredBy(tq, "Hand_R") == nil, "coverage")
check(Core.coveredBy({ ForeArm_L = {} }, "UpperArm_L") == nil, "proximal part not covered")
check(Core.tourniquetStage(1.9, cfg) == "safe" and Core.tourniquetStage(2, cfg) == "ischemia" and Core.tourniquetStage(6, cfg) == "damage", "stages default")
check(Core.tourniquetStage(7, Core.config({ TourniquetSafeHours = 4 })) == "ischemia", "stages sandbox")

-- ---------- cauterization
check(Core.canCauterize({ deepWounded = true }), "deep wound cauterizable")
check(not Core.canCauterize({ deepWounded = true, bitten = true }), "never on bites")
check(not Core.canCauterize({ cut = true }), "only deep wounds")
for _, r in ipairs({ 0, 0.5, 0.999 }) do
    local b = Core.cauterizeBurnTime(function() return r end)
    check(b >= 15 and b <= 25, "burn time 15-25")
end

-- ---------- fracture reduction (cap, once, fail)
check(near(Core.fractureFactor(5, cfg), 0.65), "L5 factor 0.65")
check(near(Core.fractureFactor(10, cfg), 0.60), "L10 capped at -40%")
check(near(Core.fractureFactor(10, Core.config({ FractureReductionMax = 0 })), 1), "max 0 -> no reduction")
for l = 0, 10 do
    local f = Core.fractureFactor(l, cfg)
    check(f >= 1 - cfg.FractureReductionMax - 1e-9 and f <= 1, "factor within cap L" .. l)
end
check(near(Core.reduceFracture(20, 5, cfg, false), 13), "reduce 20 -> 13")
check(near(Core.reduceFracture(20, 5, cfg, true), 22), "failed reduce +10%")
check(Core.reduceFracture(0, 10, cfg, false) == 0, "no fracture stays 0")

-- ---------- debridement
check(Core.canDebride({ infectedWound = true, infectionLevel = 4 }), "debride threshold")
check(not Core.canDebride({ infectedWound = true, infectionLevel = 3 }), "below threshold")
check(not Core.canDebride({ infectedWound = false, infectionLevel = 9 }), "needs infected wound")
local lv, still = Core.debrideResult(8, false)
check(lv == 0 and still == false, "debride clears")
lv, still = Core.debrideResult(8, true)
check(lv == 4 and still == true, "failed debride halves")
local bt = Core.debrideBleedTime(function() return 0.999 end)
check(bt >= 5 and bt <= 10, "debride bleed 5-10")

-- ---------- exam report
local function keys(report) local t = {}; for _, l in ipairs(report) do t[#t + 1] = l.key end; return table.concat(t, ",") end
local function has(report, key) for _, l in ipairs(report) do if l.key == key then return l end end; return nil end
local vitals = { health = 45, temperature = 38.9, thirst = 0.5, hunger = 0.2, weight = 80, panic = 70, endurance = 0.2,
    hasCold = true, bleedingParts = 0, visibleSevere = false,
    fractures = { { part = "LowerLeg_L", time = 25 } },
    woundInfections = { { part = "Hand_R", level = 2, visible = false }, { part = "Hand_L", level = 6, visible = true } } }
local r0 = Core.buildExamReport(vitals, 0, cfg)
check(has(r0, "IGUI_KFM_Exam_General_Serious") and not has(r0, "IGUI_KFM_Exam_HighFever"), "L0 only general state")
check(has(r0, "IGUI_KFM_Exam_MoreSkill"), "low level hint")
local r1 = Core.buildExamReport(vitals, 1, cfg)
check(has(r1, "IGUI_KFM_Exam_HighFever"), "L1 fever")
check(not has(Core.buildExamReport(vitals, 1, Core.config({ ShowFeverInExam = false })), "IGUI_KFM_Exam_HighFever"), "fever hidden by sandbox")
check(not has(r1, "IGUI_KFM_Exam_Dehydrated"), "L1 no hydration")
check(has(Core.buildExamReport(vitals, 0, cfg, { tongue = true }), "IGUI_KFM_Exam_Dehydrated"), "tongue depressor: hydration at L0")
check(has(Core.buildExamReport(vitals, 0, cfg, { tongue = true }), "IGUI_KFM_Exam_ThroatSore"), "tongue depressor: throat")
local r2 = Core.buildExamReport(vitals, 2, cfg)
check(has(r2, "IGUI_KFM_Exam_PulseFast") and has(r2, "IGUI_KFM_Exam_BreathFast") and has(r2, "IGUI_KFM_Exam_Dehydrated"), "L2 pulse/breath/hydration")
check(not has(r2, "IGUI_KFM_Exam_Fracture_Medium"), "L2 no fracture")
local r3 = Core.buildExamReport(vitals, 3, cfg)
local fl = has(r3, "IGUI_KFM_Exam_Fracture_Medium")
check(fl and fl.args[1] == "LowerLeg_L", "L3 coarse fracture band with part")
check(has(Core.buildExamReport(vitals, 6, cfg), "IGUI_KFM_Exam_Fracture_Medium"), "L6 fine band")
check(Core.fractureBand(50, true) == "VeryLong" and Core.fractureBand(2, true) == "AlmostHealed" and Core.fractureBand(2, false) == "Short", "bands")
check(not has(r3, "IGUI_KFM_Exam_WoundInflamed"), "L3 no early infection")
local r4 = Core.buildExamReport(vitals, 4, cfg)
local wl = has(r4, "IGUI_KFM_Exam_WoundInflamed")
check(wl and wl.args[1] == "Hand_R", "L4 early wound infection (only the one vanilla does not show)")
local cnt = 0; for _, l in ipairs(r4) do if l.key == "IGUI_KFM_Exam_WoundInflamed" then cnt = cnt + 1 end end
check(cnt == 1, "visible infection not repeated")
check(not has(r4, "IGUI_KFM_Exam_UnexplainedWeakness"), "L4 no weakness line")
check(has(Core.buildExamReport(vitals, 5, cfg), "IGUI_KFM_Exam_UnexplainedWeakness"), "L5 weakness")
check(not has(Core.buildExamReport({ health = 45, bleedingParts = 1 }, 10, cfg), "IGUI_KFM_Exam_UnexplainedWeakness"), "bleeding explains weakness")
check(has(Core.buildExamReport({}, 10, cfg), "IGUI_KFM_Exam_General_Good"), "empty vitals safe")
check(has(Core.buildExamReport({ temperature = 35 }, 5, cfg), "IGUI_KFM_Exam_Cold"), "hypothermia")
check(has(Core.buildExamReport({ temperature = 37.0, health = 30 }, 2, cfg), "IGUI_KFM_Exam_PulseWeak"), "weak pulse")

-- Knox rule: whatever extra fields a caller passes, the report never mentions the zombie infection and is
-- identical with or without them (there is no input for it).
for l = 0, 10 do
    for _, t in ipairs({ 36.6, 37.8, 39.5 }) do
        local base = { health = 30 + l * 5, temperature = t, thirst = 0.1 * l, panic = 10 * l }
        local knox = { health = base.health, temperature = t, thirst = base.thirst, panic = base.panic,
            zombieInfected = true, infectionLevel = 0.9, isInfected = true, knox = true }
        local a = Core.buildExamReport(base, l, cfg, { tongue = (l % 2 == 0) })
        local b = Core.buildExamReport(knox, l, cfg, { tongue = (l % 2 == 0) })
        check(keys(a) == keys(b), "knox input ignored L" .. l)
        for _, line in ipairs(b) do
            check(not string.find(string.lower(line.key), "zomb") and not string.find(string.lower(line.key), "knox"), "no knox line " .. line.key)
        end
    end
end

-- ---------- profession soft hooks
check(Core.registerProfessionBonus("Test:Medic", { effectiveLevel = 9, procedures = { "exam", "bogus" } }), "register ok")
local b, nh = Core.bonusFor({ "test:medic" }, "exam")
check(b == Core.MAX_PROFESSION_BONUS and nh == false, "bonus clamped to max, case-insensitive")
check(Core.bonusFor({ "test:medic" }, "debride") == 0, "bonus only for listed procedures")
check(Core.bonusFor({ "krjobs:surgeon" }, "debride") == 2, "surgeon proposal +2 debride")
local _, heat = Core.bonusFor({ "krjobs:militarymedic" }, "cauterize")
check(heat == true, "military medic no heat penalty")
check(Core.bonusFor({ "base:nurse", "base:doctor" }, "exam") == 0, "vanilla professions get no bonus")
check(Core.bonusFor({ "krjobs:paramedic", "krjobs:surgeon" }, "exam") == 2, "max of matches")
check(not Core.registerProfessionBonus(nil, {}) and not Core.registerProfessionBonus("x", nil), "bad registration rejected")
check(Core.bonusFor(nil, "exam") == 0, "nil ids safe")

-- ---------- sync flags
check(Core.SYNC_ALL == 17592186044415, "full mask equals vanilla 0xFFFFFFFFFFF")
check(Core.combineFlags({ 0x400000, 0x80000 }) == 0x00480000, "additionalPain + haveGlass = ISRemoveGlass mask")
check(Core.combineFlags({ 0x00480000, 0x400000 }) == 0x00480000, "duplicate bits not added twice")
check(Core.combineFlags({ 0x00570188, 0x00608200 }) == 0x00570188 + 0x00608200 - 0x00400000, "stitch + disinfect share additionalPain once")
check(Core.combineFlags({}) == 0, "empty")

return failures
