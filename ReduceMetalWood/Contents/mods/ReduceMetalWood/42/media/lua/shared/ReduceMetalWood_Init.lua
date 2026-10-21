--[[
    Reduce Metal&Wood v2 - event wiring (engine side).

    Loaded from lua/shared, so it runs on SP, MP clients and the dedicated server.
    Sandbox values are read from SandboxVars, which is only populated for the
    current save once the world starts loading, so we (re)apply on:
      OnInitGlobalModData - SP / client / server, world init, before players load
      OnServerStarted     - dedicated server
      OnGameStart         - SP / client, last safety net (also fixes the local inventory)
    Applying more than once is safe: Core keeps the original weights.
]]

local Core = require "ReduceMetalWood/Core"

local function isDebug()
    local ok, res = pcall(function() return isDebugEnabled() end)
    return ok and res == true
end

local function side()
    local ok, server = pcall(function() return isServer() end)
    local ok2, client = pcall(function() return isClient() end)
    if ok and server then return "server" end
    if ok2 and client then return "client" end
    return "sp"
end

local function apply(eventName, allowDefault)
    local percent = Core.readPercent(SandboxVars)
    if percent == nil then
        if not allowDefault then
            Core.log("sandbox vars not ready at " .. eventName .. ", waiting")
            return
        end
        percent = Core.DEFAULT_PERCENT
        Core.log("WARN sandbox option ReduceMetalWood.WeightReductionPercent missing at "
            .. eventName .. ", using default " .. tostring(percent))
    end
    local ok, items = pcall(function() return getScriptManager():getAllItems() end)
    if not ok or items == nil then
        ok, items = pcall(function() return ScriptManager.instance:getAllItems() end)
    end
    if not ok or items == nil then
        Core.log("ERROR could not access ScriptManager items at " .. eventName)
        return
    end
    local c = Core.applyAll(items, percent, isDebug())
    Core.log("applied (" .. eventName .. ", " .. side() .. "): reduction=" .. tostring(percent)
        .. "% wood=" .. c.wood .. " metal=" .. c.metal .. " changed=" .. c.changed
        .. " unchanged=" .. c.unchanged .. " failed=" .. c.failed .. " scanned=" .. c.total)
end

-- Items already instanced in the local player's inventory before we applied keep the
-- old weight; bring the ones that still carry the original script weight in line.
local function refreshInventory(container, depth)
    if container == nil or depth > 3 then return 0 end
    local fixed = 0
    local okItems, items = pcall(function() return container:getItems() end)
    if not okItems or items == nil then return 0 end
    for i = 0, items:size() - 1 do
        local inv = items:get(i)
        pcall(function()
            local st = Core.state[inv:getFullType()]
            if st and st.applied and not inv:isCustomWeight()
                and math.abs(inv:getActualWeight() - st.orig) < Core.EPS then
                inv:setActualWeight(st.applied)
                fixed = fixed + 1
            end
        end)
        pcall(function()
            if instanceof(inv, "InventoryContainer") then
                fixed = fixed + refreshInventory(inv:getItemContainer(), depth + 1)
            end
        end)
    end
    return fixed
end

local function onGameStart()
    apply("OnGameStart", true)
    pcall(function()
        local player = getPlayer()
        if player then
            local n = refreshInventory(player:getInventory(), 0)
            if n > 0 then Core.log("refreshed " .. n .. " inventory items") end
        end
    end)
end

if Events then
    if Events.OnInitGlobalModData then
        Events.OnInitGlobalModData.Add(function() apply("OnInitGlobalModData", false) end)
    end
    if Events.OnServerStarted then
        Events.OnServerStarted.Add(function() apply("OnServerStarted", true) end)
    end
    if Events.OnGameStart then
        Events.OnGameStart.Add(onGameStart)
    end
end

Core.log("loaded v2.0.0")
