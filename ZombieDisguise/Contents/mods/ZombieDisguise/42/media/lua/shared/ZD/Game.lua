local C=require "ZD/Core"
local Concealment=require "ZD/Concealment"
local G={pending={},mirror={},sessions={},tracked={},revision=0,sessionSerial=0,PROTOCOL=2,BACKEND="lua-invisibility-v1",LEASE_SECONDS=5}
ZD=ZD or {};ZD.Game=G
function G.finite(v)return type(v)=="number" and v==v and v~=math.huge and v~=-math.huge end
function G.now()return getGameTime():getWorldAgeHours()end
function G.millis()return getTimestampMs()end
function G.cfg()return C.config(SandboxVars and SandboxVars.ZombieDisguise)end
function G.epoch()
 if not G.serverEpoch then G.serverEpoch=tostring(G.millis())..":"..tostring({}) end
 return G.serverEpoch
end
function G.identity(player)
 local ok,v=pcall(function()
  local id=player:getOnlineID();local name=player:getUsername();local descriptor=player:getDescriptor():getID()
  if not G.finite(id) or id%1~=0 or type(name)~="string" or name=="" or not G.finite(descriptor) or descriptor%1~=0 then return nil end
  return tostring(id)..":"..tostring(#name)..":"..name..":"..tostring(descriptor)
 end)
 return ok and v or nil
end
function G.backendAvailable(player)return Concealment.available(player)end
function G.clearConcealment(player)return Concealment.clear(player)end
function G.isConcealed(player)return Concealment.active(player)end
function G.applyConcealment(player,expires,authorisedReplica)return Concealment.apply(player,expires,authorisedReplica)end
function G.healthAvailable()
 return KFM and KFM.Exposure and KFM.Exposure.version==1 and type(KFM.Exposure.register)=="function" and type(KFM.Exposure.remove)=="function" and KFM.Game and type(KFM.Game.cfg)=="function"
end
function G.healthEnabled()
 if not G.healthAvailable()then return false end
 local ok,cfg=pcall(KFM.Game.cfg)
 return ok and type(cfg)=="table" and cfg.Enabled==true
end
function G.players()
 local players={}
 if isClient()or isServer()then
  local online=getOnlinePlayers()
  if online then for i=0,online:size()-1 do players[#players+1]=online:get(i)end end
 else
  for i=0,getNumActivePlayers()-1 do local player=getSpecificPlayer(i);if player then players[#players+1]=player end end
 end
 return players
end
function G.unavailableReason(player)
 if not G.backendAvailable(player)then return "Tooltip_ZD_Backend"end
 if isClient() and G.remoteReady~=true then return "Tooltip_ZD_Peers"end
 if isServer() and G.peersReady and not G.peersReady() then return "Tooltip_ZD_Peers"end
 return nil
end
function G.available(player)return G.unavailableReason(player)==nil end
function G.session(player)
 if not G.sessions[player]then G.sessionSerial=G.sessionSerial+1;G.sessions[player]=G.epoch()..":"..G.sessionSerial end
 G.tracked[player]=true
 return G.sessions[player]
end
function G.state(player)
 local md=player:getModData();local s=md.ZD
 if not s or s.version~=4 then
  s={version=4,serial=s and G.finite(s.serial)and math.max(0,math.floor(s.serial))or 0,active=false,regions=s and s.regions or {},source=s and s.source or nil}
  md.ZD=s;md.ZD_active=nil;md.ZD_parts=nil;md.ZD_elapsedMinutes=nil
 end
 -- Saved modData is not an invisibility lease; every process/session starts inactive.
 if not G.sessions[player]then s.active=false;G.clearConcealment(player);G.session(player)end
 return s
end
function G.view(player)
 if isClient()then
  local s=G.mirror[tostring(player:getOnlineID())]
  if s and s.actor==player and s.identity==G.identity(player)then return s end
  return {active=false}
 end
 return G.state(player)
end
function G.valid(player,body)
 if not player or player:isDead() or not body or not instanceof(body,"IsoDeadBody")then return false end
 local sq=body:getSquare()
 if not sq or body:getStaticMovingObjectIndex()<0 or not body:isZombie()or player:getZ()~=sq:getZ()then return false end
 local dx,dy=player:getX()-sq:getX(),player:getY()-sq:getY()
 return dx*dx+dy*dy<=4 and player:getSquare() and player:getSquare():canReachTo(sq)
end
function G.packet(player,revision)
 local s=G.state(player)
 return {version=G.PROTOCOL,epoch=G.epoch(),revision=revision,id=player:getOnlineID(),identity=G.identity(player),session=G.session(player),serial=s.serial or 0,active=s.active==true,expires=s.expires or 0,coverage=s.coverage or 0}
end
function G.push(player)
 if isServer()then
  G.revision=G.revision+1
  -- No recipient: every client may simulate a zombie targeting this character.
  sendServerCommand("ZombieDisguise","lease",G.packet(player,G.revision))
 end
end
function G.revoke(player,reason)
 if isClient()then return end
 local s=G.state(player);G.clearConcealment(player);s.active=false;s.reason=reason
 G.pending[player]=nil;G.push(player)
end
function G.grant(player,proof)
 if isClient()or not G.available(player)or not G.cfg().Enabled or not proof or proof.actor~=player or proof.completed~=true or proof.used then return false end
 proof.used=true
 local s=G.state(player)
 if s.active then return false end
 local serial=(s.serial or 0)+1;local source="disguise:"..serial
 local regions,previous={},{};local visual=player:getHumanVisual()
 for _,part in ipairs(C.PARTS)do if BloodBodyPartType[part]then regions[part]=0.8;previous[part]=visual:getBlood(BloodBodyPartType[part])end end
 local exposed=false
 if G.healthEnabled()then
  local ok,registered=pcall(KFM.Exposure.register,player,source,regions)
  if not ok or registered~=true then pcall(KFM.Exposure.remove,player,source);return false end
  exposed=true
 end
 local expires=G.now()+G.cfg().DurationMinutes/60
 if not G.applyConcealment(player,expires)then G.clearConcealment(player);if exposed then KFM.Exposure.remove(player,source)end;return false end
 local smeared=pcall(function()
  for part,_ in pairs(regions)do visual:setBlood(BloodBodyPartType[part],math.max(0.8,previous[part]))end
 end)
 if not smeared then
  for part,blood in pairs(previous)do pcall(function()visual:setBlood(BloodBodyPartType[part],blood)end)end
  G.clearConcealment(player);if exposed then KFM.Exposure.remove(player,source)end;return false
 end
 if s.source and s.source~=source and G.healthAvailable()then KFM.Exposure.remove(player,s.source)end
 s.serial=serial;s.source=exposed and source or nil;s.regions=regions;s.active=true;s.started=G.now();s.expires=expires;s.coverage=1;s.refreshed=G.millis()
 syncVisuals(player);sendHumanVisual(player);G.push(player)
 return true
end
return G
