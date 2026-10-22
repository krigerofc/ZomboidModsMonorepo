-- Chain the native server completion; utensils/gloves and clean hands avoid this hygiene exposure.
require "TimedActions/ISEatFoodAction"
local H=require "KFM/Health"
local Game=require "KFM/Game"
if not ISEatFoodAction.KFM_hooked then
 ISEatFoodAction.KFM_hooked=true
 local original=ISEatFoodAction.complete
 ISEatFoodAction.complete=function(self)
  local dirty=false
  if not isClient() and not self.useUtensil then
   pcall(function()
    local visual=self.character:getHumanVisual()
    local gloves=Game.surgicalProtection(self.character)
    dirty=not gloves and (visual:getBlood(BloodBodyPartType.Hand_L)+visual:getDirt(BloodBodyPartType.Hand_L)+visual:getBlood(BloodBodyPartType.Hand_R)+visual:getDirt(BloodBodyPartType.Hand_R))>=0.8
   end)
  end
  local result=original(self)
  if result and not isClient() and not self.KFM_ingested then
   self.KFM_ingested=true;H.afterEating(self.character,self.item,self.percentage,dirty)
  end
  return result
 end
end
