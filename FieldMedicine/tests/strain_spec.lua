local failed=0
local function check(v,m)if not v then failed=failed+1;print(" FAIL [strain] "..m)end end
local loaded,S=pcall(require,"KFM/Strain")
check(loaded,"regional sustained-work policy exists")
if not loaded then return failed end
local I=require "KFM/Illness";local Core=require "KFM/Core";local cfg=Core.config({})
local s={};local hits={}
for n=1,24 do s,hits=S.observe(s,{online=true,running=true,moving=true,exhausted=false,stiff=true},1/6)end
check(#hits==0 and next(s.doses)==nil,"ordinary running/exercise stiffness alone never becomes strain")
s={}
for n=1,2 do s,hits=S.observe(s,{online=true,moving=true,running=true,exhausted=true,overloaded=true},1/6)end
check(#hits==0,"brief exhausted load does not instantly injure")
local seen={}
for n=1,8 do s,hits=S.observe(s,{online=true,moving=true,running=true,exhausted=true,overloaded=true},1/6);for _,v in ipairs(hits)do seen[v.part]=true end end
check(seen.Torso_Lower and seen.LowerLeg_L and seen.Foot_R,"sustained movement creates lower torso, leg and foot tracks using real regions")
local before=s.clock
s,hits=S.observe(s,{online=false,moving=true,running=true,exhausted=true,overloaded=true},100)
check(s.clock==before and #hits==0,"offline strain cannot catch up")
s={};seen={}
for n=1,5 do s,hits=S.observe(s,{online=true,exhausted=true,toolHits=16,bothHands=true},1/6);for _,v in ipairs(hits)do seen[v.part]=true end end
check(seen.ForeArm_R and seen.ForeArm_L,"repeated exhausted two-hand tool work affects forearms")
s={};seen={}
for n=1,5 do s,hits=S.observe(s,{online=true,exhausted=true,combatHits=16},1/6);for _,v in ipairs(hits)do seen[v.part]=true end end
check(seen.UpperArm_R and not seen.UpperArm_L,"weapon effort uses working arm without inventing damage in the other arm")
local function effect(part,ctx)
 local x=I.seed(I.new(),"muscle","fixture",part,false);x.episodes["muscle:"..part].age=3
 return select(2,I.advance(x,ctx,1/6,function()return 0 end,cfg))
end
local arm=effect("ForeArm_R",{online=true})
check((arm.pain.ForeArm_R or 0)>10 and arm.endurance==0,"arm strain reaches proven native pain penalty without a duplicate combat drain")
local resting=effect("LowerLeg_L",{online=true,rest=true})
local walking=effect("LowerLeg_L",{online=true,moving=true})
check(resting.endurance==0 and walking.endurance>0 and not next(walking.pain),"leg strain costs exertion only in movement and avoids unproven duplicate speed penalties")
local back=effect("Torso_Lower",{online=true,moving=true,overloaded=true})
check(back.fatigue>0 and back.endurance==0,"lower torso strain adds bounded overload fatigue")
local native=effect("ForeArm_R",{online=true,nativeRegions={ForeArm_R=true}})
check(not next(native.pain) and native.endurance==0,"native regional injury takes precedence over additional strain penalties")
local x=I.seed(I.new(),"muscle","fixture","Foot_R",false)
local _,ok=I.treat(x,"muscle:Foot_R","muscleRest",0,cfg)
check(ok,"distinct rest care is available for true strain")
return failed
