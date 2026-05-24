-- ZombieDisguise — World context menu (client-side)
-- Adds a "Disguise" option when the player right-clicks a dead zombie body.

ZD_Menu = ZD_Menu or {}

local function onFillWorldObjectContextMenu(playerNum, context, worldObjects, test)
    if test then return end

    local player = getSpecificPlayer(playerNum)
    if not player then return end

    -- Find a dead body among the world objects.
    local deadBody = nil
    for i = 0, worldObjects:size() - 1 do
        local obj = worldObjects:get(i)
        if instanceof(obj, "IsoDeadBody") then
            deadBody = obj
            break
        end
    end

    if not deadBody then return end

    local modData = player:getModData()
    local option  = context:addOption("Disguise", worldObjects, nil)

    if modData.ZD_active then
        -- Player already disguised: show disabled option with explanation.
        local tooltip = ISToolTip:new()
        tooltip:initialise()
        tooltip:setVisible(false)
        tooltip.description = "You are already disguised."
        option.toolTip      = tooltip
        option.notAvailable = true
        return
    end

    option.onSelect     = ZD_Menu.onSelectDisguise
    option.onSelectArg1 = player
    option.onSelectArg2 = deadBody
end

function ZD_Menu.onSelectDisguise(worldObjects, player, deadBody)
    if not player then return end
    -- Optimistic lock: prevent a second Disguise option click during the ~7-min action.
    -- The server remains authoritative; this only blocks the client UI until disguiseGranted arrives.
    player:getModData().ZD_active = true
    ISTimedActionQueue.add(ZDDisguiseAction:new(player, deadBody))
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
