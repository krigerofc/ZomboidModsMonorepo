-- KRjobs starting kits: the server (or single-player simulation) owns delivery.
local Kits = require "KRjobs/Kits"

local Core = {}
Core.MODDATA_KEY = "KRjobsKitGiven"
Core.PROGRESS_KEY = "KRjobsKitItems"
Core.PENDING_KEY = "KRjobsKitPending"
Core.MAX_RETRIES = 5

function Core.hasTrait(player, traitId)
    if not player or not traitId then return false end
    if CharacterTrait and CharacterTrait.get and ResourceLocation then
        local ok, trait = pcall(function() return CharacterTrait.get(ResourceLocation.of(traitId)) end)
        if not ok or not trait then return false end
        local ok2, has = pcall(function() return player:hasTrait(trait) end)
        return ok2 and has == true
    end
    if player.HasTrait then
        local ok, has = pcall(function() return player:HasTrait(traitId) end)
        return ok and has == true
    end
    return false
end

function Core.giveKits(player)
    if not player or (isClient and isClient()) then return 0 end
    local md = player:getModData()
    if not md or md[Core.MODDATA_KEY] then return 0 end
    local inv = player:getInventory()
    if not inv then return 0 end
    local progress = md[Core.PROGRESS_KEY]
    if type(progress) ~= "table" then
        progress = {}
        md[Core.PROGRESS_KEY] = progress
    end
    local added, incomplete = 0, false
    for _, kit in ipairs(Kits) do
        if Core.hasTrait(player, kit.trait) then
            for index, fullType in ipairs(kit.items) do
                local key = kit.trait .. "/" .. tostring(index) .. "/" .. fullType
                if not progress[key] then
                    local ok, item = pcall(function() return inv:AddItem(fullType) end)
                    if ok and item then
                        progress[key] = true
                        added = added + 1
                    else
                        incomplete = true
                    end
                end
            end
        end
    end
    if not incomplete then
        md[Core.MODDATA_KEY] = true
        md[Core.PROGRESS_KEY] = nil
        md[Core.PENDING_KEY] = nil
    end
    return added
end

function Core.onNewGame(player, square)
    if not player or (isClient and isClient()) then return end
    local md = player:getModData()
    if not md or md[Core.MODDATA_KEY] then return end
    -- Only a newly initiated grant authorizes automatic recovery, including a nil inventory.
    if md[Core.PENDING_KEY] == nil then md[Core.PENDING_KEY] = Core.MAX_RETRIES end
    Core.giveKits(player)
end

local function retryPending(player)
    if not player or player:isDead() then return end
    local md = player:getModData()
    local remaining = md and md[Core.PENDING_KEY]
    if not md or md[Core.MODDATA_KEY] or type(remaining) ~= "number" or remaining <= 0 then return end
    -- Persist the budget so reconnecting/restarting cannot create an unlimited retry loop.
    md[Core.PENDING_KEY] = remaining - 1
    Core.giveKits(player)
end

function Core.onEveryOneMinute()
    if isClient and isClient() then return end
    -- Native XpUpdate uses this same server/solo player enumeration.
    -- Inspect only ModData once per game minute; inventories are opened only for pending grants.
    if isServer() then
        local players = getOnlinePlayers()
        for i = 0, players:size() - 1 do retryPending(players:get(i)) end
    else
        for i = 0, getNumActivePlayers() - 1 do retryPending(getSpecificPlayer(i)) end
    end
end

return Core
