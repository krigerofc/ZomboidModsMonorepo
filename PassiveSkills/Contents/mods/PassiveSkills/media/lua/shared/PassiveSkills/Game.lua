-- Passive Skills v2 - engine glue (game API calls). Identical copy in B41 (media/) and B42 (42/media/).
-- Every entry point is wrapped in pcall so a failure here can never break vanilla reading or loot.
local Core = require "PassiveSkills/Core"
local Catalog = require "PassiveSkills/Catalog"

local Game = {}
Game.MODULE = "PassiveSkills"

local instance = nil

local function log(msg)
    print("[PassiveSkills] " .. tostring(msg))
end
Game.log = log

function Game.detectBuild()
    local ok, major = pcall(function() return getCore():getGameVersion():getMajor() end)
    if ok and tonumber(major) then return tonumber(major) end
    return 42
end

local function itemExists(fullType)
    if not getScriptManager then return true end
    local ok, item = pcall(function() return getScriptManager():FindItem(fullType) end)
    if not ok then return true end
    return item ~= nil
end

local function perkOf(perkName)
    if not Perks then return nil end
    return Perks[perkName]
end

-- Lazy: built on first use (scripts and Perks are loaded by then).
function Game.core()
    if not instance then
        local build = Game.detectBuild()
        instance = Core.new(Catalog, build, function(perkName, fullType)
            return perkOf(perkName) ~= nil and itemExists(fullType)
        end)
        log("build " .. tostring(build) .. ": " .. #instance.skills .. " skills, " .. instance.count .. " magazine types")
    end
    return instance
end

function Game.settings()
    return Core.settings(SandboxVars)
end

-- Full XP, no profession/trait/skill-book multiplier: the 5 volumes always add up to level 5.
function Game.grantXp(character, perkName, amount)
    local perk = perkOf(perkName)
    if not perk then return false end
    if addXpNoMultiplier then                      -- B42 global (server-safe, syncs to client)
        addXpNoMultiplier(character, perk, amount)
        return true
    end
    local xp = character:getXp()
    if not xp then return false end
    if xp.AddXPNoMultiplier then
        xp:AddXPNoMultiplier(perk, amount)
    elseif xp.AddXP then                           -- fallback: callLua=false, doXPBoost=false, remote=false
        xp:AddXP(perk, amount, false, false, false)
    else
        return false
    end
    return true
end

local function halo(character, text)
    if not HaloTextHelper then return end
    pcall(function()
        if HaloTextHelper.addGoodText then
            HaloTextHelper.addGoodText(character, text)
        elseif HaloTextHelper.addTextWithArrow then
            HaloTextHelper.addTextWithArrow(character, text, true, HaloTextHelper.getColorGreen())
        end
    end)
end

-- Client / SP only: speech bubble + halo text.
function Game.showFeedback(character, status, skillId)
    if not character or not skillId then return end
    local name = getText("IGUI_PassiveSkills_Skill_" .. tostring(skillId))
    if status == "learned" then
        character:Say(getText("IGUI_PassiveSkills_Learned", name))
        halo(character, getText("IGUI_PassiveSkills_Halo", name))
    elseif status == "already" then
        character:Say(getText("IGUI_PassiveSkills_AlreadyRead"))
    end
end

-- Server (B42 MP) -> owning client; SP / B41 -> show directly.
function Game.notify(character, status, entry)
    if isServer() then
        sendServerCommand(character, Game.MODULE, status, {
            key = entry.key, skill = entry.skill, pid = character:getOnlineID(),
        })
    else
        Game.showFeedback(character, status, entry.skill)
    end
end

-- Returns (true, entry) when this character already read this volume (client-side pre-check).
function Game.alreadyRead(character, item)
    if not character or not item then return false end
    local entry = Game.core():entryFor(item:getFullType())
    if not entry then return false end
    return Core.hasRead(character:getModData(), entry.key), entry
end

-- Called when a read finished: B42 ISReadABook:complete (SP or MP server), B41 ISReadABook:perform.
function Game.onFinishedReading(character, item)
    local ok, err = pcall(function()
        if not character or not item then return end
        local core = Game.core()
        local entry = core:entryFor(item:getFullType())
        if not entry then return end
        local md = character:getModData()
        local status = Core.hasRead(md, entry.key) and "already" or "learned"
        if status == "learned" then
            local amount = core:xpFor(entry.tier, Game.settings().xpPercent)
            if amount > 0 and not Game.grantXp(character, entry.perk, amount) then
                log("XP grant failed: " .. tostring(entry.perk))
                return
            end
            Core.markRead(md, entry.key)
            log("read " .. item:getFullType() .. " -> " .. entry.perk .. " +" .. amount .. " XP")
        end
        Game.notify(character, status, entry)
    end)
    if not ok then log("error onFinishedReading: " .. tostring(err)) end
end

-- OnFillContainer (server / SP): at most one magazine per eligible container.
function Game.onFillContainer(roomName, containerType, container)
    local ok, err = pcall(function()
        if not container then return end
        local s = Game.settings()
        if s.spawnChance <= 0 then return end
        local fullType = Game.core():rollSpawn(roomName, containerType, s.spawnChance, function(n) return ZombRand(n) end)
        if fullType then container:AddItem(fullType) end
    end)
    if not ok then log("error onFillContainer: " .. tostring(err)) end
end

-- Client: find the local player a server message is about (split-screen safe).
local function localPlayer(pid)
    for i = 0, 3 do
        local p = getSpecificPlayer(i)
        if p and (pid == nil or p:getOnlineID() == pid) then return p end
    end
    return nil
end

function Game.onServerCommand(module, command, args)
    if module ~= Game.MODULE or type(args) ~= "table" then return end
    local ok, err = pcall(function()
        local player = localPlayer(args.pid)
        if not player then return end
        local md = player:getModData()
        if command == "sync" then
            if type(args.read) == "table" then
                for _, k in pairs(args.read) do Core.markRead(md, k) end
            end
        elseif command == "learned" or command == "already" then
            Core.markRead(md, args.key)
            Game.showFeedback(player, command, args.skill)
        end
    end)
    if not ok then log("error onServerCommand: " .. tostring(err)) end
end

-- Server: a client asks for its character's read list (mirror for the pre-read check).
function Game.onClientCommand(module, command, player, args)
    if module ~= Game.MODULE or command ~= "requestSync" or not player then return end
    pcall(function()
        sendServerCommand(player, Game.MODULE, "sync", {
            read = Core.readKeys(player:getModData()), pid = player:getOnlineID(),
        })
    end)
end

return Game
