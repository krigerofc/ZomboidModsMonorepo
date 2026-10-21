-- Pure-logic spec for PassiveSkills/Core.lua + Catalog.lua. Run by tests/run.js in fengari once per
-- build copy. Globals provided by the runner: BUILD (41|42), PERKS (set of perk names valid in BUILD).
-- Returns the number of failures.
local Core = require "PassiveSkills/Core"
local Catalog = require "PassiveSkills/Catalog"

local failures = 0
local function check(cond, msg)
    if not cond then failures = failures + 1; print("  FAIL [B" .. BUILD .. "]: " .. msg) end
end

local core = Core.new(Catalog, BUILD, function(perk, fullType) return PERKS[perk] == true end)

-- ---------- perk mapping completeness ----------
local expectedSkills = BUILD >= 42 and 33 or 24
check(#core.skills == expectedSkills, "skill count " .. #core.skills .. " expected " .. expectedSkills)
local seenPerk = {}
for _, s in ipairs(core.skills) do
    check(PERKS[s.perk] == true, "perk missing in build: " .. s.perk)
    check(not seenPerk[s.perk], "duplicate perk (dedupe failed): " .. s.perk)
    seenPerk[s.perk] = true
    check(s.perk ~= "Fitness" and s.perk ~= "Strength", "Fitness/Strength must not have magazines")
    check(s.id ~= "Welding", "Welding must not be a spawnable skill")
end
-- every b41-flagged skill also passes in a B42 build, every non-b41 skill is excluded from B41
for _, s in ipairs(Catalog.SKILLS) do
    if BUILD < 42 and not s.b41 then check(core.byId[s.id] == nil, "B42-only skill leaked into B41: " .. s.id) end
    if BUILD >= 42 then check(core.byId[s.id] ~= nil, "skill missing in B42: " .. s.id) end
end
-- the B41 instance would drop a skill whose perk is missing (no nil-perk errors at runtime)
local noHusbandry = Core.new(Catalog, 42, function(perk) return perk ~= "Husbandry" end)
check(noHusbandry.byId.AnimalCare == nil and #noHusbandry.skills == 32, "missing perk filters the skill out")
check(core.count == expectedSkills * 5 + 5, "magazine types = 5 per skill + 5 legacy, got " .. core.count)

-- ---------- XP totals ----------
local total = 0
for t = 1, 5 do total = total + core:xpFor(t, 100) end
check(total == 2775, "5 volumes at 100% must sum 2775 (= level 5), got " .. total)
check(core:xpFor(5, 100) == 1500 and core:xpFor(4, 100) == 750, "tier 4/5 xp (v1 Sneaking_four=1500 bug)")
check(core:xpFor(1, 200) == 150 and core:xpFor(1, 0) == 0 and core:xpFor(3, 50) == 150, "xp percent scaling")

-- ---------- settings ----------
local s = Core.settings(nil)
check(s.spawnChance == 12 and s.xpPercent == 100, "defaults 12% / 100%")
s = Core.settings({ PassiveSkills = { SpawnChance = 150, XpPercent = -5 } })
check(s.spawnChance == 100 and s.xpPercent == 0, "clamping")
s = Core.settings({ PassiveSkills = { SpawnChance = 15 } })
check(s.spawnChance == 15 and s.xpPercent == 100, "partial sandbox")

-- ---------- read-once per character ----------
local alice, bob = {}, {}
local st, e = core:resolveRead(alice, "Base.MagazineWoodwork_three")
check(st == "learned" and e.perk == "Woodwork" and e.tier == 3 and e.key == "Woodwork_3", "first read learns")
st = core:resolveRead(alice, "Base.MagazineWoodwork_three")
check(st == "already", "second read by same character -> already")
st = core:resolveRead(bob, "Base.MagazineWoodwork_three")
check(st == "learned", "other character still learns (not world-global)")
st = core:resolveRead(alice, "Base.MagazineWoodwork_four")
check(st == "learned", "other volume of same skill learns")
check(core:resolveRead(alice, "Base.Magazine") == nil and core:resolveRead(alice, "Base.BookCarpentry1") == nil, "foreign items ignored")
local keys = Core.readKeys(alice)
check(#keys == 2 and keys[1] == "Woodwork_3" and keys[2] == "Woodwork_4", "readKeys sorted list")
check(Core.hasRead({ PassiveSkills = "garbage" }, "x") == false, "corrupt modData tolerated")
-- legacy Welding shares MetalWelding's read key
local carol = {}
st, e = core:resolveRead(carol, "Base.MagazineMetalWelding_two")
check(st == "learned", "MetalWelding vol 2 learns")
st, e = core:resolveRead(carol, "Base.MagazineWelding_two")
check(st == "already" and e.legacy == true and e.perk == "MetalWelding", "legacy Welding vol 2 counts as already read")

-- ---------- eligibility ----------
check(Core.isEligibleContainer("livingroom", "shelves"), "living room bookshelf")
check(Core.isEligibleContainer("all", "postbox") and Core.isEligibleContainer(nil, "postbox"), "postbox")
check(Core.isEligibleContainer("grocery", "shelvesmag"), "magazine rack")
check(Core.isEligibleContainer("office", "desk") and Core.isEligibleContainer("classroom", "schooldesk"), "desks")
check(Core.isEligibleContainer("classroom_pottery", "shelves"), "classroom_* shelves")
check(Core.isEligibleContainer("library", "counter") and not Core.isEligibleContainer("kitchen", "counter"), "counters only in book rooms")
check(not Core.isEligibleContainer("kitchen", "fridge") and not Core.isEligibleContainer("bedroom", "wardrobe"), "fridge/wardrobe not eligible")
check(not Core.isEligibleContainer("grocery", "shelves"), "grocery shelves not eligible")
check(not Core.isEligibleContainer("livingroom", nil), "nil container type")

-- ---------- spawn roll probability ----------
-- Park-Miller (float math, exact below 2^53). fengari's math.random is sequentially correlated, so not used here.
local seed = 20261017.0
local function rng(n) -- ZombRand semantics [0, n-1]
    seed = (seed * 48271.0) % 2147483647.0
    return math.floor(seed / 2147483647.0 * n)
end
local N, hits = 200000, 0
local tierHits, skillHits = { 0, 0, 0, 0, 0 }, {}
for _ = 1, N do
    local ft = core:rollSpawn("livingroom", "shelves", 12, rng)
    if ft then
        hits = hits + 1
        local en = core:entryFor(ft)
        check(en ~= nil and not en.legacy, "spawned item must be a known non-legacy magazine: " .. tostring(ft))
        if en then
            tierHits[en.tier] = tierHits[en.tier] + 1
            skillHits[en.skill] = (skillHits[en.skill] or 0) + 1
        end
    end
end
local rate = hits / N
check(math.abs(rate - 0.12) < 0.005, string.format("spawn rate %.4f ~ 0.12", rate))
for t = 1, 5 do
    local expected = Catalog.TIER_WEIGHTS[t] / 100
    local got = tierHits[t] / hits
    check(math.abs(got - expected) < 0.01, string.format("tier %d share %.3f ~ %.2f", t, got, expected))
end
check(tierHits[1] > tierHits[2] and tierHits[2] > tierHits[3] and tierHits[3] > tierHits[4] and tierHits[4] > tierHits[5], "lower tiers more common")
local nSkills = 0
for id, c in pairs(skillHits) do
    nSkills = nSkills + 1
    local share = c / hits
    check(math.abs(share - 1 / expectedSkills) < 0.01, string.format("skill share %s %.4f", id, share))
end
check(nSkills == expectedSkills, "every skill can spawn (" .. nSkills .. ")")
local h2 = 0
for _ = 1, 100000 do if core:rollSpawn("bookstore", "shelves", 15, rng) then h2 = h2 + 1 end end
check(math.abs(h2 / 100000 - 0.15) < 0.006, "15% setting")
check(core:rollSpawn("livingroom", "shelves", 0, rng) == nil, "0% never spawns")
local ineligible = 0
for _ = 1, 10000 do if core:rollSpawn("kitchen", "fridge", 100, rng) then ineligible = ineligible + 1 end end
check(ineligible == 0, "ineligible container never spawns even at 100%")
local always = 0
for _ = 1, 1000 do if core:rollSpawn("post", "postbox", 100, rng) then always = always + 1 end end
check(always == 1000, "100% always spawns exactly one")

return failures
