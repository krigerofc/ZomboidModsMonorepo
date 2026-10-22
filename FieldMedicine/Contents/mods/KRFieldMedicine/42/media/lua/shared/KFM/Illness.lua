local C=require "KFM/Conditions"
local Strain=require "KFM/Strain"
local I={VERSION=2}
local function copy(t)
 if type(t)~="table" then return t end
 local r={};for k,v in pairs(t) do r[k]=copy(v) end;return r
end
function I.count(t) local n=0;for _ in pairs(t or {}) do n=n+1 end;return n end
function I.new() return {version=2,clock=0,serial=0,episodes={},sources={}} end
function I.migrate(old)
 local s=copy(old or I.new())
 s.version=2;s.clock=tonumber(s.clock) or 0;s.serial=tonumber(s.serial) or 0
 s.episodes=s.episodes or {};s.sources=s.sources or {}
 return s
end
function I.seed(state,condition,cause,part,native)
 local s=I.migrate(state);local d=C.DEFS[condition]
 if not d then return s end
 local key=d.family..":"..tostring(part or "general")
 local prev=s.episodes[key]
 -- Resolved same-cause entries are tombstones against replay; a genuinely new source may start again.
 if prev and (prev.phase~="resolved" or prev.cause==cause) then return s end
 s.serial=s.serial+1
 s.episodes[key]={id=s.serial,condition=condition,cause=cause,part=part,native=native==true,
  age=0,stageAge=0,remaining=d.hours,baseHours=d.hours,careBonus=0,neglect=0,phase="latent",treatments={},severity=1}
 return s
end
function I.addSource(state,id,source)
 local s=I.migrate(state)
 if type(id)~="string" or #id>160 then return s end
 if s.sources[id] then
  local existing=s.sources[id]
  for k,v in pairs(source or {}) do if k~="hours" and k~="window" and k~="id" then existing[k]=copy(v) end end
  return s
 end
 local v=copy(source);v.hours=0;v.window=0;v.id=id;s.sources[id]=v
 return s
end
function I.removeSource(state,id)
 local s=I.migrate(state);s.sources[id]=nil;return s
end
function I.treat(state,key,treatment,level,cfg)
 local s=I.migrate(state);local e=s.episodes[key];local t=C.TREATMENTS[treatment]
 if not e or e.phase=="resolved" or not t or (level or 0)<t.level or (cfg and not cfg.Enabled) then return s,false end
 local allowed=false;for _,id in ipairs(C.DEFS[e.condition].care) do if id==treatment then allowed=true end end
 if not allowed then return s,false end
 local last=e.treatments[treatment]
 if last and s.clock-last.at<t.interval then return s,false end
 local bonus=math.min(0.4-e.careBonus,t.quality*(0.6+math.min(10,level or 0)*0.04))
 e.careBonus=math.min(0.4,e.careBonus+math.max(0,bonus))
 e.remaining=math.max(e.baseHours*0.05,e.remaining-e.baseHours*math.max(0,bonus))
 e.treatments[treatment]={at=s.clock,untilHour=s.clock+t.duration}
 e.neglect=math.max(0,e.neglect-t.duration);e.phase="recovering"
 return s,true
end
function I.contactEligible(c,cfg)
 if not cfg.ContactTransmissionEnabled or not c.sameFloor or c.barrier or c.distance>2 then return false end
 if c.source=="viral" then return c.route=="care" and c.touch==true end
 return c.source=="flu" and (c.minutes or 0)>=15
end
local function cared(e,clock)
 for _,t in pairs(e.treatments) do if t.untilHour>clock then return true end end
 return false
end
function I.advance(state,ctx,elapsed,rng,cfg)
 local s=I.migrate(state);local fx={health=0,thirst=0,endurance=0,pain={},warnings={},fatigue=0,cough=0,blur=0,faint=false}
 ctx=ctx or {};cfg=cfg or {};rng=rng or function()return 1 end
 if not ctx.online or cfg.Enabled==false or cfg.IllnessEnabled==false then return s,fx end
 -- Never consume offline elapsed or a large catch-up interval.
 local dt=math.max(0,math.min(1/6,tonumber(elapsed) or 0));s.clock=s.clock+dt
 for id,v in pairs(s.sources) do
  if not v.protected then
   v.hours=v.hours+dt
   local window=math.floor(v.hours+0.000001)
   if window>(v.window or 0) and v.hours>=(v.grace or 1) then
    v.window=window
    local condition=(v.condition and C.DEFS[v.condition]) and v.condition or v.kind=="damp" and "fungal" or v.kind=="respiratory" and "flu" or v.kind=="enteric" and "viral" or v.open and "wound" or v.part=="Head" and "conjunctivitis" or "dermatitis"
    local key=C.DEFS[condition].family..":"..tostring(v.part or "general")
    if not s.episodes[key] or (s.episodes[key].phase=="resolved" and s.episodes[key].cause~=(v.cause or id)) then
     local chance=(v.risk or (v.open and 0.08 or 0.025))*(tonumber(v.intensity) or 1)*(cfg.DiseaseFrequency or 1)
     if rng()<chance then s=I.seed(s,condition,v.cause or id,v.part,false) end
    end
   end
  end
 end
 for key,e in pairs(s.episodes) do
  if e.phase~="resolved" and (not C.DEFS[e.condition].switch or cfg[C.DEFS[e.condition].switch]~=false) then
   local d=C.DEFS[e.condition];local activeCare=cared(e,s.clock) or (e.condition=="flu" and ctx.rest and ctx.hydrated)
   e.age=e.age+dt;e.stageAge=e.stageAge+dt
   if activeCare or (ctx.rest and ctx.hydrated and not d.next and not d.fatal) then e.neglect=math.max(0,e.neglect-dt) else e.neglect=e.neglect+dt end
   if e.age>=d.latency then
    if e.phase=="latent" then e.phase="symptomatic" end
    local recovery=dt
    if d.family=="muscle"then recovery=dt*(ctx.rest and 1.5 or (ctx.moving or ctx.toolWorking or ctx.combatWorking)and 0.15 or 0.5)end
    if (d.next or d.fatal) and not activeCare then recovery=recovery*0.15 end
    e.remaining=math.max(0,e.remaining-recovery)
    if d.next and e.neglect>=d.neglect then
     e.condition=d.next;d=C.DEFS[e.condition];e.stageAge=0;e.neglect=0
     e.remaining=d.hours;e.baseHours=d.hours;e.careBonus=0;e.treatments={};e.phase="complication"
    end
    e.severity=d.fatal and 3 or (d.next and 2 or 1)
    if e.remaining<=0 then e.phase="resolved"
    else
     local native=(d.family=="food" and ctx.nativeFood) or (d.family=="resp" and ctx.nativeCold) or (d.family=="wound" and e.native and e.condition=="wound") or d.family=="burn" or d.family=="fracture"
     if not native then
      local relief=activeCare and 0.5 or 1
      if d.family=="muscle"then
       local regional=Strain.effects(e.part,ctx,relief,dt)
       if regional.pain>0 then fx.pain[e.part]=math.max(fx.pain[e.part]or 0,regional.pain)end
       fx.endurance=math.max(fx.endurance,regional.endurance);fx.fatigue=math.max(fx.fatigue,regional.fatigue)
      end
      fx.thirst=math.max(fx.thirst,(d.symptoms.thirst or 0)*dt*relief)
      fx.endurance=math.max(fx.endurance,(d.symptoms.endurance or 0)*dt*relief)
      fx.fatigue=math.max(fx.fatigue,(d.symptoms.fatigue or 0)*dt*relief)
      fx.blur=math.max(fx.blur,(d.symptoms.blur or 0)*relief)
      if not ctx.nativeCold then fx.cough=math.max(fx.cough,(d.symptoms.cough or 0)*relief) end
      if e.part and (d.symptoms.pain or 0)>0 then fx.pain[e.part]=math.max(fx.pain[e.part] or 0,d.symptoms.pain*relief) end
     end
     if d.severeAfter and e.age>d.severeAfter then e.severity=2;fx.warnings[#fx.warnings+1]=key end
     if d.faint and cfg.FaintingEnabled~=false and e.age>12 and ((ctx.thirst or 0)>0.8 or (ctx.health or 100)<35) and s.clock-(e.lastFaint or -100)>12 then fx.faint=true;e.lastFaint=s.clock end
     if d.fatal then
      fx.warnings[#fx.warnings+1]=key
      if cfg.NewDiseaseMortalityEnabled~=false and not activeCare and e.neglect>d.neglect and e.stageAge>d.neglect then
       fx.health=math.max(fx.health,math.min(0.5,0.5*dt))
      end
     end
    end
   end
  end
 end
 local severity=cfg.DiseaseSeverity or 1
 fx.health=fx.health*severity;fx.thirst=fx.thirst*severity;fx.endurance=fx.endurance*severity;fx.fatigue=fx.fatigue*severity
 fx.blur=math.min(0.35,fx.blur*severity)
 for part,pain in pairs(fx.pain) do fx.pain[part]=pain*severity end
 if severity==0 then fx.cough=0;fx.faint=false end
 return s,fx
end
return I
