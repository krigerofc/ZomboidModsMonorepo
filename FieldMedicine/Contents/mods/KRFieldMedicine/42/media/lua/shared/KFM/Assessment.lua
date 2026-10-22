-- Server-side observer projection. Never serialize raw clinical state.
local C=require "KFM/Conditions"
local D=require "KFM/Dynamics"
local A={VERSION=3}
A.SYMPTOMS={"pain","fatigue","endurance","thirst","cough","vision","nausea","fainting","aim","combat","toolEffort","mobility","overload","sleep","mood","alertness"}
local dynamicSymptoms={respiratoryVulnerability={endurance=true},cardiacVulnerability={fatigue=true,endurance=true},hypervigilance={alertness=true,fatigue=true},lowMood={mood=true,fatigue=true},sleepDisruption={sleep=true,fatigue=true},resilience={alertness=true}}
function A.tool(condition)
 if condition=="soreThroat"then return "tongue"end
 if condition=="flu"or condition=="respiratory"or condition=="respiratoryVulnerability"or condition=="cardiacVulnerability"then return "steth"end
end
A.GENERIC_CARE={repellent=true,support=true,hygiene=true,dry=true,warming=true,cooling=true,muscleRest=true,calmRoutine=true,sleepRoutine=true}
function A.finding(e,level,tools,dynamic,known)
 if type(e)~="table"or e.phase=="resolved"or e.phase=="latent"then return nil end
 local def=(dynamic and D.DEFS or C.DEFS)[e.condition]
 if not def then return nil end
 level=math.max(0,math.min(10,tonumber(level)or 0));tools=tools or {}
 local required=A.tool(e.condition)
 local clinical=known or level>=6 and(not required or tools[required]==true)
 local confidence=clinical and "clinical"or(level>=3 and "suspected"or "observations")
 local out={part=e.part,severity=e.severity or 1,confidence=confidence,symptoms={},care={}}
 local symptoms=dynamic and dynamicSymptoms[e.condition]or C.symptomsFor(e.condition,e.part)
 for _,id in ipairs(A.SYMPTOMS)do
  local value=symptoms and symptoms[id]
  if value==true or type(value)=="number"and value>0 then out.symptoms[id]=true end
 end
 if confidence=="suspected"then
  out.syndrome=out.symptoms.cough and "breathing"or(out.symptoms.toolEffort or out.symptoms.mobility or out.symptoms.overload)and "regional"or(out.symptoms.sleep or out.symptoms.mood or out.symptoms.alertness)and "wellbeing"or "general"
 elseif clinical then
  out.condition=e.condition
  if dynamic then out.labelKey="IGUI_KFM_Trait_"..e.condition;out.benefit=e.benefit==true end
 end
 for _,kind in ipairs(def.care or {})do
  if clinical or A.GENERIC_CARE[kind]then out.care[#out.care+1]=kind end
 end
 return out
end
return A
