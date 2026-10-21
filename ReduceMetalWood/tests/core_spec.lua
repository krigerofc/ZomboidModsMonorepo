-- Runtime tests for Core.lua and ReduceMetalWood_Init.lua against mocked engine objects.
-- Run by tests/run.js inside fengari; package.path is set by the runner.
local failures, passes = 0, 0
local function check(cond, msg)
    if cond then passes = passes + 1 else failures = failures + 1; print("  FAIL: " .. msg) end
end
local function near(a, b) return a ~= nil and b ~= nil and math.abs(a - b) < 1e-6 end

-- Mock Java collection with iterator() (like Set<ItemTag> / ArrayList<String>)
local function javaCollection(list)
    local c = { list = list }
    function c:size() return #self.list end
    function c:get(i) return self.list[i + 1] end
    function c:iterator()
        local i = 0
        local lst = self.list
        return {
            hasNext = function() return i < #lst end,
            next = function() i = i + 1; return lst[i] end,
        }
    end
    return c
end

-- ItemTag mock: tostring gives "base:xxx"
local tagMeta = { __tostring = function(t) return "base:" .. t.id end }
local function itemTag(id) return setmetatable({ id = id }, tagMeta) end

local function mockItem(o)
    local it = { module = o.module or "Base", name = o.name, dc = o.dc, w = o.w, we = o.we,
                 tags = o.tags or {}, mv = o.mv, noSet = o.noSet }
    function it:getModuleName() return self.module end
    function it:getName() return self.name end
    function it:getFullName() return self.module .. "." .. self.name end
    function it:getDisplayCategory() return self.dc end
    function it:getTags() return javaCollection(self.tags) end
    function it:getActualWeight() return self.w end
    if not o.noSet then
        function it:setActualWeight(v) self.w = v; self.sets = (self.sets or 0) + 1 end
    end
    function it:DoParam(s)
        local v = string.match(s, "^Weight%s*=%s*([%d%.]+)$")
        if v then self.w = tonumber(v); self.doparams = (self.doparams or 0) + 1 end
    end
    if o.we then
        function it:getWeightEmpty() return self.we end
        function it:setWeightEmpty(v) self.we = v end
    end
    if o.mv and not o.noMvGetter then function it:getMetalValue() return self.mv end end
    return it
end

local Core = require "ReduceMetalWood/Core"

-- readTags with ItemTag objects (B42) and plain strings (B41)
local t42 = Core.readTags(mockItem({ name = "X", tags = { itemTag("hasmetal"), itemTag("ingot") } }))
check(t42[1] == "base:hasmetal" and t42[2] == "base:ingot", "readTags B42 ItemTag set")
local t41 = Core.readTags(mockItem({ name = "X", tags = { "HasMetal" } }))
check(t41[1] == "HasMetal", "readTags B41 string list")

-- basic apply + idempotence
local plank = mockItem({ name = "Plank", dc = "MaterialWeapon", w = 3.0 })
local steel = mockItem({ name = "SteelIngot", dc = "Material", w = 6.0, tags = { itemTag("hasmetal"), itemTag("ingot") } })
local door = mockItem({ name = "Door", dc = "Furniture", w = 20.0, tags = { itemTag("hasmetal") } })
local anvil = mockItem({ module = "OtherMod", name = "SteelAnvil", dc = "Material", w = 40.0, tags = { itemTag("hasmetal") } })
local modBeam = mockItem({ module = "OtherMod", name = "OakBeam", dc = "Material", w = 8.0 })
local modBar = mockItem({ module = "OtherMod", name = "TitaniumBar", dc = "Material", w = 4.0, tags = { "othermod:barstock" } })
local rods = mockItem({ name = "WeldingRods", dc = "Material", w = 1.5, we = 0.2, mv = 20, noMvGetter = true })
check(Core.describe(rods).metalValue == 0, "missing script getMetalValue safely yields zero")
local legacy = mockItem({ name = "Nails", dc = "Material", w = 0.05, noSet = true, mv = 1 })
local all = javaCollection({ plank, steel, door, anvil, modBeam, modBar, rods, legacy })

local c = Core.applyAll(all, 50, false)
check(near(plank.w, 1.5), "Plank 3.0 -> 1.5 got " .. tostring(plank.w))
check(near(steel.w, 3.0), "SteelIngot 6 -> 3 got " .. tostring(steel.w))
check(near(door.w, 20.0), "Door (finished product) unchanged")
check(near(anvil.w, 40.0), "other-mod anvil unchanged")
check(near(modBeam.w, 4.0), "other-mod OakBeam wood 8 -> 4 got " .. tostring(modBeam.w))
check(near(modBar.w, 2.0), "other-mod barstock tag 4 -> 2 got " .. tostring(modBar.w))
check(near(rods.w, 0.75) and near(rods.we, 0.1), "WeldingRods weight+empty halved")
check(near(legacy.w, 0.025) and legacy.doparams == 1, "DoParam fallback when setActualWeight missing")
check(c.wood == 2 and c.metal == 4 and c.changed == 6 and c.skipped == 2, "counts wood=2 metal=4 changed=6 skipped=2 got "
    .. c.wood .. "/" .. c.metal .. "/" .. c.changed .. "/" .. c.skipped)

Core.applyAll(all, 50, false)
Core.applyAll(all, 50, false)
check(near(plank.w, 1.5), "re-apply x2 does not compound (Plank still 1.5) got " .. tostring(plank.w))
check(near(rods.we, 0.1), "re-apply does not compound WeightEmpty")
check(Core.originalWeight("Base.Plank") == 3.0, "original weight stored")

Core.applyAll(all, 25, false)
check(near(plank.w, 2.25), "percent change recomputes from original (25% -> 2.25) got " .. tostring(plank.w))
Core.applyAll(all, 0, false)
check(near(plank.w, 3.0), "0% restores original")

-- external script reload resets weight to vanilla: new original captured, no compounding
Core.applyAll(all, 50, false)
plank.w = 3.0
Core.applyAll(all, 50, false)
check(near(plank.w, 1.5), "after external reload re-applies from new original")

-- Lua list input also accepted
local p2 = mockItem({ name = "Log", dc = "Material", w = 9.0, tags = { itemTag("log") } })
Core.applyAll({ p2 }, 50, false)
check(near(p2.w, 4.5), "Lua list input")

-- readPercent
check(Core.readPercent(nil) == nil, "readPercent nil")
check(Core.readPercent({}) == nil, "readPercent missing page")
check(Core.readPercent({ ReduceMetalWood = { WeightReductionPercent = 70 } }) == 70, "readPercent 70")
check(Core.readPercent({ ReduceMetalWood = { WeightReductionPercent = 500 } }) == 99, "readPercent clamps")

-- ===== Init wiring with mocked globals =====
local handlers = {}
local function ev(name)
    return { Add = function(f) handlers[name] = handlers[name] or {}; table.insert(handlers[name], f) end }
end
Events = { OnInitGlobalModData = ev("OnInitGlobalModData"), OnGameStart = ev("OnGameStart"), OnServerStarted = ev("OnServerStarted") }
local logs = {}
local realPrint = print
print = function(s) table.insert(logs, tostring(s)) end
local branch = mockItem({ name = "TreeBranch2", dc = "MaterialWeapon", w = 2.0, tags = { itemTag("woodhandle") } })
local scriptItems = javaCollection({ branch })
getScriptManager = function() return { getAllItems = function() return scriptItems end } end
isDebugEnabled = function() return true end
isServer = function() return false end
isClient = function() return false end
instanceof = function() return false end
-- inventory item still carrying the original weight
local invItem = { ft = "Base.TreeBranch2", w = 2.0 }
function invItem:getFullType() return self.ft end
function invItem:isCustomWeight() return false end
function invItem:getActualWeight() return self.w end
function invItem:setActualWeight(v) self.w = v end
getPlayer = function()
    return { getInventory = function() return { getItems = function() return javaCollection({ invItem }) end } end }
end
SandboxVars = nil

package.loaded["ReduceMetalWood_Init"] = nil
require "ReduceMetalWood_Init"
check(handlers.OnInitGlobalModData and handlers.OnGameStart and handlers.OnServerStarted, "events registered")

handlers.OnInitGlobalModData[1]()
check(near(branch.w, 2.0), "no apply while SandboxVars missing at OnInitGlobalModData")
SandboxVars = { ReduceMetalWood = { WeightReductionPercent = 50 } }
handlers.OnInitGlobalModData[1]()
check(near(branch.w, 1.0), "applied at OnInitGlobalModData")
handlers.OnGameStart[1]()
check(near(branch.w, 1.0), "OnGameStart re-apply idempotent")
check(near(invItem.w, 1.0), "inventory item refreshed")
print = realPrint

local joined = table.concat(logs, "\n")
check(string.find(joined, "[ReduceMetalWood] loaded v2.0.0", 1, true) ~= nil, "log: loaded")
check(string.find(joined, "sandbox vars not ready at OnInitGlobalModData", 1, true) ~= nil, "log: waiting")
check(string.find(joined, "applied (OnInitGlobalModData, sp): reduction=50% wood=1 metal=0", 1, true) ~= nil, "log: applied summary")
check(string.find(joined, "Base.TreeBranch2 2.0 -> 1.0", 1, true) ~= nil or string.find(joined, "Base.TreeBranch2 2 -> 1", 1, true) ~= nil, "log: per-item debug")
check(string.find(joined, "refreshed 1 inventory items", 1, true) ~= nil, "log: inventory refresh")

realPrint("core_spec: " .. passes .. " passed, " .. failures .. " failed")
return failures
