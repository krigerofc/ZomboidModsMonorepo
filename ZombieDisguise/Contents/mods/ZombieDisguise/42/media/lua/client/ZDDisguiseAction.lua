-- ZombieDisguise — Timed action + blood visuals (client-side)
-- Player spends ~7 in-game minutes applying zombie blood to themselves.
-- After completion, applies blood visuals and notifies the server to grant the disguise.
-- Wash detection is handled server-side (ZDDisguiseServer.lua).

require "TimedActions/ISBaseTimedAction"

ZDDisguiseAction = ISBaseTimedAction:derive("ZDDisguiseAction")

ZD_Action = ZD_Action or {}

-- ─── Timed Action ────────────────────────────────────────────────────────────

function ZDDisguiseAction:new(character, deadBody)
    local o = ISBaseTimedAction.new(self, character)
    setmetatable(o, self)
    self.__index = self

    o.character = character
    o.deadBody  = deadBody
    o.maxTime   = ZD_Config.APPLY_TIME
    -- Respect instant-action sandbox settings.
    if character:isTimedActionInstant() then o.maxTime = 1 end

    return o
end

function ZDDisguiseAction:isValid()
    if not self.character or self.character:isDead() then return false end
    -- Verify the body object still exists in the world (getSquare() returns nil if removed).
    if not self.deadBody or not self.deadBody:getSquare() then return false end
    return true
end

function ZDDisguiseAction:waitToStart()
    return false
end

function ZDDisguiseAction:start()
    -- "Loot" is a safe crouch-and-reach animation available in B42.
    -- [VERIFICAR V4]: check whether a more fitting animation exists (e.g. smear/blood).
    self:setActionAnim("Loot")
end

function ZDDisguiseAction:update()
    -- No per-tick logic needed; the animation runs until maxTime is reached.
end

function ZDDisguiseAction:stop()
    -- If the action was cancelled (not completed via perform()), release the optimistic
    -- ZD_active lock set in onSelectDisguise so the Disguise menu option re-enables.
    if not self._performed then
        local modData = self.character and self.character:getModData()
        if modData then modData.ZD_active = false end
    end
    ISBaseTimedAction.stop(self)
end

function ZDDisguiseAction:perform()
    self._performed = true   -- mark as completed before stop() can fire

    -- Apply blood visuals client-side (purely cosmetic).
    ZD_Action.applyBloodVisuals(self.character)

    -- Notify server to grant the authoritative disguise state.
    sendClientCommand(ZD_Config.MODULE, "startDisguise", {})

    ISBaseTimedAction.perform(self)
end

-- ─── Blood Visual Application ─────────────────────────────────────────────────

function ZD_Action.applyBloodVisuals(character)
    if not character then return end

    for _, partName in ipairs(ZD_Config.DISGUISE_PARTS) do
        -- BloodBodyPartType is used by IsoGameCharacter:addBlood.
        -- [VERIFICAR V1]: confirm BloodBodyPartType enum names match BodyPartType names in B42.
        local bpt = BloodBodyPartType and BloodBodyPartType[partName]
        if bpt then
            -- allLayers=true fully covers the part with blood.
            character:addBlood(bpt, false, false, true)
        else
            ZD_log("BloodBodyPartType." .. partName .. " not found — skipping visual")
        end
    end
end

-- ─── Server → Client Sync ────────────────────────────────────────────────────
-- Keeps the client's local modData in sync with the server's authoritative state.
-- Required because player:getModData() writes done server-side are NOT reflected
-- on the client in real-time during a live MP session.
-- Wash detection has been moved fully server-side (ZDDisguiseServer.lua) to avoid
-- this desync problem entirely for that feature.

local function onServerCommand(module, command, args)
    if module ~= ZD_Config.MODULE then return end

    -- Use playerIndex from args so split-screen players (slots 1-3) sync correctly.
    local idx    = (args and args.playerIndex) or 0
    local player = getSpecificPlayer(idx)
    if not player then return end
    local modData = player:getModData()

    if command == "disguiseGranted" then
        modData.ZD_active = true
        ZD_log("Client: disguise granted")
    elseif command == "disguiseRevoked" then
        modData.ZD_active = false
        ZD_log("Client: disguise revoked")
    end
end

Events.OnServerCommand.Add(onServerCommand)
