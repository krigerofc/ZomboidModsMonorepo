local failed=0
local function check(v,m)if not v then failed=failed+1;print(" FAIL [disguise] "..m)end end
local hours,ms,client,server=100,1000,false,true
local players,packets={},{}
local function list(t)return{size=function()return #t end,get=function(_,i)return t[i+1]end}end
isClient=function()return client end;isServer=function()return server end;isMultiplayer=function()return client or server end
getTimestampMs=function()return ms end;getGameTime=function()return{getWorldAgeHours=function()return hours end}end
getOnlinePlayers=function()return list(players)end;getNumActivePlayers=function()return #players end;getSpecificPlayer=function(i)return players[i+1]end
SandboxVars={KFM={},ZombieDisguise={}};instanceof=function(o,c)return o and o.class==c end
local requests={}
sendServerCommand=function(...)packets[#packets+1]={...}end;sendClientCommand=function(...)requests[#requests+1]={...}end;sendHumanVisual=function()end;syncVisuals=function()end
Events=setmetatable({},{__index=function(t,k)local e={Add=function()end};rawset(t,k,e);return e end})
local registered={}
KFM={Game={cfg=function()return{Enabled=SandboxVars.KFM.Enabled~=false}end}}
KFM.Exposure={version=1,register=function(p,s,r)registered[p]=registered[p]or{};local copy={};for k,v in pairs(r)do copy[k]=v end;registered[p][s]=copy;return true end,remove=function(p,s,part)if registered[p]then if part and registered[p][s]then registered[p][s][part]=nil;if next(registered[p][s])==nil then registered[p][s]=nil end else registered[p][s]=nil end end end}
package.preload["KFM/Health"]=function()return{}end
package.preload["KFM/Game"]=function()return{players=function()return players end}end
package.preload["TimedActions/ISBaseTimedAction"]=function()
 ISBaseTimedAction={}
 function ISBaseTimedAction:derive()local x={};x.__index=x;setmetatable(x,{__index=self});return x end
 function ISBaseTimedAction.new(self,p)return setmetatable({character=p},self)end
 function ISBaseTimedAction.perform()end;function ISBaseTimedAction.stop()end
end
local C=require"ZD/Core"
BloodBodyPartType={};for _,n in ipairs(C.PARTS)do BloodBodyPartType[n]=n end
local function actor(id)
 local p={id=id,md={},x=10,y=10,z=0,blood={},descriptor=id+100,lease=false,calls=0}
 p.square={canReachTo=function()return true end}
 function p:getModData()return self.md end;function p:getOnlineID()return self.id end;function p:getUsername()return"P"..self.id end
 function p:getDescriptor()return{getID=function()return self.descriptor end}end
 function p:getX()return self.x end;function p:getY()return self.y end;function p:getZ()return self.z end
 function p:getSquare()return self.square end;function p:isDead()return self.dead==true end
 function p:isRunning()return self.running==true end;function p:isSprinting()return false end;function p:isAttacking()return self.attack==true end
 function p:getHumanVisual()local me=self;return{getBlood=function(_,n)return me.blood[n]or 0 end,setBlood=function(_,n,v)me.blood[n]=v end}end
 function p:getZombieDisguiseBridgeVersion()return 1 end
 function p:setZombieDisguiseLease(expiry,ttl)self.calls=self.calls+1;self.ttl=ttl;self.lease=not self.reject;return not self.reject end
 function p:clearZombieDisguiseLease()self.lease=false end
 players[#players+1]=p;return p
end
local function corpse()
 local b={class="IsoDeadBody",index=0,zombie=true,square={getX=function()return 10 end,getY=function()return 10 end,getZ=function()return 0 end}}
 function b:getSquare()return self.square end;function b:getStaticMovingObjectIndex()return self.index end;function b:isZombie()return self.zombie end
 return b
end
local G=require"ZD/Game"
local S=dofile(MODLUA.."/server/ZD/Server.lua")
dofile(MODLUA.."/shared/TimedActions/ZDDisguiseAction.lua")
local Client=dofile(MODLUA.."/client/ZD/Client.lua")
check(type(G.bridgeAvailable)=="function","native bridge adapter exists")
if not G.bridgeAvailable then return failed end
local function action(p,b,progress)local a=ZDDisguiseAction:new(p,b or corpse());a.netAction={getProgress=function()return progress or 0 end};return a end
local function apply(p)local a=action(p,nil,1);a:serverStart();return a:complete()end
local function ready(p)S.onCommand("ZombieDisguise","sync",p,{nonce="request"..p.id,bridge=1})end
local p=actor(0);ready(p)
local bridge=p.getZombieDisguiseBridgeVersion;p.getZombieDisguiseBridgeVersion=nil
check(not G.available(p) and G.unavailableReason(p)=="Tooltip_ZD_Backend","missing bridge explicitly unavailable")
check(not apply(p)and next(p.blood)==nil,"missing bridge cannot smear blood");p.getZombieDisguiseBridgeVersion=bridge
local a=action(p,nil,1);check(not a:complete(),"completion without start rejected")
a=action(p,nil,0);a:serverStart();check(not a:complete(),"unfinished action rejected")
a=action(p,nil,0/0);a:serverStart();check(not a:complete(),"NaN progress rejected")
a=action(p,nil,1);a:serverStart();a:serverStop();check(not a:complete(),"interrupted action rejected")
a=action(p,nil,1);a:serverStart();a.corpseBody.index=-1;check(not a:complete(),"removed corpse rejected")
local register=KFM.Exposure.register;KFM.Exposure.register=function()return false end
check(not apply(p)and not p.lease and next(p.blood)==nil,"health rejection leaves no blood or native lease");KFM.Exposure.register=register
p.reject=true;check(not apply(p)and next(p.blood)==nil and next(registered[p]or{})==nil,"native rejection rolls health source back");p.reject=false
check(apply(p)and p.lease and p.ttl==5 and G.state(p).expires==102,"completed action grants bounded lease")
local count=p.calls;ms=ms+999;S.fastTick();check(p.calls==count,"refresh rate bounded");ms=ms+1;S.fastTick();check(p.calls==count+1,"refresh every real second")
local broadcast=false;for _,packet in ipairs(packets)do if packet[1]=="ZombieDisguise"and packet[2]=="lease"then broadcast=true end end
check(broadcast,"lease broadcasts to every simulation owner")
p.running=true;S.fastTick();check(not p.lease and next(registered[p]or{})~=nil,"running preserves residual blood risk");p.running=false
apply(p);for _,part in ipairs(C.PARTS)do p.blood[part]=0 end;S.tickPlayer(p)
check(not p.lease and next(registered[p]or{})==nil,"washing removes native lease and exposure")
apply(p);hours=103;S.fastTick();check(not p.lease and next(registered[p]or{})~=nil,"expiry preserves residual exposure")
SandboxVars.KFM.Enabled=false;check(apply(p),"disabled optional health does not prevent grant");G.revoke(p,"test");SandboxVars.KFM.Enabled=true
local other=actor(1);ready(other);ready(p)
client=true;server=false;Client.reset();Client.onCreatePlayer(0,p)
Client.onServerCommand("ZombieDisguise","snapshot",{version=1,nonce=Client.nonce,epoch="e1",revision=10,ready=true,leases={{version=1,epoch="e1",revision=10,id=other.id,identity=G.identity(other),session="session",serial=0,active=false,expires=0}}})
local packet={version=1,epoch="e1",revision=11,id=other.id,identity=G.identity(other),session="session",serial=1,active=true,expires=hours+1,coverage=1}
Client.onServerCommand("ZombieDisguise","lease",packet)
check(other.lease and G.view(other).active,"remote simulated player receives native lease")
local calls=other.calls
packet.revision=10;packet.active=false;Client.onServerCommand("ZombieDisguise","lease",packet);check(other.lease,"stale revocation ignored")
packet.revision=12;packet.active=true;packet.epoch="foreign";Client.onServerCommand("ZombieDisguise","lease",packet)
check(other.calls==calls,"foreign epoch rejected");packet.epoch="e1";packet.expires=0/0;Client.onServerCommand("ZombieDisguise","lease",packet)
check(other.calls==calls,"NaN expiry rejected");packet.expires=hours+9;Client.onServerCommand("ZombieDisguise","lease",packet)
check(other.calls==calls,"unbounded expiry rejected");packet.expires=hours+1;packet.serial=0;Client.onServerCommand("ZombieDisguise","lease",packet)
check(other.calls==calls,"zero serial rejected");packet.serial=1;packet.active=false;Client.onServerCommand("ZombieDisguise","lease",packet)
check(not other.lease,"new revocation clears lease");packet.revision=13;packet.active=true;Client.onServerCommand("ZombieDisguise","lease",packet)
check(not other.lease,"revoked serial cannot reactivate");packet.revision=14;packet.serial=2;Client.onServerCommand("ZombieDisguise","lease",packet)
check(other.lease,"new completed serial can activate");ms=ms+6000;Client.tick();check(not other.lease,"lost refresh expires local cache")
packet.revision=15;Client.onServerCommand("ZombieDisguise","lease",packet)
local replacement=actor(1);players[2]=replacement;players[3]=nil;ms=ms+1000;Client.tick()
check(not other.lease and not replacement.lease,"online ID reuse cannot transfer lease")
Client.reset();check(not p.lease and not replacement.lease,"disconnect resets leases")
local requestsBefore=#requests;ms=ms+11000;Client.tick()
local acknowledgments=0;for i=requestsBefore+1,#requests do if requests[i][3]=="ready"then acknowledgments=acknowledgments+1 end end
check(acknowledgments==2,"periodic readiness refresh covers every local split-screen actor")
client=false;server=true

-- Lifecycle, action identity and rollback edge cases.
ready(p);ready(replacement)
local b=corpse();local moved=action(p,b,1);moved:serverStart();p.x=11
check(not moved:complete(),"moving after server start rejects completion");p.x=10
b=corpse();local swapped=action(p,b,1);swapped:serverStart();swapped.corpseBody=corpse()
check(not swapped:complete(),"different corpse object cannot reuse action proof")
local unready=actor(2)
check(not G.available(p)and G.unavailableReason(p)=="Tooltip_ZD_Peers","missing client acknowledgment disables grants")
ready(unready);ready(p);ready(replacement)
check(apply(p),"fixture can apply after every client acknowledges")
local expiry=G.state(p).expires;S.reconcile(p);check(G.state(p).expires==expiry,"resync cannot renew duration")
p.dead=true;S.fastTick();check(not p.lease,"death revokes native lease");p.dead=false
ready(p);check(apply(p),"can reapply after death fixture reset")
SandboxVars.ZombieDisguise.Enabled=false;S.fastTick();check(not p.lease,"sandbox disable clears native lease");SandboxVars.ZombieDisguise.Enabled=true
ready(p);check(apply(p),"can reapply after sandbox enabled")
ms=ms+16000;S.fastTick();check(not p.lease and not G.available(p),"lost peer acknowledgments revoke and disable")
ready(p);ready(replacement);ready(unready)
local saved=KFM.Exposure;KFM.Exposure=nil
check(G.available(p),"missing optional exposure API does not block camouflage");KFM.Exposure=saved
SandboxVars.KFM.Enabled=false;check(G.available(p),"disabled optional health does not block camouflage");SandboxVars.KFM.Enabled=true
server=false
check(apply(p),"single player needs native bridge but no network acknowledgment")
S.reset();check(not p.lease and not G.state(p).active,"world reset retires saved native disguise")
local migrated=actor(3);migrated.md.ZD={version=2,serial=5,source="disguise:5",regions={Head=0.8},active=true}
check(G.state(migrated).serial==5 and not G.state(migrated).active,"migration preserves source serial while clearing active status")
server=true

return failed
