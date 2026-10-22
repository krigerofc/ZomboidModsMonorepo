-- Replica cache reconstruction only; authoritative changes remain in the shared timed action.
require "MVR/Game"
local ticks = 0
Events.OnTick.Add(function()
    if not isClient() then return end
    ticks = ticks + 1
    if ticks < 60 then return end
    ticks = 0
    local cell = getCell()
    if not cell then return end
    local vehicles = cell:getVehicles()
    for i = 0, vehicles:size() - 1 do MVR.Game.refreshReplica(vehicles:get(i)) end
end)
