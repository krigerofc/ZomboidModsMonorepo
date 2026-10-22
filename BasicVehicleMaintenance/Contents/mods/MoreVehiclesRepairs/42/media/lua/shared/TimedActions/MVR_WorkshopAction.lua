require "TimedActions/ISBaseTimedAction"
require "MVR/Game"

MVR_WorkshopAction = ISBaseTimedAction:derive("MVR_WorkshopAction")

function MVR_WorkshopAction:isValid()
    return self.part and self.part:getVehicle() == self.vehicle
        and tostring(MVR.Game.installedItemId(self.part) or "") == self.expectedItemId
        and MVR.Game.workshopRevision(self.part) == self.expectedRevision
        and MVR.Game.workAllowed(self.character, self.part)
        and MVR.Game.evaluateWorkshop(self.character, self.part, self.operation, self.choice).status == "ok"
end
function MVR_WorkshopAction:waitToStart()
    self.character:faceThisObject(self.vehicle)
    return self.character:shouldBeTurning()
end
function MVR_WorkshopAction:update()
    self.character:faceThisObject(self.vehicle)
    self.character:setMetabolicTarget(Metabolics.MediumWork)
end
function MVR_WorkshopAction:start()
    self:setActionAnim("VehicleWorkOnMid")
end
function MVR_WorkshopAction:stop()
    ISBaseTimedAction.stop(self)
end
function MVR_WorkshopAction:perform()
    ISBaseTimedAction.perform(self)
end
function MVR_WorkshopAction:complete()
    if not self:isValid() then return false end
    local result = MVR.Game.applyWorkshop(self.character, self.part, self.operation, self.choice, self.expectedItemId, self.expectedRevision)
    result.onlineId = self.character:getOnlineID()
    MVR.Game.feedback(self.character, result)
    return result.status == "customized"
end
function MVR_WorkshopAction:getDuration()
    if self.character:isTimedActionInstant() then return 1 end
    return MVR.Game.evaluateWorkshop(self.character, self.part, self.operation, self.choice).time or 300
end
function MVR_WorkshopAction:new(character, part, operation, choice, expectedItemId, expectedRevision)
    local o = ISBaseTimedAction.new(self, character)
    o.part, o.vehicle = part, part and part:getVehicle()
    o.operation, o.choice = operation, choice
    o.expectedItemId = expectedItemId or tostring(part and MVR.Game.installedItemId(part) or "")
    o.expectedRevision = expectedRevision or (part and MVR.Game.workshopRevision(part) or 0)
    o.stopOnWalk, o.stopOnRun, o.forceProgressBar = true, true, true
    o.maxTime = o:getDuration()
    o.jobType = getText("IGUI_MVR_WorkshopJob")
    return o
end
