local G=require "ZD/Game"
local C=require "ZD/Core"
local Game=require "KFM/Game"
local S={}
ZD.Server=S
function S.tickPlayer(player)
 if isClient() then return end
 local s=G.state(player);local cfg=G.cfg()
 if not s.source and not s.active then return end
 local total,covered=0,0
 local visual=player:getHumanVisual()
 for part,_ in pairs(s.regions or {}) do
  total=total+1
  local enum=BloodBodyPartType[part]
  local blood=enum and visual:getBlood(enum) or 0
  if blood>=0.15 then covered=covered+math.min(1,blood/0.8)
  elseif G.healthAvailable() then KFM.Exposure.remove(player,s.source,part) end
 end
 s.coverage=total>0 and covered/total or 0
 if not s.active then return end
 if player:isDead() then G.revoke(player,"death")
 elseif not cfg.Enabled or not G.available() or not KFM.Game.cfg().Enabled then G.revoke(player,"disabled")
 elseif G.now()>=(s.expires or 0) then G.revoke(player,"expired")
 elseif cfg.BreakOnRun and (player:isRunning() or player:isSprinting()) then G.revoke(player,"running")
 elseif cfg.BreakOnAttack and player:isAttacking() then G.revoke(player,"attack")
 elseif s.coverage<cfg.RequiredCoverage then G.revoke(player,"washed")
 else
  if not player:isZombiesDontAttack() then player:setZombiesDontAttack(true);s.owned=true;s.externalBefore=false end
  G.push(player)
 end
end
function S.reconcile(player)
 if not isClient() and player then S.tickPlayer(player);G.push(player) end
end
function S.onCommand(module,command,player,args)
 if module~="ZombieDisguise" or not player then return end
 if command=="sync" then S.reconcile(player) end
 -- No client command grants or renews protection. Native complete() is the only grant route.
end
function S.tick()
 if isClient() then return end
 for _,p in ipairs(Game.players())do S.tickPlayer(p) end
end
function S.onDeath(player) if player and not isClient() then G.revoke(player,"death") end end
Events.OnClientCommand.Add(S.onCommand)
Events.EveryOneMinute.Add(S.tick)
Events.OnPlayerDeath.Add(S.onDeath)

function S.fastTick()
 if isClient() then return end
 for _,p in ipairs(Game.players()) do
  local s=p:getModData().ZD
  if s and s.active then
   local cfg=G.cfg()
   if p:isDead() or (cfg.BreakOnRun and (p:isRunning() or p:isSprinting())) or (cfg.BreakOnAttack and p:isAttacking()) then G.revoke(p,"activity") end
  end
 end
end
function S.onAttack(player)
 if player and not isClient() and G.cfg().BreakOnAttack and G.state(player).active then G.revoke(player,"attack") end
end
Events.OnTick.Add(S.fastTick)
Events.OnWeaponSwingHitPoint.Add(S.onAttack)

return S
