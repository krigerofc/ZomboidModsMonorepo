local failed=0
local function check(v,m)if not v then failed=failed+1;print("FAIL clinical: "..m)end end
local ok,A=pcall(require,"KFM/Assessment")
check(ok,"server assessment policy exists")
if not ok then return failed end
local H=require "KFM/History"
local raw={id=17,condition="respiratory",phase="symptomatic",severity=3,part="Torso_Upper",remaining=119,cause="secret",treatments={}}
local low=A.finding(raw,0,{},false,false)
check(low.condition==nil and low.phase==nil and low.remaining==nil and low.cause==nil,"observations contain no hidden diagnosis, phase, timer or cause")
check(low.confidence=="observations" and low.symptoms.cough and low.severity==3,"observations retain symptoms and severity")
check(A.finding(raw,4,{},false,false).confidence=="suspected","intermediate examiner receives syndrome")
check(A.finding(raw,8,{},false,false).condition==nil,"missing instrument downgrades respiratory examiner")
check(A.finding(raw,8,{steth=true},false,false).condition=="respiratory","genuine instrument enables respiratory assessment")
local regional={condition="muscle",phase="symptomatic",part="Hand_L",severity=2}
check(A.finding(regional,8,{},false,false).condition=="muscle","regional inspection needs skill, no unrelated instrument")
local throat={condition="soreThroat",phase="symptomatic",severity=1}
check(A.finding(throat,8,{tongue=true},false,false).condition=="soreThroat","throat assessment uses tongue depressor")
raw.phase="latent";check(A.finding(raw,10,{steth=true},false,false)==nil,"latent episodes never exposed")
local s=H.new()
local f={confidence="observations",part="Torso_Upper",symptoms={cough=true},severity=2}
s=H.exam(s,"a",10,{f},0,{})
s=H.exam(s,"a",10.5,{f},0,{})
check(#s.events==1,"identical examination coalesces within simulated hour")
s=H.exam(s,"b",10.5,{f},0,{})
check(#s.events==2,"different observer has distinct examination")
f.condition="respiratory";check(s.events[1].findings[1].condition==nil,"history owns immutable findings at recording time")
for n=1,90 do s=H.care(s,n,"Hand_L","support","Base.KFM_SupportSachet")end
check(#s.events==64 and #H.view(s,"a")==20,"history persistence bounded64, view latest20")
local migrated=H.migrate({version=0,events={{kind="care",at=3,part="Hand_L",intervention="support",resource="Base.KFM_SupportSachet",secret={condition="viral"}}}})
check(migrated.events[1].secret==nil and migrated.version==1,"old history whitelisted primitive migration")
local before=H.new();before=H.exam(before,"doctor",1,{{confidence="clinical",condition="respiratory",symptoms={cough=true}}},8,{steth=true})
check(#H.view(before,"patient")==0 and #H.view(before,"doctor")==1,"observer cannot inherit another examiner's diagnosis")

local privacy=H.care(H.new(),10,"Torso_Upper","inhaler","Base.KFM_BreathingAid","performer")
local hidden=H.view(privacy,"uninformed",false)[1]
check(hidden and hidden.redacted==true and hidden.intervention==nil and hidden.resource==nil,"unexamined other observer receives only a redacted specific-care event")
check(H.view(privacy,"performer",false)[1].intervention=="inhaler","performing doctor retains factual medication record")
check(H.view(privacy,"patient",true)[1].resource=="Base.KFM_BreathingAid","patient knows medication actually administered")

return failed
