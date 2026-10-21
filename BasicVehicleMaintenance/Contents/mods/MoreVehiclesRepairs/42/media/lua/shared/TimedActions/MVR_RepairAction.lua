-- Basic Vehicle Maintenance - improvised repair TimedAction (B42.13+ pattern).
-- Lives in shared/ so the server can rebuild it: B42 re-creates the action on the server by
-- calling MVR_RepairAction:new() with the fields named like new()'s parameters (character,
-- part, tierId, dark, expectedItemId). Everything authoritative happens in complete().
require "TimedActions/ISBaseTimedAction"
require "MVR/Game"

MVR_RepairAction = ISBaseTimedAction:derive("MVR_RepairAction")

local MAX_DIST = 6 -- tiles from the vehicle centre (cars are ~5 tiles long)

function MVR_RepairAction:isValid()
    local part = self.part
    if not part or not self.vehicle then return false end
    if part:getVehicle() ~= self.vehicle then return false end
    if not MVR.Game.isPartPresent(part) then return false end
    if tostring(MVR.Game.installedItemId(part) or "") ~= self.expectedItemId then return false end
    if self.character:getVehicle() then return false end
    return self.character:DistTo(self.vehicle:getX(), self.vehicle:getY()) <= MAX_DIST
end

function MVR_RepairAction:waitToStart()
    self.character:faceThisObject(self.vehicle)
    return self.character:shouldBeTurning()
end

function MVR_RepairAction:update()
    self.character:faceThisObject(self.vehicle)
    local item = self.part:getInventoryItem()
    if item then item:setJobDelta(self:getJobDelta()) end
    self.character:setMetabolicTarget(Metabolics.MediumWork)
end

function MVR_RepairAction:start()
    local item = self.part:getInventoryItem()
    if item then
        item:setJobType(getText("IGUI_MVR_Job"))
        item:setJobDelta(0)
    end
    local id = self.part:getId()
    if self.part:getWheelIndex() ~= -1 or string.find(id, "Brake", 1, true) or string.find(id, "Suspension", 1, true) then
        self:setActionAnim("VehicleWorkOnTire")
    else
        self:setActionAnim("VehicleWorkOnMid")
    end
end

local function clearJob(self)
    local item = self.part and self.part:getInventoryItem()
    if item then item:setJobDelta(0) end
end

function MVR_RepairAction:stop()
    clearJob(self)
    ISBaseTimedAction.stop(self)
end

function MVR_RepairAction:perform()
    clearJob(self)
    ISBaseTimedAction.perform(self)
end

-- Server (MP) or local (SP): revalidate, consume, roll, apply, sync, XP, side effects.
function MVR_RepairAction:complete()
    if not self:isValid() then return false end
    local result = MVR.Game.applyRepair(self.character, self.part, self.tierId, self.dark)
    result.onlineId = self.character:getOnlineID()
    MVR.Game.feedback(self.character, result)
    return true
end

function MVR_RepairAction:getDuration()
    if self.character:isTimedActionInstant() then return 1 end
    local opts = MVR.Game.opts()
    local cfg = MVR.Core.getConfig(self.part:getId())
    local tier = opts.QualityTiersEnabled and MVR.Core.getTier(self.tierId) or MVR.Config.Tiers[1]
    return MVR.Core.duration(cfg, tier, opts, MVR.Game.hasJack(self.character))
end

function MVR_RepairAction:new(character, part, tierId, dark, expectedItemId)
    local o = ISBaseTimedAction.new(self, character)
    o.part = part
    o.expectedItemId = expectedItemId or tostring(MVR.Game.installedItemId(part) or "")
    o.vehicle = part and part:getVehicle() or nil
    o.tierId = tierId or "patch"
    o.dark = dark and true or false
    o.stopOnWalk = true
    o.stopOnRun = true
    o.forceProgressBar = true
    o.caloriesModifier = 3
    o.maxTime = o:getDuration()
    o.jobType = getText("IGUI_MVR_Job")
    return o
end
