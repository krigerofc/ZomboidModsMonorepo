local failed=0
local function check(v,m)if not v then failed=failed+1;print(" FAIL [symptoms] "..m)end end
local loaded,P=pcall(require,"KFM/Symptoms")
check(loaded,"finite server symptom policy exists")
if not loaded then return failed end
local Core=require "KFM/Core";local cfg=Core.config({})
local s,events=P.advance(nil,{online=true,blur=0.2,faint=true,perception="door"},10,cfg)
local seen={};for _,e in ipairs(events)do seen[e.kind]=true end
check(seen.blur and seen.faint and seen.door,"bounded visual/blackout/perceptual events planned")
local _,again=P.advance(s,{online=true,blur=0.2,faint=true,perception="door"},10,cfg)
check(#again==0,"same server window emits no burst or replay")
local _,offline=P.advance(s,{online=false,blur=1,faint=true,perception="door"},100,cfg)
check(#offline==0,"offline cannot emit catchup symptoms")
local _,invalid=P.advance(s,{online=true,perception="arbitrarySound"},11,cfg)
check(#invalid==0,"only known effect IDs accepted")
cfg.PsychologicalEffectsEnabled=false
local _,off=P.advance(s,{online=true,perception="door"},20,cfg)
local psych=false;for _,e in ipairs(off)do if e.kind=="door"then psych=true end end
check(not psych,"psych effects toggle suppresses local perceptions")
return failed
