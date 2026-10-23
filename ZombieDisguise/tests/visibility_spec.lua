local failed=0
local function check(v,m)if not v then failed=failed+1;print(" FAIL [visibility] "..m)end end
local ms,hours=1000,100
local client,server,debug=false,true,false
isClient=function()return client end;isServer=function()return server end;getDebug=function()return debug end
getTimestampMs=function()return ms end;getGameTime=function()return{getWorldAgeHours=function()return hours end}end
SandboxVars={ZombieDisguise={}}
Events=setmetatable({},{__index=function(t,k)local e={Add=function()end};rawset(t,k,e);return e end})
local ok,B=pcall(require,"ZD/Concealment")
check(ok,"built-in invisibility adapter loads without native companion")
if not ok then return failed end
local function actor()
 local p={md={},invisible=false,writes=0,dead=false,running=false,attack=false}
 function p:getModData()return self.md end;function p:isInvisible()return self.invisible end
 function p:setInvisible(value,forced)self.writes=self.writes+1;self.forced=forced;if self.throw then error("setter rejected")end;if not self.reject then self.invisible=value end end
 function p:isDead()return self.dead end;function p:isRunning()return self.running end;function p:isSprinting()return false end;function p:isAttacking()return self.attack end
 return p
end
local p=actor()
check(B.available(p),"MP backend needs only public built-in methods")
check(B.apply(p,hours+1)and p.invisible and p.forced,"grant sets verified public invisibility without a native bridge")
check(B.apply(p,hours+1)and p.writes==1,"refresh does not repeatedly overwrite the flag")
check(B.clear(p)and not p.invisible,"revoke clears only owned invisibility")
p.invisible=true;local count=p.writes
check(not B.apply(p,hours+1),"pre-existing invisibility is not claimed as camouflage")
check(not B.apply(p,hours+1,true),"replica hint cannot adopt foreign invisibility on authoritative server")
check(B.clear(p)and p.invisible and p.writes==count,"cleanup preserves invisibility owned by another system")
p=actor();p.reject=true
check(not B.apply(p,hours+1)and not p.invisible,"a setter that silently refuses cannot grant camouflage")
p.reject=false;p.throw=true
check(not B.apply(p,hours+1)and not p.invisible,"a throwing setter cannot grant camouflage")
p=actor()
for _,expiry in ipairs({0,hours,hours+9,math.huge})do check(not B.apply(p,expiry),"invalid expiry rejected")end
check(not B.apply(p,0/0),"NaN expiry rejected")
check(p.writes==0,"invalid bounds never touch visibility")
B.apply(p,hours+1);ms=ms+5000;B.tick()
check(not p.invisible,"lost heartbeat clears owned invisibility after five real seconds")
p=actor();B.apply(p,hours+1);hours=hours+2;B.tick();check(not p.invisible,"world expiry clears visibility")
p=actor();B.apply(p,hours+1);ms=ms-1;B.tick();check(not p.invisible,"wall-clock rollback clears visibility")
p=actor();B.apply(p,hours+1);p.running=true;B.tick();check(not p.invisible,"running clears visibility immediately")
p=actor();B.apply(p,hours+1);p.attack=true;B.tick();check(not p.invisible,"attacking clears visibility immediately")
p=actor();B.apply(p,hours+1);p.dead=true;B.tick();check(not p.invisible,"death clears visibility")
p=actor();B.apply(p,hours+1);SandboxVars.ZombieDisguise.Enabled=false;B.tick();check(not p.invisible,"sandbox disable clears visibility");SandboxVars.ZombieDisguise.Enabled=true
p=actor();B.apply(p,hours+1);p.invisible=false;count=p.writes
check(not B.apply(p,hours+1)and p.writes==count,"an external flag change is not overwritten by refresh")
p=actor();B.apply(p,hours+1);B.reset();check(not p.invisible,"disconnect/world/save cleanup clears owned flags")
p=actor();p.md.ZD_invisibility={version=1,owned=true};p.invisible=true
check(B.clear(p)and not p.invisible,"persisted ownership marker permits cleanup after reconnect")
-- Prefer the exact public API used by the vanilla debug menu when present.
p=actor();p.ghostWrites=0
function p:isGhostMode()return self.invisible end
function p:setGhostMode(value,forced)self.ghostWrites=self.ghostWrites+1;self.ghostForced=forced;if not self.reject then self.invisible=value end end
check(B.available(p)and B.apply(p,hours+1)and p.invisible and p.ghostWrites==1 and p.writes==0 and p.ghostForced,"grant prefers the same ghost-mode API as the debug menu")
check(B.clear(p)and not p.invisible and p.ghostWrites==2 and p.writes==0,"cleanup uses ghost mode without rewriting the alternate API")
p.reject=true;check(not B.apply(p,hours+1)and not p.invisible,"ghost setter refusal cannot grant camouflage")
p=actor();p.isInvisible=nil;p.setInvisible=nil
function p:isGhostMode()return self.invisible end
function p:setGhostMode(value,forced)self.invisible=value end
check(B.available(p)and B.apply(p,hours+1)and p.invisible,"ghost-only public API is supported");B.clear(p)
client=true;server=false
p=actor();p.invisible=true
check(not B.apply(p,hours+1),"client cannot adopt without an authorized lease")
check(B.apply(p,hours+1,true)and B.active(p),"trusted client lease may adopt an already replicated vanilla flag")
check(B.clear(p)and not p.invisible,"adopted server flag is cleared on lease revocation")
client=false
p=actor()
check(not B.available(p)and not B.apply(p,hours+1)and p.writes==0,"ordinary non-debug SP is blocked before touching an unsupported cheat")
debug=true;check(B.available(p)and B.apply(p,hours+1),"debug SP uses the same explicitly supported adapter");B.clear(p)
return failed
