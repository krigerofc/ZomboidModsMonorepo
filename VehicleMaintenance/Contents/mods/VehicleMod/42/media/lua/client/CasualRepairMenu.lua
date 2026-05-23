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

-- Status keys: "ok", "no_damage", "above_cap", "not_installed", "missing_items"
function MVR_RepairMenu.buildTooltip(config, player, breakChance, missingItems, status, currentCondition)
    local inventory = player and player:getInventory()
    local lines = { "--- Casual Repair ---" }

    if status == "no_damage" then
        table.insert(lines, "\n[!] This part is undamaged. Nothing to repair.")
        table.insert(lines, "    (condition: " .. tostring(currentCondition or "100") .. "/100)")
    elseif status == "above_cap" then
        table.insert(lines, "\n[!] This part is too well-maintained for casual repair.")
        table.insert(lines, "    (current " .. tostring(currentCondition) .. " is above casual cap " .. config.conditionCap .. ")")
    elseif status == "not_installed" then
        table.insert(lines, "\n[!] This part is not installed on the vehicle.")
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

-- Adds the "Casual Repair" entry to a vehicle-part context menu.
-- Generic by design: the option appears for ANY part with a valid id, even when
-- not actionable. notAvailable + tooltip explain why when it can't be used.
-- Reused for ISVehicleMechanics and (defensively) ISCarMechanicsOverlay if present.
function MVR_RepairMenu.addRepairOption(self, vehiclePart)
    if not vehiclePart or not vehiclePart:getId() then return end
    if not self.context then return end
    if not MVR_RepairConfig then return end

    local player = getSpecificPlayer(0)
    if not player then return end

    -- Diagnostic: only logs in debug mode
    if MVR_RepairConfig.DEBUG then
        if not MVR_RepairMenu._seenParts then MVR_RepairMenu._seenParts = {} end
        local partId = vehiclePart:getId()
        if not MVR_RepairMenu._seenParts[partId] then
            MVR_RepairMenu._seenParts[partId] = true
            print("[MVR_RepairMenu] Right-clicked partId='" .. partId .. "' condition=" .. tostring(vehiclePart:getCondition()))
        end
    end

    local config = MVR_RepairConfig.getConfigForPart(vehiclePart)
    -- nil config => part is explicitly non-repairable (e.g. headlight bulbs).
    -- Skip menu entirely so the option does NOT appear at all.
    if not config then return end
    local condition = vehiclePart:getCondition()
    local hasItems, missingItems = MVR_RepairMenu.hasRequiredItems(player, config)
    local breakChance = MVR_RepairMenu.getAdjustedBreakChance(player, config)

    -- Determine status (drives notAvailable + tooltip explanation)
    -- "not_installed" check is best-effort: some parts return non-nil InventoryItem
    -- even when uninstalled; we only block when both signals agree.
    local status
    if not condition then
        status = "not_installed"
    elseif condition >= 100 then
        status = "no_damage"
    elseif condition >= config.conditionCap then
        status = "above_cap"
    elseif not hasItems then
        status = "missing_items"
    else
        status = "ok"
    end

    local option = self.context:addOption("Casual Repair", self, MVR_RepairMenu.onCasualRepair, vehiclePart)

    local tooltip = ISToolTip:new()
    tooltip:initialise()
    tooltip:setVisible(false)
    tooltip.description = MVR_RepairMenu.buildTooltip(config, player, breakChance, missingItems, status, condition)
    option.toolTip = tooltip
    option.notAvailable = (status ~= "ok")
end

-- Hook into the standard vehicle mechanics context menu
local originalDoPartContextMenu = ISVehicleMechanics.doPartContextMenu
function ISVehicleMechanics:doPartContextMenu(vehiclePart, x, y)
    originalDoPartContextMenu(self, vehiclePart, x, y)
    MVR_RepairMenu.addRepairOption(self, vehiclePart)
end

-- Defensive: ISCarMechanicsOverlay exists in some B42 builds and may build its own
-- part menu for certain vehicles. Hook it the same way if both class and method exist.
if ISCarMechanicsOverlay and ISCarMechanicsOverlay.doPartContextMenu then
    local originalOverlay = ISCarMechanicsOverlay.doPartContextMenu
    function ISCarMechanicsOverlay:doPartContextMenu(vehiclePart, x, y)
        originalOverlay(self, vehiclePart, x, y)
        MVR_RepairMenu.addRepairOption(self, vehiclePart)
    end
end
