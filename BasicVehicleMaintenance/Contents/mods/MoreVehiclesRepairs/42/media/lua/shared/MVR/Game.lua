-- Basic Vehicle Maintenance - glue between Core (pure logic) and the B42 game API.
-- Loaded on client and server. Item/condition/body/stat/XP changes happen only through
-- Game.applyRepair, which is called from MVR_RepairAction:complete() (server in MP, local in SP).
require "MVR/Core"

local Core = MVR.Core
local Config = MVR.Config
local Game = {}
MVR.Game = Game

Game.MODULE = "MVR"

local function safe(fn, ...)
    local ok, res = pcall(fn, ...)
    if ok then return res end
    return nil
end

local function log(msg)
    if getDebug and getDebug() then print("[MVR] " .. tostring(msg)) end
end
Game.log = log

function Game.opts()
    return Core.readSandbox(SandboxVars)
end

function Game.rng()
    return ZombRand(1000000) / 1000000
end

-- ---------------------------------------------------------------- inventory

local function toArray(list)
    local out = {}
    if not list then return out end
    for i = 0, list:size() - 1 do out[#out + 1] = list:get(i) end
    return out
end
Game.toArray = toArray

Game.adapter = {
    items = function(container) return toArray(container:getItems()) end,
    child = function(item)
        if instanceof(item, "InventoryContainer") then return item:getInventory() end
        return nil
    end,
    fullType = function(item) return item:getFullType() end,
    units = function(item)
        if instanceof(item, "DrainableComboItem") then return item:getCurrentUses() end
        return 1
    end,
    usable = function(item)
        if item:isBroken() then return false end
        if instanceof(item, "DrainableComboItem") then return item:getCurrentUses() > 0 end
        return true
    end,
}

-- Every usable item the character carries, including nested bags.
function Game.collect(chr)
    return Core.collectItems(chr:getInventory(), Game.adapter)
end

local function notBroken(item) return not item:isBroken() end

function Game.findTool(chr, tagName)
    local tag = ItemTag and ItemTag[tagName]
    if not tag then log("unknown ItemTag " .. tostring(tagName)); return nil end
    return chr:getInventory():getFirstTagEvalRecurse(tag, notBroken)
end

function Game.hasJack(chr)
    return chr:getInventory():getFirstTypeRecurse("Base.Jack") ~= nil
end

-- ---------------------------------------------------------------- context

local GLOVE_LOCATIONS = { "HANDS", "HANDS_LEFT", "HANDS_RIGHT" }

function Game.hasGloves(chr)
    if not ItemBodyLocation then return false end
    for _, name in ipairs(GLOVE_LOCATIONS) do
        local loc = ItemBodyLocation[name]
        if loc and safe(function() return chr:getWornItem(loc) end) then return true end
    end
    return false
end

function Game.isIndoors(vehicle)
    local sq = vehicle and vehicle:getSquare()
    if not sq then return false end
    return not sq:isOutside()
end

-- Darkness is a client-side notion (lighting is not simulated on a dedicated server), so the
-- client computes it and passes it to the action.
function Game.isDark(chr)
    return safe(function() return chr:tooDarkToRead() end) == true
end

function Game.context(chr, part, dark)
    local vehicle = part:getVehicle()
    return {
        mech = chr:getPerkLevel(Perks.Mechanics),
        metal = chr:getPerkLevel(Perks.MetalWelding),
        elec = chr:getPerkLevel(Perks.Electricity),
        indoors = Game.isIndoors(vehicle),
        dark = dark and true or false,
        gloves = Game.hasGloves(chr),
        hasJack = Game.hasJack(chr),
    }
end

-- Engine is intrinsic in vanilla and has no InventoryItem. Removable parts still require an item.
function Game.isPartPresent(part)
    return part ~= nil and (part:getId() == "Engine" or part:getInventoryItem() ~= nil)
end

function Game.installedItemId(part)
    local item = part:getInventoryItem()
    return item and item:getID() or nil
end

function Game.patches(part, opts)
    return Core.getPatches(part:getModData(), Game.installedItemId(part), opts)
end

-- "available" (a vanilla fix whose fixer item the player carries), "exists", or nil.
function Game.vanillaFix(chr, part)
    return safe(function()
        local item = part:getInventoryItem()
        if not item or not part:getScriptPart():isRepairMechanic() then return nil end
        local list = FixingManager.getFixes(item)
        if not list or list:isEmpty() then return nil end
        local inv = chr:getInventory()
        for i = 0, list:size() - 1 do
            local fixers = list:get(i):getFixers()
            for j = 0, fixers:size() - 1 do
                local name = fixers:get(j):getFixerName()
                if inv:containsTypeRecurse(name) then return "available" end
            end
        end
        return "exists"
    end)
end

-- ---------------------------------------------------------------- evaluation

-- Full evaluation of one repair option. Used by the tooltip (client) and re-run by the
-- action on the server before anything is changed. Returns a table; ev.status == "ok" means
-- the repair can be done right now.
function Game.evaluate(chr, part, tierId, dark, opts)
    opts = opts or Game.opts()
    local cfg, key = Core.getConfig(part:getId())
    local tier = Core.getTier(tierId)
    if not opts.QualityTiersEnabled then tier = Config.Tiers[1] end
    local ev = { cfg = cfg, key = key, tier = tier, opts = opts, current = part:getCondition() }

    local function finish(status)
        ev.status = status
        return ev
    end
    if not opts.Enabled then return finish("disabled") end
    if cfg.notRepairable then return finish("not_repairable") end
    if not Game.isPartPresent(part) then return finish("not_installed") end

    local ctx = Game.context(chr, part, dark)
    ev.ctx = ctx
    ev.patches = Game.patches(part, opts)
    ev.bonus = Core.workshopBonus(ctx, opts)
    ev.fail = Core.failChance(cfg, ctx.mech, ev.bonus, opts)
    ev.crit = Core.critChance(ctx.mech)
    ev.gain = Core.gain(cfg, ctx.mech, opts)
    ev.cap = Core.cap(cfg, ctx.mech, ev.patches, tier, opts)
    ev.time = Core.duration(cfg, tier, opts, ctx.hasJack)
    ev.reqOk, ev.reqs = Core.tierRequirements(cfg, tier, ctx)

    ev.groups = Core.materialsFor(cfg, tier, opts)
    ev.index = Core.indexByType(Game.collect(chr))
    ev.matOk, ev.picks, ev.report, ev.used = Core.planMaterials(ev.groups, ev.index)

    ev.tools, ev.toolOk = {}, true
    for _, tagName in ipairs(cfg.tools or {}) do
        local item = Game.findTool(chr, tagName)
        ev.tools[#ev.tools + 1] = { tag = tagName, item = item }
        if not item then ev.toolOk = false end
    end

    if ev.current >= 100 then return finish("undamaged") end
    if ev.current >= ev.cap then return finish("above_cap") end
    if not ev.reqOk then return finish("skill") end
    if not ev.toolOk then return finish("missing_tools") end
    if not ev.matOk then return finish("missing_materials") end
    return finish("ok")
end

-- ---------------------------------------------------------------- server-side effects

local function removeItem(item)
    local container = item:getContainer()
    if not container then return end
    container:DoRemoveItem(item)
    if isServer() then sendRemoveItemFromContainer(container, item) end
end

local function consumePick(pick)
    local item = pick.entry.item
    if instanceof(item, "DrainableComboItem") then
        for _ = 1, pick.units do
            if item:getCurrentUses() <= 0 then break end
            item:UseAndSync()
        end
    else
        removeItem(item)
    end
end

function Game.consume(picks)
    for _, pick in ipairs(picks) do consumePick(pick) end
end

local function hand(chr, side)
    local bt = side == "L" and BodyPartType.Hand_L or BodyPartType.Hand_R
    return chr:getBodyDamage():getBodyPart(bt)
end

local function syncBody(bp)
    if isServer() then syncBodyPart(bp, 0xFFFFFFFFFFF) end
end

local function syncStats(chr, stat)
    if not isServer() then return end
    local mask = safe(function() return SyncPlayerStatsPacket.getBitMaskForStat(stat) end)
    syncPlayerStats(chr, tonumber(mask) or 0x7FFFFFFF)
end

-- ev: events from Core.rollSideEffects. Returns list of feedback keys.
function Game.applySideEffects(chr, events, tools)
    local said = {}
    if events.injury then
        local bp = hand(chr, events.hand)
        if bp then
            if events.injury == "cut" then bp:setCut(true) else bp:setScratched(true, true) end
            syncBody(bp)
            said[#said + 1] = "Injury"
        end
    end
    if events.burn then
        local bp = hand(chr, events.burnHand)
        if bp then
            bp:setBurnTime(events.burn)
            bp:setNeedBurnWash(true)
            syncBody(bp)
            said[#said + 1] = "Burn"
        end
    end
    if events.toolWear and tools and #tools > 0 then
        local t = tools[ZombRand(#tools) + 1].item
        if t then
            t:setCondition(math.max(0, t:getCondition() - events.toolWear))
            if isServer() then sendItemStats(t) end
            said[#said + 1] = "ToolWear"
        end
    end
    if events.frustration then
        chr:getStats():add(CharacterStat.UNHAPPINESS, events.frustration)
        syncStats(chr, CharacterStat.UNHAPPINESS)
        said[#said + 1] = "Frustration"
    end
    return said
end

function Game.setPartCondition(part, cond)
    local vehicle = part:getVehicle()
    part:setCondition(cond)
    local item = part:getInventoryItem()
    if item then safe(function() part:doInventoryItemStats(item, part:getMechanicSkillInstaller()) end) end
    if part:isContainer() and not part:getItemContainer() then
        safe(function() part:setContainerContentAmount(part:getContainerContentAmount()) end)
    end
    safe(function() vehicle:updatePartStats() end)
    vehicle:transmitPartCondition(part)
end

function Game.xpKey(part)
    return tostring(part:getVehicle():getMechanicalID()) .. part:getId() .. "MVR"
end

local function nowMillis()
    return getGameTime():getCalender():getTimeInMillis()
end

-- Gives Mechanics XP with the vanilla per-character anti-farm store. Returns XP given.
function Game.giveXp(chr, part, outcome, opts)
    local key = Game.xpKey(part)
    local last = safe(function() return chr:getMechanicsItem(key) end)
    local now = nowMillis()
    if not Core.xpAllowed(last, now) then return 0 end
    local xp = Core.xpFor(outcome, opts)
    if xp > 0 then
        addXp(chr, Perks.Mechanics, xp)
        chr:addMechanicsItem(key, part, now)
    end
    return xp
end

-- The whole repair, authoritative. Returns result table (sent to the client as feedback).
function Game.applyRepair(chr, part, tierId, dark)
    local opts = Game.opts()
    local ev = Game.evaluate(chr, part, tierId, dark, opts)
    if ev.status ~= "ok" then return { status = ev.status } end

    local rng = Game.rng
    local outcome = Core.rollOutcome(ev.fail, ev.crit, opts.SevereFailEnabled, rng())
    local events = Core.rollSideEffects({ mech = ev.ctx.mech, gloves = ev.ctx.gloves, heat = ev.cfg.heat,
        failed = not Core.isSuccess(outcome), hasTools = #ev.tools > 0 }, opts, rng)

    Game.consume(ev.picks)
    local wasted = false
    if events.waste then
        local extra = Core.planWaste(ev.report, ev.index, ev.used)
        if extra then consumePick(extra); wasted = true end
    end

    local before = ev.current
    local after = Core.applyOutcome(before, outcome, ev.gain, ev.cap)
    if Core.isSuccess(outcome) then
        Core.addPatch(part:getModData(), Game.installedItemId(part), ev.tier.id, opts)
        safe(function() part:getVehicle():transmitPartModData(part) end)
    end
    if after ~= before then Game.setPartCondition(part, after) end

    local xp = Game.giveXp(chr, part, outcome, opts)
    local said = Game.applySideEffects(chr, events, ev.tools)
    if wasted then said[#said + 1] = "Waste" end
    safe(function() chr:sendObjectChange(IsoObjectChange.MECHANIC_ACTION_DONE, { success = Core.isSuccess(outcome) }) end)

    return { status = "done", outcome = outcome, before = before, after = after, xp = xp, events = said, partId = part:getId() }
end

-- Delivers the result to the acting player's client (direct call in SP / host).
function Game.feedback(chr, result)
    if isServer() then
        sendServerCommand(chr, Game.MODULE, "result", result)
    elseif MVR.Client and MVR.Client.showResult then
        MVR.Client.showResult(chr, result)
    end
end

return Game
