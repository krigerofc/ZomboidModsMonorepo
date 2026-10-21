-- Integration against the installed native ISRadioInteractions.lua (no copied synthetic XP path).
local failures = 0
local function check(v, m) if not v then failures = failures + 1; print("  FAIL [VHS]: " .. m) end end
local function event()
    local e = { fns = {} }
    function e.Add(f) e.fns[#e.fns + 1] = f end
    function e.Remove(f) for i = #e.fns, 1, -1 do if e.fns[i] == f then table.remove(e.fns, i) end end end
    return e
end
Events = setmetatable({}, { __index = function(t, k) local e = event(); rawset(t, k, e); return e end })
local Data = require "PassiveSkills/VHSData"
local VHS = require "PassiveSkills/VHS"
local media, registered = {}, {}
local rc = {}
function rc:register(category, id, title, spawning)
    check(category == "PassiveSkills-VHS", "private category keeps native retail loot unchanged")
    check(not registered[id], "registration identity unique")
    local d = { id = id, title = title, lines = {} }
    function d:setTitle(t) self.title = t end
    function d:setSubtitle(t) self.subtitle = t end
    function d:setAuthor(t) self.author = t end
    function d:addLine(text, r, g, b, codes) self.lines[#self.lines + 1] = { text = text, codes = codes } end
    registered[id] = d; media[#media + 1] = d
    return d
end
function rc:getMediaData(id) return registered[id] end
dofile(MODROOT .. "/shared/PassiveSkills_VHS.lua")
check(#Events.OnInitRecordedMedia.fns == 1 and #Events.OnGameBoot.fns == 1 and #Events.OnFillContainer.fns == 1, "auto-loaded registration/playback/spawn hooks")
Events.OnInitRecordedMedia.fns[1](rc)
check(#media == 16, "16 registered original playable programs")
local perkSet, guids = {}, {}
for _, tape in ipairs(Data) do
    perkSet[tape.perk] = true
    local d = registered[tape.id]
    check(d and #d.lines == 5, tape.id .. " has five teaching lines")
    check(PERKS[tape.perk], "target perk exists: " .. tape.perk)
    check(MEDIA_TEXT[tape.title] ~= nil, "localized title exists")
    for _, line in ipairs(tape.lines) do
        check(not guids[line.text], "stable line identity unique")
        guids[line.text] = true
        check(MEDIA_TEXT[line.text] and #MEDIA_TEXT[line.text] > 35, "full original caption exists")
    end
end
local stableIds = { "SquareStart", "ShelfSunday", "DrivewayChecks", "WheelRoutine", "FirstMinutes", "CleanDressings", "DeadCircuit", "BenchRadio", "WeldPrep", "SteadyBead", "ForgeMorning", "HookAndEye", "FirstCourse", "BrickRhythm", "MendBasket", "WorkingHem" }
for i, id in ipairs(stableIds) do
    check(Data[i].id == "PassiveSkillsVHS_" .. id, "published program identity preserved")
    for j, line in ipairs(Data[i].lines) do
        check(line.text == "RM_PassiveSkillsVHS_" .. id .. "_L" .. j, "published caption identity preserved")
    end
end
local n = 0; for _ in pairs(perkSet) do n = n + 1 end
check(n == 8, "eight skills")
-- Spawn is independent of magazine chance; possession/creation never calls XP.
local added, xpCalls = {}, 0
getZomboidRadio = function() return { getRecordedMedia = function() return rc end } end
isClient = function() return false end
isServer = function() return true end
addXp = function() xpCalls = xpCalls + 1 end
ZombRand = function() return 0 end
SandboxVars = { PassiveSkills = { SpawnChance = 0, VHSSpawnChance = 100, VHSXpPercent = 100 } }
local container = {}
function container:AddItem(ft)
    local item = { fullType = ft }
    function item:setRecordedMediaData(d) self.data = d end
    added[#added + 1] = item; return item
end
VHS.onFillContainer("livingroom", "shelves", container)
check(#added == 1 and added[1].fullType == "Base.VHS_Retail" and added[1].data == media[1], "native VHS item receives registered program")
check(xpCalls == 0, "possession/insertion-independent spawn grants no XP")
VHS.onFillContainer("kitchen", "fridge", container)
check(#added == 1, "unsupported loot location ignored")
SandboxVars.PassiveSkills.VHSSpawnChance = 0
VHS.onFillContainer("livingroom", "shelves", container)
check(#added == 1, "independent VHS disable works")
isClient = function() return true end
SandboxVars.PassiveSkills.VHSSpawnChance = 100
VHS.onFillContainer("livingroom", "shelves", container)
check(#added == 1, "client cannot spawn")
if not VANILLA_RADIO then
    print("  SKIP VHS native playback-learning integration: set PZ_MEDIA to installed game media.")
    return failures
end
local function character(id, x, z)
    local p = { id = id, x = x or 0, z = z or 0, known = {}, totals = {}, level = 0, multiplier = 1 }
    function p:getPlayerNum() return self.id end
    function p:getOnlineID() return self.id end
    function p:getX() return self.x end
    function p:getY() return 0 end
    function p:getZ() return self.z end
    function p:getSquare() return { isOutside = function() return false end } end
    function p:isAsleep() return self.sleeping == true end
    function p:isDead() return self.dead == true end
    function p:isKnownMediaLine(g) return self.known[g] == true end
    function p:addKnownMediaLine(g) self.known[g] = true end
    function p:getStats() return {} end
    function p:getMoodles() return nil end
    function p:getPerkLevel() return self.level end
    function p:getXp() return { getXP = function(_, perk) return self.totals[perk] or 0 end } end
    return p
end
local players, nativeCalls, nativeArgs
local function boot(server)
    Events = setmetatable({}, { __index = function(t, k) local e = event(); rawset(t, k, e); return e end })
    isServer = function() return server end
    isClient = function() return not server end
    players = {}
    getSpecificPlayer = function(i) return players[i] end
    getOnlinePlayers = function() return { size = function() return 4 end, get = function(_, i) return players[i] end } end
    -- Native server loop requires non-nil list members.
    if server then getOnlinePlayers = function()
        local a = {}; for i = 0, 3 do if players[i] then a[#a + 1] = players[i] end end
        return { size = function() return #a end, get = function(_, i) return a[i + 1] end }
    end end
    getCell = function() return { getGridSquare = function() return { isOutside = function() return false end } end } end
    getGameTime = function() return { getMultiplier = function() return 1 end } end
    getText = function(k) return k end
    HaloTextHelper = { getGoodColor = function() return {} end, addTextWithArrow = function() end }
    Perks = {}; for p in pairs(PERKS) do Perks[p] = p end
    SandboxVars = { LevelForMediaXPCutoff = 10, PassiveSkills = { VHSXpPercent = 100 } }
    addXp = function(p, perk, a) p.totals[perk] = (p.totals[perk] or 0) + a * p.multiplier end
    dofile(VANILLA_RADIO)
    local native = ISRadioInteractions:getInstance()
    local original = native.OnDeviceText
    nativeCalls = 0
    -- Instrument native invocation, while its real body and history logic still run.
    Events.OnDeviceText.Remove(original)
    native.OnDeviceText = function(...) nativeCalls = nativeCalls + 1; nativeArgs = { ... }; return original(...) end
    Events.OnDeviceText.Add(native.OnDeviceText)
    VHS.install()
    VHS.install()
    check(#Events.OnDeviceText.fns == 1, "one native delegate after idempotent installation")
    return native
end
local function emit(tape, i, x, z)
    local l = tape.lines[i]
    for _, fn in ipairs(Events.OnDeviceText.fns) do fn(l.text, l.codes, x or 0, 0, z or 0, MEDIA_TEXT[l.text]) end
    -- Real DeviceData lineCounter minimum is >=60 ticks, native cooldown is30.
    for _ = 1, 60 do for _, fn in ipairs(Events.OnTick.fns) do fn() end end
end
for _, server in ipairs({ false, true }) do
    boot(server)
    local a, b = character(0), character(1)
    players[0] = a; players[1] = b
    for _, tape in ipairs(Data) do
        local before = a.totals[tape.perk] or 0
        emit(tape, 1); emit(tape, 2)
        check(a.totals[tape.perk] == before + 100, "partial playback gives only two lines")
        emit(tape, 1) -- replay/two copies/moved TV, GUID remains identical
        check(a.totals[tape.perk] == before + 100, "repeat/copy cannot replay a line")
        for i = 3, 5 do emit(tape, i) end
        check(a.totals[tape.perk] == before + 250, "full tape gives250 base XP: " .. tape.perk)
        check(b.totals[tape.perk] == a.totals[tape.perk], "two viewers learn independently")
    end
    -- Native character save/load persists this set; mimic restored engine fields on reconnect.
    local restored = character(0)
    restored.known = a.known; restored.totals = a.totals
    players[0] = restored
    local old = restored.totals.Woodwork
    emit(Data[1], 1, 1)
    check(restored.totals.Woodwork == old, "restored native line history prevents replay after moving TV")
    local far, upstairs, sleeping = character(2, 6), character(3, 0, 1), character(1)
    sleeping.sleeping = true
    players[0] = far; players[1] = upstairs; players[2] = sleeping; players[3] = nil
    emit(Data[1], 1)
    check(not next(far.totals) and not next(upstairs.totals) and not next(sleeping.totals), "native range/floor/sleep gates")
end
boot(false)
local p = character(0); players[0] = p
SandboxVars.PassiveSkills.VHSXpPercent = 50
emit(Data[1], 1)
check(p.totals.Woodwork == 25, "independent VHS XP50 scales native code")
p.multiplier = 2; emit(Data[1], 2)
check(p.totals.Woodwork == 75, "native XP multipliers remain active")
SandboxVars.PassiveSkills.VHSXpPercent = 0
emit(Data[1], 3)
check(not p.known[Data[1].lines[3].text], "disabled XP does not consume learning history")
SandboxVars.PassiveSkills.VHSXpPercent = 100
emit(Data[1], 3)
check(p.totals.Woodwork == 175, "reenabling can learn the unconsumed line")
p.level = 10; emit(Data[1], 4)
check(p.totals.Woodwork == 175 and p.known[Data[1].lines[4].text], "native cutoff consumes seen line with no XP")
local calls = nativeCalls
local source = {}
Events.OnDeviceText.fns[1]("foreign-guid", "CRP+2", 0, 0, 0, "vanilla", source)
check(nativeCalls == calls + 1 and p.known["foreign-guid"], "foreign GUID delegates exactly once with native history")
check(nativeArgs[1] == "foreign-guid" and nativeArgs[2] == "CRP+2" and nativeArgs[3] == 0 and nativeArgs[6] == "vanilla" and nativeArgs[7] == source, "foreign GUID/codes/text/source pass through verbatim")
-- Wrapper delegates original captured handler; foreign scaling checked via fresh eligible perk/player.
p.level = 0; p.multiplier = 1; SandboxVars.PassiveSkills.VHSXpPercent = 50
for _ = 1, 60 do for _, f in ipairs(Events.OnTick.fns) do f() end end
local before = p.totals.Woodwork
Events.OnDeviceText.fns[1]("RM_PS_unknown", "CRP+2", 0, 0, 0, "foreign-prefix")
check(p.totals.Woodwork == before + 100, "unrecognized GUID with similar prefix is unchanged")
boot(false)
p = character(0); players[0] = p
local a, b = Data[1].lines[1], Data[1].lines[2]
Events.OnDeviceText.fns[1](a.text, a.codes, 0, 0, 0, MEDIA_TEXT[a.text])
Events.OnDeviceText.fns[1](b.text, b.codes, 0, 0, 0, MEDIA_TEXT[b.text])
check(p.totals.Woodwork == 50 and p.known[b.text], "native concurrent-TV cooldown can consume a line without XP")
boot(false)
p = character(0); players[0] = p
local noCode = Data[1].lines[3]
Events.OnDeviceText.fns[1](noCode.text, nil, 0, 0, 0, MEDIA_TEXT[noCode.text])
check(nativeArgs[2] == nil and not next(p.totals), "caption-only native event must not manufacture an XP code")
return failures
