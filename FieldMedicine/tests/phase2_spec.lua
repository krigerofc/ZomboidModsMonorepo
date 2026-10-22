local failed=0
local function check(v,m)if not v then failed=failed+1;print(" FAIL [phase2] "..m)end end
local loaded,R=pcall(require,"KFM/Risks")
check(loaded,"seasonal risk policy exists")
local dl,D=pcall(require,"KFM/Dynamics")
check(dl,"reversible trait policy exists")
if not loaded or not dl then return failed end
local Core=require "KFM/Core";local I=require "KFM/Illness";local C=require "KFM/Conditions";local cfg=Core.config({})
local function count(t)local n=0;for _ in pairs(t or {})do n=n+1 end;return n end
local winter=R.sources({month=1,temperature=-5,wetness=80,wind=0.7,outdoors=true,gloves=0,mask=0,skinExposure=1},cfg)
check(winter["env:cold:throat"] and winter["env:cold:Hand_L"] and winter["env:cold:Hand_R"],"wet winter cold exposes throat and existing hand regions")
check(not winter["env:mosquito"],"winter has no summer mosquito risk")
local summer=R.sources({month=7,temperature=31,wetness=80,humidity=0.8,wind=0.1,outdoors=true,gloves=0,mask=0,skinExposure=1},cfg)
check(summer["env:mosquito"] and summer["env:heat"],"summer wet heat has mosquito/heat risk profile")
local indoor=R.sources({month=7,temperature=24,wetness=0,outdoors=false,skinExposure=1},cfg)
check(not indoor["env:mosquito"],"shelter excludes mosquito exposure")
local gloves=R.sources({month=1,temperature=-5,wetness=20,wind=0.3,outdoors=true,gloves=1,mask=0.8,skinExposure=0.1},cfg)
check(not gloves["env:cold:Hand_L"] and gloves["env:cold:throat"].intensity<winter["env:cold:throat"].intensity,"warm gloves and appropriate mask reduce relevant exposure")
check(R.maskFactor("Base.Hat_SurgicalMask",100)<1 and R.maskFactor("Base.Hat_HockeyMask",100)==1,"real respiratory masks have bounded route-specific protection")
local cold=I.new()
for key,v in pairs(winter)do cold=I.addSource(cold,key,v)end
for n=1,5 do cold=I.advance(cold,{online=true},1/6,function()return 0 end,cfg)end
check(not cold.episodes["coldHands:Hand_L"],"cold injury never instant")
for n=1,20 do cold=I.advance(cold,{online=true},1/6,function()return 0 end,cfg)end
check(cold.episodes["coldHands:Hand_L"]~=nil,"sustained cold creates hand episode")
local paused=I.advance(cold,{online=false},100,function()error("offline roll")end,cfg)
check(paused.clock==cold.clock,"reconnect/offline cannot catch up cold injury")
check(C.DEFS.coldHands.symptoms.pain>0 and C.DEFS.coldHands.care[1]=="warming","cold fingers use native hand pain and a warming recovery path")
local mask=R.sources({month=7,temperature=31,wetness=80,humidity=0.8,outdoors=true,mask=0.9,skinExposure=1},cfg)
check(mask["env:mosquito"].intensity==summer["env:mosquito"].intensity,"face mask is not whole-body mosquito protection")
local s=D.new()
s=D.initialize(s,{respiratory=true,cardiac=true,stresssensitivity=true})
check(s.states.respiratoryVulnerability and s.states.cardiacVulnerability,"player-selected starting susceptibility seeds reversible states once")
local serial=s.serial;s=D.initialize(s,{respiratory=true,cardiac=true})
check(s.serial==serial,"starting registration never repeatedly seeds or awards points")
local noFx
s,noFx=D.advance(s,{online=false,panic=100,unhappiness=100},100,cfg)
check(s.clock==0 and noFx.fatigue==0,"dynamic states pause offline")
local mental=D.new()
for n=1,80 do mental=D.advance(mental,{online=true,panic=90,unhappiness=90,fatigue=0.95,asleep=false,safe=false},1/6,cfg)end
check(mental.states.hypervigilance and mental.states.lowMood and mental.states.sleepDisruption,"prolonged actual mental strain develops recoverable states")
local before=mental.states.hypervigilance.remaining
local treated,ok=D.treat(mental,"hypervigilance","calmRoutine",3)
check(ok and treated.states.hypervigilance.remaining<before and treated.states.hypervigilance.remaining>0,"routine care helps gradually")
local _,again=D.treat(treated,"hypervigilance","calmRoutine",3)
check(not again,"mental care cooldown prevents farming")
for n=1,1200 do treated=D.advance(treated,{online=true,panic=0,unhappiness=0,fatigue=0.2,asleep=true,safe=true,rest=true},1/6,cfg)end
check(treated.states.hypervigilance.phase=="resolved","mental state can recover and lose penalties")
local resilient=D.new()
for n=1,300 do resilient=D.advance(resilient,{online=true,panic=0,unhappiness=0,fatigue=0.1,asleep=true,safe=true,rest=true},1/6,cfg)end
check(resilient.states.resilience and resilient.states.resilience.benefit,"healthy routines acquire a bounded beneficial state")
local _,fx=D.advance(resilient,{online=true,safe=true,rest=true},1/6,cfg)
check(fx.enduranceRecovery>0 and fx.enduranceRecovery<=0.01,"recovered/resilient state has a finite real buff")
cfg.PsychologicalConditionsEnabled=false
local _,off=D.advance(mental,{online=true,panic=100,unhappiness=100},1/6,cfg)
check(off.psych==false,"mental-family switch suspends its additional effects")
return failed
