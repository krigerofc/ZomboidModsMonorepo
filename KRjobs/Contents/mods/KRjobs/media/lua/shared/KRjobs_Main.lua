-- KRjobs v2 - event wiring (identical file in B41 and B42).
local Core = require "KRjobs/Core"

Events.OnNewGame.Add(Core.onNewGame)
Events.EveryOneMinute.Add(Core.onEveryOneMinute)
