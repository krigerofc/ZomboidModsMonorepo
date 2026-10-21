-- KRjobs v2 - starting kits for profession traits (identical file in B41 and B42).
-- A kit is 1-3 vanilla tools/clothes given once, when a new character is created (OnNewGame).
-- Trait ids: B42 "krjobs:<id>" (CharacterTrait registry), B41 "KRjobs_<Name>" (B41 trait type).
local Kits = require "KRjobs/Kits"

local Core = {}
Core.MODDATA_KEY = "KRjobsKitGiven"

-- true when the character has the trait, for either build; never throws
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

-- gives every kit the character qualifies for, once per character; returns number of items added
function Core.giveKits(player)
    if not player then return 0 end
    local md = player:getModData()
    if md[Core.MODDATA_KEY] then return 0 end
    md[Core.MODDATA_KEY] = true
    local inv = player:getInventory()
    local added = 0
    for _, kit in ipairs(Kits) do
        if Core.hasTrait(player, kit.trait) then
            for _, fullType in ipairs(kit.items) do
                local ok, item = pcall(function() return inv:AddItem(fullType) end)
                if ok and item then added = added + 1 end
            end
        end
    end
    return added
end

function Core.onNewGame(player, square)
    Core.giveKits(player)
end

return Core
