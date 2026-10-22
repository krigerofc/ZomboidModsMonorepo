-- Per-instance workshop adapter. Invoked by Game after its repair adapter is defined.
-- All authoring happens in complete() on the simulation; the client only previews intentions.
require "MVR/Upgrades"
local U = MVR.Upgrades

return function(Game)
    local Core = MVR.Core
    local function attempt(fn)
        local ok, value = pcall(fn)
        if ok then return value end
        return nil
    end
    local function state(part)
        local md = part:getModData()
        if type(md.MVR) ~= "table" then md.MVR = {} end
        return md.MVR
    end
    local function anchor(part)
        local v = part:getVehicle()
        return v:getPartById("Engine") or v:getPartByIndex(0) or part
    end
    function Game.workshopRevision(part)
        local md = anchor(part):getModData()
        return type(md.MVR) == "table" and tonumber(md.MVR.workRevision) or 0
    end
    local function bump(part)
        local a = anchor(part)
        state(a).workRevision = Game.workshopRevision(part) + 1
        a:getVehicle():transmitPartModData(a)
    end
    function Game.partRole(part)
        local it = part:getInventoryItem()
        local update = attempt(function() return part:getLuaFunction("update") end)
        local special = type(update) == "string" and string.find(update, "TrailerAnimal", 1, true) ~= nil
        local role = U.role({ id = part:getId(), inventory = part:getItemContainer() ~= nil, itemType = it and it:getFullType(), special = special })
        if role == "cargo" and (attempt(function() return part:getVehicle():getAnimalTrailerSize() end) or 0) > 0 then return nil end
        return role
    end
    function Game.upgradeRecord(part)
        if part:getId() == "Engine" then
            local md = part:getModData()
            return type(md.MVR) == "table" and md.MVR.upgrade or nil
        end
        local item = part:getInventoryItem()
        return item and item:getModData().MVRUpgrade or nil
    end
    local function itemIdentity(part)
        return tostring(Game.installedItemId(part) or "")
    end
    local function baseValue(part, role)
        if role == "power" then return part:getVehicle():getEnginePower() end
        local it = part:getInventoryItem()
        return it and it:getMaxCapacity()
    end
    function Game.workAccess(chr, part)
        if not chr or not part then return false end
        local requiresKey = attempt(function() return part:getScriptPart():isMechanicRequireKey() end)
        if requiresKey == false then return true end
        if requiresKey ~= true then return false end
        if SandboxVars and SandboxVars.VehicleEasyUse then return true end
        local vehicle = part:getVehicle()
        -- Mirrors native key/door/window semantics without the client-only mechanics-cheat global.
        if VehicleUtils and attempt(function() return VehicleUtils.CheckForUnlockedDoorsWindows(vehicle) end) == true then return true end
        local key = attempt(function() return chr:getInventory():haveThisKeyId(vehicle:getKeyId()) end)
        return key ~= nil and key ~= false
    end

    Game.Palette = {
        { id = "red", item = "Base.PaintRed", h = 0, s = 0.8, v = 0.65 },
        { id = "blue", item = "Base.PaintBlue", h = 0.62, s = 0.75, v = 0.65 },
        { id = "green", item = "Base.PaintGreen", h = 0.33, s = 0.65, v = 0.5 },
        { id = "yellow", item = "Base.PaintYellow", h = 0.14, s = 0.8, v = 0.8 },
        { id = "orange", item = "Base.PaintOrange", h = 0.07, s = 0.8, v = 0.75 },
        { id = "purple", item = "Base.PaintPurple", h = 0.77, s = 0.65, v = 0.6 },
        { id = "brown", item = "Base.PaintBrown", h = 0.08, s = 0.65, v = 0.35 },
        { id = "black", item = "Base.PaintBlack", h = 0, s = 0, v = 0.12 },
        { id = "white", item = "Base.PaintWhite", h = 0, s = 0, v = 0.9 },
        { id = "grey", item = "Base.PaintGrey", h = 0, s = 0, v = 0.45 },
    }
    local function pigment(id)
        for _, c in ipairs(Game.Palette) do if c.id == id then return c end end
    end
    local function sameColor(v, c)
        return math.abs(v:getColorHue() - c.h) < 0.001 and math.abs(v:getColorSaturation() - c.s) < 0.001
            and math.abs(v:getColorValue() - c.v) < 0.001
    end
    local function nativeTrailer(part)
        local item = part:getInventoryItem()
        return part:getId() == "TrailerTrunk" and item and item:getFullType():match("^Base%.TrailerTrunk%d$")
    end
    local function expectedEffective(part, raw, baseline)
        if nativeTrailer(part) then
            local rec = Game.upgradeRecord(part)
            baseline = baseline or (rec and rec.base) or part:getInventoryItem():getMaxCapacity()
            return math.max(80, part:getCondition()) + raw - baseline
        end
        -- Installed native getNumberByCondition(base, condition, 5), rounded to 2 decimals then cast to int.
        -- Conservative for containers whose scripts do not reduce capacity: a loaded downgrade may
        -- require unloading farther, but can never silently produce an overloaded inventory.
        local condition = part:getCondition()
        return math.floor(math.max(5, raw * (condition + 20 * (100 - condition) / 100) / 100) * 100 + 0.5) / 100
    end
    local function conflict(part, role, rec)
        local cur = baseValue(part, role)
        if type(rec) ~= "table" then
            if role == "power" then return false end
            local capacity = part:getContainerCapacity()
            return capacity ~= cur and capacity ~= math.floor(expectedEffective(part, cur, cur))
        end
        local target = U.target(rec.base, role, rec.level)
        if not target or (cur ~= target and cur ~= rec.base) then return true end
        if role ~= "power" then
            local capacity = part:getContainerCapacity()
            if capacity ~= cur and capacity ~= math.floor(expectedEffective(part, cur, rec.base))
                and capacity ~= rec.base and capacity ~= math.floor(expectedEffective(part, rec.base, rec.base)) then return true end
        end
        return false
    end
    function Game.evaluateWorkshop(chr, part, operation, choice)
        local opts = Game.opts()
        local ev = { operation = operation, choice = choice, opts = opts, tools = {}, report = {}, reqs = {}, time = 300 }
        local function done(status) ev.status = status; return ev end
        if not opts.Enabled or (operation == "upgrade" and not opts.UpgradesEnabled)
            or (operation ~= "upgrade" and not opts.CustomizationEnabled) then return done("disabled") end
        if not chr or not part or not Game.isPartPresent(part) then return done("not_installed") end
        local v = part:getVehicle()
        if not Game.workAccess(chr, part) then return done("access") end
        local groups, toolTypes, need = {}, {}, 0
        if operation == "upgrade" then
            ev.role = Game.partRole(part)
            if not ev.role then return done("unsupported") end
            local rec = Game.upgradeRecord(part)
            if conflict(part, ev.role, rec) then return done("conflict") end
            local occupied = part:getItemContainer() and part:getItemContainer():getCapacityWeight() or 0
            local record, target, why = U.record(rec, itemIdentity(part), baseValue(part, ev.role), ev.role, choice, occupied)
            ev.target, ev.record, ev.base = target, record, rec and rec.base or baseValue(part, ev.role)
            if why ~= "ok" then return done(why) end
            if ev.role ~= "power" and occupied > math.floor(expectedEffective(part, target, record.base)) then return done("overloaded") end
            need = choice == 0 and 2 or (choice == 2 and 6 or 3)
            ev.time = choice == 2 and 900 or 450
            toolTypes = { "Base.Wrench", "Base.Screwdriver" }
            groups = { { "Base.Screws", choice == 0 and 1 or choice * 4 } }
            if choice > 0 then
                groups[#groups + 1] = { "Base.ScrapMetal", choice * (ev.role == "power" and 6 or 3) }
                groups[#groups + 1] = { "Base.SheetMetal", choice }
            end
            ev.shelterOk = choice ~= 2 or Game.isIndoors(v)
        elseif operation == "paint" then
            ev.color = pigment(choice)
            if not ev.color then return done("unsupported") end
            if attempt(function() return v:isDoColor() end) ~= true then return done("unpaintable") end
            if sameColor(v, ev.color) then return done("already") end
            toolTypes = { "Base.Paintbrush" }
            groups = { { ev.color.item, 4 } }
            ev.time, need = 900, 1
        elseif operation == "rust" then
            if v:getRust() <= 0 then return done("already") end
            groups = { { "Base.ScrapMetal", 2 }, { "Base.RippedSheets", 4 } }
            toolTypes = { "Base.Screwdriver" }
            ev.time, need = 500, 2
        else return done("unsupported") end
        ev.time = math.max(10, Core.round(ev.time * opts.TimeMultiplier))
        local have = chr:getPerkLevel(Perks.Mechanics)
        ev.reqs = { { key = "Mechanics", need = need, have = have, ok = have >= need } }
        if ev.shelterOk ~= nil and choice == 2 then
            ev.reqs[#ev.reqs + 1] = { key = "WorkshopShelter", need = 1, have = ev.shelterOk and 1 or 0, ok = ev.shelterOk }
        end
        local idx = Core.indexByType(Game.collect(chr))
        for _, t in ipairs(toolTypes) do
            local list = idx[t]
            ev.tools[#ev.tools + 1] = { type = t, item = list and list[1].item }
        end
        ev.groups = Core.materialsFor({ materials = groups }, nil, opts)
        local matOk
        matOk, ev.picks, ev.report = Core.planMaterials(ev.groups, idx)
        if ev.shelterOk == false then return done("workshop") end
        if have < need then return done("skill") end
        for _, t in ipairs(ev.tools) do if not t.item then return done("missing_tools") end end
        if not matOk then return done("missing_materials") end
        return done("ok")
    end

    -- Persists with the physical item. Native doInventoryItemStats then keeps damage penalties
    -- and container rules; script definitions shared by other vehicles are never changed.
    local function writeUpgrade(part, rec, raw)
        local v, it = part:getVehicle(), part:getInventoryItem()
        if rec.kind == "power" then
            state(part).upgrade = rec
            -- Native setter divides its loudness argument by 2.7 (integer truncation).
            v:setEngineFeature(v:getEngineQuality(), math.ceil(v:getEngineLoudness() * 2.7 + 0.5), raw)
            v:transmitEngine()
        else
            it:getModData().MVRUpgrade = rec
            it:setMaxCapacity(raw)
            part:doInventoryItemStats(it, part:getMechanicSkillInstaller())
            if nativeTrailer(part) then part:setContainerCapacity(math.floor(expectedEffective(part, raw, rec.base))) end
            state(part).upgrade = rec
            v:transmitPartItem(part)
        end
        v:transmitPartModData(part)
    end
    function Game.reapplyUpgrade(part)
        if isClient() then return false end
        local rec, role = Game.upgradeRecord(part), Game.partRole(part)
        if type(rec) ~= "table" or rec.kind ~= role or rec.itemId ~= itemIdentity(part) then
            if part:getId() ~= "Engine" and type(part:getModData().MVR) == "table" and part:getModData().MVR.upgrade then
                part:getModData().MVR.upgrade = nil
                part:getVehicle():transmitPartModData(part)
            end
            return false
        end
        if conflict(part, role, rec) then return false end
        local enabled = Game.opts()
        local raw = U.target(rec.base, role, enabled.Enabled and enabled.UpgradesEnabled and rec.level or 0)
        if not raw then return false end
        if role == "power" then
            if part:getVehicle():getEnginePower() ~= raw then writeUpgrade(part, rec, raw); return true end
        else
            local it, box = part:getInventoryItem(), part:getItemContainer()
            if box:getCapacityWeight() > math.floor(expectedEffective(part, raw, rec.base)) and raw < it:getMaxCapacity() then return false end
            local before, oldRaw = part:getContainerCapacity(), it:getMaxCapacity()
            it:setMaxCapacity(raw)
            part:doInventoryItemStats(it, part:getMechanicSkillInstaller())
            if nativeTrailer(part) then part:setContainerCapacity(math.floor(expectedEffective(part, raw, rec.base))) end
            local changed = before ~= part:getContainerCapacity() or oldRaw ~= raw
            if changed or state(part).upgrade ~= rec then
                state(part).upgrade = rec
                part:getVehicle():transmitPartItem(part)
                part:getVehicle():transmitPartModData(part)
                return true
            end
        end
        return false
    end
    function Game.reapplyVehicle(vehicle)
        if isClient() or not vehicle then return end
        for i = 0, vehicle:getPartCount() - 1 do
            local part = vehicle:getPartByIndex(i)
            if part then Game.reapplyUpgrade(part) end
        end
    end
    -- Native TrailerTrunk.setCondition ignores maxCapacity when decoding part-item packets.
    -- Reconstruct only that local cache from the item state published by the server; never
    -- create records, consume resources, change item values or transmit from this client path.
    function Game.refreshReplica(vehicle)
        if not isClient() or not vehicle then return end
        for i = 0, vehicle:getPartCount() - 1 do
            local part = vehicle:getPartByIndex(i)
            if nativeTrailer(part) and Game.partRole(part) == "cargo" then
                local rec = Game.upgradeRecord(part)
                if type(rec) == "table" and rec.version == 1 and rec.kind == "cargo" and rec.itemId == itemIdentity(part) then
                    local raw = part:getInventoryItem():getMaxCapacity()
                    local target = U.target(rec.base, rec.kind, rec.level)
                    if target and (raw == rec.base or raw == target) then
                        part:setContainerCapacity(math.floor(expectedEffective(part, raw, rec.base)))
                    end
                end
            end
        end
    end
    function Game.applyWorkshop(chr, part, operation, choice, expectedItemId, expectedRevision)
        if isClient() then return { status = "disabled" } end
        if not part or not Game.workAllowed(chr, part) then return { status = "work_area" } end
        if itemIdentity(part) ~= tostring(expectedItemId or "") or Game.workshopRevision(part) ~= expectedRevision then return { status = "stale" } end
        local ev = Game.evaluateWorkshop(chr, part, operation, choice)
        if ev.status ~= "ok" then return { status = ev.status } end
        local v = part:getVehicle()
        Game.consume(ev.picks)
        if operation == "upgrade" then writeUpgrade(part, ev.record, ev.target)
        elseif operation == "paint" then v:setColorHSV(ev.color.h, ev.color.s, ev.color.v); v:transmitColorHSV()
        elseif operation == "rust" then v:setRust(math.max(0, v:getRust() - 0.2)); v:transmitRust() end
        bump(part)
        return { status = "customized", operation = operation, target = ev.target }
    end
end
