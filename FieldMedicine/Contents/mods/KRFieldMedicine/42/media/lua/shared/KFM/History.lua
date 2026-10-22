-- Bounded, immutable-at-record-time primitive clinical history.
local A=require "KFM/Assessment"
local C=require "KFM/Conditions"
local D=require "KFM/Dynamics"
local H={VERSION=1}
local function str(v,max)if type(v)=="string"then return string.sub(v:gsub("%c"," "),1,max or 80)end end
local function num(v) v=tonumber(v);return v and v==v and v>=0 and v<1e10 and v or 0 end
local function finding(v)
 if type(v)~="table"then return nil end
 local confidence=v.confidence
 if confidence~="observations"and confidence~="suspected"and confidence~="clinical"then return nil end
 local out={confidence=confidence,part=str(v.part,24),severity=math.min(3,num(v.severity)),symptoms={}}
 for _,id in ipairs(A.SYMPTOMS)do if v.symptoms and v.symptoms[id]==true then out.symptoms[id]=true end end
 if confidence=="clinical"and(C.DEFS[v.condition]or D.DEFS[v.condition])then out.condition=v.condition end
 if confidence=="suspected"and({breathing=true,regional=true,wellbeing=true,general=true})[v.syndrome]then out.syndrome=v.syndrome end
 return out
end
function H.new()return {version=1,events={}}end
local function append(s,event)
 s.events[#s.events+1]=event
 while #s.events>64 do table.remove(s.events,1)end
 return s
end
function H.migrate(old)
 local s=H.new()
 if type(old)~="table"or type(old.events)~="table"then return s end
 -- Visit only a bounded suffix, even for oversized legacy saves.
 local start=math.max(1,#old.events-63)
 for n=start,#old.events do
  local e=old.events[n]
  if type(e)=="table"then
   local out={kind=e.kind,at=num(e.at)}
   if e.kind=="exam"and type(e.observer)=="string"then
    out.observer=str(e.observer);out.level=math.min(10,num(e.level));out.tools={steth=e.tools and e.tools.steth==true or false,tongue=e.tools and e.tools.tongue==true or false};out.findings={}
    for k=1,math.min(32,type(e.findings)=="table"and #e.findings or 0)do local f=finding(e.findings[k]);if f then out.findings[#out.findings+1]=f end end
    append(s,out)
   elseif e.kind=="care"and(C.TREATMENTS[e.intervention]or e.intervention=="repellent")then
    out.observer=str(e.observer);out.part=str(e.part,24);out.intervention=e.intervention;out.resource=str(e.resource,80);append(s,out)
   end
  end
 end
 return s
end
local function signature(event)
 local out={tostring(event.level),tostring(event.tools.steth),tostring(event.tools.tongue)}
 for _,f in ipairs(event.findings)do
  out[#out+1]=tostring(f.part)..":"..f.confidence..":"..tostring(f.condition)..":"..tostring(f.syndrome)..":"..f.severity
  for _,id in ipairs(A.SYMPTOMS)do if f.symptoms[id]then out[#out+1]=id end end
 end
 return table.concat(out,"|")
end
function H.exam(old,observer,at,findings,level,tools)
 local s=H.migrate(old)
 local candidate=H.migrate({events={{kind="exam",observer=observer,at=at,findings=findings,level=level,tools=tools}}}).events[1]
 if not candidate then return s end
 for n=#s.events,1,-1 do
  local e=s.events[n]
  if candidate.at-e.at>=1 then break end
  if e.kind=="exam"and e.observer==candidate.observer and signature(e)==signature(candidate)then return s end
 end
 return append(s,candidate)
end
function H.care(old,at,part,intervention,resource,observer)
 local s=H.migrate(old);local e=H.migrate({events={{kind="care",at=at,part=part,intervention=intervention,resource=resource,observer=observer}}}).events[1]
 return e and append(s,e)or s
end
function H.view(old,observer,isPatient)
 local s=H.migrate(old);local out={}
 for n=#s.events,1,-1 do
  local e=s.events[n]
  if e.kind=="care"or e.observer==observer then
   if e.kind=="care"and not isPatient and e.observer~=observer and not A.GENERIC_CARE[e.intervention]then
    e.redacted=true;e.intervention=nil;e.resource=nil
   end
   e.observer=nil;out[#out+1]=e
   if #out==20 then break end
  end
 end
 return out
end
return H
