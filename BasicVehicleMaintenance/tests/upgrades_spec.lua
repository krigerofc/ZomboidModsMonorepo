local failures, checks = 0, 0
local function check(ok, msg) checks = checks + 1; if not ok then failures = failures + 1; print("  FAIL upgrades: " .. msg) end end
local loaded, U = pcall(require, "MVR/Upgrades")
if not loaded then U = {} end
local function target(base, kind, tier)
    if U.target then return U.target(base, kind, tier) end
end
check(target(100, "cargo", 1) == 110, "cargo first tier is ten percent")
check(target(100, "cargo", 2) == 120, "cargo second tier is twenty percent")
check(target(500, "cargo", 2) == 540, "large cargo additional capacity capped at forty")
check(target(10, "glove", 2) == 15, "glovebox increase capped at five")
check(target(10000, "power", 2) == 11000, "engine power at most ten percent")
check(target(100, "cargo", 0) == 100, "reset restores baseline")
check(target(100, "fuel", 2) == nil, "fuel cannot be treated as cargo")
check(target(100, "cargo", 99) == nil, "invalid tier rejected")
check(target(-10, "cargo", 1) == nil and target(0/0, "cargo", 1) == nil, "nonfinite or negative baseline rejected")
local function role(info) return U.role and U.role(info) end
check(role({id="CustomBoot", inventory=true, itemType="Base.NormalTrunk2"}) == "cargo", "unknown model part with generic trunk accepted")
check(role({id="Storage", inventory=true, itemType="Base.GloveBox3"}) == "glove", "generic glovebox accepted by capability")
check(role({id="Engine"}) == "power", "intrinsic generic engine accepted")
check(role({id="GasTank", inventory=false, itemType="Base.GasTank1"}) == nil, "fluid storage excluded")
check(role({id="TrailerAnimalFood", inventory=true, special=true, itemType="Base.NormalTrunk1"}) == nil, "special purpose container excluded")
local function record(...) if U.record then return U.record(...) end end
local state, value, status = record(nil, "item1", 100, "cargo", 1, 0)
check(state and state.base == 100 and value == 110 and status == "ok", "records immutable baseline")
local second, value2 = record(state, "item1", 110, "cargo", 2, 0)
check(second and second.base == 100 and value2 == 120, "upgrade uses original rather than upgraded baseline")
local _, _, repeated = record(second, "item1", 120, "cargo", 2, 0)
check(repeated == "already", "same tier cannot stack")
local _, _, crowded = record(second, "item1", 120, "cargo", 0, 110)
check(crowded == "overloaded", "downgrade cannot lose occupied cargo")
local replacement, replacementValue = record(second, "item2", 40, "cargo", 1, 0)
check(replacement and replacement.base == 40 and replacementValue == 44, "replacement item has own baseline")
check(state and state.level == 1, "pure updates never mutate previous snapshot")
check(role({id="TrailerTrunk", inventory=true, itemType="Base.TrailerTrunk1"}) == "cargo", "ordinary trailer generic item accepted")
check(role({id="TrailerAnimalFood", inventory=true, itemType="Base.TrailerTrunk1"}) == nil, "shared animal food item does not imply ordinary cargo")
print("  upgrades_spec.lua: " .. checks .. " checks")
return failures
