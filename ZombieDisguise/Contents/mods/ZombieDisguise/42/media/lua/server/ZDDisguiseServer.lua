-- ZombieDisguise — Server authority
-- Manages disguise state, zombie detection bypass, and contamination effects.
-- Server is the sole writer of ZD_* ModData keys; clients only send commands.

ZD_Server = ZD_Server or {}

-- ─── Player Iteration ─────────────────────────────────────────────────────────

-- Abstracts SP (getSpecificPlayer) vs dedicated MP (getOnlinePlayers Java list).
-- [VERIFICAR]: confirm getOnlinePlayers() interface in B42.
local function iteratePlayers(callback)
    if getOnlinePlayers then
        local list = getOnlinePlayers()
        if list and list.size then
            for i = 0, list:size() - 1 do
                local p = list:get(i)
                if p then callback(p) end
            end
            return
        end
    end
    -- SP / coop fallback: up to 4 split-screen players.
    for i = 0, 3 do
        local p = getSpecificPlayer(i)
        if p then callback(p) end
    end
end

-- ─── Stat Helper ──────────────────────────────────────────────────────────────

-- Guard against Stats API changes in B42 (method may be renamed or moved to CharacterStat enum).
-- [VERIFICAR V2]: test setNausea/setStress/setPanic/setUnhappyness/setFatigue in B42.
local function setStatSafe(stats, method, value)
    if stats and stats[method] then
        stats[method](stats, value)
    else
        ZD_log("Stats:" .. method .. " unavailable — [VERIFICAR V2]")
    end
end

-- ─── Disguise Revocation ──────────────────────────────────────────────────────

function ZD_Server.revokeDisguise(player)
    if not player then return end

    -- Re-enable zombie detection for this player.
    -- [VERIFICAR]: confirm setZombiesDontAttack exists on IsoPlayer in B42.
    if player.setZombiesDontAttack then
        player:setZombiesDontAttack(false)
    else
        ZD_log("setZombiesDontAttack not available on player — [VERIFICAR]")
    end

    local modData = player:getModData()
    modData.ZD_active         = false
    modData.ZD_parts          = nil
    modData.ZD_elapsedMinutes = nil

    -- Notify the owning client so it can update its local ZD_active flag.
    -- Include playerIndex so split-screen clients update the correct local player slot.
    sendServerCommand(player, ZD_Config.MODULE, "disguiseRevoked",
        { playerIndex = player:getPlayerNum() })

    ZD_log("Disguise revoked: " .. tostring(player:getUsername()))
end

-- ─── Phase Effects ────────────────────────────────────────────────────────────

-- Applies contamination effects based on how many in-game minutes have elapsed.
local function applyPhaseEffects(player, elapsed)
    local cfg   = ZD_Config
    local stats = player:getStats()
    if not stats then return end

    if elapsed >= cfg.CRITICAL_MINUTES then
        -- 6 h+: full bacterial illness — debilitating.
        setStatSafe(stats, "setNausea",      cfg.CRITICAL_NAUSEA)
        setStatSafe(stats, "setStress",      cfg.CRITICAL_STRESS)
        setStatSafe(stats, "setPanic",       cfg.CRITICAL_PANIC)
        setStatSafe(stats, "setUnhappyness", cfg.CRITICAL_UNHAPPY)
        setStatSafe(stats, "setFatigue",     cfg.CRITICAL_FATIGUE)

    elseif elapsed >= cfg.SEVERE_MINUTES then
        -- 5–6 h: nausea + stress + panic.
        setStatSafe(stats, "setNausea", cfg.SEVERE_NAUSEA)
        setStatSafe(stats, "setStress", cfg.SEVERE_STRESS)
        setStatSafe(stats, "setPanic",  cfg.SEVERE_PANIC)

    elseif elapsed >= cfg.MODERATE_MINUTES then
        -- 4–5 h: nausea + stress.
        setStatSafe(stats, "setNausea", cfg.MODERATE_NAUSEA)
        setStatSafe(stats, "setStress", cfg.MODERATE_STRESS)

    elseif elapsed >= cfg.MILD_MINUTES then
        -- 3–4 h: nausea (light) + unhappiness.
        setStatSafe(stats, "setNausea",      cfg.MILD_NAUSEA)
        setStatSafe(stats, "setUnhappyness", cfg.MILD_UNHAPPY)
    end
    -- Below MILD_MINUTES (< 3 h): safe window, no effects applied.
end

-- ─── Command Handler ──────────────────────────────────────────────────────────

local function onClientCommand(module, command, player, args)
    if module ~= ZD_Config.MODULE then return end
    if not player then return end

    local modData = player:getModData()

    if command == "startDisguise" then
        -- Guard: server validates; do not double-apply or grant to a dead player.
        if modData.ZD_active then
            ZD_log("startDisguise ignored — already active: " .. tostring(player:getUsername()))
            return
        end
        if player:isDead() then
            ZD_log("startDisguise ignored — player is dead: " .. tostring(player:getUsername()))
            return
        end

        -- Build parts tracking table.
        local parts = {}
        for _, partName in ipairs(ZD_Config.DISGUISE_PARTS) do
            parts[partName] = true
        end

        modData.ZD_active         = true
        modData.ZD_parts          = parts
        modData.ZD_elapsedMinutes = 0

        -- Make zombies ignore this player.
        if player.setZombiesDontAttack then
            player:setZombiesDontAttack(true)
        else
            ZD_log("setZombiesDontAttack not available — [VERIFICAR]")
        end

        -- Notify the owning client so it can update its local ZD_active flag.
        -- Include playerIndex so split-screen clients update the correct local player slot.
        sendServerCommand(player, ZD_Config.MODULE, "disguiseGranted",
            { playerIndex = player:getPlayerNum() })

        ZD_log("Disguise granted: " .. tostring(player:getUsername()))

    elseif command == "removeDisguise" then
        -- Explicit removal fallback (e.g. future client-triggered clean-up).
        ZD_Server.revokeDisguise(player)
    end
end

-- ─── Periodic Tick (EveryOneMinute) ──────────────────────────────────────────

local function onEveryMinute()
    iteratePlayers(function(player)
        local modData = player:getModData()
        if not modData.ZD_active then return end

        -- Increment in-game minute counter (1 EveryOneMinute tick = 1 in-game minute).
        modData.ZD_elapsedMinutes = (modData.ZD_elapsedMinutes or 0) + 1

        -- Re-apply zombie blindness every tick; handles reconnects without extra event.
        if player.setZombiesDontAttack then
            player:setZombiesDontAttack(true)
        end

        -- Apply contamination phase effects.
        applyPhaseEffects(player, modData.ZD_elapsedMinutes)

        -- ── Wash detection (server-side) ──────────────────────────────────────
        -- Check each disguised body part for wetness. This covers showers, sinks,
        -- and rain without requiring a client round-trip. Server has full player access.
        local parts = modData.ZD_parts
        if not parts then
            -- ZD_active=true but ZD_parts=nil: inconsistent state (e.g. after a partial crash).
            -- Revoke rather than loop forever with escalating health effects.
            ZD_log("ZD_active but ZD_parts is nil — revoking (inconsistent state): " .. tostring(player:getUsername()))
            ZD_Server.revokeDisguise(player)
            return
        end

        local bodyDamage = player:getBodyDamage()
        if not bodyDamage then return end

        local allWashed = true
        for partName, active in pairs(parts) do
            if active then
                -- Guard the BodyPartType global itself, matching the client-side pattern.
                local bpt = BodyPartType and BodyPartType[partName]
                if not bpt then
                    -- Enum lookup failed: treat as still-covered so it never triggers premature
                    -- full-revocation if all names fail (e.g. B42 enum rename).
                    allWashed = false
                    ZD_log("BodyPartType." .. partName .. " not found — keeping in tracking")
                else
                    local bodyPart = bodyDamage:getBodyPart(bpt)
                    if bodyPart and bodyPart:getWetness() >= ZD_Config.WETNESS_THRESHOLD then
                        parts[partName] = nil
                        ZD_log("Washed part: " .. partName .. " (" .. tostring(player:getUsername()) .. ")")
                    else
                        -- Part still has disguise blood and is not wet enough.
                        allWashed = false
                    end
                end
            end
        end

        -- If every disguised part has been washed, revoke.
        if allWashed then
            ZD_Server.revokeDisguise(player)
        end
    end)
end

-- ─── Death Handler ────────────────────────────────────────────────────────────

local function onPlayerDeath(player)
    if not player then return end
    local modData = player:getModData()
    if modData.ZD_active then
        ZD_Server.revokeDisguise(player)
    end
end

-- ─── Event Registration ───────────────────────────────────────────────────────

Events.OnClientCommand.Add(onClientCommand)
Events.EveryOneMinute.Add(onEveryMinute)
Events.OnPlayerDeath.Add(onPlayerDeath)
