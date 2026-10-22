local failed=0
local function check(v,m)if not v then failed=failed+1;print(" FAIL [local effects] "..m)end end
local now=1000;local sounds={}
SandboxVars={KFM={}}
getTimestampMs=function()return now end
getNumActivePlayers=function()return 2 end
getPlayerScreenLeft=function(i)return i*600 end;getPlayerScreenTop=function()return 0 end
getPlayerScreenWidth=function()return 600 end;getPlayerScreenHeight=function()return 600 end
local function player(id,slot)
 local p={id=id,slot=slot,md={},blocked=false,dead=false}
 function p:getOnlineID()return self.id end;function p:getPlayerNum()return self.slot end;function p:getModData()return self.md end
 function p:isDead()return self.dead end;function p:getVehicle()return nil end
 function p:isBlockMovement()return self.blocked end;function p:setBlockMovement(v)self.blocked=v end
 function p:reportEvent(v)self.event=v end;function p:nullifyAiming()self.aimStopped=true end
 return p
end
local a,b=player(10,0),player(11,1)
getSpecificPlayer=function(i)return i==0 and a or i==1 and b or nil end
getSoundManager=function()return {playUISound=function(_,id)sounds[#sounds+1]=id end}end
addSound=function()error("no world sound for local perception")end
sendClientCommand=function()error("no local FX command to server")end
ISTimedActionQueue={clear=function(p)p.interrupted=true end}
ISPanel={}
function ISPanel:derive()local c={};c.__index=c;setmetatable(c,{__index=self});return c end
function ISPanel.new(self,x,y,w,h)return setmetatable({x=x,y=y,width=w,height=h},self)end
function ISPanel:initialise()end;function ISPanel:addToUIManager()end;function ISPanel:removeFromUIManager()self.removed=true end
Events=setmetatable({},{__index=function(t,k)local e={Add=function()end};rawset(t,k,e);return e end})
package.preload["ISUI/ISPanel"]=function()return ISPanel end
local ok,E=pcall(dofile,MODLUA.."/client/KFM/HealthEffects.lua")
check(ok,"real finite local perception adapter exists")
if not ok then return failed end
check(E.receive({id=11,seq=1,kind="door"})and #sounds==1,"owning player receives a verified native local door sound")
check(E.active["10"]==nil and E.active["11"].panel.x==600,"only matching split-screen viewport receives effect")
check(not E.receive({id=99,seq=1,kind="door"})and #sounds==1,"unaffected remote observer cannot receive local sound")
check(not E.receive({id=11,seq=1,kind="door"})and #sounds==1,"same effect sequence is not replayed on reconnect")
check(not E.receive({id=11,seq=2,kind="arbitrarySound"})and #sounds==1,"no arbitrary audio key accepted")
E.receive({id=10,seq=1,kind="faint"})
check(a.blocked and a.interrupted and a.event=="EventSitOnGround"and a.aimStopped,"blackout briefly interrupts action/movement with native seated event")

E.receive({id=10,seq=2,kind="door"})
check(a.blocked and E.active["10"].kind=="faint","simultaneous lower-priority perception cannot cancel blackout")
SandboxVars.KFM.PsychologicalEffectsEnabled=false
E.receive({id=10,seq=3,kind="flicker"})
check(a.blocked and E.active["10"].kind=="faint","disabled psychological packet cannot release unrelated owned blackout")
SandboxVars.KFM.PsychologicalEffectsEnabled=true

now=5000;E.update()
check(not a.blocked,"owned faint movement block independently expires")
b.blocked=true
E.receive({id=11,seq=3,kind="faint"})
now=9000;E.update()
check(b.blocked,"pre-existing movement restriction is preserved")
E.receive({id=11,seq=4,kind="flicker"})
SandboxVars.KFM.PsychologicalEffectsEnabled=false;E.update()
check(E.active["11"]==nil,"psych effects disabled clears only owned perception")
return failed
