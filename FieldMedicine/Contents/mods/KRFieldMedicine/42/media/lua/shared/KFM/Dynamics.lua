-- Recoverable game states; no native trait-point changes or permanent acquired native traits.
local D={VERSION=1,POINTS=0}
D.DEFS={
 respiratoryVulnerability={hours=120,severity=2,care={"inhaler","pacedRehab"},family="cardiorespiratory"},
 cardiacVulnerability={hours=168,severity=2,care={"cardiacSupport","pacedRehab"},family="cardiorespiratory"},
 hypervigilance={hours=72,severity=1,care={"calmRoutine","counseling"},family="psychological"},
 lowMood={hours=96,severity=1,care={"counseling","journaling"},family="psychological"},
 sleepDisruption={hours=72,severity=1,care={"sleepRoutine","calmRoutine"},family="psychological"},
 resilience={hours=72,severity=1,care={"calmRoutine"},family="psychological",benefit=true},
}
local function copy(t)if type(t)~="table"then return t end;local r={};for k,v in pairs(t)do r[k]=copy(v)end;return r end
function D.new()return {version=1,clock=0,serial=0,states={},doses={},history={}}end
function D.migrate(old)
 local s=copy(old or D.new());s.version=1;s.clock=s.clock or 0;s.serial=s.serial or 0
 s.states=s.states or {};s.doses=s.doses or {};s.history=s.history or {};return s
end
function D.seed(state,id,source)
 local s=D.migrate(state);local d=D.DEFS[id]
 if not d then return s end
 local prev=s.states[id]
 if prev and (prev.phase~="resolved" or s.clock-(prev.resolvedAt or 0)<24)then return s end
 s.serial=s.serial+1
 s.states[id]={id=s.serial,condition=id,phase="active",severity=d.severity,source=source,age=0,remaining=d.hours,baseHours=d.hours,careBonus=0,benefit=d.benefit==true,care=copy(d.care),careKey="IGUI_KFM_DynamicCare_"..id,treatments={}}
 return s
end
function D.initialize(state,selected)
 local s=D.migrate(state)
 if s.initialized then return s end;s.initialized=true
 if selected.respiratory then s=D.seed(s,"respiratoryVulnerability","selectedHistory")end
 if selected.cardiac then s=D.seed(s,"cardiacVulnerability","selectedHistory")end
 if selected.stresssensitivity then s=D.seed(s,"hypervigilance","selectedHistory")end
 if selected.resilience then s=D.seed(s,"resilience","selectedHistory")end
 return s
end
function D.treat(state,id,treatment,level)
 local s=D.migrate(state);local e=s.states[id]
 local C=require "KFM/Conditions";local t=C.TREATMENTS[treatment]
 if not e or e.phase=="resolved" or not t or (level or 0)<t.level then return s,false end
 local eligible=false;for _,care in ipairs(D.DEFS[id].care)do if care==treatment then eligible=true end end
 if not eligible then return s,false end
 local last=e.treatments[treatment]
 if last and s.clock-last.at<t.interval then return s,false end
 local bonus=math.min(0.4-e.careBonus,t.quality)
 e.careBonus=e.careBonus+bonus;e.remaining=math.max(e.baseHours*0.05,e.remaining-e.baseHours*bonus)
 e.treatments[treatment]={at=s.clock,untilHour=s.clock+t.duration}
 e.phase="recovering";return s,true
end
function D.advance(state,c,elapsed,cfg)
 local s=D.migrate(state);local fx={fatigue=0,endurance=0,enduranceRecovery=0,medicalTime=1,focus=0,psych=false,perception=false,faint=false}
 if not c.online or cfg.Enabled==false or cfg.IllnessEnabled==false then return s,fx end
 local dt=math.max(0,math.min(1/6,tonumber(elapsed)or 0));s.clock=s.clock+dt
 local triggers={
  hypervigilance=(c.panic or 0)>=70,
  lowMood=(c.unhappiness or 0)>=65,
  sleepDisruption=(c.fatigue or 0)>=0.85 and not c.asleep,
  respiratoryVulnerability=(c.respiratoryBurden or 0)>=2,
  cardiacVulnerability=c.overexerted or ((c.faintCount or 0)>=2 and (c.fatigue or 0)>=0.8),
  resilience=c.safe and c.rest and (c.panic or 0)<20 and (c.unhappiness or 0)<30,
 }
 local thresholds={hypervigilance=6,lowMood=12,sleepDisruption=8,respiratoryVulnerability=24,cardiacVulnerability=24,resilience=36}
 for id,on in pairs(triggers)do
  local enabled=D.DEFS[id].family=="psychological" and cfg.PsychologicalConditionsEnabled~=false or D.DEFS[id].family=="cardiorespiratory" and cfg.DynamicCardiorespiratoryEnabled~=false
  if enabled then
   s.doses[id]=on and ((s.doses[id]or 0)+dt)or math.max(0,(s.doses[id]or 0)-dt)
   if s.doses[id]>=thresholds[id]then s=D.seed(s,id,"prolongedGameContext");s.doses[id]=0 end
  end
 end
 for id,e in pairs(s.states)do
  local def=D.DEFS[id]
  local enabled=def.family=="psychological" and cfg.PsychologicalConditionsEnabled~=false or def.family=="cardiorespiratory" and cfg.DynamicCardiorespiratoryEnabled~=false
  if enabled and e.phase~="resolved"then
   e.age=e.age+dt
   local care=false;for _,v in pairs(e.treatments)do if v.untilHour>s.clock then care=true end end
   local recovery=(c.safe and c.rest) and 1.5 or 0.15
   if c.asleep then recovery=2 end
   if care then recovery=recovery+0.5;e.phase="recovering"end
   e.remaining=math.max(0,e.remaining-dt*recovery)
   if e.remaining<=0 then e.phase="resolved";e.resolvedAt=s.clock
   else
    if def.family=="psychological"then fx.psych=true end
    local relief=care and 0.5 or 1
    if id=="respiratoryVulnerability"and c.exerting then fx.endurance=math.max(fx.endurance,0.04*dt*relief)
    elseif id=="cardiacVulnerability"and c.exerting then
     fx.endurance=math.max(fx.endurance,0.03*dt*relief)
     fx.fatigue=math.max(fx.fatigue,0.015*dt*relief)
     if (c.fatigue or 0)>0.95 and e.age>12 and s.clock-(e.lastFaint or -100)>12 then fx.faint=true;e.lastFaint=s.clock end
    elseif id=="hypervigilance"then fx.fatigue=math.max(fx.fatigue,0.01*dt*relief);fx.focus=1
    elseif id=="lowMood"then fx.medicalTime=math.max(fx.medicalTime,1.12);fx.fatigue=math.max(fx.fatigue,0.004*dt*relief)
    elseif id=="sleepDisruption"then fx.fatigue=math.max(fx.fatigue,0.01*dt*relief)
    elseif id=="resilience"and c.rest then fx.enduranceRecovery=math.min(0.01,0.03*dt);fx.medicalTime=math.min(fx.medicalTime,0.92)end
    if (id=="hypervigilance"or id=="sleepDisruption")and e.age>=4 and cfg.PsychologicalEffectsEnabled~=false then
     local window=math.floor(s.clock/6)
     if window>(e.perceptionWindow or -1)then fx.perception=({"knock","door","flicker"})[window%3+1];e.perceptionWindow=window end
    end
   end
  end
 end
 return s,fx
end
return D
