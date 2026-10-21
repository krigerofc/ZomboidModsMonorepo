-- B42 native RecordedMedia integration. No custom XP, playback timers, or read-state store.
local Data = require "PassiveSkills/VHSData"
local Core = require "PassiveSkills/Core"
local VHS = {}
local lineCodes = {}
for _, tape in ipairs(Data) do
    for _, line in ipairs(tape.lines) do lineCodes[line.text] = tape.code end
end
local function settings()
    local s = SandboxVars and SandboxVars.PassiveSkills or {}
    local chance = tonumber(s.VHSSpawnChance) or 2
    local xp = tonumber(s.VHSXpPercent) or 100
    return math.max(0, math.min(100, chance)), math.max(0, math.min(1000, xp))
end
function VHS.init(recordedMedia)
    for _, tape in ipairs(Data) do
        -- A private category keeps these programs out of vanilla retail spawn tables.
        -- RecordedMedia.getMediaTypeForCategory maps every non-CD category to VHS type1.
        local media = recordedMedia:register("PassiveSkills-VHS", tape.id, tape.title, 0)
        if media then
            media:setTitle(tape.title)
            media:setSubtitle("RM_PassiveSkillsVHS_Subtitle")
            media:setAuthor("RM_PassiveSkillsVHS_Author")
            for _, line in ipairs(tape.lines) do media:addLine(line.text, 0.2, 0.8, 0.4, line.codes) end
        end
    end
end
local installedInstance
function VHS.install()
    if not ISRadioInteractions then require "RadioCom/ISRadioInteractions" end
    local native = ISRadioInteractions:getInstance()
    if installedInstance == native then return end
    local original = native.OnDeviceText
    local function onText(guid, codes, x, y, z, line, source)
        local code = lineCodes[guid]
        if code and codes == code .. "+1" then
            local _, xp = settings()
            -- XP0 leaves native history unconsumed. Subtitles still come from DeviceData.
            if xp <= 0 then return end
            codes = code .. "+" .. tostring(xp / 100)
        end
        -- Native owns viewer gates, per-character saved line history, XP, cooldown and feedback.
        -- Foreign GUIDs and arguments pass through unchanged, exactly once.
        return original(guid, codes, x, y, z, line, source)
    end
    Events.OnDeviceText.Remove(original)
    Events.OnDeviceText.Add(onText)
    native.OnDeviceText = onText
    installedInstance = native
end
function VHS.onFillContainer(roomName, containerType, container)
    if isClient() or not container then return end
    local chance = settings()
    if chance <= 0 or not Core.isEligibleContainer(roomName, containerType) then return end
    if ZombRand(10000) >= chance * 100 then return end
    local tape = Data[ZombRand(#Data) + 1]
    local media = getZomboidRadio():getRecordedMedia():getMediaData(tape.id)
    if not media then return end
    -- RWMMedia keyboard/controller both look up the exact vanilla full type.
    local item = container:AddItem("Base.VHS_Retail")
    if item then item:setRecordedMediaData(media) end
end
return VHS
