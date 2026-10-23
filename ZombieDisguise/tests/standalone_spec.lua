local failed=0
local function check(v,m)if not v then failed=failed+1;print(" FAIL [standalone] "..m)end end
local client,server=false,true
local ms,hours=1000,100
local players={}
local attempted={}
KFM=nil
for _,name in ipairs({"KFM/Health","KFM/Game"})do
 package.preload[name]=function()attempted[name]=true;error("FieldMedicine is not installed")end
end
getDebug=function()return true end
isClient=function()return client end;isServer=function()return server end
getTimestampMs=function()return ms end;getGameTime=function()return{getWorldAgeHours=function()return hours end}end
getOnlinePlayers=function()return{size=function()return #players end,get=function(_,i)return players[i+1]end}end
getNumActivePlayers=function()return #players end;getSpecificPlayer=function(i)return players[i+1]end
SandboxVars={ZombieDisguise={}}
Events=setmetatable({},{__index=function(t,k)local e={Add=function()end};rawset(t,k,e);return e end})
sendServerCommand=function()end;sendClientCommand=function()end;sendHumanVisual=function()end;syncVisuals=function()end
package.preload["TimedActions/ZDDisguiseAction"]=function()return{}end
local C=require"ZD/Core";BloodBodyPartType={};for _,n in ipairs(C.PARTS)do BloodBodyPartType[n]=n end
local G=require"ZD/Game"
check(not attempted["KFM/Health"],"loading standalone does not attempt to require absent medical files")
local ok,S=pcall(dofile,MODLUA.."/server/ZD/Server.lua")
check(ok,"server loads without FieldMedicine")
if not ok then return failed end
check(not attempted["KFM/Game"],"server never imports medical player enumeration")
local p={md={},blood={},lease=false}
function p:getModData()return self.md end;function p:getOnlineID()return 1 end
function p:getUsername()return"Standalone"end;function p:getDescriptor()return{getID=function()return 10 end}end
function p:isDead()return false end;function p:isRunning()return false end;function p:isSprinting()return false end;function p:isAttacking()return false end
function p:getHumanVisual()return{getBlood=function(_,n)return self.blood[n]or 0 end,setBlood=function(_,n,v)self.blood[n]=v end}end
function p:isInvisible()return self.lease end
function p:setInvisible(value,forced)if not self.reject then self.lease=value end end
players[1]=p
S.onCommand("ZombieDisguise","ready",p,{nonce="standalone",backend="lua-invisibility-v1",protocol=2})
check(G.available(p),"medical absence does not block a ready backend")
check(G.grant(p,{actor=p,completed=true})and p.lease and next(p.blood)~=nil,"standalone grant has no medical API calls")
check(G.state(p).source==nil,"standalone grant creates no phantom medical exposure source")
S.fastTick();G.revoke(p,"test");p.blood={}
local visual=p.getHumanVisual
p.getHumanVisual=function(self)
 local v=visual(self);local set=v.setBlood;local writes=0
 v.setBlood=function(obj,part,value)writes=writes+1;if writes==2 then error("visual write rejected")end;set(obj,part,value)end
 return v
end
local rollbackOk,granted=pcall(G.grant,p,{actor=p,completed=true})
local restored=true;for _,value in pairs(p.blood)do if value~=0 then restored=false end end
check(rollbackOk and granted==false and not p.lease and restored,"visual failure rolls back standalone blood and native lease without medical API")
p.getHumanVisual=visual;p.blood={};p.reject=true
check(not G.grant(p,{actor=p,completed=true})and next(p.blood)==nil,"standalone backend rejection leaves blood unchanged");p.reject=false
server=false
check(#G.players()==1 and G.players()[1]==p,"single-player enumeration works without medicine")
server=true
check(#G.players()==1 and G.players()[1]==p,"dedicated enumeration works without medicine")
local bridge=p.setInvisible;p.setInvisible=nil
check(not G.available(p)and G.unavailableReason(p)=="Tooltip_ZD_Backend","independence never pretends the missing native backend is working")
p.setInvisible=bridge
client=true;server=false
local Client=dofile(MODLUA.."/client/ZD/Client.lua")
Client.reset();Client.request(p,true)
p.lease=true -- Native player replication can arrive before the authoritative mod lease.
Client.onServerCommand("ZombieDisguise","snapshot",{version=2,nonce=Client.nonce,epoch="standalone",revision=1,ready=true,leases={{version=2,epoch="standalone",revision=1,id=1,identity=G.identity(p),session="s1",serial=1,active=true,expires=hours+1}}})
check(p.lease and G.view(p).active,"client accepts validated snapshot without FieldMedicine")
Client.tick();check(p.lease,"client maintenance has no optional health dependency")
ms=ms+6000;Client.tick();check(not p.lease,"standalone client still expires stale native lease")
return failed
