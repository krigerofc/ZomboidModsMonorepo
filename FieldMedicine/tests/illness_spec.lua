-- Pure episode policy; engine behavior has separate glue assertions.
local failures=0
local function check(v,m) if not v then failures=failures+1;print(" FAIL [illness]: "..m) end end
local loaded,I=pcall(require,"KFM/Illness")
check(loaded,"persistent shared illness engine exists")
if not loaded then return failures end
local C=require "KFM/Conditions"
local Core=require "KFM/Core"
local cfg=Core.config({})
local function step(s,ctx,h,rng)
 for i=1,math.floor(h*6+0.5) do s=I.advance(s,ctx,1/6,rng or function() return 0 end,cfg) end
 return s
end
check(#C.ILLNESS_IDS==14,"fourteen conditions including seasonal/cold expansion")
for _,id in ipairs(C.ILLNESS_IDS) do
 local d=C.DEFS[id]
 check(d and d.family and d.hours>0 and d.latency>=0 and #d.care>0 and d.symptoms,"each illness has cause, symptoms, care and recovery: "..id)
end
local s=I.new()
s=I.addSource(s,"blood:1",{kind="blood",part="Hand_L",intensity=1,open=true})
s=I.addSource(s,"blood:1",{kind="blood",part="Hand_L",intensity=1,open=true})
check(I.count(s.sources)==1,"stable exposure registration idempotent")
s=step(s,{online=true},0.8)
check(I.count(s.episodes)==0,"blood grace before 60 minutes")
s=step(s,{online=true},1.4)
check(I.count(s.episodes)==1,"one hourly exposure creates one wound episode")
local before=s.serial
s=step(s,{online=true},4)
check(s.serial==before,"no tick repeated episode or random reroll")
local age=s.clock
s=I.advance(s,{online=false},100,function()error("offline RNG")end,cfg)
check(s.clock==age,"offline pauses episodes and no catchup")
s=I.removeSource(s,"blood:1")
check(I.count(s.sources)==0 and I.count(s.episodes)==1,"washing removes future exposure, not episode")
local e=next(s.episodes);local ep=s.episodes[e]
local untreated=step(s,{online=true},100)
check(untreated.episodes[e].condition=="systemic","wound to deep to systemic evolves same episode")
check(untreated.serial==before,"complications do not stack episodes")
local treated=I.new();treated=I.seed(treated,"wound","wound:Hand_R","Hand_R",false)
local tid=next(treated.episodes)
local ok
treated,ok=I.treat(treated,tid,"antibacterial",10,cfg)
check(ok and treated.episodes[tid].remaining>0,"bacterial treatment helps without instant cure")
local again;treated,again=I.treat(treated,tid,"antibacterial",10,cfg)
check(not again,"treatment interval prevents stacking/XP")
local viral=I.seed(I.new(),"flu","contact:1",nil,false)
local vid=next(viral.episodes)
viral,ok=I.treat(viral,vid,"antibacterial",10,cfg)
check(not ok,"antibacterial is not viral cure")
local old=viral.episodes[vid].remaining
viral,ok=I.treat(viral,vid,"support",10,cfg)
check(ok and viral.episodes[vid].remaining>=old*0.6,"care capped at 40 percent combined recovery")
local resolved=step(viral,{online=true,rest=true,hydrated=true},120)
check(resolved.episodes[vid].phase=="resolved","viral care to complete recovery")
local native=I.seed(I.new(),"foodborne","native:food",nil,true)
native=step(native,{online=true,nativeFood=true},5)
local _,fx=I.advance(native,{online=true,nativeFood=true},1/6,function()return 0 end,cfg)
check(fx.thirst==0 and fx.endurance==0 and fx.health==0,"native food symptoms not duplicated")
local mild=I.seed(I.new(),"dermatitis","blood",nil,false)
mild=step(mild,{online=true},200)
local _,mf=I.advance(mild,{online=true},1/6,function()return 0 end,cfg)
check(mf.health==0,"mild skin conditions cannot kill by generic timer")
local severe=I.seed(I.new(),"systemic","complication",nil,false)
severe=step(severe,{online=true},60)
local _,fatal=I.advance(severe,{online=true},1/6,function()return 0 end,cfg)
check(fatal.health>0 and fatal.health<=0.5,"neglected severe systemic gradual mortality only")
cfg.NewDiseaseMortalityEnabled=false
local _,safe=I.advance(severe,{online=true},1/6,function()return 0 end,cfg)
check(safe.health==0,"sandbox mortality off removes extra health loss")
cfg.Enabled=false
local _,disabled=I.advance(severe,{online=true},1/6,function()return 0 end,cfg)
check(disabled.health==0 and disabled.endurance==0,"disabled engine imposes no additional effects")
cfg=Core.config({})
check(I.contactEligible({distance=1,sameFloor=true,barrier=false,source="flu",minutes=15},cfg),"respiratory sustained contact eligible")
check(not I.contactEligible({distance=1,sameFloor=false,barrier=false,source="flu",minutes=15},cfg),"cross-floor contact excluded")
check(not I.contactEligible({distance=1,sameFloor=true,barrier=true,source="flu",minutes=15},cfg),"barriers exclude contact")
check(not I.contactEligible({distance=1,sameFloor=true,barrier=false,source="fungal",minutes=15},cfg),"skin and injury not airborne")
cfg.ContactTransmissionEnabled=false
check(not I.contactEligible({distance=1,sameFloor=true,barrier=false,source="flu",minutes=15},cfg),"contact transmission off")
for _,id in ipairs({"burn","fracture","muscle","nerve"}) do
 local inj=I.seed(I.new(),id,"trauma:1","Hand_L",id=="burn" or id=="fracture")
 local key=next(inj.episodes); local care=C.DEFS[id].care[1]
 inj,ok=I.treat(inj,key,care,8,Core.config({}))
 check(ok and inj.episodes[key].remaining>0,"injury care meaningful without instant cure: "..id)
 check(step(inj,{online=true,rest=true,hydrated=true},1000).episodes[key].phase=="resolved","injury recovers: "..id)
end
local migrated=I.migrate({version=1,episodes={},sources={}})
check(migrated.version==2 and migrated.serial==0,"state migration stable")
local update=I.addSource(I.new(),"blood:test",{kind="blood",part="Hand_L",open=false,protected=false,intensity=0.2})
update=step(update,{online=true},0.5)
local oldHours=update.sources["blood:test"].hours
update=I.addSource(update,"blood:test",{kind="blood",part="Hand_L",open=true,protected=true,intensity=1})
check(update.sources["blood:test"].open and update.sources["blood:test"].protected and update.sources["blood:test"].intensity==1 and update.sources["blood:test"].hours==oldHours,"source metadata refresh keeps deterministic time windows")
local cf=Core.config({})
check(I.contactEligible({distance=1,sameFloor=true,barrier=false,source="viral",route="care",touch=true,minutes=0},cf),"viral spreads by actual unprotected care contact")
check(not I.contactEligible({distance=1,sameFloor=true,barrier=false,source="viral",route="air",minutes=60},cf),"viral gastroenteritis is not airborne")

local severity=I.seed(I.new(),"coldHands","fixture","Hand_L",false)
severity.episodes["coldHands:Hand_L"].age=5
local zeroCfg=Core.config({DiseaseSeverity=0})
local _,zeroFx=I.advance(severity,{online=true},1/6,function()return 0 end,zeroCfg)
check((zeroFx.pain.Hand_L or 0)==0,"zero severity suspends additional regional pain")


local scaleCfg=Core.config({DiseaseSeverity=2})
cfg=Core.config({})
local _,baseFatal=I.advance(severe,{online=true},1/6,function()return 0 end,cfg)
local _,twiceFatal=I.advance(severe,{online=true},1/6,function()return 0 end,scaleCfg)
check(baseFatal.health>0 and math.abs(twiceFatal.health-baseFatal.health*2)<0.000001,"severity applies mortality multiplier once")
return failures
