local failures=0
local function check(c,m)if not c then failures=failures+1;print("FAIL exam: "..m)end end
local E=require "KFM/ExamModel"
local function text(k,...)local s=k;for _,v in ipairs({...})do s=s.." | "..tostring(v)end;return s end
local function part(p)return "BODY:"..p end
local empty=E.build({self=true,health={version=3,episodes={}}},text,part)
check(#empty.tabs==5,"fifth history section")
local state={version=3,episodes={e1={id=1,confidence="observations",severity=3,part="ForeArm_R",symptoms={pain=true,toolEffort=true},care={"muscleRest"},condition="muscle",remaining=72,phase="recovering"},
 e2={id=2,confidence="clinical",severity=2,part="Torso_Upper",condition="respiratory",symptoms={cough=true},care={"support","antibacterial"}}},
 history={{kind="care",at=12,part="Hand_L",intervention="support",resource="Base.KFM_SupportSachet"},{kind="exam",at=10,level=0,tools={},findings={{confidence="observations",severity=2,part="Hand_L",symptoms={pain=true}}}}}}
local payload={self=true,patient="<RGB:1,0,0>Sam",health=state}
local model=E.build(payload,text,part)
check(model.priority[1].condition==nil,"observation ignores accidentally supplied exact diagnosis")
check(model.tabs[2].text:find("IGUI_KFM_Detail_Symptom_toolEffort",1,true),"observable regional function appears")
check(model.tabs[2].text:find("IGUI_KFM_Confidence_observations",1,true),"confidence explicit")
check(not model.tabs[2].text:find("Remaining",1,true)and not model.tabs[2].text:find("Phase_",1,true),"no secret countdown or phase")
check(model.tabs[3].text:find("ContextMenu_KFM_Care_muscleRest",1,true)and not model.tabs[3].text:find("ContextMenu_KFM_Care_rehab",1,true),"only server-offered care is rendered")
check(model.tabs[3].text:find("ContextMenu_KFM_Care_antibacterial",1,true),"supported clinical care remains usable")
check(model.tabs[5].text:find("Base.KFM_SupportSachet",1,true)and model.tabs[5].text:find("IGUI_KFM_History_Exam",1,true),"history contains actual resource and exam")
check(state.episodes.e1.condition=="muscle","presentation never mutates source")
local legacy=E.build({health={episodes={["wound:Hand_L"]={condition="systemic",phase="complication",remaining=150}}}},text,part)
check(not legacy.tabs[1].text:find("Condition_systemic",1,true)and #legacy.priority==0,"legacy raw health is never rendered")
local invalid=E.build({health={version=99,episodes={secret={condition="viral"}}}},text,part)
check(#invalid.priority==0,"unknown protocol safely empty")
local high=E.build({health={version=3,episodes={e3={confidence="suspected",syndrome="breathing",severity=2,symptoms={cough=true},care={}}}}},text,part)
check(high.tabs[1].text:find("IGUI_KFM_Syndrome_breathing",1,true),"suspected syndrome is localized")
return failures
