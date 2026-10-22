-- B42 native timed-action authority, following ISGrabCorpseAction.corpseBody and serverStart/serverStop.
require "TimedActions/ISBaseTimedAction"
local G=require "ZD/Game"
ZDDisguiseAction=ISBaseTimedAction:derive("ZDDisguiseAction")
function ZDDisguiseAction:isValid()
 return G.available() and G.cfg().Enabled and G.valid(self.character,self.corpseBody) and not G.state(self.character).active
end
function ZDDisguiseAction:waitToStart()
 self.character:faceThisObject(self.corpseBody)
 return self.character:shouldBeTurning()
end
function ZDDisguiseAction:serverStart()
 if isClient() or not self:isValid() then return end
 local sq=self.corpseBody:getSquare()
 G.pending[self.character]={action=self,actor=self.character,corpse=self.corpseBody,square=sq,index=self.corpseBody:getStaticMovingObjectIndex(),x=self.character:getX(),y=self.character:getY(),z=self.character:getZ()}
end
function ZDDisguiseAction:start()
 self:setActionAnim("Loot")
 if not isClient() and not isServer() then self:serverStart() end
end
function ZDDisguiseAction:serverStop()
 local p=G.pending[self.character]
 if p and p.action==self then G.pending[self.character]=nil end
end
function ZDDisguiseAction:stop()
 if not isClient() and not isServer() then self:serverStop() end
 ISBaseTimedAction.stop(self)
end
function ZDDisguiseAction:update()
 self.character:faceThisObject(self.corpseBody)
 self.character:setMetabolicTarget(Metabolics.LightDomestic)
end
function ZDDisguiseAction:perform() ISBaseTimedAction.perform(self) end
function ZDDisguiseAction:complete()
 if isClient() then return false end
 local p=G.pending[self.character]
 if not p or p.action~=self or p.actor~=self.character or p.corpse~=self.corpseBody then return false end
 local progress=self.netAction and self.netAction:getProgress() or (self.action and self:getJobDelta()) or 0
 if progress<0.999 or not self:isValid() or self.corpseBody:getSquare()~=p.square or self.corpseBody:getStaticMovingObjectIndex()~=p.index
  or self.character:getX()~=p.x or self.character:getY()~=p.y or self.character:getZ()~=p.z then G.pending[self.character]=nil;return false end
 G.pending[self.character]=nil
 return G.grant(self.character,p)
end
function ZDDisguiseAction:getDuration()return 420 end
function ZDDisguiseAction:new(character,corpseBody)
 local o=ISBaseTimedAction.new(self,character)
 o.corpseBody=corpseBody;o.stopOnWalk=true;o.stopOnRun=true;o.stopOnAim=true;o.maxTime=o:getDuration()
 return o
end
