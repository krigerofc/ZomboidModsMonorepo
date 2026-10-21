--[[
    Reduce Metal&Wood v2 - runtime application of the weight reduction.

    Works on any object exposing the script Item API (real zombie.scripting.objects.Item
    in game, plain Lua tables in tests). Every engine call is wrapped in pcall so a
    missing method on one build (B41 vs B42) degrades instead of erroring.

    Idempotent: the original weight of every touched script item is remembered in
    Core.state[fullType] = { orig, applied, origEmpty, appliedEmpty }. Re-applying
    always starts from the original, so weights never compound. If something else
    changed the weight since our last write (e.g. scripts reloaded), the current
    value is taken as the new original.
]]

local Classifier = require "ReduceMetalWood/Classifier"

local Core = {}

Core.TAG = "[ReduceMetalWood]"
Core.EPS = 0.0005
Core.DEFAULT_PERCENT = 50
Core.state = {}
Core.lastPercent = nil

local unpackArgs = unpack or table.unpack

-- Safe method call: returns ok, result. Never raises.
-- A missing method returns false without error(): under -debug every error
-- caught by pcall dumps a full stack trace (seen 2x per scanned item for
-- Item:getMetalValue on a B42 dedicated server).
local function call(obj, method, ...)
    if obj == nil then return false, nil end
    local f = obj[method]
    if f == nil then return false, nil end
    local args = { ... }
    local n = select("#", ...)
    local ok, res = pcall(function()
        return f(obj, unpackArgs(args, 1, n))
    end)
    return ok, res
end
Core.call = call

local function log(msg)
    print(Core.TAG .. " " .. msg)
end
Core.log = log

local function near(a, b)
    return a ~= nil and b ~= nil and math.abs(a - b) < Core.EPS
end

--- Read the tags of a script item as a list of strings.
-- B42: Set<ItemTag> (toString "base:xxx"); B41: ArrayList<String>.
function Core.readTags(item)
    local out = {}
    local ok, tags = call(item, "getTags")
    if not ok or tags == nil then return out end
    if type(tags) == "table" and tags.iterator == nil then
        for i = 1, #tags do out[#out + 1] = tostring(tags[i]) end
        return out
    end
    local okIt, it = call(tags, "iterator")
    if okIt and it ~= nil then
        local guard = 0
        while guard < 1000 do
            local okHas, has = call(it, "hasNext")
            if not okHas or not has then break end
            local okNext, tag = call(it, "next")
            if not okNext then break end
            if tag ~= nil then out[#out + 1] = tostring(tag) end
            guard = guard + 1
        end
        return out
    end
    -- last resort: parse "[base:a, base:b]"
    local s = tostring(tags)
    s = string.gsub(s, "[%[%]]", "")
    local start = 1
    while true do
        local comma = string.find(s, ",", start, true)
        local piece = string.sub(s, start, comma and (comma - 1) or string.len(s))
        if piece ~= "" then out[#out + 1] = piece end
        if not comma then break end
        start = comma + 1
    end
    return out
end

--- Build the plain classifier input for a script item.
function Core.describe(item)
    local _, module = call(item, "getModuleName")
    local _, name = call(item, "getName")
    local _, dc = call(item, "getDisplayCategory")
    local okMv, mv = call(item, "getMetalValue")
    return {
        module = module and tostring(module) or "Base",
        name = name and tostring(name) or nil,
        displayCategory = dc and tostring(dc) or nil,
        tags = Core.readTags(item),
        metalValue = okMv and tonumber(mv) or 0,
    }
end

local function getWeight(item)
    local ok, w = call(item, "getActualWeight")
    if ok then return tonumber(w) end
    return nil
end

local function setWeight(item, w)
    local ok = call(item, "setActualWeight", w)
    if ok and near(getWeight(item), w) then return "setActualWeight" end
    ok = call(item, "DoParam", "Weight = " .. tostring(w))
    if ok and near(getWeight(item), w) then return "DoParam" end
    return nil
end

local function scaleEmpty(item, st, percent)
    local ok, cur = call(item, "getWeightEmpty")
    cur = ok and tonumber(cur) or nil
    if cur == nil or cur <= 0 then return end
    if st.origEmpty == nil or not near(cur, st.appliedEmpty) then st.origEmpty = cur end
    local target = Classifier.computeWeight(st.origEmpty, percent)
    if call(item, "setWeightEmpty", target) then st.appliedEmpty = target end
end

--- Apply the reduction to one script item. Returns material, result, reason.
-- result: "changed" | "unchanged" | "skipped" | "failed"
function Core.applyItem(item, percent, debug)
    local info = Core.describe(item)
    if not info.name then return nil, "skipped", "no name" end
    local material, included, reason = Classifier.classify(info)
    if not included then return material, "skipped", reason end

    local fullType = info.module .. "." .. info.name
    local cur = getWeight(item)
    if cur == nil then return material, "failed", "no weight" end

    local st = Core.state[fullType]
    if st == nil or not near(cur, st.applied) then
        st = { orig = cur }
        Core.state[fullType] = st
    end
    local target = Classifier.computeWeight(st.orig, percent)
    local how = "noop"
    if not near(cur, target) then
        how = setWeight(item, target)
        if how == nil then
            st.applied = cur
            log("WARN could not set weight of " .. fullType)
            return material, "failed", reason
        end
    end
    st.applied = target
    scaleEmpty(item, st, percent)
    if debug then
        log(fullType .. " " .. tostring(st.orig) .. " -> " .. tostring(target)
            .. " (" .. material .. ", " .. reason .. ", " .. how .. ")")
    end
    if how == "noop" then return material, "unchanged", reason end
    return material, "changed", reason
end

--- Apply to every item of a Java ArrayList-like (size/get) or Lua list.
function Core.applyAll(items, percent, debug)
    local counts = { wood = 0, metal = 0, changed = 0, unchanged = 0, skipped = 0, failed = 0, total = 0 }
    if items == nil then return counts end
    local n, get
    if type(items) == "table" and items.size == nil then
        n = #items
        get = function(i) return items[i + 1] end
    else
        local ok, size = call(items, "size")
        n = ok and size or 0
        get = function(i) local _, v = call(items, "get", i); return v end
    end
    for i = 0, n - 1 do
        local item = get(i)
        counts.total = counts.total + 1
        local material, result = Core.applyItem(item, percent, debug)
        counts[result] = counts[result] + 1
        if result ~= "skipped" and material then counts[material] = counts[material] + 1 end
    end
    Core.lastPercent = percent
    return counts
end

--- Original (unreduced) weight recorded for a full type, or nil.
function Core.originalWeight(fullType)
    local st = Core.state[fullType]
    return st and st.orig or nil
end

--- Read the sandbox percent. Returns number or nil when sandbox vars are not ready.
function Core.readPercent(sandboxVars)
    if type(sandboxVars) ~= "table" then return nil end
    local page = sandboxVars.ReduceMetalWood
    if type(page) ~= "table" then return nil end
    local p = tonumber(page.WeightReductionPercent)
    if p == nil then return nil end
    if p < 0 then p = 0 end
    if p > 99 then p = 99 end
    return p
end

return Core
