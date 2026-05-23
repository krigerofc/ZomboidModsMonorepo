local MVR_MODULE = "MoreVehiclesRepairs"

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

local function consumeMaterial(inventory, fullType, qty)
    for _ = 1, qty do
        local item = inventory:FindAndReturn(fullType)
        if item then inventory:Remove(item) end
    end
end

-- Validates materials AND tools (anti-cheat)
local function validateRequirements(inventory, config)
    for itemType, qty in pairs(config.materials) do
        if countItem(inventory, itemType) < qty then return false end
    end
    for _, toolType in ipairs(config.tools) do
        if not hasItem(inventory, toolType) then return false end
    end
    return true
end

local function onClientCommand(module, command, player, args)
    if module ~= MVR_MODULE or command ~= "doRepair" then return end
    if not player or not args then return end

    local vehicle = args.vehicleId and getVehicleById(args.vehicleId)
    if not vehicle then
        sendServerCommand(player, MVR_MODULE, "repairResult", { success = false, reason = "vehicle_not_found" })
        return
    end

    local vehiclePart = vehicle:getPartById(args.partId)
    if not vehiclePart then
        sendServerCommand(player, MVR_MODULE, "repairResult", { success = false, reason = "part_not_found" })
        return
    end

    local condition = vehiclePart:getCondition()
    if not condition or condition >= 100 then
        sendServerCommand(player, MVR_MODULE, "repairResult", { success = false, reason = "part_not_damaged" })
        return
    end

    local config = MVR_RepairConfig.getConfigForPart(vehiclePart)

    if condition >= config.conditionCap then
        sendServerCommand(player, MVR_MODULE, "repairResult", { success = false, reason = "above_cap" })
        return
    end

    local inventory = player:getInventory()
    if not inventory or not validateRequirements(inventory, config) then
        sendServerCommand(player, MVR_MODULE, "repairResult", { success = false, reason = "missing_items" })
        return
    end

    -- Consume base materials
    for itemType, qty in pairs(config.materials) do
        consumeMaterial(inventory, itemType, qty)
    end

    -- extraMaterial: server consumes one extra unit
    local extraMaterialUsed = false
    if ZombRand(100) < 10 then
        for itemType, _ in pairs(config.materials) do
            local item = inventory:FindAndReturn(itemType)
            if item then
                inventory:Remove(item)
                extraMaterialUsed = true
                break
            end
        end
    end

    -- ADDS gain to current, clamped at cap when below cap; never reduces.
    local function computeNewCondition(current, gain, cap)
        local result = current + gain
        if current < cap and result > cap then result = cap end
        if result > 100 then result = 100 end
        if result < current then result = current end
        return result
    end

    -- critSuccess skips break roll and gives bonus gain
    local critSuccess = ZombRand(100) < 5
    local broke       = false
    local newCond

    if critSuccess then
        local gain = math.floor(config.conditionGain * 1.5)
        newCond = computeNewCondition(condition, gain, config.conditionCap)
    else
        local mechLevel            = player:getPerkLevel(Perks.Mechanics) or 0
        local reduction            = math.max(0, mechLevel - MVR_RepairConfig.SkillThreshold) * MVR_RepairConfig.SkillBreakReduction
        local effectiveBreakChance = math.max(MVR_RepairConfig.MinBreakChance, config.breakChance - reduction)

        if ZombRand(100) < math.floor(effectiveBreakChance * 100) then
            broke   = true
            newCond = 0
        else
            newCond = computeNewCondition(condition, config.conditionGain, config.conditionCap)
        end
    end

    vehiclePart:setCondition(newCond)
    vehicle:transmitPartCondition(vehiclePart)

    sendServerCommand(player, MVR_MODULE, "repairResult", {
        success           = true,
        broke             = broke,
        critSuccess       = critSuccess,
        extraMaterialUsed = extraMaterialUsed,
        newCondition      = vehiclePart:getCondition(),
        vehicleId         = args.vehicleId,
        partId            = args.partId,
    })
end

Events.OnClientCommand.Add(onClientCommand)
