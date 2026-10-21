-- Field Medicine '93 - server (and SP): tourniquet over time + state sync to clients. Never runs on MP clients.
local Core = require "KFM/Core"
local Game = require "KFM/Game"

local Server = {}
KFM = KFM or {}
KFM.Server = Server

local function hasAny(t)
    for _ in pairs(t) do return true end
    return false
end

-- Every game minute: bleeding below each tourniquet stays paused.
function Server.everyOneMinute()
    if isClient() then return end
    for _, player in ipairs(Game.players()) do
        if not player:isDead() then
            local md = player:getModData().KFM
            if md and md.tq and hasAny(md.tq) then
                for part, st in pairs(md.tq) do
                    st.saved = st.saved or {}
                    Game.suppressBleeding(player, part, st)
                end
            end
        end
    end
end

-- Every 10 game minutes: ischemia past the safe window (health loss + pain); once past safeHours * 3 the limb
-- takes lasting damage (long fracture time). Also clears the "already reduced" flag of healed fractures.
function Server.everyTenMinutes()
    if isClient() then return end
    local cfg = Game.cfg()
    local now = Game.nowHours()
    for _, player in ipairs(Game.players()) do
        local md = player:getModData().KFM
        if md and not player:isDead() then
            for part, st in pairs(md.tq or {}) do
                local stage = Core.tourniquetStage(now - (st.t or now), cfg)
                local bp = Game.partByName(player, part)
                if bp and stage ~= "safe" then
                    bp:SetHealth(math.max(0, bp:getHealth() - Core.TOURNIQUET_HEALTH_LOSS))
                    bp:setAdditionalPain(bp:getAdditionalPain() + Core.TOURNIQUET_PAIN_GAIN)
                    if stage == "damage" and not st.dmg then
                        st.dmg = true
                        bp:setFractureTime(math.max(bp:getFractureTime(), Core.TOURNIQUET_DAMAGE_FRACTURE))
                    end
                    Game.sync(bp)
                end
            end
            for part, _ in pairs(md.reduced or {}) do
                local bp = Game.partByName(player, part)
                if not bp or bp:getFractureTime() <= 0 then md.reduced[part] = nil end
            end
        end
    end
end

function Server.onClientCommand(module, command, player, args)
    if module ~= Game.MODULE then return end
    if command == "tqSync" then
        local target = player
        if args and args.id ~= nil then target = getPlayerByOnlineID(args.id) end
        if target then sendServerCommand(player, Game.MODULE, "tq", { id = target:getOnlineID(), tq = Game.tqSnapshot(target) }) end
    end
end

Events.EveryOneMinute.Add(Server.everyOneMinute)
Events.EveryTenMinutes.Add(Server.everyTenMinutes)
Events.OnClientCommand.Add(Server.onClientCommand)

return Server
