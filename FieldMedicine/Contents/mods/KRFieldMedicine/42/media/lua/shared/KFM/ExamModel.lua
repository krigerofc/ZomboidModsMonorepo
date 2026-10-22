-- Read-only presentation. Accept only the observer-filtered v3 protocol.
local C=require "KFM/Conditions"
local D=require "KFM/Dynamics"
local A=require "KFM/Assessment"
local M={}
local function safe(v)return tostring(v or ""):gsub("%c"," "):gsub("<","("):gsub(">",")")end
local function num(v)local n=tonumber(v);return n and n==n and n>=0 and n<1e10 and n or 0 end
function M.build(payload,translate,partName)
 payload=type(payload)=="table"and payload or {}
 local tr=translate or getText
 local function t(key,...)return safe(tr(key,...))end
 local function line(text)return " <LINE> <TEXT> "..text end
 local function heading(text)return " <LINE> <H2> "..text.." <TEXT> "end
 local function location(part)return part and safe(partName and partName(part)or part)or t("IGUI_KFM_Detail_GeneralRegion")end
 local state=type(payload.health)=="table"and payload.health.version==3 and payload.health or {}
 local function name(e)
  if e.confidence=="clinical"and C.DEFS[e.condition]then return t("IGUI_KFM_Condition_"..e.condition)end
  if e.confidence=="clinical"and D.DEFS[e.condition]then return t("IGUI_KFM_Trait_"..e.condition)end
  if e.confidence=="suspected"and({breathing=true,regional=true,wellbeing=true,general=true})[e.syndrome]then return t("IGUI_KFM_Syndrome_"..e.syndrome)end
  return t("IGUI_KFM_Observation")
 end
 local entries={}
 for key,e in pairs(type(state.episodes)=="table"and state.episodes or {})do
  if type(e)=="table"and({observations=true,suspected=true,clinical=true})[e.confidence]then
   local f={key=key,id=e.id,confidence=e.confidence,part=e.part,severity=num(e.severity),symptoms=type(e.symptoms)=="table"and e.symptoms or {},care=type(e.care)=="table"and e.care or {},syndrome=e.syndrome}
   if e.confidence=="clinical"and(C.DEFS[e.condition]or D.DEFS[e.condition])then f.condition=e.condition end
   entries[#entries+1]=f
  end
 end
 table.sort(entries,function(a,b)if a.severity~=b.severity then return a.severity>b.severity end;return tostring(a.key)<tostring(b.key)end)
 local overview=heading(t("IGUI_KFM_Detail_Overview"))..line(t("IGUI_KFM_Detail_Snapshot"))
 overview=overview..line(entries[1]and(entries[1].severity>=3 and t("IGUI_KFM_Detail_Urgent")or t("IGUI_KFM_Detail_ActiveCount",tostring(#entries)))or t("IGUI_KFM_Detail_NoFindings"))
 local regions=heading(t("IGUI_KFM_Detail_Regions"))
 local care=heading(t("IGUI_KFM_Detail_Care"))..line(t("IGUI_KFM_Detail_CareIntro"))
 for _,e in ipairs(entries)do
  local label=name(e).." - "..location(e.part)
  overview=overview..line(label)..line(t("IGUI_KFM_Confidence_"..e.confidence))
  regions=regions..heading(label)..line(t("IGUI_KFM_Confidence_"..e.confidence))..line(t("IGUI_KFM_Severity",tostring(e.severity)))
  for _,symptom in ipairs(A.SYMPTOMS)do if e.symptoms[symptom]==true then regions=regions..line(t("IGUI_KFM_Detail_Symptom_"..symptom))end end
  regions=regions..line(t("IGUI_KFM_Detail_Review"))
  care=care..heading(label)
  for _,kind in ipairs(e.care)do
   local spec=C.TREATMENTS[kind]
   if spec then care=care..line(t("ContextMenu_KFM_Care_"..kind))..line(t("IGUI_KFM_Detail_CareInterval",tostring(spec.interval),tostring(spec.level)))end
  end
  care=care..line(t("IGUI_KFM_Detail_Review"))
 end
 -- Native observations have already been filtered by Core's examination policy.
 for _,l in ipairs(payload.lines or {})do
  if type(l)=="table"and type(l.key)=="string"and l.key:match("^IGUI_KFM_Exam_")then
   local args=type(l.args)=="table"and l.args or {};overview=overview..line(t(l.key,args[1]and location(args[1])or nil))
  end
 end
 local guide=heading(t("IGUI_KFM_Detail_Guide"))
 for _,key in ipairs({"Climate","Mask","Blood","Medicine","Injuries","Mind","Progress","Warning"})do guide=guide..line(t("IGUI_KFM_Detail_Guide"..key))end
 guide=guide..line(t("IGUI_KFM_Exam_Disclaimer"))
 local history=heading(t("IGUI_KFM_History_Title"))..line(t("IGUI_KFM_History_Intro"))
 local events=type(state.history)=="table"and state.history or {}
 if #events==0 then history=history..line(t("IGUI_KFM_History_Empty"))end
 for n=1,math.min(20,#events)do
  local e=events[n]
  if type(e)=="table"then
   local at=tostring(math.floor(num(e.at)*10)/10)
   if e.kind=="care"and e.redacted==true then
    history=history..heading(t("IGUI_KFM_History_Care",at))..line(location(e.part))..line(t("IGUI_KFM_History_CareHidden"))
   elseif e.kind=="care"and(C.TREATMENTS[e.intervention]or e.intervention=="repellent")then
    history=history..heading(t("IGUI_KFM_History_Care",at))..line(location(e.part))..line(t("ContextMenu_KFM_Care_"..e.intervention))
    if type(e.resource)=="string"then history=history..line(t("IGUI_KFM_History_Resource",safe(e.resource)))end
   elseif e.kind=="exam"then
    history=history..heading(t("IGUI_KFM_History_Exam",at))..line(t("IGUI_KFM_History_Method",tostring(num(e.level))))
    if e.tools and e.tools.steth then history=history..line(t("IGUI_KFM_History_Steth"))end
    if e.tools and e.tools.tongue then history=history..line(t("IGUI_KFM_History_Tongue"))end
    for _,f in ipairs(type(e.findings)=="table"and e.findings or {})do
     history=history..line(name(f).." - "..location(f.part))..line(t("IGUI_KFM_Confidence_"..tostring(f.confidence)))
     for _,symptom in ipairs(A.SYMPTOMS)do if f.symptoms and f.symptoms[symptom]then history=history..line(t("IGUI_KFM_Detail_Symptom_"..symptom))end end
    end
   end
  end
 end
 return {title=payload.self and t("IGUI_KFM_Exam_TitleSelf")or t("IGUI_KFM_Exam_Title",safe(payload.patient)),priority=entries,tabs={
  {id="overview",label=t("IGUI_KFM_Detail_TabOverview"),text=overview},
  {id="regions",label=t("IGUI_KFM_Detail_TabRegions"),text=regions},
  {id="care",label=t("IGUI_KFM_Detail_TabCare"),text=care},
  {id="guide",label=t("IGUI_KFM_Detail_TabGuide"),text=guide},
  {id="history",label=t("IGUI_KFM_History_Tab"),text=history}}}
end
return M
