local C={VERSION=2,PARTS={"Hand_L","Hand_R","ForeArm_L","ForeArm_R","UpperArm_L","UpperArm_R","Torso_Upper","Torso_Lower","Head","Neck","Groin","UpperLeg_L","UpperLeg_R","LowerLeg_L","LowerLeg_R","Foot_L","Foot_R"}}
function C.config(sv)
 sv=sv or {}
 return {Enabled=sv.Enabled~=false,DurationMinutes=math.max(10,math.min(480,tonumber(sv.DurationMinutes) or 120)),RequiredCoverage=math.max(0.1,math.min(1,tonumber(sv.RequiredCoverage) or 0.65)),BreakOnRun=sv.BreakOnRun~=false,BreakOnAttack=sv.BreakOnAttack~=false}
end
return C
