-- Authoritative engine adapter. All persistent state contains only Lua primitives.
local I=require "KFM/Illness"
local C=require "KFM/Conditions"
local Game=require "KFM/Game"
local D=require "KFM/Dynamics"
local Environment=require "KFM/Environment"
local Symptoms=require "KFM/Symptoms"
local Strain=require "KFM/Strain"
local Assessment=require "KFM/Assessment"
local History=require "KFM/History"
local H={VERSION=3,mirror={},sessions={},leases={},assessments={}}
KFM.Health=H
H.ITEMS={support="Base.KFM_SupportSachet",antibacterial="Base.Antibiotics",topical="Base.KFM_SkinOintment",burnCare="Base.KFM_BurnDressing",rehab="Base.KFM_RehabWrap",stabilize="Base.Splint",throatRemedy="Base.KFM_ThroatLozenges",feverCare="Base.Pills",protectiveDressing="Base.Bandage",inhaler="Base.KFM_BreathingAid",cardiacSupport="Base.KFM_CardiacSupport",pacedRehab="Base.KFM_RehabWrap",journaling="Base.KFM_RecoveryJournal",repellent="Base.KFM_InsectRepellent"}
local function authority() return not isClient() end
function H.state(patient)
 local md=Game.md(patient);md.health=I.migrate(md.health);return md.health
end
function H.mirrorKey(patient,observer)return tostring(observer:getOnlineID())..":"..tostring(patient:getOnlineID())end
function H.empty()return {version=3,episodes={},traits={},history={}}end
function H.view(patient,observer)
 observer=observer or patient
 if not isClient()then return H.project(patient,observer)end
 local view=H.mirror[H.mirrorKey(patient,observer)]
 if not view or view.version~=3 then return H.empty()end
 if observer~=patient and(not H.reachable(observer,patient)or not view.accessUntil or view.accessUntil<=Game.nowHours())then return H.empty()end
 return view
end
local function bloodFactor(patient,part,open)
 -- Masks cover mouth/nose, not exposed eyes or open skin wounds.
 if part~="Head"or open then return 1 end
 return 1-Environment.context(patient).mask*0.5
end
function H.registerExposure(patient,id,regions)
 if not authority() or not Game.cfg().Enabled then return false end
 local s=H.state(patient)
 for part,intensity in pairs(regions or {}) do
  local bp=Game.partByName(patient,part)
  if bp then
   local w=Game.wound(bp)
   s.sources["visual:"..part]=nil
   s=I.addSource(s,id..":"..part,{origin=id,kind="blood",part=part,rawIntensity=math.min(2,tonumber(intensity) or 1),intensity=math.min(2,tonumber(intensity) or 1)*bloodFactor(patient,part,w.cut or w.scratched or w.deepWounded or w.bitten),open=(w.cut or w.scratched or w.deepWounded or w.bitten),protected=w.bandaged or w.stitched})
  end
 end
 Game.md(patient).health=s;return true
end
function H.removeExposure(patient,id,part)
 if not authority() then return false end
 local s=H.state(patient)
 for key,v in pairs(s.sources) do if v.origin==id and (not part or v.part==part) then s=I.removeSource(s,key) end end
 Game.md(patient).health=s;return true
end
KFM.Exposure={version=1,register=H.registerExposure,remove=H.removeExposure}
local function getStat(player,key,default)
 local ok,v=pcall(function() return player:getStats():get(CharacterStat[key]) end)
 return ok and tonumber(v) or default
end
function H.seedNative(patient,kind,part,present)
 local md=Game.md(patient);md.observed=md.observed or {}
 local key=kind..":"..tostring(part or "general");local edge=md.observed[key] or {active=false,n=0}
 if present and not edge.active then
  edge.n=edge.n+1
  md.health=I.seed(H.state(patient),kind,"native:"..key..":"..edge.n,part,true)
 elseif not present and edge.active then
  local d=C.DEFS[kind];local e=H.state(patient).episodes[d.family..":"..tostring(part or "general")]
  if md.recovery then md.recovery[key]=nil end
  if e and (kind=="burn" or kind=="fracture" or kind=="wound") and e.condition==kind then e.phase="resolved" end
 end
 edge.active=present;md.observed[key]=edge
end
function H.observe(patient,elapsed)
 if not authority() or not Game.cfg().Enabled or not Game.cfg().IllnessEnabled then return end
 local md=Game.md(patient);local bd=patient:getBodyDamage()
 local cold=false;pcall(function() cold=bd:isHasACold() end)
 H.seedNative(patient,"flu",nil,cold)
 H.seedNative(patient,"foodborne",nil,getStat(patient,"FOOD_SICKNESS",0)>0.15)
 local parts=bd:getBodyParts()
 for n=0,parts:size()-1 do
  local bp=parts:get(n);local part=Game.partName(bp);local w=Game.wound(bp)
  H.seedNative(patient,"burn",part,bp:getBurnTime()>0)
  H.seedNative(patient,"fracture",part,bp:getFractureTime()>0)
  H.seedNative(patient,"wound",part,bp:getWoundInfectionLevel()>0)
  local ok,blood,dirt,wet=pcall(function()
   local visual=patient:getHumanVisual();local enum=BloodBodyPartType[part]
   return visual:getBlood(enum),visual:getDirt(enum),bp:getWetness()
  end)
  if ok then
   local s=H.state(patient);local shared=false
   for key,v in pairs(s.sources) do
    if v.origin and v.part==part then
     shared=true
     if blood<0.05 then s.sources[key]=nil else
      v.open=w.cut or w.scratched or w.deepWounded or w.bitten;v.protected=w.bandaged or w.stitched
      v.intensity=(v.rawIntensity or blood)*bloodFactor(patient,part,v.open)
     end
    end
   end
   local source="visual:"..part
   if blood>=0.15 and not shared then
    if not s.sources[source] then md.visualSerial=(md.visualSerial or 0)+1 end
    s=I.addSource(s,source,{cause="visual:"..part..":"..md.visualSerial,kind="blood",part=part,intensity=blood*bloodFactor(patient,part,w.cut or w.scratched or w.deepWounded or w.bitten),open=w.cut or w.scratched or w.deepWounded or w.bitten,protected=w.bandaged or w.stitched})
   else s.sources[source]=nil end
   local damp="damp:"..part
   if wet>=70 and dirt>=0.4 and (part=="Foot_L" or part=="Foot_R" or part=="Groin") then s=I.addSource(s,damp,{kind="damp",part=part,intensity=0.6})
   else s.sources[damp]=nil end
   if shared then s.sources[source]=nil end
   md.health=s
  end
 end
 local work=H.workContext(patient)
 local recent=md.effort and Game.nowHours()-(md.effort.at or -100)<=1/6+0.000001 and md.effort or {}
 work.online=not patient:isDead();work.toolHits=recent.tool or 0;work.combatHits=recent.combat or 0;work.bothHands=recent.bothHands
 local injuries
 md.strain,injuries=Strain.observe(md.strain or {},work,elapsed or 0)
 md.effort=nil;md.strainMinutes=nil
 for _,entry in ipairs(injuries)do md.health=I.seed(H.state(patient),"muscle",entry.cause,entry.part,false)end
 md.health=Environment.observe(patient,H.state(patient),Game.cfg())
end
function H.applyEffects(patient,fx)
 if not authority() then return end
 local md=Game.md(patient);md.ownedPain=md.ownedPain or {};md.painLast=md.painLast or {}
 for part,_ in pairs(md.ownedPain) do if not fx.pain[part] then fx.pain[part]=0 end end
 for part,target in pairs(fx.pain) do
  local bp=Game.partByName(patient,part)
  if bp then
   local current=bp:getAdditionalPain();local owned=md.ownedPain[part] or 0
   if owned>0 and current==md.painLast[part] then
    local nextPain=math.max(0,current-owned)+target
    bp:setAdditionalPain(nextPain);md.ownedPain[part]=target;md.painLast[part]=nextPain;Game.sync(bp)
   elseif current==0 then
    bp:setAdditionalPain(target);md.ownedPain[part]=target;md.painLast[part]=target;Game.sync(bp)
   else
    -- The engine/another mod reconstructed this channel. Its current value takes precedence.
    md.ownedPain[part]=0;md.painLast[part]=nil
   end
  end
 end
 local stats=patient:getStats()
 if (fx.fatigue or 0)>0 and CharacterStat.FATIGUE then stats:add(CharacterStat.FATIGUE,math.min(fx.fatigue,math.max(0,1-getStat(patient,"FATIGUE",0)))) end
 if (fx.enduranceRecovery or 0)>0 and CharacterStat.ENDURANCE then stats:add(CharacterStat.ENDURANCE,math.min(fx.enduranceRecovery,math.max(0,1-getStat(patient,"ENDURANCE",1)))) end
 if fx.thirst>0 and CharacterStat.THIRST then stats:add(CharacterStat.THIRST,math.min(fx.thirst,math.max(0,1-getStat(patient,"THIRST",0)))) end
 if fx.endurance>0 and CharacterStat.ENDURANCE then stats:add(CharacterStat.ENDURANCE,-math.min(fx.endurance,math.max(0,getStat(patient,"ENDURANCE",1)))) end
 if fx.health>0 then
  patient:getBodyDamage():ReduceGeneralHealth(fx.health)
  local parts=patient:getBodyDamage():getBodyParts()
  for n=0,parts:size()-1 do Game.sync(parts:get(n)) end
 end
 if isServer() and SyncPlayerStatsPacket then
  local mask=0
  if fx.thirst>0 then mask=mask+SyncPlayerStatsPacket.getBitMaskForStat(CharacterStat.THIRST) end
  if fx.endurance>0 or (fx.enduranceRecovery or 0)>0 then mask=mask+SyncPlayerStatsPacket.getBitMaskForStat(CharacterStat.ENDURANCE) end
  if (fx.fatigue or 0)>0 then mask=mask+SyncPlayerStatsPacket.getBitMaskForStat(CharacterStat.FATIGUE) end
  if mask~=0 then syncPlayerStats(patient,mask) end
 end
end
function H.snapshot(patient)
 local s=H.state(patient);local out={version=2,clock=s.clock,dynamicClock=H.dynamic(patient).clock,episodes={},traits={},exposures={},environment=Game.md(patient).environment or H.environment(patient)}
 for key,e in pairs(s.episodes)do
  if e.phase~="resolved"and(not C.DEFS[e.condition].switch or Game.cfg()[C.DEFS[e.condition].switch])then
   out.episodes[key]={id=e.id,condition=e.condition,part=e.part,phase=e.phase,severity=e.severity,remaining=math.ceil(e.remaining),careBonus=e.careBonus,treatments=e.treatments,symptoms=C.symptomsFor(e.condition,e.part),care=C.DEFS[e.condition].care}
  end
 end
 for id,e in pairs(H.dynamic(patient).states)do
  if e.phase~="resolved"and((D.DEFS[id].family=="psychological"and Game.cfg().PsychologicalConditionsEnabled)or(D.DEFS[id].family=="cardiorespiratory"and Game.cfg().DynamicCardiorespiratoryEnabled))then
   out.traits[id]={id=e.id,condition=id,labelKey="IGUI_KFM_Trait_"..id,careKey=e.careKey,care=e.care,phase=e.phase,severity=e.severity,remaining=math.ceil(e.remaining),benefit=e.benefit,source=e.source,treatments=e.treatments}
  end
 end
 for id,v in pairs(s.sources)do out.exposures[id]={kind=v.kind,part=v.part,intensity=v.intensity,hours=v.hours,protected=v.protected==true}end
 return out
end
-- Raw snapshot above remains an internal diagnostic/testing interface. Only project() crosses UI/network.
local function observerKey(doctor)
 local md=Game.md(doctor)
 if type(md.medicalObserverId)~="string"or #md.medicalObserverId>80 then md.medicalObserverId="observer:"..getRandomUUID()end
 return md.medicalObserverId
end
local function ownedTool(doctor,item,fullType)
 if not item or item:getFullType()~=fullType or not doctor:getInventory():contains(item)or Game.boundItem(item)then return false end
 local ok,condition=pcall(function()return item:getCondition()end)
 return not ok or tonumber(condition)and condition>0
end
local function knowledge(patient,doctor)
 local grant=H.assessments[patient]and H.assessments[patient][doctor]
 if not grant or grant.expires<=Game.nowHours()then return 0,{}end
 local level=math.min(grant.level,(Game.effectiveLevel(doctor,"exam",0)))
 local tools={steth=ownedTool(doctor,grant.steth,Game.ITEM_STETHOSCOPE),tongue=grant.tongue==true}
 return level,tools,grant
end
function H.project(patient,doctor)
 doctor=doctor or patient
 local out=H.empty()
 if not authority()or not H.reachable(doctor,patient)or not H.consent(doctor,patient)then return out end
 local cfg=Game.cfg()
 if not cfg.Enabled or not cfg.IllnessEnabled then return out end
 local level,tools,grant=knowledge(patient,doctor)
 out.clock=H.state(patient).clock;out.dynamicClock=H.dynamic(patient).clock
 out.medicalTime=H.medicalTime(patient);out.focus=H.focusBonus(patient)
 out.observerId=doctor:getOnlineID();out.patientId=patient:getOnlineID()
 if doctor~=patient then out.accessUntil=H.leases[patient][doctor]end
 local function add(e,dynamic)
  local known=doctor==patient and dynamic and e.source=="selectedHistory"
  local handle=(dynamic and "d"or "e")..tostring(e.id)
  local examined=grant and grant.examined and grant.examined[handle]==e.condition
  local f=Assessment.finding(e,examined and level or 0,examined and tools or {},dynamic,known)
  if not f then return end
  f.id=e.id;f.treatments={}
  -- Only offered intervals may be inspected; never expose condition-specific hidden treatment keys.
  for _,kind in ipairs(f.care)do
   local last=e.treatments and e.treatments[kind]
   if last then f.treatments[kind]={at=last.at}end
  end
  f.dynamic=dynamic==true
  out.episodes[handle]=f
 end
 for _,e in pairs(H.state(patient).episodes)do
  local d=C.DEFS[e.condition]
  if d and(not d.switch or cfg[d.switch])then add(e,false)end
 end
 for id,e in pairs(H.dynamic(patient).states)do
  local d=D.DEFS[id]
  if d and((d.family=="psychological"and cfg.PsychologicalConditionsEnabled)or(d.family=="cardiorespiratory"and cfg.DynamicCardiorespiratoryEnabled))then add(e,true)end
 end
 Game.md(patient).medicalHistory=History.migrate(Game.md(patient).medicalHistory)
 out.history=History.view(Game.md(patient).medicalHistory,observerKey(doctor))
 return out
end
function H.examine(patient,doctor,steth,tongue)
 if not authority()or not Game.cfg().Enabled or not Game.cfg().ExamEnabled or not H.reachable(doctor,patient)or not H.consent(doctor,patient)then return nil end
 if steth and not ownedTool(doctor,steth,Game.ITEM_STETHOSCOPE)then return nil end
 if tongue and not ownedTool(doctor,tongue,Game.ITEM_TONGUE)then return nil end
 -- Clinical confidence uses actual skill; a stethoscope cannot promote skill 5 to clinical skill 6.
 local level=Game.effectiveLevel(doctor,"exam",0)
 H.assessments[patient]=H.assessments[patient]or {}
 local examined={}
 for _,e in pairs(H.state(patient).episodes)do if e.phase~="resolved"and e.phase~="latent"then examined["e"..e.id]=e.condition end end
 for _,e in pairs(H.dynamic(patient).states)do if e.phase~="resolved"and e.phase~="latent"then examined["d"..e.id]=e.condition end end
 H.assessments[patient][doctor]={level=level,steth=steth,tongue=tongue~=nil,expires=Game.nowHours()+1,examined=examined}
 local view=H.project(patient,doctor);local findings={}
 local keys={};for key in pairs(view.episodes)do keys[#keys+1]=key end;table.sort(keys)
 for _,key in ipairs(keys)do findings[#findings+1]=view.episodes[key]end
 local md=Game.md(patient)
 md.medicalHistory=History.exam(md.medicalHistory,observerKey(doctor),Game.nowHours(),findings,level,{steth=steth~=nil,tongue=tongue~=nil})
 view.history=History.view(md.medicalHistory,observerKey(doctor))
 return view
end
function H.clearObserver(patient,doctor)
 if H.assessments[patient]then H.assessments[patient][doctor]=nil end
 if isServer()and doctor~=patient then sendServerCommand(doctor,Game.MODULE,"healthClear",{id=patient:getOnlineID(),observerId=doctor:getOnlineID()})
 elseif not isServer()and KFM.Client and KFM.Client.clearReport then KFM.Client.clearReport(patient:getOnlineID(),doctor:getOnlineID())end
 H.mirror[H.mirrorKey(patient,doctor)]=nil
end
function H.push(patient,doctor)
 if not isServer()then return end
 sendServerCommand(patient,Game.MODULE,"health",{id=patient:getOnlineID(),observerId=patient:getOnlineID(),state=H.project(patient,patient)})
 if doctor and doctor~=patient then
  if H.consent(doctor,patient)and H.reachable(doctor,patient)then sendServerCommand(doctor,Game.MODULE,"health",{id=patient:getOnlineID(),observerId=doctor:getOnlineID(),state=H.project(patient,doctor)})
  else H.clearObserver(patient,doctor)end
 end
 for observer in pairs(H.leases[patient]or {})do
  if not H.consent(observer,patient)or not H.reachable(observer,patient)then
   H.clearObserver(patient,observer);H.leases[patient][observer]=nil
  end
 end
end
function H.tick(patient,dt,rng)
 if not authority()then return end
 local cfg=Game.cfg()
 local ctx={online=not patient:isDead(),rest=Game.isResting(patient),hydrated=getStat(patient,"THIRST",0)<0.4,nativeFood=getStat(patient,"FOOD_SICKNESS",0)>0.15,nativeCold=false,thirst=getStat(patient,"THIRST",0),health=patient:getBodyDamage():getOverallBodyHealth()}
 pcall(function()ctx.nativeCold=patient:getBodyDamage():isHasACold()end)
 local work=H.workContext(patient)
 ctx.moving=work.moving;ctx.overloaded=work.overloaded
 local effort=Game.md(patient).recentEffort
 if effort and Game.nowHours()-(effort.at or -100)<=1/6+0.000001 then ctx.toolWorking=effort.tool;ctx.combatWorking=effort.combat end
 ctx.nativeRegions={}
 for part in pairs(Strain.REGIONS)do
  local bp=Game.partByName(patient,part)
  if bp then
   local w=Game.wound(bp)
   ctx.nativeRegions[part]=bp:getFractureTime()>0 or bp:getBurnTime()>0 or bp:getStiffness()>0 or w.cut or w.scratched or w.deepWounded or w.bitten
  end
 end
 local s,fx=I.advance(H.state(patient),ctx,dt,rng or Game.rng,cfg)
 Game.md(patient).health=s
 local burden=0
 for _,e in pairs(s.episodes)do if e.phase~="resolved"and e.condition=="respiratory"then burden=3 end end
 local exerting=false;pcall(function()exerting=patient:isRunning()or patient:isSprinting()end)
 local dynamicContext={online=ctx.online,rest=ctx.rest,safe=getStat(patient,"PANIC",0)<20,asleep=false,panic=getStat(patient,"PANIC",0),unhappiness=getStat(patient,"UNHAPPINESS",0),fatigue=getStat(patient,"FATIGUE",0),respiratoryBurden=burden,exerting=exerting,overexerted=exerting and getStat(patient,"ENDURANCE",1)<0.1,faintCount=Game.md(patient).faintCount or 0}
 pcall(function()dynamicContext.asleep=patient:isAsleep()end)
 local nextDynamic,dynamicFx=D.advance(H.dynamic(patient),dynamicContext,dt,cfg)
 Game.md(patient).dynamic=nextDynamic
 fx.fatigue=math.max(fx.fatigue or 0,dynamicFx.fatigue)
 fx.endurance=math.max(fx.endurance,dynamicFx.endurance)
 fx.enduranceRecovery=dynamicFx.enduranceRecovery
 fx.perception=dynamicFx.perception;fx.faint=fx.faint or dynamicFx.faint
 H.applyEffects(patient,fx)
 if H.emitSymptoms then H.emitSymptoms(patient,fx,ctx)end
 H.push(patient)
 for _,key in ipairs(fx.warnings)do
  local e=s.episodes[key]
  if not e.warned then
   e.warned=true
   local text=e.condition=="coldHands"and "IGUI_KFM_ColdHandsWarning"or "IGUI_KFM_SevereWarning"
   if isServer()then sendServerCommand(patient,Game.MODULE,"result",{id=patient:getOnlineID(),key=text})elseif KFM.Client then KFM.Client.say(patient,text)end
  end
 end
end
function H.reachable(doctor,patient)
 if doctor:isDead() or patient:isDead() or doctor:getZ()~=patient:getZ() then return false end
 local dx,dy=doctor:getX()-patient:getX(),doctor:getY()-patient:getY()
 if dx*dx+dy*dy>4 then return false end
 if doctor==patient then return true end
 local ok,v=pcall(function() return doctor:getSquare():canReachTo(patient:getSquare()) end)
 return ok and v==true
end
function H.consent(doctor,patient)
 if doctor==patient then return true end
 if not H.active(doctor) or not H.active(patient) then return false end
 local lease=H.leases[patient] and H.leases[patient][doctor]
 return lease and lease>Game.nowHours() or false
end
function H.treat(doctor,patient,key,treatment,item,episodeId)
 if not authority() or not H.reachable(doctor,patient)or not H.consent(doctor,patient)then return false end
 local cfg=Game.cfg()
 if not cfg.Enabled or not cfg.IllnessEnabled then return false end
 local md=Game.md(patient)
 -- Handle and identity are mandatory; resolve only after validating this observer's current offer.
 if key~="prevention:mosquito"then
  if type(key)~="string"or episodeId==nil then return false end
  local offer=H.project(patient,doctor).episodes[key]
  if not offer or offer.id~=episodeId then return false end
  local allowed=false;for _,kind in ipairs(offer.care or {})do if kind==treatment then allowed=true end end
  if not allowed then return false end
  local rawKey
  for candidate,e in pairs(H.state(patient).episodes)do if key=="e"..tostring(e.id)then rawKey=candidate;break end end
  if not rawKey then for id,e in pairs(H.dynamic(patient).states)do if key=="d"..tostring(e.id)then rawKey="trait:"..id;break end end end
  if not rawKey then return false end
  key=rawKey
 end
 local dynamicId=string.match(key or "","^trait:(%w+)$")
 local preventive=key=="prevention:mosquito"and treatment=="repellent"
 local old=dynamicId and H.dynamic(patient).states[dynamicId]or H.state(patient).episodes[key]
 if not preventive and (not old or (episodeId and old.id~=episodeId))then return false end
 if dynamicId then
  local family=D.DEFS[dynamicId].family
  if (family=="psychological"and not cfg.PsychologicalConditionsEnabled)or(family=="cardiorespiratory"and not cfg.DynamicCardiorespiratoryEnabled)then return false end
 end
 local required=H.ITEMS[treatment]
 if required and(not item or item:getFullType()~=required or not doctor:getInventory():contains(item)or Game.boundItem(item))then return false end
 if treatment=="feverCare"and item:getCurrentUses()<=0 then return false end
 if preventive and not cfg.MosquitoIllnessEnabled then return false end
 if treatment=="hygiene"and(not item or not doctor:getInventory():contains(item)or Game.boundItem(item)or Game.waterKind(item)~="clean")then return false end
 local resting={dry=true,rehab=true,muscleRest=true,stabilize=true,warming=true,cooling=true,pacedRehab=true,calmRoutine=true,sleepRoutine=true,journaling=true}
 if resting[treatment]and not Game.isResting(patient)then return false end
 if treatment=="counseling"and doctor==patient then return false end
 local context=H.environment(patient)
 if treatment=="warming"and(context.temperature<15 or context.wetness>50)then return false end
 if treatment=="cooling"and context.temperature>=29 then return false end
 if preventive then
  md.prevention=md.prevention or {}
  if(md.prevention.repellentUntil or 0)>H.state(patient).clock then return false end
  md.prevention.repellentUntil=H.state(patient).clock+4
  Game.removeItem(doctor,item);md.medicalHistory=History.care(md.medicalHistory,Game.nowHours(),nil,treatment,required);H.push(patient,doctor);return true
 end
 local nextState,changed
 if dynamicId then nextState,changed=D.treat(H.dynamic(patient),dynamicId,treatment,Game.doctorLevel(doctor))
 else nextState,changed=I.treat(H.state(patient),key,treatment,Game.doctorLevel(doctor),cfg)end
 if not changed then return false end
 local episode
 if dynamicId then md.dynamic=nextState;episode=nextState.states[dynamicId]
 else md.health=nextState;episode=nextState.episodes[key]end
 if episode.part then
  local bp=Game.partByName(patient,episode.part)
  if bp and treatment=="burnCare"and bp:getBurnTime()>0 then
   local reduction=H.recoveryReduction(patient,bp,"burn",bp:getBurnTime()*0.1)
   bp:setBurnTime(bp:getBurnTime()-reduction);bp:setNeedBurnWash(false);Game.sync(bp)
  elseif bp and treatment=="stabilize"and bp:getFractureTime()>0 then
   bp:setSplint(true,math.min(5,(Game.doctorLevel(doctor)+1)/2));bp:setSplintItem("Base.Splint");Game.sync(bp)
  end
 end
 if required then
  if treatment=="feverCare"then item:UseAndSync()else Game.removeItem(doctor,item)end
 elseif treatment=="hygiene"then Game.useWater(item)end
 if treatment=="hygiene"and episode.part then
  local enum=BloodBodyPartType and BloodBodyPartType[episode.part]
  if enum then
   local visual=patient:getHumanVisual();visual:setBlood(enum,0);visual:setDirt(enum,0);syncVisuals(patient);sendHumanVisual(patient)
   for source,v in pairs(md.health.sources)do if v.part==episode.part then md.health.sources[source]=nil end end
  end
 elseif treatment=="dry"then patient:getBodyDamage():decreaseBodyWetness(20)end
 if doctor~=patient and I.contactEligible({source=old.condition,route="care",touch=true,distance=0,sameFloor=true,barrier=false},cfg)then
  local gloves=Game.surgicalProtection(doctor)
  if not gloves and Game.rng()<0.03*cfg.DiseaseFrequency then Game.md(doctor).health=I.seed(H.state(doctor),"viral","care:"..patient:getOnlineID()..":"..old.id,nil,false)end
 end
 md.medicalHistory=History.care(md.medicalHistory,Game.nowHours(),episode.part,treatment,required or(treatment=="hygiene"and item:getFullType()or nil))
 Game.grantXp(doctor,patient,"care_"..treatment,key);H.push(patient,doctor)
 return true
end
function H.contact(players)
 if not authority() then return end
 local eligible={}
 for _,target in ipairs(players) do eligible[target]={} end
 for _,source in ipairs(players) do
  if not source:isDead() then
   for _,e in pairs(H.state(source).episodes) do
    -- Enteric viral spread uses successful ungloved patient care, never proximity/air.
    if e.condition=="flu" and e.phase~="latent" and e.phase~="resolved" then
     for _,target in ipairs(players) do
      if target~=source and not target:isDead() then
       local dx,dy=source:getX()-target:getX(),source:getY()-target:getY()
       local barrier=true
       pcall(function() barrier=not source:getSquare():canReachTo(target:getSquare()) or source:getSquare():isSomethingTo(target:getSquare()) end)
       local id="contact:"..tostring(source:getOnlineID())..":"..e.id
       local md=Game.md(target);md.contacts=md.contacts or {}
       if Game.cfg().ContactTransmissionEnabled and source:getZ()==target:getZ() and dx*dx+dy*dy<=4 and not barrier then
        local minutes=(md.contacts[id] or 0)+10
        eligible[target][id]=minutes
        md.contacts[id]=minutes
        if I.contactEligible({distance=math.sqrt(dx*dx+dy*dy),sameFloor=true,barrier=false,source="flu",minutes=minutes},Game.cfg()) then
         md.health=I.addSource(H.state(target),id,{kind="respiratory",intensity=0.5*(1-H.environment(source).mask)*(1-H.environment(target).mask)})
        end
       end
      end
     end
    end
   end
  end
 end
 -- Every pass is rebuilt from currently simulated, living, symptomatic sources.
 for _,target in ipairs(players) do
  local md=Game.md(target);md.contacts=md.contacts or {}
  for id,_ in pairs(md.contacts) do
   if not eligible[target][id] then md.contacts[id]=nil;md.health=I.removeSource(H.state(target),id) end
  end
  for id,v in pairs(H.state(target).sources) do
   if v.kind=="respiratory" and not eligible[target][id] then md.health=I.removeSource(H.state(target),id) end
  end
 end
end

function H.active(player)
 for _,p in ipairs(Game.players()) do if p==player and not p:isDead() then return true end end
 return false
end
H.pending={};H.nonce=0
function H.requestConsent(doctor,patient)
 if not authority() or doctor==patient or not H.active(doctor) or not H.active(patient) or not H.reachable(doctor,patient) then return nil end
 for nonce,p in pairs(H.pending) do
  if p.patient==patient and p.doctor==doctor and p.expires>Game.nowHours() then return nonce end
 end
 H.nonce=H.nonce+1
 local nonce=tostring(H.nonce)..":"..tostring(Game.nowHours())
 H.pending[nonce]={doctor=doctor,patient=patient,expires=Game.nowHours()+1/6}
 if isServer() then sendServerCommand(patient,Game.MODULE,"consent",{id=patient:getOnlineID(),doctor=doctor:getDisplayName(),nonce=nonce}) end
 return nonce
end
function H.answerConsent(patient,nonce,accepted)
 if not authority() or type(nonce)~="string" then return false end
 local p=H.pending[nonce]
 if not p or p.patient~=patient or p.expires<Game.nowHours() or not H.active(p.doctor) or not H.active(patient) or not H.reachable(p.doctor,patient) then return false end
 H.pending[nonce]=nil
 if accepted~=true then return false end
 H.leases[patient]=H.leases[patient] or {};H.leases[patient][p.doctor]=Game.nowHours()+1
 H.push(patient,p.doctor)
 return true
end
function H.revokeConsent(patient)
 for observer in pairs(H.leases[patient]or {})do H.clearObserver(patient,observer)end
 H.assessments[patient]=nil
 for target,observers in pairs(H.leases)do
  if observers[patient]then H.clearObserver(target,patient);observers[patient]=nil end
 end
 H.leases[patient]=nil
 for nonce,p in pairs(H.pending) do if p.patient==patient or p.doctor==patient then H.pending[nonce]=nil end end
end
function H.recoveryReduction(patient,bp,kind,requested)
 local md=Game.md(patient);md.recovery=md.recovery or {}
 local key=kind..":"..Game.partName(bp)
 local current=kind=="burn" and bp:getBurnTime() or bp:getFractureTime()
 local st=md.recovery[key] or {base=current,removed=0}
 local reduction=math.max(0,math.min(requested,st.base*0.4-st.removed,current*0.4))
 st.removed=st.removed+reduction;md.recovery[key]=st
 return reduction
end


function H.afterEating(player,item,percentage,dirty)
 if not authority() or not Game.cfg().Enabled or not Game.cfg().IllnessEnabled or (percentage or 0)<=0 then return end
 if getStat(player,"FOOD_SICKNESS",0)>0.15 or getStat(player,"POISON",0)>0 then H.seedNative(player,"foodborne",nil,true);return end
 if not dirty then return end
 local md=Game.md(player);md.ingestSerial=(md.ingestSerial or 0)+1
 if Game.rng()<0.08*Game.cfg().DiseaseFrequency then
  md.health=I.seed(H.state(player),"viral","dirtyMeal:"..md.ingestSerial,nil,false)
 end
end


function H.dynamic(patient)
 local md=Game.md(patient)
 local selected={}
 for _,id in ipairs(Game.identityIds(patient))do
  local name=string.match(id,"^kfm:(.+)$")
  if name then selected[name]=true end
 end
 md.dynamic=D.initialize(md.dynamic,selected)
 return md.dynamic
end
function H.medicalTime(patient)
 local cfg=Game.cfg()
 if not cfg.Enabled or not cfg.IllnessEnabled or not cfg.PsychologicalConditionsEnabled then return 1 end
 if isClient()then return H.view(patient).medicalTime or 1 end
 local states=H.dynamic(patient).states
 local multiplier=1
 if states.lowMood and states.lowMood.phase~="resolved"then multiplier=1.12 end
 if states.resilience and states.resilience.phase~="resolved"then multiplier=multiplier*0.92 end
 return math.max(0.9,math.min(1.15,multiplier))
end
function H.focusBonus(patient)
 if not Game.cfg().PsychologicalConditionsEnabled or not Game.cfg().Enabled or not Game.cfg().IllnessEnabled then return 0 end
 if isClient()then return H.view(patient).focus or 0 end
 local states=H.dynamic(patient).states
 return states.hypervigilance and states.hypervigilance.phase~="resolved"and 1 or 0
end
H.environment=Environment.context

function H.workContext(patient)
 local c={moving=false,running=false,overloaded=false,exhausted=getStat(patient,"ENDURANCE",1)<0.2}
 pcall(function()c.running=patient:isRunning()or patient:isSprinting();c.moving=patient:isPlayerMoving()or c.running end)
 pcall(function()c.overloaded=patient:getInventoryWeight()>patient:getMaxWeight()end)
 return c
end
-- Called only from native authoritative hit events; no client grant/effort command exists.
function H.recordEffort(patient,weapon,tool)
 if not authority()or not patient or not weapon or not H.active(patient)then return end
 local cfg=Game.cfg()
 if not cfg.Enabled or not cfg.IllnessEnabled then return end
 local ok,eligible=pcall(function()return weapon:getType()~="BareHands"and not weapon:isRanged()end)
 if not ok or not eligible then return end
 local md=Game.md(patient);local now=Game.nowHours();local kind=tool and "tool"or "combat"
 local e=md.effort or {tool=0,combat=0,at=now,last={}}
 if now-e.at>1/6+0.000001 then e={tool=0,combat=0,at=now,last={}}end
 -- One multi-target swing may dispatch several hit-XP callbacks at the same instant.
 if e.last[kind]==now then return end
 e.last[kind]=now;e[kind]=math.min(120,e[kind]+1)
 pcall(function()e.bothHands=patient:getPrimaryHandItem()==weapon and patient:getSecondaryHandItem()==weapon end)
 md.effort=e;md.recentEffort={at=now,tool=tool==true,combat=not tool}
end


function H.emitSymptoms(patient,fx,context)
 local md=Game.md(patient);local cfg=Game.cfg()
 local state,events=Symptoms.advance(md.symptomPlan,{online=not patient:isDead(),blur=fx.blur,cough=fx.cough,faint=fx.faint,perception=fx.perception,nativeCold=context.nativeCold},H.state(patient).clock,cfg)
 md.symptomPlan=state
 for _,effect in ipairs(events)do
  if effect.kind=="cough"then
   -- Native finite cough creates its ordinary sound and MP cough packet without setting a cold.
   patient:getBodyDamage():TriggerSneezeCough()
  else
   if effect.kind=="faint"then md.faintCount=(md.faintCount or 0)+1 end
   local packet={id=patient:getOnlineID(),seq=effect.seq,kind=effect.kind,strength=effect.strength}
   if isServer()then sendServerCommand(patient,Game.MODULE,"symptom",packet)
   elseif KFM.ClientEffects then KFM.ClientEffects.receive(packet)end
  end
 end
end

return H
