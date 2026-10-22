-- Bounded workload doses in simulated hours. Fitness stiffness is never an injury source.
local S={}
S.REGIONS={UpperArm_L="arm",UpperArm_R="arm",ForeArm_L="arm",ForeArm_R="arm",
 UpperLeg_L="leg",UpperLeg_R="leg",LowerLeg_L="leg",LowerLeg_R="leg",Foot_L="leg",Foot_R="leg",Torso_Lower="back"}
function S.observe(old,c,elapsed)
 local s={version=1,clock=old.clock or 0,serial=old.serial or 0,doses={}}
 for k,v in pairs(old.doses or {})do if S.REGIONS[k]then s.doses[k]=v end end
 local injuries={}
 if not c.online then return s,injuries end
 local dt=math.max(0,math.min(1/6,tonumber(elapsed)or 0));s.clock=s.clock+dt
 local loads={}
 if c.exhausted then
  if (c.toolHits or 0)>=12 then loads.ForeArm_R=2/3;if c.bothHands then loads.ForeArm_L=2/3 end end
  if (c.combatHits or 0)>=12 then loads.UpperArm_R=2/3;if c.bothHands then loads.UpperArm_L=2/3 end end
  if c.moving and c.running then
   loads.LowerLeg_L=2/3;loads.LowerLeg_R=2/3
   loads.Foot_L=1;loads.Foot_R=1
  end
  if c.moving and c.overloaded then loads.Torso_Lower=0.5 end
 end
 for part in pairs(S.REGIONS)do
  local threshold=loads[part]
  local dose=threshold and ((s.doses[part]or 0)+dt)or math.max(0,(s.doses[part]or 0)-dt*2)
  if threshold and dose+0.000001>=threshold then
   s.serial=s.serial+1;injuries[#injuries+1]={part=part,cause="workload:"..part..":"..s.serial};dose=0
  end
  if dose>0 then s.doses[part]=dose else s.doses[part]=nil end
 end
 return s,injuries
end
function S.effects(part,c,relief,dt)
 local fx={pain=0,endurance=0,fatigue=0}
 if c.nativeRegions and c.nativeRegions[part]then return fx end
 local region=S.REGIONS[part]
 if region=="arm"then
  fx.pain=12*relief -- Native arm hit/aim pain, rather than a second combat multiplier.
  if c.toolWorking then fx.fatigue=0.01*dt*relief end
 elseif region=="leg"and c.moving then fx.endurance=0.02*dt*relief
 elseif region=="back"and c.moving and c.overloaded then fx.fatigue=0.015*dt*relief end
 return fx
end
function S.symptoms(part)
 local region=S.REGIONS[part]
 if region=="arm"then return {pain=12,aim=true,combat=true,toolEffort=true}
 elseif region=="leg"then return {endurance=0.02,mobility=true}
 elseif region=="back"then return {fatigue=0.015,overload=true}end
 return {}
end
return S
