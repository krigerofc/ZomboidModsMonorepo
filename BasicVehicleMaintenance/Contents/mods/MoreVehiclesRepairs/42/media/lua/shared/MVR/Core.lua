-- Basic Vehicle Maintenance - pure logic (no game API; everything game-side is injected).
-- Shared by the client menu/tooltip and the server-side TimedAction:complete(), and unit-tested
-- in tests/core_spec.lua (fengari).
require "MVR/Config"

local Config = MVR.Config
local Rules = Config.Rules
local Core = {}
MVR.Core = Core

local floor = math.floor

function Core.clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

function Core.round(v)
    return floor(v + 0.5)
end

-- ---------------------------------------------------------------- sandbox

-- name -> { default, min, max } (booleans: { default })
Core.SandboxSpec = {
    Enabled = { true },
    MaterialCostMultiplier = { 1.0, 0.25, 4 },
    ConditionGainMultiplier = { 1.0, 0.25, 3 },
    CapOffset = { 0, -30, 20 },
    FailChanceMultiplier = { 1.0, 0, 3 },
    SevereFailEnabled = { true },
    SideEffectsEnabled = { true },
    InjuryChanceMultiplier = { 1.0, 0, 3 },
    XPMultiplier = { 1.0, 0, 5 },
    TimeMultiplier = { 1.0, 0.25, 3 },
    PatchHistoryEnabled = { true },
    WorkshopBonusEnabled = { true },
    QualityTiersEnabled = { true },
}

-- Reads SandboxVars.MVR (may be nil in menus/tests) into a complete, clamped options table.
function Core.readSandbox(sandboxVars)
    local src = type(sandboxVars) == "table" and sandboxVars.MVR or nil
    if type(src) ~= "table" then src = {} end
    local out = {}
    for name, spec in pairs(Core.SandboxSpec) do
        local v = src[name]
        if type(spec[1]) == "boolean" then
            if type(v) == "boolean" then out[name] = v else out[name] = spec[1] end
        else
            v = tonumber(v)
            if v == nil or v ~= v then v = spec[1] end
            out[name] = Core.clamp(v, spec[2], spec[3])
        end
    end
    return out
end

-- ---------------------------------------------------------------- part config

-- Returns configKey for a vehicle part id. Never nil: unknown ids use "Default".
function Core.getConfigKey(partId)
    if type(partId) ~= "string" or partId == "" then return "Default" end
    local lower = string.lower(partId)
    for _, alias in ipairs(Config.PartAliases) do
        if string.find(lower, string.lower(alias[1]), 1, true) then
            if Config.Parts[alias[2]] then return alias[2] end
        end
    end
    return "Default"
end

-- Returns config table (never nil), configKey.
function Core.getConfig(partId)
    local key = Core.getConfigKey(partId)
    return Config.Parts[key] or Config.Parts.Default, key
end

function Core.getTier(tierId)
    for i, t in ipairs(Config.Tiers) do
        if t.id == tierId then return t, i end
    end
    return Config.Tiers[1], 1
end

-- ---------------------------------------------------------------- formulas

-- workshopBonus > 0 lowers the chance, < 0 raises it (darkness).
function Core.failChance(cfg, mech, workshopBonus, opts)
    mech = tonumber(mech) or 0
    local base = (cfg.fail or 0.2) - Rules.failPerLevel * math.max(0, mech - 1) - (workshopBonus or 0)
    local f = Core.clamp(base, Rules.failMin, Rules.failMax) * (opts and opts.FailChanceMultiplier or 1)
    return Core.clamp(f, 0, 0.95)
end

function Core.critChance(mech)
    return Core.clamp(Rules.critBase + Rules.critPerLevel * (tonumber(mech) or 0), 0, 0.5)
end

function Core.gain(cfg, mech, opts)
    local g = (cfg.gain or 10) * (1 + Rules.gainPerLevel * (tonumber(mech) or 0)) * (opts and opts.ConditionGainMultiplier or 1)
    return math.max(1, Core.round(g))
end

function Core.critGain(gain)
    return Core.round(gain * Rules.critGainMult)
end

-- patches: earlier improvised repairs on this part (0 when history is disabled).
function Core.cap(cfg, mech, patches, tier, opts)
    tier = tier or Config.Tiers[1]
    local c = (cfg.cap or 50) + Rules.capPerLevel * (tonumber(mech) or 0) - Rules.capPerPatch * (tonumber(patches) or 0)
        + (opts and opts.CapOffset or 0) + (tier.capBonus or 0)
    c = math.min(tier.hardCap or 75, c)
    return math.max(Rules.capFloor, floor(c))
end

-- Single roll r in [0,1). Returns "severe" | "light" | "crit" | "success".
function Core.rollOutcome(fail, crit, severeEnabled, r)
    if r < fail then
        if severeEnabled and r < fail * Rules.severeShare then return "severe" end
        return "light"
    end
    if r < fail + math.min(crit, 1 - fail) then return "crit" end
    return "success"
end

function Core.isSuccess(outcome)
    return outcome == "success" or outcome == "crit"
end

-- New condition after the outcome. Success never lowers the condition.
function Core.applyOutcome(current, outcome, gain, cap)
    current = tonumber(current) or 0
    if outcome == "success" or outcome == "crit" then
        local g = outcome == "crit" and Core.critGain(gain) or gain
        local n = math.min(cap, current + g)
        if n > 100 then n = 100 end
        if n < current then n = current end
        return n
    elseif outcome == "light" then
        return math.max(math.min(current, 1), current - Rules.lightFailLoss)
    elseif outcome == "severe" then
        return math.max(0, current - Rules.severeFailLoss)
    end
    return current
end

function Core.xpFor(outcome, opts)
    local base = Rules.xpFail
    if outcome == "crit" then base = Rules.xpCrit elseif outcome == "success" then base = Rules.xpSuccess end
    return base * (opts and opts.XPMultiplier or 1)
end

-- lastTime: value from chr:getMechanicsItem(key) (Long timestamp, nil if never).
function Core.xpAllowed(lastTime, now)
    if lastTime == nil then return true end
    local t = tonumber(lastTime)
    if not t or not tonumber(now) then return false end
    return (now - t) >= Rules.xpCooldownMs or now < t
end

function Core.riskBand(fail)
    if fail < 0.10 then return "low" end
    if fail < 0.25 then return "medium" end
    return "high"
end

-- Workshop modifiers. ctx: { indoors=bool, dark=bool }. Returns bonus (positive = safer).
function Core.workshopBonus(ctx, opts)
    if not (opts and opts.WorkshopBonusEnabled) or not ctx then return 0 end
    local b = 0
    if ctx.indoors then b = b + Rules.indoorBonus end
    b = math.min(b, Rules.bonusLimit)
    if ctx.dark then b = b - Rules.darkPenalty end
    return b
end

-- Action duration in ticks.
function Core.duration(cfg, tier, opts, hasJack)
    tier = tier or Config.Tiers[1]
    local t = (cfg.time or 200) * (tier.timeMult or 1) * (opts and opts.TimeMultiplier or 1)
    if hasJack and cfg.jack and opts and opts.WorkshopBonusEnabled then t = t * Rules.jackTimeMult end
    return math.max(10, Core.round(t))
end

-- ---------------------------------------------------------------- materials

-- Returns new groups with every quantity scaled (min 1). Overhaul on heat parts adds a torch group.
function Core.materialsFor(cfg, tier, opts)
    tier = tier or Config.Tiers[1]
    local mult = (opts and opts.MaterialCostMultiplier or 1) * (tier.matMult or 1)
    local out = {}
    for _, group in ipairs(cfg.materials or {}) do
        local g = {}
        for i = 1, #group, 2 do
            g[#g + 1] = group[i]
            g[#g + 1] = math.max(1, Core.round(group[i + 1] * mult))
        end
        out[#out + 1] = g
    end
    if cfg.heat and tier.heatTorchUses then
        out[#out + 1] = { "Base.BlowTorch", tier.heatTorchUses }
    end
    return out
end

-- Flattens a container tree. adapter = { items(container) -> array, child(item) -> container|nil,
-- fullType(item), units(item) -> number of uses (1 for normal items), usable(item) -> bool }.
-- Returns array of entries { item, type, units, container }.
function Core.collectItems(root, adapter, out, depth)
    out = out or {}
    depth = depth or 0
    if not root or depth > 8 then return out end
    for _, item in ipairs(adapter.items(root) or {}) do
        if adapter.usable(item) then
            out[#out + 1] = { item = item, type = adapter.fullType(item), units = adapter.units(item) or 1, container = root }
        end
        local child = adapter.child(item)
        if child then Core.collectItems(child, adapter, out, depth + 1) end
    end
    return out
end

function Core.indexByType(entries)
    local idx = {}
    for _, e in ipairs(entries) do
        local list = idx[e.type]
        if not list then list = {}; idx[e.type] = list end
        list[#list + 1] = e
    end
    return idx
end

function Core.countType(index, fullType, used)
    local n = 0
    for _, e in ipairs(index[fullType] or {}) do
        n = n + e.units - ((used and used[e]) or 0)
    end
    return n
end

-- Take `qty` units of `fullType` from index, preferring the emptiest drainables first.
local function allocate(index, fullType, qty, used, picks)
    local list = {}
    for _, e in ipairs(index[fullType] or {}) do list[#list + 1] = e end
    table.sort(list, function(a, b) return a.units < b.units end)
    local left = qty
    for _, e in ipairs(list) do
        if left <= 0 then break end
        local avail = e.units - (used[e] or 0)
        if avail > 0 then
            local take = math.min(avail, left)
            used[e] = (used[e] or 0) + take
            picks[#picks + 1] = { entry = e, units = take }
            left = left - take
        end
    end
end

-- Plans which items pay for `groups`. Returns ok, picks, report, used.
-- report[i] = { type, need, have, ok, altIndex } for the alternative shown/used for group i.
function Core.planMaterials(groups, index)
    local used, picks, report, ok = {}, {}, {}, true
    for gi, group in ipairs(groups) do
        local chosen
        for i = 1, #group, 2 do
            local have = Core.countType(index, group[i], used)
            if have >= group[i + 1] then
                chosen = { type = group[i], need = group[i + 1], have = have, ok = true, altIndex = (i + 1) / 2 }
                break
            end
        end
        if chosen then
            allocate(index, chosen.type, chosen.need, used, picks)
        else
            ok = false
            chosen = { type = group[1], need = group[2], have = Core.countType(index, group[1], used), ok = false, altIndex = 1 }
        end
        local alts = {}
        for i = 1, #group, 2 do
            if group[i] ~= chosen.type then alts[#alts + 1] = { type = group[i], need = group[i + 1] } end
        end
        chosen.alternatives = alts
        report[gi] = chosen
    end
    return ok, picks, report, used
end

-- One extra unit of one of the materials actually used (waste event). Returns pick or nil.
function Core.planWaste(report, index, used)
    for _, r in ipairs(report) do
        if r.ok and Core.countType(index, r.type, used) > 0 then
            local picks = {}
            allocate(index, r.type, 1, used, picks)
            return picks[1]
        end
    end
    return nil
end

-- ---------------------------------------------------------------- tiers

-- ctx: { mech, metal, elec, indoors, hasJack }. Returns ok, list of { key, need, have, ok }.
function Core.tierRequirements(cfg, tier, ctx)
    local reqs, ok = {}, true
    local function add(key, need, have)
        local good = (have or 0) >= need
        reqs[#reqs + 1] = { key = key, need = need, have = have or 0, ok = good }
        if not good then ok = false end
    end
    if (tier.mech or 0) > 0 then add("Mechanics", tier.mech, ctx.mech) end
    if cfg.heat and tier.heatMetal then add("MetalWelding", tier.heatMetal, ctx.metal) end
    if cfg.electric and tier.electricSkill then add("Electricity", tier.electricSkill, ctx.elec) end
    if tier.needsShelterOrJack then
        local good = ctx.indoors or ctx.hasJack
        reqs[#reqs + 1] = { key = "ShelterOrJack", need = 1, have = good and 1 or 0, ok = good and true or false }
        if not good then ok = false end
    end
    return ok, reqs
end

-- ---------------------------------------------------------------- side effects

-- ctx: { mech, gloves, heat, failed, hasTools }. rng() -> [0,1). Returns events table.
function Core.rollSideEffects(ctx, opts, rng)
    local ev = {}
    if not (opts and opts.SideEffectsEnabled) then return ev end
    local injMult = opts.InjuryChanceMultiplier or 1
    local inj = math.max(0, Rules.injuryBase - Rules.injuryPerLevel * (ctx.mech or 0)) * injMult
    if ctx.gloves then inj = inj * Rules.injuryGloves end
    if rng() < inj then
        ev.injury = (rng() < Rules.cutShare) and "cut" or "scratch"
        ev.hand = (rng() < 0.5) and "L" or "R"
    end
    if ctx.heat then
        local burn = Rules.burnBase * injMult
        if ctx.gloves then burn = burn * Rules.burnGloves end
        if rng() < burn then
            ev.burn = Rules.burnMin + floor(rng() * (Rules.burnMax - Rules.burnMin + 1))
            ev.burnHand = (rng() < 0.5) and "L" or "R"
        end
    end
    if ctx.hasTools and rng() < Rules.toolWearChance then
        ev.toolWear = Rules.toolWearMin + floor(rng() * (Rules.toolWearMax - Rules.toolWearMin + 1))
    end
    if rng() < Rules.wasteChance then ev.waste = true end
    if ctx.failed and rng() < Rules.frustrationChance then ev.frustration = Rules.frustrationAmount end
    return ev
end

-- ---------------------------------------------------------------- patch history

-- md: the part's modData table. itemId: id of the installed InventoryItem (a new part resets).
-- Returns the number of earlier patches.
function Core.getPatches(md, itemId, opts)
    if not (opts and opts.PatchHistoryEnabled) or type(md) ~= "table" then return 0 end
    local h = md.MVR
    if type(h) ~= "table" then return 0 end
    if itemId ~= nil and h.itemId ~= nil and tostring(h.itemId) ~= tostring(itemId) then return 0 end
    return tonumber(h.patches) or 0
end

-- Records one more patch (call on success only). Returns new count.
function Core.addPatch(md, itemId, tierId, opts)
    if not (opts and opts.PatchHistoryEnabled) or type(md) ~= "table" then return 0 end
    local n = Core.getPatches(md, itemId, opts) + 1
    md.MVR = { patches = n, itemId = itemId ~= nil and tostring(itemId) or nil, last = tierId }
    return n
end

return Core
