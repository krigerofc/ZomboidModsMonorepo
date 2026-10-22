-- Field Medicine '93 - server (and SP): tourniquet over time + state sync to clients. Never runs on MP clients.
local Core = require "KFM/Core"
local Game = require "KFM/Game"

local Health = require "KFM/Health"
local Illness = require "KFM/Illness"
require "KFM/Ingestion"
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
        if player:isDead() or not Game.cfg().Enabled then
            Server.releaseTourniquets(player)
        else
            local md = player:getModData().KFM
            if md and md.tq and hasAny(md.tq) then
                for part, st in pairs(md.tq) do
                    local item = st.itemId and player:getInventory():getItemById(st.itemId)
                    if st.itemId and (not item or item:isWorn() or (item.getCondition and item:getCondition()<=0)) then
                        Game.removeTourniquet(player,part)
                        Game.pushTq(player)
                    else
                        st.saved = st.saved or {}
                        Game.suppressBleeding(player, part, st)
                    end
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
    local players=Game.players()
    Health.contact(players)
    for _, player in ipairs(Game.players()) do
        local md = player:getModData().KFM
        if not md then md=Game.md(player) end
        if md and not player:isDead() then
            for part, st in pairs(cfg.Enabled and md.tq or {}) do
                local stage = Core.tourniquetStage(now - (st.t or now), cfg)
                local bp = Game.partByName(player, part)
                if bp and stage ~= "safe" then
                    bp:SetHealth(math.max(0, bp:getHealth() - Core.TOURNIQUET_HEALTH_LOSS))
                    bp:setAdditionalPain(bp:getAdditionalPain() + Core.TOURNIQUET_PAIN_GAIN)
                    if stage == "damage" and not st.dmg then
                        st.dmg = true
                        md.health=Illness.seed(Health.state(player),"nerve","tourniquet:"..part..":"..st.t,part,false)
                        bp:setFractureTime(math.max(bp:getFractureTime(), Core.TOURNIQUET_DAMAGE_FRACTURE))
                    end
                    Game.sync(bp)
                end
            end
            local previous=Health.sessions[player]
            Health.sessions[player]=now
            local elapsed=previous and now-previous or 0
            -- A missing simulation window is not sustained live workload.
            local workloadElapsed=elapsed<=1/6+0.000001 and math.max(0,elapsed)or 0
            Health.observe(player,workloadElapsed)
            Health.tick(player,math.max(0,math.min(1/6,elapsed)))
            for part, _ in pairs(md.reduced or {}) do
                local bp = Game.partByName(player, part)
                if not bp or bp:getFractureTime() <= 0 then md.reduced[part] = nil end
            end
        end
    end
end

function Server.onClientCommand(module, command, player, args)
    if module ~= Game.MODULE or not player then return end
    args=args or {}
    if command=="careAsk" then local target=getPlayerByOnlineID(args.id);if target then Health.requestConsent(player,target) end;return end
    if command=="careAnswer" then Health.answerConsent(player,args.nonce,args.accepted);return end
    if command=="careRevoke" then Health.revokeConsent(player);return end
    if command == "tqSync" then
        local target = player
        if args and args.id ~= nil then target = getPlayerByOnlineID(args.id) end
        if target and Health.reachable(player,target) then Health.push(target,player); sendServerCommand(player, Game.MODULE, "tq", { id = target:getOnlineID(), tq = Game.tqSnapshot(target) }) end
    end
end

Events.EveryOneMinute.Add(Server.everyOneMinute)
Events.EveryTenMinutes.Add(Server.everyTenMinutes)
Events.OnClientCommand.Add(Server.onClientCommand)
Events.OnWeaponHitTree.Add(function(owner,weapon)Health.recordEffort(owner,weapon,true)end)
Events.OnWeaponHitXp.Add(function(owner,weapon)Health.recordEffort(owner,weapon,false)end)


function Server.releaseTourniquets(player)
 local md=Game.md(player)
 for part,st in pairs(md.tq) do
  local fullType,itemId=Game.removeTourniquet(player,part)
  if fullType and not itemId then Game.giveItem(player,fullType) end
 end
 Game.pushTq(player)
end
function Server.onDeath(player)
 if isClient() or not player then return end
 Server.releaseTourniquets(player);Health.revokeConsent(player);Health.sessions[player]=nil
end
Events.OnPlayerDeath.Add(Server.onDeath)
Events.OnCreatePlayer.Add(function(_,player)if not isClient()and player then Health.revokeConsent(player);Health.sessions[player]=nil end end)

return Server
