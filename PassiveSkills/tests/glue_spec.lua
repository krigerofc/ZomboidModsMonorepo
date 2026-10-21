-- Integration spec: Game.lua + PassiveSkills_ReadHook.lua + client/server files against mocked engine.
-- Runner globals: BUILD (41|42), MODROOT (lua dir of the build copy), HOOKFILE (path of ReadHook),
-- PERKS (set), ITEMS (set of script fullTypes for BUILD), TR (EN translation map for BUILD).
-- Returns the number of failures.
local realPrint = print
local failures = 0
local function check(cond, msg)
    if not cond then failures = failures + 1; realPrint("  FAIL [B" .. BUILD .. " glue]: " .. msg) end
end

local missingText = {}
local function fmt(key, a1)
    local s = TR[key]
    if s == nil then missingText[#missingText + 1] = key; return key end
    if a1 ~= nil then s = string.gsub(s, "%%1", (string.gsub(tostring(a1), "%%", "%%%%"))) end
    return s
end

-- ------------------------------------------------------------ engine mocks
local log -- per scenario
local function resetWorld(opts)
    log = { xp = {}, cmds = {}, halo = {}, added = {}, queued = {}, origComplete = 0, origPerform = 0 }
    for k in pairs(package.loaded) do
        if string.find(k, "PassiveSkills", 1, true) or k == "TimedActions/ISReadABook" then package.loaded[k] = nil end
    end
    _G.print = function() end
    _G.getCore = function() return { getGameVersion = function() return { getMajor = function() return BUILD end } end } end
    _G.getScriptManager = function() return { FindItem = function(_, ft) return ITEMS[ft] and {} or nil end } end
    _G.Perks = {}
    for p in pairs(PERKS) do Perks[p] = { name = p } end
    _G.SandboxVars = { PassiveSkills = { SpawnChance = opts.spawn or 12, XpPercent = opts.xpPct or 100 } }
    _G.ZombRand = function(n) return math.random(0, n - 1) end
    _G.getText = fmt
    _G.isServer = function() return opts.server == true end
    _G.isClient = function() return opts.client == true end
    _G.sendServerCommand = function(player, module, command, args) log.cmds[#log.cmds + 1] = { player = player, module = module, command = command, args = args } end
    _G.sendClientCommand = function() end
    local players = {}
    _G.getSpecificPlayer = function(i) return players[i] end
    _G.Events = setmetatable({}, { __index = function(t, k) local ev = { fns = {} }; ev.Add = function(fn) ev.fns[#ev.fns + 1] = fn end; rawset(t, k, ev); return ev end })
    if BUILD >= 42 then
        _G.addXpNoMultiplier = function(ch, perk, amount) log.xp[#log.xp + 1] = { ch = ch, perk = perk.name, amount = amount, via = "global" } end
        _G.HaloTextHelper = { addGoodText = function(ch, text) log.halo[#log.halo + 1] = text end }
    else
        _G.addXpNoMultiplier = nil
        _G.HaloTextHelper = {
            addTextWithArrow = function(ch, text, up, color) log.halo[#log.halo + 1] = text end,
            getColorGreen = function() return "green" end,
        }
    end
    -- minimal ISReadABook with the vanilla shape of this build (B42 has complete(), B41 does not)
    package.preload["TimedActions/ISReadABook"] = function()
        ISReadABook = {}
        ISReadABook.__index = ISReadABook
        function ISReadABook:new(character, item, time)
            local o = setmetatable({}, self)
            o.character = character; o.item = item; o.maxTime = time or 100
            return o
        end
        function ISReadABook:isValid() return true end
        function ISReadABook:perform() log.origPerform = log.origPerform + 1 end
        if BUILD >= 42 then
            function ISReadABook:complete() log.origComplete = log.origComplete + 1; return true end
        end
        return ISReadABook
    end
    _G.ISTimedActionQueue = { add = function(a) if a.ignoreAction then return end; log.queued[#log.queued + 1] = a; return true end }
    package.path = MODROOT .. "/shared/?.lua;" .. package.path
    dofile(HOOKFILE)
    return players
end

local nextId = 0
local function newCharacter(withNoMultiplierXp)
    nextId = nextId + 1
    local c = { md = {}, said = {}, id = nextId, xpCalls = {} }
    function c:getModData() return self.md end
    function c:Say(t) self.said[#self.said + 1] = t end
    function c:getOnlineID() return self.id end
    local xp = {}
    if withNoMultiplierXp then
        function xp:AddXPNoMultiplier(perk, amount) log.xp[#log.xp + 1] = { ch = c, perk = perk.name, amount = amount, via = "AddXPNoMultiplier" } end
    end
    function xp:AddXP(perk, amount, callLua, boost, remote)
        log.xp[#log.xp + 1] = { ch = c, perk = perk.name, amount = amount, via = "AddXP", boost = boost }
    end
    function c:getXp() return xp end
    return c
end
local function newItem(ft) return { getFullType = function() return ft end } end

-- runs the action like the engine would: queue, then perform (+ complete on B42)
local function read(character, item, opts)
    opts = opts or {}
    local a = ISReadABook:new(character, item, 150)
    local queued = ISTimedActionQueue.add(a)
    if queued and a:isValid() then
        a:perform()
        if ISReadABook.complete and not opts.skipComplete then a:complete() end
    end
    return a, queued
end

local MAG3 = "Base.MagazineWoodwork_three"
local LEARNED = fmt("IGUI_PassiveSkills_Learned", fmt("IGUI_PassiveSkills_Skill_Woodwork"))
local ALREADY = fmt("IGUI_PassiveSkills_AlreadyRead")

-- ------------------------------------------------------------ scenario 1: single player
do
    resetWorld({})
    local Game = require "PassiveSkills/Game"
    local alice = newCharacter(false)
    local a = read(alice, newItem(MAG3))
    check(not a.ignoreAction, "first read is queued")
    check(#log.xp == 1 and log.xp[1].perk == "Woodwork" and log.xp[1].amount == 300, "first read grants 300 Woodwork XP")
    if BUILD >= 42 then
        check(log.xp[1] and log.xp[1].via == "global", "B42 uses addXpNoMultiplier (no profession multiplier)")
        check(log.origComplete == 1, "vanilla complete still runs")
    else
        check(log.xp[1] and log.xp[1].via == "AddXP" and log.xp[1].boost == false, "B41 fallback AddXP without XP boost")
    end
    check(log.origPerform == 1, "vanilla perform still runs (action leaves the queue, no hang)")
    check(alice.said[1] == LEARNED, "Say learned line: " .. tostring(alice.said[1]))
    check(#log.halo == 1, "halo text shown")
    -- re-read: blocked before queueing
    local b, queued = read(alice, newItem(MAG3))
    check(b.ignoreAction == true and not queued, "re-read is never queued (no hang)")
    check(b:isValid() == false, "re-read isValid false as second guard")
    check(#log.xp == 1, "re-read grants no XP")
    check(alice.said[2] == ALREADY, "Say already-read line")
    check(log.origPerform == 1, "blocked action never performed")
    -- even if an action slips through (forced complete/perform), no double XP
    local c = ISReadABook:new(newCharacter(false), newItem(MAG3), 1)
    c.character = alice
    c:perform(); if c.complete then c:complete() end
    check(#log.xp == 1, "forced finish of an already-read volume grants nothing")
    -- another character learns from the same magazine type
    local bob = newCharacter(false)
    read(bob, newItem(MAG3))
    check(#log.xp == 2 and log.xp[2].ch == bob, "other character learns (per-character record)")
    -- legacy v1 Welding item maps to MetalWelding and shares its read key
    read(bob, newItem("Base.MagazineWelding_one"))
    check(#log.xp == 3 and log.xp[3].perk == "MetalWelding" and log.xp[3].amount == 75, "legacy Welding vol 1 -> MetalWelding 75")
    local d = read(bob, newItem("Base.MagazineMetalWelding_one"))
    check(d.ignoreAction == true and #log.xp == 3, "MetalWelding vol 1 already read via legacy item")
    -- vanilla literature untouched
    local said = #bob.said
    read(bob, newItem("Base.BookCarpentry1"))
    check(#log.xp == 3 and #bob.said == said, "vanilla book: no XP, no Say")
    -- B42-only skill on B42, absent on B41
    if BUILD >= 42 then
        read(bob, newItem("Base.MagazineBlacksmith_five"))
        check(log.xp[4] and log.xp[4].perk == "Blacksmith" and log.xp[4].amount == 1500, "Blacksmith vol 5 = 1500")
    else
        read(bob, newItem("Base.MagazineAnimalCare_one"))
        check(#log.xp == 3, "B42-only magazine type ignored in B41")
        read(bob, newItem("Base.MagazineRunning_five"))
        check(log.xp[4] and log.xp[4].perk == "Sprinting" and log.xp[4].amount == 1500, "Running vol 5 -> Sprinting 1500")
    end
    -- all 5 volumes of every skill -> exactly level-5 XP per skill
    local eve = newCharacter(false)
    local before = #log.xp
    local perSkill = {}
    for _, s in ipairs(Game.core().skills) do
        for t = 1, 5 do read(eve, newItem("Base.Magazine" .. s.id .. "_" .. ({ "one", "two", "three", "four", "five" })[t])) end
    end
    for i = before + 1, #log.xp do perSkill[log.xp[i].perk] = (perSkill[log.xp[i].perk] or 0) + log.xp[i].amount end
    local nPerk = 0
    for perk, total in pairs(perSkill) do
        nPerk = nPerk + 1
        check(total == 2775, "all 5 volumes of " .. perk .. " = 2775 XP (level 5), got " .. total)
    end
    check(nPerk == #Game.core().skills, "every skill gained XP (" .. nPerk .. ")")
    -- sandbox XP percent
    resetWorld({ xpPct = 50 })
    read(newCharacter(false), newItem("Base.MagazineCooking_five"))
    check(log.xp[1] and log.xp[1].amount == 750, "XpPercent 50 halves XP")
end

-- ------------------------------------------------------------ scenario 2: B41 with AddXPNoMultiplier available
if BUILD < 42 then
    resetWorld({})
    local ch = newCharacter(true)
    read(ch, newItem("Base.MagazineAxe_two"))
    check(log.xp[1] and log.xp[1].via == "AddXPNoMultiplier" and log.xp[1].amount == 150, "B41 prefers AddXPNoMultiplier")
end

-- ------------------------------------------------------------ scenario 3: B42 multiplayer (server authoritative)
if BUILD >= 42 then
    resetWorld({ server = true })
    local Game = require "PassiveSkills/Game"
    local srvChar = newCharacter(false)
    local a = ISReadABook:new(srvChar, newItem(MAG3), 150)   -- server-side construction: never pre-blocked
    check(not a.ignoreAction, "server never sets ignoreAction")
    a:perform(); a:complete()
    check(#log.xp == 1 and log.xp[1].amount == 300, "server grants XP in complete()")
    check(#srvChar.said == 0, "server does not Say")
    check(#log.cmds == 1 and log.cmds[1].command == "learned" and log.cmds[1].args.key == "Woodwork_3"
        and log.cmds[1].player == srvChar, "server notifies owning client")
    local learnedArgs = log.cmds[1].args
    local b = ISReadABook:new(srvChar, newItem(MAG3), 150)
    b:perform(); b:complete()
    check(#log.xp == 1 and log.cmds[2] and log.cmds[2].command == "already", "server re-read: no XP, 'already' sent")
    Game.onClientCommand("PassiveSkills", "requestSync", srvChar, {})
    local syncArgs = log.cmds[3] and log.cmds[3].args
    check(log.cmds[3] and log.cmds[3].command == "sync" and syncArgs.read[1] == "Woodwork_3", "sync reply lists read keys")

    -- client side of the same session
    local players = resetWorld({ client = true })
    Game = require "PassiveSkills/Game"
    local cli = newCharacter(false)
    cli.id = srvChar.id
    players[0] = cli
    local c = ISReadABook:new(cli, newItem(MAG3), 150)
    check(not c.ignoreAction, "client mirror empty before sync")
    c:perform(); c:complete()
    check(#log.xp == 0, "client never grants XP (isClient)")
    Game.onServerCommand("PassiveSkills", "learned", learnedArgs)
    check(cli.said[1] == LEARNED and #log.halo == 1, "client shows learned feedback from server")
    local d = ISReadABook:new(cli, newItem(MAG3), 150)
    check(d.ignoreAction == true and cli.said[2] == ALREADY, "client mirror blocks re-read")
    local cli2 = newCharacter(false)
    cli2.id = 77
    players[0] = cli2
    Game.onServerCommand("PassiveSkills", "sync", { read = { "Cooking_1" }, pid = 77 })
    check(require("PassiveSkills/Core").hasRead(cli2:getModData(), "Cooking_1"), "sync fills client mirror")
    Game.onServerCommand("OtherMod", "learned", learnedArgs)
    check(#cli2.said == 0, "other modules ignored")
    check(#Events.OnServerCommand.fns == 0, "(events registered only by client file)")
end

-- ------------------------------------------------------------ scenario 4: spawning through the server file
do
    resetWorld({ spawn = 100 })
    dofile(MODROOT .. "/server/PassiveSkills_Server.lua")
    check(#Events.OnFillContainer.fns == 1 and #Events.OnClientCommand.fns == 1, "server file registers OnFillContainer + OnClientCommand")
    local fill = Events.OnFillContainer.fns[1]
    local container = { AddItem = function(_, ft) log.added[#log.added + 1] = ft end }
    fill("livingroom", "shelves", container)
    check(#log.added == 1 and ITEMS[log.added[1]] == true, "100%: eligible container gets exactly one real item: " .. tostring(log.added[1]))
    fill("kitchen", "fridge", container)
    check(#log.added == 1, "ineligible container gets nothing")
    fill("livingroom", "shelves", nil)
    check(#log.added == 1, "nil container tolerated")
    resetWorld({ spawn = 0 })
    dofile(MODROOT .. "/server/PassiveSkills_Server.lua")
    Events.OnFillContainer.fns[1]("livingroom", "shelves", container)
    check(#log.added == 0, "0%: nothing spawns")
    local players = resetWorld({})
    dofile(MODROOT .. "/client/PassiveSkills_Client.lua")
    check(#Events.OnServerCommand.fns == 1 and #Events.OnCreatePlayer.fns == 1, "client file registers OnServerCommand + OnCreatePlayer")
end


-- Revalidate queued duplicates and commit read state only after XP succeeds.
do
    resetWorld({})
    local ch = newCharacter(false)
    local first = ISReadABook:new(ch, newItem(MAG3), 150)
    local second = ISReadABook:new(ch, newItem(MAG3), 150)
    first:perform()
    if first.complete then first:complete() end
    check(second:isValid() == false, "queued duplicate rejects at start")
    check(#log.xp == 1, "first volume grants XP once")
end
do
    resetWorld({})
    local Game = require "PassiveSkills/Game"
    local Core = require "PassiveSkills/Core"
    local ch = newCharacter(false)
    local grant = Game.grantXp
    Game.grantXp = function() return false end
    read(ch, newItem(MAG3))
    check(not Core.hasRead(ch.md, "Woodwork_3"), "failed XP preserves retry")
    Game.grantXp = grant
    read(ch, newItem(MAG3))
    check(#log.xp == 1, "retry grants missing XP once")
end
do
    resetWorld({})
    local Game = require "PassiveSkills/Game"
    local ch = newCharacter(false)
    _G.addXpNoMultiplier = nil
    ch.getXp = function() return {} end
    local ok, result = pcall(Game.grantXp, ch, "Woodwork", 300)
    check(ok and result == false, "missing XP methods report failure without throwing")
    ch.getXp = function() return nil end
    ok, result = pcall(Game.grantXp, ch, "Woodwork", 300)
    check(ok and result == false, "missing XP object reports failure without throwing")
end
do
    resetWorld({})
    local Game = require "PassiveSkills/Game"
    local Core = require "PassiveSkills/Core"
    local ch = newCharacter(false)
    local grant = Game.grantXp
    Game.grantXp = function() error("injected transient XP failure") end
    read(ch, newItem(MAG3))
    check(not Core.hasRead(ch.md, "Woodwork_3"), "XP exception preserves retry")
    Game.grantXp = grant
    read(ch, newItem(MAG3))
    check(#log.xp == 1, "retry after XP exception succeeds once")
end
do
    resetWorld({})
    local ch = newCharacter(false)
    read(ch, newItem(MAG3))
    ch.Say = function() error("injected speech failure") end
    local ok, action = pcall(ISReadABook.new, ISReadABook, ch, newItem(MAG3), 150)
    check(ok and action and action.ignoreAction, "feedback error does not break read constructor")
end

do
    resetWorld({})
    local ch = newCharacter(false)
    ch.md.PassiveSkills = { read = { Woodwork_3 = true, MetalWelding_1 = true, old_custom_key = true } }
    read(ch, newItem(MAG3))
    read(ch, newItem("Base.MagazineWelding_one"))
    check(#log.xp == 0 and ch.md.PassiveSkills.read.old_custom_key == true, "existing v2 read history and unrelated keys survive unchanged")
end
check(#missingText == 0, "getText keys missing from translations: " .. table.concat(missingText, ", "))
return failures
