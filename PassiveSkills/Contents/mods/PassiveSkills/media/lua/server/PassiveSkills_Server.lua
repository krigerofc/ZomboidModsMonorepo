-- Passive Skills v2 - server side (also runs in SP): magazine spawning and read-list sync.
-- Spawning is one explicit roll per filled eligible container (no vanilla distribution tables are
-- touched, so magazines can never double-spawn through vanilla loot lists).
local Game = require "PassiveSkills/Game"

Events.OnFillContainer.Add(Game.onFillContainer)
Events.OnClientCommand.Add(Game.onClientCommand)
