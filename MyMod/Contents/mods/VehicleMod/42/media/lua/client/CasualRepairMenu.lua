MVR_RepairMenu = {}

local function countItem(inventory, fullType)
    local count = 0
    local items = inventory:getItems()
    if not items then return 0 end
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and item:getFullType() == fullType then count = count + 1 end
    end
    return count
end

local function hasItem(inventory, fullType)
    local items = inventory:getItems()
    if not items then return false end
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and item:getFullType() == fullType then return true end
    end
    return false
end

-- Returns: allPresent (bool), missingDescriptions (table of strings)
function MVR_RepairMenu.hasRequiredItems(player, config)
    if not player or not config then return false, {} end
    local inventory = player:getInventory()
    if not inventory then return false, {} end

    local missing = {}
    local allPresent = true

    for itemType, qty in pairs(config.materials) do
        local have = countItem(inventory, itemType)
        if have < qty then
            allPresent = false
            table.insert(missing, itemType:gsub("Base.", "") .. " x" .. qty .. " (have " .. have .. ")")
        end
    end

    for _, toolType in ipairs(config.tools) do
        if not hasItem(inventory, toolType) then
            allPresent = false
            table.insert(missing, toolType:gsub("Base.", "") .. " (tool)")
        end
    end

    return allPresent, missing
end

function MVR_RepairMenu.getAdjustedBreakChance(player, config)
    if not player or not config then return config and config.breakChance or 0.25 end
    local mechLevel = player:getPerkLevel(Perks.Mechanics)
    if not mechLevel then return config.breakChance end
    local reduction = math.max(0, mechLevel - MVR_RepairConfig.SkillThreshold) * MVR_RepairConfig.SkillBreakReduction
    return math.max(MVR_RepairConfig.MinBreakChance, config.breakChance - reduction)
end

function MVR_RepairMenu.buildTooltip(config, player, breakChance, missingItems, aboveCap)
    local inventory = player and player:getInventory()
    local lines = { "--- Casual Repair ---" }

    if aboveCap then
        table.insert(lines, "\n[!] This part is too well-maintained for casual repair.")
        table.insert(lines, "    (current condition is at or above the casual cap of " .. config.conditionCap .. ")")
    end

    table.insert(lines, "\nMaterials:")
    for itemType, qty in pairs(config.materials) do
        local have = inventory and countItem(inventory, itemType) or 0
        local mark = have >= qty and "[v]" or "[x]"
        table.insert(lines, mark .. " " .. itemType:gsub("Base.", "") .. " x" .. qty)
    end

    if #config.tools > 0 then
        table.insert(lines, "\nTools:")
        for _, toolType in ipairs(config.tools) do
            local has = inventory and hasItem(inventory, toolType) or false
            local mark = has and "[v]" or "[x]"
            table.insert(lines, mark .. " " .. toolType:gsub("Base.", ""))
        end
    end

    table.insert(lines, "\nCondition gain: +" .. config.conditionGain .. " (cap: " .. config.conditionCap .. ")")
    table.insert(lines, "Break chance: " .. math.floor(breakChance * 100) .. "%")

    if missingItems and #missingItems > 0 then
        table.insert(lines, "\nMissing:")
        for _, m in ipairs(missingItems) do
            table.insert(lines, "  " .. m)
        end
    end

    return table.concat(lines, "\n")
end

function MVR_RepairMenu.onCasualRepair(self, vehiclePart)
    local player = getSpecificPlayer(0)
    if not player then return end
    if not MVR_RepairConfig then return end
    local config = MVR_RepairConfig.getConfigForPart(vehiclePart)
    ISTimedActionQueue.add(MVR_CasualRepairAction:new(player, vehiclePart, config))
end

-- Hook into the vehicle mechanics context menu
local originalDoPartContextMenu = ISVehicleMechanics.doPartContextMenu

function ISVehicleMechanics:doPartContextMenu(vehiclePart, x, y)
    originalDoPartContextMenu(self, vehiclePart, x, y)

    if not vehiclePart or not vehiclePart:getId() then return end
    if not self.context then return end
    if not MVR_RepairConfig then return end

    local player = getSpecificPlayer(0)
    if not player then return end

    -- Diagnostic: log every unique partId encountered once. Open console (F11) and right-click parts to see their IDs.
    if not MVR_RepairMenu._seenParts then MVR_RepairMenu._seenParts = {} end
    local partId = vehiclePart:getId()
    if not MVR_RepairMenu._seenParts[partId] then
        MVR_RepairMenu._seenParts[partId] = true
        print("[MVR_RepairMenu] Right-clicked partId='" .. partId .. "' condition=" .. tostring(vehiclePart:getCondition()))
    end

    local condition = vehiclePart:getCondition()
    if not condition or condition >= 100 then return end

    local config = MVR_RepairConfig.getConfigForPart(vehiclePart)
    local aboveCap = condition >= config.conditionCap

    local hasItems, missingItems = MVR_RepairMenu.hasRequiredItems(player, config)
    local breakChance = MVR_RepairMenu.getAdjustedBreakChance(player, config)

    local option = self.context:addOption("Casual Repair", self, MVR_RepairMenu.onCasualRepair, vehiclePart)

    local tooltip = ISToolTip:new()
    tooltip:initialise()
    tooltip:setVisible(false)
    tooltip.description = MVR_RepairMenu.buildTooltip(config, player, breakChance, missingItems, aboveCap)
    option.toolTip = tooltip
    option.notAvailable = (not hasItems) or aboveCap
end
