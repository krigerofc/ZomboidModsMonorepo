-- Bounded per-instance policies. Baselines are saved before the first upgrade.
MVR = MVR or {}
local U = {}
MVR.Upgrades = U

local function finite(n)
    return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
end

function U.target(base, kind, tier)
    if not finite(base) or base <= 0 or not finite(tier) or tier ~= math.floor(tier) or tier < 0 or tier > 2 then
        return nil
    end
    if kind ~= "cargo" and kind ~= "glove" and kind ~= "power" then return nil end
    local addition = 0
    if kind == "cargo" then addition = math.min(base * tier * 0.1, 40)
    elseif kind == "glove" then addition = math.min(base * tier * 0.25, 5)
    elseif kind == "power" then addition = base * tier * 0.05 end
    return math.floor(base + addition + 0.5)
end

function U.role(info)
    if type(info) ~= "table" or info.special then return nil end
    if type(info.id) == "string" and info.id:match("^TrailerAnimal") then return nil end
    if info.id == "Engine" then return "power" end
    if not info.inventory or type(info.itemType) ~= "string" then return nil end
    if info.itemType:match("^Base%.GloveBox%d$") then return "glove" end
    for _, pattern in ipairs({ "^Base%.TrailerTrunk%d$", "^Base%.NormalTrunk%d$", "^Base%.BigTrunk%d$", "^Base%.SmallTrunk%d$" }) do
        if info.itemType:match(pattern) then return "cargo" end
    end
    return nil
end

function U.record(previous, itemId, currentBase, kind, tier, occupied)
    local same = type(previous) == "table" and previous.itemId == tostring(itemId) and previous.kind == kind
    local baseline = same and previous.base or currentBase
    local level = same and previous.level or 0
    local value = U.target(baseline, kind, tier)
    if not value then return nil, nil, "unsupported" end
    if tier == level then return nil, value, "already" end
    if kind ~= "power" and (tonumber(occupied) or 0) > value then return nil, value, "overloaded" end
    return { version = 1, itemId = tostring(itemId), kind = kind, base = baseline, level = tier }, value, "ok"
end

return U
