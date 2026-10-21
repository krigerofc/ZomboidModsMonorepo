-- Passive Skills v2 - client side: feedback from the server (B42 MP) and read-list mirror sync.
local Game = require "PassiveSkills/Game"

Events.OnServerCommand.Add(Game.onServerCommand)

-- MP only: ask the server for this character's read list so the pre-read check is accurate.
Events.OnCreatePlayer.Add(function(playerNum, player)
    if isClient() and player and Game.detectBuild() >= 42 then
        pcall(sendClientCommand, player, Game.MODULE, "requestSync", {})
    end
end)
