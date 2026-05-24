-- ZombieDisguise — Shared configuration
-- Accessible by client, server, and shared modules.

ZD_Config = {
    DEBUG              = false,
    MODULE             = "ZombieDisguise",

    -- Timed action duration (game time units).
    -- 420 ≈ 7 in-game minutes at 1× speed. [VERIFICAR: calibrate in-game — V3]
    APPLY_TIME         = 420,

    -- Contamination phase thresholds in elapsed in-game MINUTES (EveryOneMinute ticks).
    -- Safe window is implicit: elapsed < MILD_MINUTES → no effects.
    MILD_MINUTES       = 180,   -- 3 h: mild nausea + unhappiness begins
    MODERATE_MINUTES   = 240,   -- 4 h: nausea + stress
    SEVERE_MINUTES     = 300,   -- 5 h: nausea + stress + panic
    CRITICAL_MINUTES   = 360,   -- 6 h+: full illness (sick, fatigue, all effects peak)

    -- Wetness level on a BodyPart that triggers "washed" removal.
    -- [VERIFICAR: confirm getWetness() scale is 0.0–1.0 in B42 — V5]
    WETNESS_THRESHOLD  = 0.5,

    -- Stat intensities per phase (0.0 – 1.0).
    MILD_NAUSEA        = 0.20,
    MILD_UNHAPPY       = 0.25,

    MODERATE_NAUSEA    = 0.45,
    MODERATE_STRESS    = 0.35,

    SEVERE_NAUSEA      = 0.70,
    SEVERE_STRESS      = 0.55,
    SEVERE_PANIC       = 0.40,

    CRITICAL_NAUSEA    = 1.00,
    CRITICAL_STRESS    = 0.80,
    CRITICAL_PANIC     = 0.70,
    CRITICAL_UNHAPPY   = 0.75,
    CRITICAL_FATIGUE   = 0.60,

    -- Body parts to cover with blood (head/neck/face excluded by design).
    -- Names match BodyPartType B42 enum (confirmed). BloodBodyPartType may differ — [VERIFICAR V1].
    DISGUISE_PARTS = {
        "Torso_Upper", "Torso_Lower",
        "UpperArm_L",  "UpperArm_R",
        "ForeArm_L",   "ForeArm_R",
        "Hand_L",      "Hand_R",
        "UpperLeg_L",  "UpperLeg_R",
        "LowerLeg_L",  "LowerLeg_R",
        "Foot_L",      "Foot_R",
        "Groin",
    },
}

function ZD_log(msg)
    if ZD_Config.DEBUG then
        print("[ZombieDisguise] " .. tostring(msg))
    end
end
