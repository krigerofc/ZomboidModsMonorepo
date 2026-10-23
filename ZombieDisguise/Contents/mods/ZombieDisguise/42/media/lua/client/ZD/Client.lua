local G=require "ZD/Game"
require "TimedActions/ZDDisguiseAction"
local Client={cache={},counter=0}
ZD.Client=Client
function Client.localActor(id)
 for i=0,getNumActivePlayers()-1 do local p=getSpecificPlayer(i);if p and p:getOnlineID()==id then return p end end
 return nil
end
function Client.actor(id)
 local online=getOnlinePlayers()
 if online then for i=0,online:size()-1 do local p=online:get(i);if p and p:getOnlineID()==id then return p end end end
 return Client.localActor(id)
end
function Client.reset()
 for _,s in pairs(Client.cache)do G.clearConcealment(s.actor)end
 Client.cache={};G.mirror={};Client.epoch=nil;Client.floor=0;Client.highest=0;Client.nonce=nil;Client.lastSync=nil;G.remoteReady=false
end
function Client.request(player,force)
 if not isClient()then return end
 local now=G.millis()
 if not force and Client.lastSync and now>=Client.lastSync and now-Client.lastSync<1000 then return end
 player=player or getSpecificPlayer(0)
 if not player then return end
 Client.counter=Client.counter+1;Client.nonce=tostring(now)..":"..Client.counter;Client.lastSync=now
 for i=0,getNumActivePlayers()-1 do
  local localPlayer=getSpecificPlayer(i)
  if localPlayer then sendClientCommand(localPlayer,"ZombieDisguise","ready",{nonce=Client.nonce,protocol=G.PROTOCOL,backend=G.backendAvailable(localPlayer)and G.BACKEND or false})end
 end
 sendClientCommand(player,"ZombieDisguise","sync",{nonce=Client.nonce,protocol=G.PROTOCOL,backend=G.backendAvailable(player)and G.BACKEND or false})
end
local function integer(v,min)return G.finite(v)and v%1==0 and v>=min end
function Client.validPacket(a)
 if type(a)~="table"or a.version~=G.PROTOCOL or type(a.epoch)~="string"or #a.epoch>160 or not integer(a.revision,0)
  or not integer(a.id,0)or type(a.identity)~="string"or #a.identity>512 or type(a.session)~="string"or #a.session>200
  or not integer(a.serial,0)or type(a.active)~="boolean"then return false end
 if a.active and (a.serial<1 or not G.finite(a.expires)or a.expires<=G.now()or a.expires>G.now()+8)then return false end
 return true
end
function Client.install(a,snapshot)
 local actor=Client.actor(a.id);local key=tostring(a.id);local old=Client.cache[key]
 if not actor or G.identity(actor)~=a.identity then return end
 if not snapshot then
  if not old or old.actor~=actor or old.identity~=a.identity or old.session~=a.session then
   if old then G.clearConcealment(old.actor);old.active=false end
   Client.request();return
  end
  if a.revision<=old.revision or a.serial<old.serial or (a.active and old.revoked and a.serial<=old.serial)then return end
 end
 local revoked=not a.active
 if old and old.session==a.session and old.serial==a.serial and old.revoked then revoked=true end
 local active=a.active and not revoked and not actor:isDead()and G.cfg().Enabled
 local s={actor=actor,id=a.id,identity=a.identity,session=a.session,revision=a.revision,serial=a.serial,expires=a.expires,coverage=a.coverage or 0,active=false,received=G.millis(),revoked=revoked}
 if active and G.applyConcealment(actor,a.expires,true)then s.active=true else G.clearConcealment(actor)end
 Client.cache[key]=s;G.mirror[key]=s
end
function Client.onServerCommand(module,command,args)
 if not isClient()or module~="ZombieDisguise"or type(args)~="table"then return end
 if command=="snapshot"then
  if args.version~=G.PROTOCOL or args.nonce~=Client.nonce or not Client.nonce or type(args.epoch)~="string"or #args.epoch>160
   or not integer(args.revision,0)or type(args.leases)~="table"or #args.leases>512 then return end
  if Client.epoch==args.epoch and args.revision<(Client.highest or 0) then return end
  for _,a in ipairs(args.leases)do if not Client.validPacket(a)or a.epoch~=args.epoch or a.revision>args.revision then return end end
  local previous=Client.cache
  for _,s in pairs(previous)do G.clearConcealment(s.actor)end
  Client.cache={};G.mirror={};Client.epoch=args.epoch;Client.floor=args.revision;Client.highest=args.revision;Client.nonce=nil;G.remoteReady=args.ready==true
  -- Preserve same-session revocation tombstones through resync.
  for _,a in ipairs(args.leases)do
   local old=previous[tostring(a.id)]
   if old and old.actor==Client.actor(a.id)and old.session==a.session then Client.cache[tostring(a.id)]=old end
   Client.install(a,true)
  end
 elseif command=="lease"then
  if not Client.validPacket(args)or args.epoch~=Client.epoch or args.revision<=Client.floor then return end
  Client.highest=math.max(Client.highest or 0,args.revision)
  Client.install(args,false)
 end
end
function Client.tick()
 if not isClient()then return end
 local now=G.millis();local cfg=G.cfg()
 for _,s in pairs(Client.cache)do
  if s.active then
   local p=s.actor
   local invalid=Client.actor(s.id)~=p or G.identity(p)~=s.identity or p:isDead()or not cfg.Enabled
    or G.now()>=s.expires or (cfg.BreakOnRun and (p:isRunning()or p:isSprinting()))or (cfg.BreakOnAttack and p:isAttacking())
   if invalid or now<s.received or now-s.received>=G.LEASE_SECONDS*1000 then
    G.clearConcealment(p);s.active=false
    if invalid then s.revoked=true end
   end
  end
 end
 if not Client.lastSync or now<Client.lastSync or now-Client.lastSync>=10000 then Client.request()end
end
function Client.findCorpse(objects)
 local function match(obj)
  if obj and instanceof(obj,"IsoDeadBody") and obj:isZombie() then return obj end
  return nil
 end
 if type(objects)=="table" then
  for _,obj in pairs(objects) do local body=match(obj);if body then return body end end
 elseif objects and objects.size then
  for i=0,objects:size()-1 do local body=match(objects:get(i));if body then return body end end
 end
 local fetch=ISWorldObjectContextMenu and ISWorldObjectContextMenu.fetchVars
 return fetch and match(fetch.body) or nil
end
function Client.onMenu(playerNum,context,objects,test)
 if test then return end
 local player=getSpecificPlayer(playerNum)
 if not player then return end
 local body=Client.findCorpse(objects);local state=G.view(player)
 if not body and not state.active then return end
 local name=state.active and getText("ContextMenu_ZD_Status",tostring(math.max(0,math.ceil(((state.expires or G.now())-G.now())*60)))) or getText("ContextMenu_ZD_Apply")
 local opt=context:addOption(name,player,function()
  if body then ISTimedActionQueue.add(ZDDisguiseAction:new(player,body)) end
 end)
 local reason="Tooltip_ZD_Risk"
 opt.notAvailable=state.active or not G.available(player) or not G.cfg().Enabled or not body or not G.valid(player,body)
 if not G.available(player) then reason=G.unavailableReason(player)
 elseif state.active then reason="Tooltip_ZD_Active"
 elseif not body or not G.valid(player,body) then reason="Tooltip_ZD_Reach" end
 if ISWorldObjectContextMenu and ISWorldObjectContextMenu.addToolTip then opt.toolTip=ISWorldObjectContextMenu.addToolTip()
 elseif ISToolTip then opt.toolTip=ISToolTip:new();opt.toolTip:initialise() end
 if opt.toolTip then opt.toolTip.description=getText(reason) end
end
function Client.onCreatePlayer(_,player)
 if not player then return end
 if isClient() then Client.request(player,true)
 elseif ZD.Server then ZD.Server.reconcile(player) end
end
Events.OnTick.Add(Client.tick)
Events.OnDisconnect.Add(Client.reset)
Events.OnGameStart.Add(Client.reset)
Events.OnServerCommand.Add(Client.onServerCommand)
Events.OnFillWorldObjectContextMenu.Add(Client.onMenu)
Events.OnCreatePlayer.Add(Client.onCreatePlayer)
return Client
