local Game=require "KFM/Game"
local R=require "KFM/Risks"
local I=require "KFM/Illness"
local E={}
local function read(fn,fallback)local ok,v=pcall(fn);if ok and v~=nil then return v end;return fallback end
function E.context(patient)
 local c={month=1,temperature=20,wetness=0,wind=0,humidity=0,outdoors=false,mask=0,gloves=0,skinExposure=1}
 c.month=read(function()return getGameTime():getMonth()+1 end,1)
 c.outdoors=read(function()return patient:getSquare():isOutside()end,false)
 c.wetness=read(function()return patient:getStats():get(CharacterStat.WETNESS)end,0)
 c.temperature=read(function()return getClimateManager():getAirTemperatureForCharacter(patient)end,20)
 c.wind=c.outdoors and read(function()return getClimateManager():getWindIntensity()end,0)or 0
 c.humidity=read(function()return getClimateManager():getHumidity()end,0)
 local mask=read(function()return patient:getWornItem(ItemBodyLocation.MASK)end,nil)
 if mask and Game.cfg().MaskProtectionEnabled then
  c.mask=1-R.maskFactor(mask:getFullType(),read(function()return mask:getCondition()end,100))
 end
 local gloves=read(function()return patient:getWornItem(ItemBodyLocation.HANDS)end,nil)
 if gloves then
  local insulation=read(function()return gloves:getInsulation()end,0)
  local condition=read(function()return gloves:getCondition()/math.max(1,gloves:getConditionMax())end,1)
  c.gloves=math.min(1,insulation/0.65)*math.max(0,math.min(1,condition))
  c.skinExposure=c.skinExposure-0.2
 end
 if read(function()return patient:getWornItem(ItemBodyLocation.PANTS)~=nil end,false)then c.skinExposure=c.skinExposure-0.25 end
 if read(function()return patient:getWornItem(ItemBodyLocation.JACKET)~=nil end,false)then c.skinExposure=c.skinExposure-0.3 end
 c.profile=c.temperature<=8 and c.wetness>=50 and "coldWet" or c.temperature>=29 and c.wetness>=60 and "hotWet" or "temperate"
 local md=Game.md(patient)
 c.repellent=md.prevention and md.prevention.repellentUntil and md.prevention.repellentUntil>(md.health and md.health.clock or 0) or false
 return c
end
function E.observe(patient,state,cfg)
 local c=E.context(patient);local eligible=R.sources(c,cfg);local s=I.migrate(state)
 local md=Game.md(patient);md.environmentSerial=md.environmentSerial or 0
 for id,v in pairs(eligible)do
  if not s.sources[id]then md.environmentSerial=md.environmentSerial+1 end
  v.cause=s.sources[id] and s.sources[id].cause or id..":"..md.environmentSerial
  s=I.addSource(s,id,v)
 end
 for id,v in pairs(s.sources)do
  if v.kind=="environment"and not eligible[id]then s.sources[id]=nil end
 end
 md.environment=c
 return s,c
end
return E
