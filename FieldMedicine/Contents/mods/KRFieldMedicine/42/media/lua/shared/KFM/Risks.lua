local R={}
-- Returned factors multiply exposure, not immunity. Mask fit/condition are game abstractions.
function R.maskFactor(fullType,condition)
 if (condition or 100)<=0 then return 1 end
 if fullType=="Base.Hat_GasMask" or fullType=="Base.Hat_NBCmask" then return 0.2 end
 if fullType=="Base.Hat_DustMask" then return 0.35 end
 if fullType=="Base.Hat_SurgicalMask" then return 0.4 end
 if fullType=="Base.Hat_BandanaMask" or fullType=="Base.Hat_RagBandanaMask" then return 0.75 end
 return 1
end
function R.sources(c,cfg)
 local out={}
 if cfg.Enabled==false or cfg.IllnessEnabled==false then return out end
 local temp=tonumber(c.temperature) or 20;local wet=tonumber(c.wetness) or 0
 local mask=cfg.MaskProtectionEnabled==false and 0 or (tonumber(c.mask) or 0)
 local gloves=tonumber(c.gloves) or 0
 local cold=math.max(0,(10-temp)/15)+(wet>=60 and 0.6 or 0)+(c.wind or 0)*0.3
 if cfg.SeasonalIllnessEnabled~=false and temp<=8 and (wet>=50 or temp<=0) then
  local winter=c.month==12 or c.month==1 or c.month==2
  out["env:cold:throat"]={kind="environment",condition="soreThroat",part="Neck",intensity=cold*(1-mask*0.5),grace=2,risk=0.04}
  if winter then out["env:cold:flu"]={kind="environment",condition="flu",intensity=cold*(1-mask*0.4),grace=4,risk=0.025} end
 end
 if cfg.ColdInjuryEnabled~=false and temp<=0 and gloves<0.8 then
  for _,part in ipairs({"Hand_L","Hand_R"})do
   out["env:cold:"..part]={kind="environment",condition="coldHands",part=part,intensity=cold*(1-gloves),grace=2,risk=0.2}
  end
 end
 if cfg.SeasonalIllnessEnabled~=false and temp>=29 and wet>=60 then
  out["env:heat"]={kind="environment",condition="heatExhaustion",intensity=(temp-25)/10,grace=2,risk=0.08}
 end
 local summer=c.month and c.month>=6 and c.month<=9
 if cfg.MosquitoIllnessEnabled~=false and summer and temp>=24 and c.outdoors and (c.humidity or 0)>=0.45 and (c.skinExposure or 0)>0.15 then
  local protected=c.repellent and 0.2 or 1
  out["env:mosquito"]={kind="environment",condition="mosquitoFever",intensity=(c.skinExposure or 0)*protected,grace=3,risk=0.03}
 end
 return out
end
return R
