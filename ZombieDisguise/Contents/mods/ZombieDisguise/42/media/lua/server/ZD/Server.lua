local G=require "ZD/Game"
local Game=require "KFM/Game"
local S={ready={}}
ZD.Server=S
function S.peersReady()
 local now=G.millis()
 for _,p in ipairs(Game.players())do local ack=S.ready[p];if not ack or ack.identity~=G.identity(p)or now<ack.at or now-ack.at>15000 then return false end end
 return true
end
G.peersReady=S.peersReady
function S.tickPlayer(player,refresh)
 if isClient()then return end
 local s=G.state(player);local cfg=G.cfg()
 if not s.source and not s.active then return end
 local total,covered=0,0;local visual=player:getHumanVisual()
 for part,_ in pairs(s.regions or {})do
  total=total+1;local enum=BloodBodyPartType[part];local blood=enum and visual:getBlood(enum)or 0
  if blood>=0.15 then covered=covered+math.min(1,blood/0.8)
  elseif s.source and G.healthAvailable()then KFM.Exposure.remove(player,s.source,part)end
 end
 s.coverage=total>0 and covered/total or 0
 if not s.active then return end
 if player:isDead()then G.revoke(player,"death")
 elseif not cfg.Enabled or not G.available(player)then G.revoke(player,"disabled")
 elseif not G.finite(s.expires)or G.now()>=s.expires then G.revoke(player,"expired")
 elseif cfg.BreakOnRun and (player:isRunning()or player:isSprinting())then G.revoke(player,"running")
 elseif cfg.BreakOnAttack and player:isAttacking()then G.revoke(player,"attack")
 elseif s.coverage<cfg.RequiredCoverage then G.revoke(player,"washed")
 elseif refresh then
  if G.native(player,s.expires)then s.refreshed=G.millis();G.push(player)else G.revoke(player,"backend")end
 end
end
function S.reconcile(player)
 if isClient()or not player then return end
 S.tickPlayer(player,false);G.push(player)
end
function S.onCommand(module,command,player,args)
 if module~="ZombieDisguise"or not player or (command~="sync"and command~="ready")or type(args)~="table"or type(args.nonce)~="string"or #args.nonce>160 then return end
 S.ready[player]=args.bridge==1 and G.identity(player) and {at=G.millis(),identity=G.identity(player)}or nil
 if command=="ready"then return end
 local leases={}
 for _,p in ipairs(Game.players())do S.tickPlayer(p,false);leases[#leases+1]=G.packet(p,G.revision)end
 sendServerCommand(player,"ZombieDisguise","snapshot",{version=1,epoch=G.epoch(),nonce=args.nonce,revision=G.revision,ready=S.peersReady(),leases=leases})
end
function S.fastTick()
 if isClient()then return end
 local now=G.millis();local present={}
 for _,p in ipairs(Game.players())do
  present[p]=true
  local s=G.state(p);local due=not s.refreshed or now<s.refreshed or now-s.refreshed>=1000
  S.tickPlayer(p,due)
 end
 for p,_ in pairs(G.tracked)do if not present[p]then
  G.revoke(p,"disconnect");G.tracked[p]=nil;G.sessions[p]=nil;S.ready[p]=nil;G.pending[p]=nil
 end end
end
function S.tick()for _,p in ipairs(Game.players())do S.tickPlayer(p,false)end end
function S.onDeath(p)if p and not isClient()then G.revoke(p,"death")end end
function S.onAttack(p)if p and not isClient()and G.cfg().BreakOnAttack and G.state(p).active then G.revoke(p,"attack")end end
function S.reset()
 for p,_ in pairs(G.tracked)do G.clearNative(p);local s=p:getModData().ZD;if s then s.active=false end end
 G.pending={};G.tracked={};G.sessions={};G.serverEpoch=nil;G.revision=0;S.ready={}
end
Events.OnClientCommand.Add(S.onCommand)
Events.EveryOneMinute.Add(S.tick)
Events.OnTick.Add(S.fastTick)
Events.OnPlayerDeath.Add(S.onDeath)
Events.OnWeaponSwingHitPoint.Add(S.onAttack)
Events.OnDisconnect.Add(S.reset)
Events.OnGameStart.Add(S.reset)
return S
