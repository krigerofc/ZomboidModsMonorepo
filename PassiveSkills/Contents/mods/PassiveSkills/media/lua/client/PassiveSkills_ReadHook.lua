-- Passive Skills v2 - ISReadABook hooks. Same file in B42 (shared/, ISReadABook is shared there)
-- and B41 (client/, ISReadABook is client-only there).
--  * new():      re-read pre-check on the client -> action is never queued (no hang), character says so.
--  * complete(): B42 (SP + MP server) grants XP after vanilla completes.
--  * perform():  B41 grants XP after vanilla perform (which removes the action from the queue).
require "TimedActions/ISReadABook"
local Game = require "PassiveSkills/Game"

if ISReadABook and not ISReadABook.passiveSkillsHooked then
    ISReadABook.passiveSkillsHooked = true

    local orig_new = ISReadABook.new
    function ISReadABook.new(self, character, item, ...)
        local o = orig_new(self, character, item, ...)
        if o and not isServer() then
            local ok, already, entry = pcall(Game.alreadyRead, character, item)
            if ok and already then
                o.ignoreAction = true            -- ISTimedActionQueue.add() skips it entirely
                o.passiveSkillsBlocked = true    -- and isValid() rejects it if queued anyway
                pcall(Game.showFeedback, character, "already", entry.skill)
            end
        end
        return o
    end

    local orig_isValid = ISReadABook.isValid
    function ISReadABook.isValid(self, ...)
        if self.passiveSkillsBlocked then return false end
        local ok, already, entry = pcall(Game.alreadyRead, self.character, self.item)
        if ok and already then
            self.passiveSkillsBlocked = true
            if not isServer() then pcall(Game.showFeedback, self.character, "already", entry.skill) end
            return false
        end
        return orig_isValid(self, ...)
    end

    if ISReadABook.complete then
        local orig_complete = ISReadABook.complete
        function ISReadABook.complete(self, ...)
            local result = orig_complete(self, ...)
            if not isClient() then
                Game.onFinishedReading(self.character, self.item)
            end
            return result
        end
    else
        local orig_perform = ISReadABook.perform
        function ISReadABook.perform(self, ...)
            local character, item = self.character, self.item
            local result = orig_perform(self, ...)
            Game.onFinishedReading(character, item)
            return result
        end
    end
end
