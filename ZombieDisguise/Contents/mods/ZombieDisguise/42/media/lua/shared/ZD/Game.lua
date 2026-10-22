local C=require "ZD/Core"
local G={pending={},external={},mirror={},CONCEALMENT_READY=false}
ZD=ZD or {};ZD.Game=G
-- Dependency is declared in mod.info; pcall permits a clear UI reason for incompatible API versions.
pcall(require,"KFM/Health")
function G.now()return getGameTime():getWorldAgeHours() end
function G.cfg()return C.config(SandboxVars and SandboxVars.ZombieDisguise) end
function G.healthAvailable()
 return KFM and KFM.Exposure and KFM.Exposure.version==1 and type(KFM.Exposure.register)=="function" and type(KFM.Exposure.remove)=="function" and KFM.Game and type(KFM.Game.cfg)=="function"
end
function G.unavailableReason()
 if not G.healthAvailable() then return "Tooltip_ZD_Dependency" end
 if not KFM.Game.cfg().Enabled then return "Tooltip_ZD_HealthDisabled" end
 if not G.CONCEALMENT_READY then return "Tooltip_ZD_Backend" end
 return nil
end
function G.available()return G.unavailableReason()==nil end
function G.view(player)
 if isClient() then return G.mirror[tostring(player:getOnlineID())] or {active=false} end
 return G.state(player)
end
function G.state(player)
 local md=player:getModData()
 if not md.ZD or md.ZD.version~=2 then
  -- Old state had no trustworthy duration or ownership: retire it, preserving unexplained external protection.
  local legacy=md.ZD_active==true
  local protected=false
  pcall(function() protected=player:isGodMod() or player:isGhostMode() end)
  md.ZD={version=2,serial=0,active=legacy,owned=legacy,externalBefore=protected or next(G.external[player] or {})~=nil,expires=G.now(),regions={}}
  md.ZD_active=nil;md.ZD_parts=nil;md.ZD_elapsedMinutes=nil
 end
 return md.ZD
end
function G.valid(player,body)
 if not player or player:isDead() or not body or not instanceof(body,"IsoDeadBody") then return false end
 local sq=body:getSquare()
 if not sq or body:getStaticMovingObjectIndex()<0 or not body:isZombie() then return false end
 if player:getZ()~=sq:getZ() then return false end
 local dx,dy=player:getX()-sq:getX(),player:getY()-sq:getY()
 if dx*dx+dy*dy>4 then return false end
 return player:getSquare():canReachTo(sq)
end
function G.push(player)
 if isServer() then
  local s=G.state(player)
  sendServerCommand(player,"ZombieDisguise","state",{id=player:getOnlineID(),active=s.active,expires=s.expires,coverage=s.coverage or 0})
 end
end
-- Cooperating systems can declare a named lease instead of racing the engine's single boolean.
function G.externalProtection(player,source,enabled)
 if isClient() or type(source)~="string" then return false end
 G.external[player]=G.external[player] or {};G.external[player][source]=enabled and true or nil
 return true
end
function G.revoke(player,reason)
 if isClient() then return end
 local s=G.state(player)
 if s.owned and not s.externalBefore and not next(G.external[player] or {}) then player:setZombiesDontAttack(false) end
 s.active=false;s.owned=false;s.reason=reason
 G.pending[player]=nil;G.push(player)
end
function G.grant(player,proof)
 if isClient() or not G.available() or not G.cfg().Enabled then return false end
 local s=G.state(player)
 if s.active or not proof then return false end
 local serial=(s.serial or 0)+1;local source="disguise:"..serial
 local regions={};local visual=player:getHumanVisual()
 for _,part in ipairs(C.PARTS)do
  if BloodBodyPartType[part] then regions[part]=0.8 end
 end
 -- Register first: a rejected health transaction must not smear blood or retire the previous source.
 if not KFM.Exposure.register(player,source,regions) then return false end
 if s.source then KFM.Exposure.remove(player,s.source) end
 s.serial=serial;s.source=source;s.regions=regions
 for part,_ in pairs(regions)do
  local enum=BloodBodyPartType[part]
  visual:setBlood(enum,math.max(0.8,visual:getBlood(enum)))
 end
 s.active=true;s.started=G.now();s.expires=G.now()+G.cfg().DurationMinutes/60;s.coverage=1
 s.externalBefore=player:isZombiesDontAttack();s.owned=not s.externalBefore
 if s.owned then player:setZombiesDontAttack(true) end
 syncVisuals(player);sendHumanVisual(player);G.push(player)
 return true
end
return G
