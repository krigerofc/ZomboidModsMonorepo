require "TimedActions/ISBaseTimedAction"

local MVR_MODULE = "MoreVehiclesRepairs"

-- ─── helpers (file-local) ──────────────────────────────────────────────────

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

local function validateRequirements(inventory, config)
    for itemType, qty in pairs(config.materials) do
        if countItem(inventory, itemType) < qty then return false end
    end
    for _, toolType in ipairs(config.tools) do
        if not hasItem(inventory, toolType) then return false end
    end
    return true
end

-- Computes the new condition after a successful repair.
-- Rule: ADD gain to current, clamp at conditionCap when below cap; never reduce.
local function computeNewCondition(currentCondition, gain, cap)
    local result = currentCondition + gain
    if currentCondition < cap and result > cap then result = cap end
    if result > 100 then result = 100 end
    if result < currentCondition then result = currentCondition end
    return result
end

-- Random hand body part (Hand_R or Hand_L) — injuries stay on the hand only
local function randomHand(player)
    local bodyDamage = player:getBodyDamage()
    if not bodyDamage then return nil end
    -- [VERIFICAR] BodyPartType.Hand_R / Hand_L constants in b42
    local handType = ZombRand(2) == 0 and BodyPartType.Hand_R or BodyPartType.Hand_L
    return bodyDamage:getBodyPart(handType)
end

-- Cosmetic events: injury, burn, toolBreak, stress.
-- Does NOT cover critSuccess or extraMaterial — those are authority decisions.
local function rollCosmeticEvents(player, config)
    local inventory = player:getInventory()

    for _, event in ipairs(MVR_RepairConfig.RandomEvents) do
        if ZombRand(100) < math.floor(event.chance * 100) then

            if event.id == "injury" then
                local bodyPart = randomHand(player)
                -- [VERIFICAR] SetScratchedWindow — confirm correct wound method in b42
                if bodyPart then bodyPart:SetScratchedWindow(true) end
                player:Say("Ouch, cut my hand!")

            elseif event.id == "burn" and config.requiresHeat then
                local bodyPart = randomHand(player)
                -- [VERIFICAR] setBurned method in b42
                if bodyPart then bodyPart:setBurned(true) end
                player:Say("That's hot!")

            elseif event.id == "toolBreak" and #config.tools > 0 then
                if inventory then
                    local tool = inventory:FindAndReturn(config.tools[1])
                    if tool and tool.getCondition then
                        tool:setCondition(math.max(0, tool:getCondition() - 30))
                    end
                end
                player:Say("That took a toll on my tool.")

            elseif event.id == "stress" then
                -- [VERIFICAR] exact stats method names in b42
                local stats = player:getStats()
                if stats then
                    local current = stats:getUnhappyness()
                    if current then stats:setUnhappyness(math.min(100, current + 20)) end
                end
                player:Say("This is really frustrating...")
            end
        end
    end
end

-- ─── class definition ──────────────────────────────────────────────────────

-- [B42] Prefixed name to avoid global namespace collision with other mods.
MVR_CasualRepairAction = ISBaseTimedAction:derive("MVR_CasualRepairAction")

function MVR_CasualRepairAction:new(character, vehiclePart, config)
    local o = ISBaseTimedAction.new(self, character)
    setmetatable(o, self)
    self.__index = self
    o.vehiclePart      = vehiclePart
    o.config           = config
    o.stopOnWalk       = true
    o.stopOnRun        = true
    o.forceProgressBar = true
    o.maxTime          = config.repairTime
    if character:isTimedActionInstant() then o.maxTime = 1 end
    return o
end

function MVR_CasualRepairAction:isValid()
    if not self.vehiclePart or not self.vehiclePart:getId() then return false end
    local condition = self.vehiclePart:getCondition()
    if not condition then return false end
    return condition < 100
end

function MVR_CasualRepairAction:waitToStart()
    return false
end

function MVR_CasualRepairAction:start()
    -- Generic PZ "working on something" animation. Used by ISFixAction and other vanilla repair actions.
    -- [VERIFICAR] alternatives: "VehicleWorkOnTire", "Mechanic", "Build"
    self:setActionAnim("Loot")
end

function MVR_CasualRepairAction:update()
end

function MVR_CasualRepairAction:stop()
    ISBaseTimedAction.stop(self)
end

function MVR_CasualRepairAction:perform()
    if isClient() then
        -- MP: send command and wait for server result (cosmetic events fire on success in onServerCommand)
        local vehicle = self.vehiclePart:getVehicle()
        if vehicle then
            -- [VERIFICAR] vehicle:getOnlineID() — confirm exact method name in b42
            sendClientCommand(self.character, MVR_MODULE, "doRepair", {
                vehicleOnlineId = vehicle:getOnlineID(),
                partId          = self.vehiclePart:getId(),
            })
        end
    else
        -- SP: full authority, execute everything inline
        MVR_CasualRepairAction.executeRepair(self.character, self.vehiclePart, self.config)
    end

    ISBaseTimedAction.perform(self)
end

-- ─── full repair (singleplayer — has authority over everything) ────────────

function MVR_CasualRepairAction.executeRepair(player, vehiclePart, config)
    if not player or not vehiclePart or not config then return end
    local inventory = player:getInventory()
    if not inventory then return end

    local currentCondition = vehiclePart:getCondition()
    if not currentCondition or currentCondition >= 100 then return end

    if currentCondition >= config.conditionCap then
        player:Say("This part is in too good shape for casual repair.")
        return
    end

    -- Re-validate materials AND tools (player may have dropped items mid-action)
    if not validateRequirements(inventory, config) then
        player:Say("I don't have the materials anymore.")
        return
    end

    for itemType, qty in pairs(config.materials) do
        consumeMaterial(inventory, itemType, qty)
    end

    -- extraMaterial: consume one extra unit of any material
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
    if extraMaterialUsed then player:Say("Wasted some material...") end

    -- critSuccess skips break roll and gives bonus gain
    local critSuccess = ZombRand(100) < 5

    rollCosmeticEvents(player, config)

    if critSuccess then
        local gain    = math.floor(config.conditionGain * 1.5)
        local newCond = computeNewCondition(currentCondition, gain, config.conditionCap)
        vehiclePart:setCondition(newCond)
        player:Say("Nailed it! Condition: " .. tostring(newCond))
        return
    end

    local mechLevel            = player:getPerkLevel(Perks.Mechanics) or 0
    local reduction            = math.max(0, mechLevel - MVR_RepairConfig.SkillThreshold) * MVR_RepairConfig.SkillBreakReduction
    local effectiveBreakChance = math.max(MVR_RepairConfig.MinBreakChance, config.breakChance - reduction)

    if ZombRand(100) < math.floor(effectiveBreakChance * 100) then
        vehiclePart:setCondition(0)
        player:Say("It just gave out completely!")
    else
        local newCond = computeNewCondition(currentCondition, config.conditionGain, config.conditionCap)
        vehiclePart:setCondition(newCond)
        player:Say("Patched it up. Condition: " .. tostring(newCond))
    end
end

-- ─── MP: receive server result, apply local effects and show feedback ──────

local function onServerCommand(module, command, args)
    if module ~= MVR_MODULE or command ~= "repairResult" then return end
    local player = getSpecificPlayer(0)
    if not player then return end

    if not args.success then
        if args.reason == "missing_items" then
            player:Say("I don't have the materials anymore.")
        elseif args.reason == "above_cap" then
            player:Say("This part is in too good shape for casual repair.")
        end
        return
    end

    -- Look up the part to retrieve its config (needed for cosmetic event rolls — requiresHeat etc.)
    -- [VERIFICAR] getVehicleByOnlineID — confirm exact global function name in b42
    local config
    if args.vehicleOnlineId and getVehicleByOnlineID then
        local vehicle = getVehicleByOnlineID(args.vehicleOnlineId)
        if vehicle and args.partId then
            local part = vehicle:getPartById(args.partId)
            if part then config = MVR_RepairConfig.getConfigForPart(part) end
        end
    end

    if config then rollCosmeticEvents(player, config) end

    if args.extraMaterialUsed then player:Say("Wasted some material...") end

    if args.critSuccess then
        player:Say("Nailed it! Condition: " .. tostring(args.newCondition))
    elseif args.broke then
        player:Say("It just gave out completely!")
    else
        player:Say("Patched it up. Condition: " .. tostring(args.newCondition))
    end
end

Events.OnServerCommand.Add(onServerCommand)
