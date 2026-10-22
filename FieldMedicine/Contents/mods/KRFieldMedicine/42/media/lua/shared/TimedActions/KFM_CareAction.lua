require "TimedActions/ISBaseTimedAction"
local H=require "KFM/Health"
KFM_CareAction=ISBaseTimedAction:derive("KFM_CareAction")
function KFM_CareAction:isValid()
 if not H.reachable(self.character,self.otherPlayer) then return false end
 if self.item and not self.character:getInventory():containsID(self.item:getID()) then return false end
 return true
end
function KFM_CareAction:waitToStart()
 if self.character==self.otherPlayer then return false end
 self.character:faceThisObject(self.otherPlayer)
 return self.character:shouldBeTurning()
end
function KFM_CareAction:start()
 self:setActionAnim(self.character==self.otherPlayer and CharacterActionAnims.Bandage or "Loot")
end
function KFM_CareAction:update()
 self.character:setMetabolicTarget(Metabolics.LightDomestic)
end
function KFM_CareAction:perform() ISBaseTimedAction.perform(self) end
function KFM_CareAction:complete()
 if self:isValid() then H.treat(self.character,self.otherPlayer,self.episodeKey,self.treatment,self.item,self.episodeId) end
 return true
end
function KFM_CareAction:getDuration() return math.max(100,200-self.character:getPerkLevel(Perks.Doctor)*6)*H.medicalTime(self.character) end
function KFM_CareAction:new(character,otherPlayer,episodeKey,episodeId,treatment,item)
 local o=ISBaseTimedAction.new(self,character)
 o.otherPlayer=otherPlayer;o.episodeKey=episodeKey;o.episodeId=episodeId;o.treatment=treatment;o.item=item
 o.stopOnWalk=true;o.stopOnRun=true;o.maxTime=o:getDuration()
 return o
end
