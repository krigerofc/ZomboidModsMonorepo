-- Gameplay tuning in simulated hours. No pathogen/Knox identification.
local C={}
C.ILLNESS_IDS={"flu","viral","foodborne","wound","deep","systemic","respiratory","conjunctivitis","dermatitis","fungal"}
C.DEFS={
 flu={family="resp",hours=72,latency=6,care={"support"},symptoms={endurance=0.025,thirst=0.01},next="respiratory",neglect=60},
 viral={family="gastro",hours=48,latency=4,care={"support"},symptoms={thirst=0.025,endurance=0.01}},
 foodborne={family="food",hours=36,latency=1,care={"support"},symptoms={thirst=0.025,endurance=0.015}},
 wound={family="wound",hours=48,latency=2,care={"hygiene","antibacterial"},symptoms={pain=3},next="deep",neglect=24},
 deep={family="wound",hours=96,latency=0,care={"antibacterial"},symptoms={pain=7,endurance=0.025},next="systemic",neglect=36},
 systemic={family="wound",hours=144,latency=0,care={"antibacterial","support"},symptoms={endurance=0.04,thirst=0.02},fatal=true,neglect=36},
 respiratory={family="resp",hours=120,latency=0,care={"antibacterial","support"},symptoms={endurance=0.045,thirst=0.015},fatal=true,neglect=48},
 conjunctivitis={family="eye",hours=36,latency=2,care={"hygiene"},symptoms={pain=2,endurance=0.005}},
 dermatitis={family="skin",hours=48,latency=4,care={"hygiene","topical"},symptoms={pain=2}},
 fungal={family="fungal",hours=120,latency=12,care={"dry","topical"},symptoms={pain=2}},
 burn={family="burn",hours=96,latency=0,care={"burnCare"},symptoms={pain=4}},
 fracture={family="fracture",hours=168,latency=0,care={"stabilize"},symptoms={pain=5}},
 muscle={family="muscle",hours=72,latency=1,care={"muscleRest","rehab","support"},symptoms={}},
 nerve={family="nerve",hours=240,latency=2,care={"rehab"},symptoms={pain=5,endurance=0.025}},
}
C.TREATMENTS={
 support={interval=4,duration=6,quality=0.08,level=0},
 hygiene={interval=4,duration=8,quality=0.12,level=0},
 antibacterial={interval=8,duration=12,quality=0.18,level=2},
 topical={interval=12,duration=18,quality=0.15,level=0},
 dry={interval=4,duration=8,quality=0.10,level=0},
 burnCare={interval=8,duration=12,quality=0.16,level=1},
 stabilize={interval=24,duration=48,quality=0.16,level=1},
 rehab={interval=12,duration=18,quality=0.12,level=2},
}
C.DEFS.soreThroat={family="throat",hours=36,latency=2,care={"throatRemedy","support"},symptoms={cough=1,fatigue=0.01}}
C.DEFS.mosquitoFever={family="mosquito",hours=72,latency=8,care={"support","feverCare"},symptoms={fatigue=0.025,thirst=0.02,blur=0.12}}
C.DEFS.heatExhaustion={family="heat",hours=24,latency=1,care={"cooling","support"},symptoms={fatigue=0.03,thirst=0.03,blur=0.2},faint=true}
C.DEFS.coldHands={family="coldHands",hours=72,latency=1,care={"warming","protectiveDressing"},symptoms={pain=12},severeAfter=24}
C.DEFS.flu.symptoms.cough=1;C.DEFS.flu.symptoms.fatigue=0.015
C.DEFS.respiratory.symptoms.cough=2;C.DEFS.respiratory.symptoms.fatigue=0.025
C.DEFS.conjunctivitis.symptoms.blur=0.2
C.DEFS.systemic.symptoms.fatigue=0.03;C.DEFS.systemic.symptoms.blur=0.2;C.DEFS.systemic.faint=true
for _,id in ipairs({"soreThroat","mosquitoFever","heatExhaustion","coldHands"})do C.ILLNESS_IDS[#C.ILLNESS_IDS+1]=id end
C.TREATMENTS.throatRemedy={interval=4,duration=6,quality=0.12,level=0}
C.TREATMENTS.feverCare={interval=6,duration=8,quality=0.1,level=0}
C.TREATMENTS.cooling={interval=2,duration=4,quality=0.12,level=0}
C.TREATMENTS.warming={interval=1,duration=2,quality=0.1,level=0}
C.TREATMENTS.protectiveDressing={interval=8,duration=12,quality=0.12,level=1}
C.TREATMENTS.inhaler={interval=6,duration=8,quality=0.12,level=1}
C.TREATMENTS.cardiacSupport={interval=8,duration=10,quality=0.1,level=2}
C.TREATMENTS.pacedRehab={interval=12,duration=18,quality=0.12,level=1}
C.TREATMENTS.calmRoutine={interval=6,duration=8,quality=0.08,level=0}
C.TREATMENTS.counseling={interval=12,duration=18,quality=0.12,level=2}
C.TREATMENTS.journaling={interval=8,duration=12,quality=0.1,level=0}
C.TREATMENTS.sleepRoutine={interval=12,duration=16,quality=0.1,level=0}
C.TREATMENTS.muscleRest={interval=6,duration=6,quality=0.06,level=0}

C.DEFS.soreThroat.switch="SeasonalIllnessEnabled"
C.DEFS.mosquitoFever.switch="MosquitoIllnessEnabled"
C.DEFS.heatExhaustion.switch="SeasonalIllnessEnabled"
C.DEFS.coldHands.switch="ColdInjuryEnabled"
C.DEFS.coldHands.symptoms.aim=true;C.DEFS.coldHands.symptoms.combat=true
for _,id in ipairs({"conjunctivitis","heatExhaustion","mosquitoFever","systemic"})do C.DEFS[id].symptoms.vision=true end
C.DEFS.systemic.symptoms.nausea=true;C.DEFS.systemic.symptoms.fainting=true;C.DEFS.heatExhaustion.symptoms.fainting=true
function C.symptomsFor(id,part)
 if id=="muscle"then return require("KFM/Strain").symptoms(part)end
 return C.DEFS[id]and C.DEFS[id].symptoms or {}
end
return C
