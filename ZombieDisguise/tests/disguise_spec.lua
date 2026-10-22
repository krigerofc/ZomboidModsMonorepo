local failed=0
local function check(v,m)if not v then failed=failed+1;print(" FAIL [disguise] "..m) end end
local loaded,G=pcall(require,"ZD/Game")
check(loaded,"authoritative disguise engine exists")
if not loaded then return failed end
check(G.CONCEALMENT_READY==false,"unproven native camouflage adapter is disabled by default")
G.CONCEALMENT_READY=true -- fixture-only former adapter behavior; never enables runtime gameplay
local C=require "ZD/Core"
local hours=100;local client=false;local server=true;local players={}
local function list(t)return {size=function()return #t end,get=function(_,i)return t[i+1] end}end
isClient=function()return client end;isServer=function()return server end;isMultiplayer=function()return client or server end
getGameTime=function()return{getWorldAgeHours=function()return hours end}end
getOnlinePlayers=function()return list(players)end
getNumActivePlayers=function()return #players end;getSpecificPlayer=function(i)return players[i+1]end
SandboxVars={KFM={},ZombieDisguise={}};BodyPartType={ToString=function(p)return p end}
BloodBodyPartType={};for _,name in ipairs(C.PARTS)do BloodBodyPartType[name]=name end
instanceof=function(o,c)return o and o.class==c end
sendServerCommand=function()end;sendHumanVisual=function()end;syncVisuals=function()end
syncBodyPart=function()end;ZombRandFloat=function()return 0.99 end
Events=setmetatable({},{__index=function(t,k)local e={fns={}};e.Add=function(fn)table.insert(e.fns,fn)end;rawset(t,k,e);return e end})
package.preload["TimedActions/ISBaseTimedAction"]=function()
 ISBaseTimedAction={};function ISBaseTimedAction:derive()local x={};x.__index=x;setmetatable(x,{__index=self});return x end
 function ISBaseTimedAction.new(self,p)return setmetatable({character=p},self)end
 function ISBaseTimedAction.perform()end;function ISBaseTimedAction.stop()end
end
local function actor(id)
 local p={id=id,md={},x=10,y=10,z=0,protect=false,blood={},dead=false,running=false,attack=false,parts={}}
 p.square={canReachTo=function()return true end}
 function p:getModData()return self.md end;function p:getOnlineID()return self.id end;function p:getPlayerNum()return self.id end
 function p:getX()return self.x end;function p:getY()return self.y end;function p:getZ()return self.z end
 function p:getSquare()return self.square end;function p:isDead()return self.dead end
 function p:isRunning()return self.running end;function p:isSprinting()return false end;function p:isAttacking()return self.attack end
 function p:isZombiesDontAttack()return self.protect end;function p:setZombiesDontAttack(v)self.protect=v end
 function p:getHumanVisual()local me=self;return{getBlood=function(_,n)return me.blood[n] or 0 end,setBlood=function(_,n,v)me.blood[n]=v end}end
 function p:resetModelNextFrame()end
 function p:getBodyDamage()return{getBodyParts=function()return list(self.parts)end}end
 function p:getInventory()return{getItemById=function()end}end
 function p:getDisplayName()return "P"..self.id end
 for _,name in ipairs(C.PARTS)do
  local bp={};function bp:getType()return name end
  function bp:isCut()return true end;function bp:scratched()return false end;function bp:isDeepWounded()return false end;function bp:bitten()return false end
  function bp:bandaged()return false end;function bp:stitched()return false end;function bp:isInfectedWound()return false end
  function bp:getWoundInfectionLevel()return 0 end;function bp:getBleedingTime()return 0 end;function bp:getFractureTime()return 0 end
  p.parts[#p.parts+1]=bp
 end
 players[#players+1]=p;return p
end
local function corpse()
 local b={class="IsoDeadBody",square={getX=function()return 10 end,getY=function()return 10 end,getZ=function()return 0 end},index=0,zombie=true}
 function b:getSquare()return self.square end;function b:getStaticMovingObjectIndex()return self.index end
 function b:isZombie()return self.zombie end;return b
end
local Server=dofile(MODLUA.."/server/ZD/Server.lua")
dofile(MODLUA.."/shared/TimedActions/ZDDisguiseAction.lua")
local p=actor(0);local b=corpse()
Server.onCommand("ZombieDisguise","startDisguise",p,{})
check(not p.protect,"legacy empty command cannot grant protection")
local function action(pl,body,progress)
 local a=ZDDisguiseAction:new(pl,body)
 a.netAction={getProgress=function()return progress or 0 end}
 return a
end
local a=action(p,b,1);a:complete()
check(not p.protect,"completion without server start rejected")
a=action(p,b,0);a:serverStart();a:complete()
check(not p.protect,"no elapsed native action rejected")
a=action(p,b,1);a:serverStart();b.index=-1;a:complete()
check(not p.protect,"removed corpse rejected")
b=corpse();a=action(p,b,1);a:serverStart();b.square={getX=function()return 20 end,getY=function()return 20 end,getZ=function()return 0 end};a:complete()
check(not p.protect,"moved corpse rejected")
b=corpse();a=action(p,b,1);a:serverStart();local other=actor(1);a.character=other;a:complete()
check(not p.protect and not other.protect,"actor mismatch cannot affect splitscreen peer")
a=action(p,b,1);a:serverStart();a:serverStop();a:complete()
check(not p.protect,"interrupted server action cannot grant")
a=action(p,b,1);a:serverStart();a:complete()
check(p.protect and G.state(p).expires==hours+2,"completed verified action grants 120 game minutes")
local I=require "KFM/Illness";local Health=require "KFM/Health"
check(I.count(Health.state(p).sources)==#C.PARTS,"one shared regional health exposure per application")
local expiry=G.state(p).expires;a:complete()
check(G.state(p).expires==expiry and I.count(Health.state(p).sources)==#C.PARTS,"completion replay no renewal or extra exposure")
p.running=true;Server.tickPlayer(p)
check(not p.protect and I.count(Health.state(p).sources)==#C.PARTS,"running breaks disguise but residual blood exposure persists")
p.running=false
hours=103;a=action(p,b,1);a:serverStart();a:complete()
check(p.protect,"can apply a new verified disguise")
for _,part in ipairs(C.PARTS)do p.blood[part]=0 end
Server.tickPlayer(p)
check(not p.protect and I.count(Health.state(p).sources)==0,"actual washing removes camouflage and exposures")
a=action(p,b,1);a:serverStart();a:complete()
p.wetness=100;Server.tickPlayer(p)
check(p.protect,"wetness alone is not washing")
hours=G.state(p).expires+0.1;Server.tickPlayer(p)
check(not p.protect and I.count(Health.state(p).sources)==#C.PARTS,"expiry does not clean residual blood")
p.protect=true;a=action(p,b,1);a:serverStart();a:complete()
hours=G.state(p).expires+0.1;Server.tickPlayer(p)
check(p.protect,"pre-existing external protection preserved")
p.protect=false;a=action(p,b,1);a:serverStart();a:complete();local exp=G.state(p).expires
Server.reconcile(p)
check(G.state(p).expires==exp,"reconnect does not reset duration")
p.dead=true;Server.tickPlayer(p)
check(not p.protect,"death removes owned protection")
p.dead=false;a=action(p,b,1);a:serverStart();a:complete();SandboxVars.ZombieDisguise.Enabled=false;Server.tickPlayer(p)
check(not p.protect,"disable cleans only owned protection")
SandboxVars.ZombieDisguise.Enabled=true
local dependency=KFM.Exposure;KFM.Exposure=nil
check(not G.available(),"missing incompatible health API disables operations")
KFM.Exposure=dependency
p.dead=false;p.protect=true;p.md.ZD=nil;p.md.ZD_active=true
Server.reconcile(p)
check(not p.protect,"legacy active camouflage provenance is revoked during migration")
p.protect=true;p.md.ZD=nil;p.md.ZD_active=true
p.isGodMod=function()return true end
Server.reconcile(p)
check(p.protect,"explicit god/admin protection preserved during legacy migration")
p.isGodMod=function()return false end
p.protect=false;p.md.ZD=nil
b=corpse();b.zombie=false;a=action(p,b,1);a:serverStart();a:complete()
check(not p.protect,"human corpse cannot supply zombie camouflage")
b=corpse();p.z=1;a=action(p,b,1);a:serverStart();a:complete()
check(not p.protect,"different floor corpse rejected")
p.z=0;b=corpse();a=action(p,b,1);a:serverStart();a:complete()
p.attack=true
check(type(Server.fastTick)=="function","running/attack checks run more often than once a minute")
if Server.fastTick then Server.fastTick() end
check(not p.protect,"brief hostile action immediately breaks camouflage")
p.attack=false

-- Registration failure cannot smear blood before the health transaction succeeds.
local register=KFM.Exposure.register;KFM.Exposure.register=function()return false end
local rejected=actor(8);local rejectedAction=action(rejected,corpse(),1);rejectedAction:serverStart();rejectedAction:complete()
check(next(rejected.blood)==nil and not G.state(rejected).active,"failed health registration leaves visuals and protection unchanged")
KFM.Exposure.register=register
-- Backend and health availability are separate: washing is always reconciled.
local tested=actor(9);local testedBody=corpse();local applied=action(tested,testedBody,1);applied:serverStart();applied:complete()
check(G.state(tested).active,"cleanup fixture has an active application")
G.CONCEALMENT_READY=false
for _,part in ipairs(C.PARTS)do tested.blood[part]=0 end
Server.tickPlayer(tested)
check(I.count(Health.state(tested).sources)==0,"washing removes shared exposures even when the camouflage backend is unavailable")
G.CONCEALMENT_READY=true
SandboxVars.KFM.Enabled=false
check(not G.available(),"disabled FieldMedicine prevents disguise availability")
local disabled=actor(10);local disabledAction=action(disabled,corpse(),1);disabledAction:serverStart();disabledAction:complete()
check(not G.state(disabled).active and next(disabled.blood)==nil,"disabled health cannot receive blood or protection from a completed action")
SandboxVars.KFM.Enabled=true
check(type(G.unavailableReason)=="function","availability reports a precise reason")
if G.unavailableReason then
 G.CONCEALMENT_READY=false;check(G.unavailableReason()=="Tooltip_ZD_Backend","unproven adapter is not reported as a missing health dependency")
 G.CONCEALMENT_READY=true;SandboxVars.KFM.Enabled=false;check(G.unavailableReason()=="Tooltip_ZD_HealthDisabled","health disabled reason is distinct");SandboxVars.KFM.Enabled=true
 local saved=KFM.Exposure;KFM.Exposure=nil;check(G.unavailableReason()=="Tooltip_ZD_Dependency","missing exposure API reason");KFM.Exposure=saved
 check(G.unavailableReason()==nil,"compatible enabled fixture has no availability error")
end
local uiLoaded,Client=pcall(dofile,MODLUA.."/client/ZD/Client.lua")
check(uiLoaded,"localized disguise client menu and actor-specific mirror exist")
if uiLoaded then
 check(Client.findCorpse({corpse()})~=nil,"native Lua worldobjects table accepted")
 check(Client.localActor(1)==other,"splitscreen actor resolved by online ID")
 client=true
 Client.onServerCommand("ZombieDisguise","state",{id=other.id,active=true,expires=hours+1,coverage=1})
 check(G.view(other).active==true and not G.view(p).active,"server mirror targets the matching local character")
 client=false
end

return failed
