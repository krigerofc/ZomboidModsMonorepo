local P={}
P.KNOWN={cough=true,blur=true,faint=true,knock=true,door=true,flicker=true,clear=true}
P.PSYCH={knock=true,door=true,flicker=true}
P.DURATION={blur=10000,faint=3000,knock=1200,door=1200,flicker=1600}
P.COOLDOWN={cough=0.5,blur=0.5,faint=12,knock=6,door=6,flicker=6}
function P.advance(old,c,clock,cfg)
 local s={seq=old and old.seq or 0,last={},active=old and old.active or false}
 for k,v in pairs(old and old.last or {})do s.last[k]=v end
 local events={}
 local function emit(kind,strength)
  s.seq=s.seq+1;events[#events+1]={seq=s.seq,kind=kind,strength=strength or 0};s.active=kind~="clear"
 end
 if not c.online then return s,events end
 if not cfg.Enabled or not cfg.IllnessEnabled then
  if s.active then emit("clear")end
  return s,events
 end
 local wanted={}
 if cfg.SymptomEffectsEnabled then
  if(c.blur or 0)>0 then wanted.blur=math.min(0.35,c.blur)end
  if(c.cough or 0)>0 and not c.nativeCold then wanted.cough=1 end
 end
 if cfg.FaintingEnabled and c.faint then wanted.faint=1 end
 if cfg.PsychologicalConditionsEnabled and cfg.PsychologicalEffectsEnabled and P.PSYCH[c.perception]then wanted[c.perception]=1 end
 for _,kind in ipairs({"cough","blur","faint","knock","door","flicker"})do
  if wanted[kind]and clock-(s.last[kind]or -1000)>=P.COOLDOWN[kind]then
   s.last[kind]=clock;emit(kind,wanted[kind])
  end
 end
 return s,events
end
return P
