-- Runs inside fengari with BUILD (41|42), KITS_EXPECTED (trait -> item count) and package.path set by tests/run.js.
local failures = 0
local function check(cond, msg) if not cond then failures = failures + 1; print("  spec FAIL: " .. msg) end end

-- ---- build-specific trait API mocks ----
local function newPlayer(traits)
    local p = { md = {}, items = {}, traits = {} }
    for _, t in ipairs(traits) do p.traits[t] = true end
    function p:getModData() return self.md end
    function p:getInventory()
        local owner = self
        return { AddItem = function(_, fullType) table.insert(owner.items, fullType); return { type = fullType } end }
    end
    if BUILD == 41 then
        function p:HasTrait(id) return self.traits[id] == true end
    else
        function p:hasTrait(traitObj) return self.traits[traitObj.id] == true end
    end
    return p
end
if BUILD == 42 then
    ResourceLocation = { of = function(s) return { loc = s } end }
    CharacterTrait = { get = function(rl) if rl.loc:find(":", 1, true) then return { id = rl.loc } end return nil end }
else
    ResourceLocation = nil
    CharacterTrait = nil
end
local handlers = {}
Events = { OnNewGame = { Add = function(f) table.insert(handlers, f) end } }

package.loaded["KRjobs/Core"] = nil
package.loaded["KRjobs/Kits"] = nil
dofile(MAIN_FILE)
check(#handlers == 1, "KRjobs_Main registers exactly one OnNewGame handler")
local Core = require("KRjobs/Core")
local Kits = require("KRjobs/Kits")

-- every kit: holder gets exactly its items, once
local n = 0
for _, kit in ipairs(Kits) do
    n = n + 1
    local p = newPlayer({ kit.trait })
    handlers[1](p, nil)
    check(#p.items == #kit.items, kit.trait .. " gives " .. #kit.items .. " items, got " .. #p.items)
    check(#p.items == KITS_EXPECTED[kit.trait], kit.trait .. " kit size matches data.js")
    handlers[1](p, nil)
    check(#p.items == #kit.items, kit.trait .. " kit is given only once per character")
    check(#kit.items >= 1 and #kit.items <= 3, kit.trait .. " kit has 1-3 items (modest)")
end
local expectedKits = 0
for _ in pairs(KITS_EXPECTED) do expectedKits = expectedKits + 1 end
check(n == expectedKits, "Kits.lua has " .. expectedKits .. " kits, got " .. n)

-- no trait -> nothing; unknown trait ids never throw
local plain = newPlayer({})
check(Core.giveKits(plain) == 0 and #plain.items == 0, "character without KRjobs traits gets nothing")
check(Core.hasTrait(plain, "nope") == false and Core.hasTrait(nil, "x") == false, "hasTrait is safe")
check(Core.giveKits(nil) == 0, "giveKits(nil) is safe")

-- Separate actor replicas must not both mutate inventories in multiplayer.
local clientSide = true
isClient = function() return clientSide end
local clientReplica = newPlayer({ Kits[1].trait })
handlers[1](clientReplica, nil)
check(#clientReplica.items == 0, "client representation receives no locally-created kit")
check(not clientReplica.md[Core.MODDATA_KEY], "client does not mark a server kit as delivered")
clientSide = false
local serverReplica = newPlayer({ Kits[1].trait })
handlers[1](serverReplica, nil)
check(#serverReplica.items == #Kits[1].items, "server representation receives the kit")
handlers[1](serverReplica, nil)
check(#serverReplica.items == #Kits[1].items, "server event replay cannot duplicate the kit")

-- A failed slot remains retryable without recreating slots already delivered.
local retryPlayer = newPlayer({ Kits[1].trait })
local reject = true
local failedType = Kits[1].items[1]
function retryPlayer:getInventory()
    local owner = self
    return { AddItem = function(_, fullType)
        if reject and fullType == failedType then return nil end
        table.insert(owner.items, fullType)
        return { type = fullType }
    end }
end
Core.giveKits(retryPlayer)
check(not retryPlayer.md[Core.MODDATA_KEY], "partial kit is not marked complete")
reject = false
Core.giveKits(retryPlayer)
check(#retryPlayer.items == #Kits[1].items, "failed slot retries without duplicating successful slots")
check(retryPlayer.md[Core.MODDATA_KEY] == true, "successful retry completes delivery")
local legacyPlayer = newPlayer({ Kits[1].trait })
legacyPlayer.md[Core.MODDATA_KEY] = true
Core.giveKits(legacyPlayer)
check(#legacyPlayer.items == 0, "legacy completed marker remains authoritative")

return failures
