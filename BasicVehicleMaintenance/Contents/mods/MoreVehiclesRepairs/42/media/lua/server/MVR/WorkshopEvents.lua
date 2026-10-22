-- Authoritative lifecycle maintenance. Native item/max-capacity and part state are persisted
-- and replicated; this scan also catches repairs performed by another normal game action.
require "MVR/Game"
require "Vehicles/TimedActions/ISInstallVehiclePart"
require "Vehicles/TimedActions/ISRepairEngine"

local function wrap(class)
    if class._MVRWorkshopComplete then return end
    class._MVRWorkshopComplete = true
    local original = class.complete
    function class:complete()
        local result = original(self)
        if not isClient() and self.vehicle then MVR.Game.reapplyVehicle(self.vehicle) end
        return result
    end
end
wrap(ISInstallVehiclePart)
wrap(ISRepairEngine)

local ticks = 0
local function onTick()
    if isClient() then return end
    ticks = ticks + 1
    if ticks < 60 then return end
    ticks = 0
    local cell = getCell()
    if not cell then return end
    local vehicles = cell:getVehicles()
    for i = 0, vehicles:size() - 1 do MVR.Game.reapplyVehicle(vehicles:get(i)) end
end
Events.OnTick.Add(onTick)
