-- Field Medicine '93 - one timed action for every procedure. Same structure as vanilla ISStitch/ISDisinfect:
-- state is set in new(), body/stat/item changes only happen in complete() (server in MP, local in SP) and are
-- synced with syncBodyPart / syncPlayerStats / sendItemStats / sendRemoveItemFromContainer.
-- new(character = doctor, otherPlayer = patient, bodyPart, procId, item, item2)
--   exam:           item = stethoscope (opt.), item2 = tongue depressor (opt., consumed)
--   irrigate:       item = water container (0.25 L used)
--   tourniquet:     item = improvised tourniquet or belt (moves onto the limb, returned on removal)
--   tourniquetOff:  -
--   cauterize:      item = blade (kept), item2 = lighter/matches (one use)
--   reduceFracture: -
--   debride:        item = scalpel (kept)
require "TimedActions/ISBaseTimedAction"
local Core = require "KFM/Core"
local Game = require "KFM/Game"

KFM_ProcedureAction = ISBaseTimedAction:derive("KFM_ProcedureAction")

KFM_ProcedureAction.LABEL = {
    exam = "ContextMenu_KFM_Exam",
    irrigate = "ContextMenu_KFM_Irrigate",
    tourniquet = "ContextMenu_KFM_Tourniquet",
    tourniquetOff = "ContextMenu_KFM_TourniquetRemove",
    cauterize = "ContextMenu_KFM_Cauterize",
    reduceFracture = "ContextMenu_KFM_ReduceFracture",
    debride = "ContextMenu_KFM_Debride",
}
KFM_ProcedureAction.SOUND = {
    irrigate = "FirstAidApplyAlcohol",
    cauterize = "FirstAidApplyStitch",
    debride = "FirstAidApplyStitch",
}

-- Is the procedure still meaningful for this body part right now? (re-checked every tick and on the server)
function KFM_ProcedureAction.applies(procId, patient, bp)
    if procId == "exam" then return true end
    local w = Game.wound(bp)
    local part = Game.partName(bp)
    if procId == "irrigate" then return Core.canIrrigate(w) end
    if procId == "tourniquet" then
        return Core.canTourniquet(part) and Core.tourniquetOnLimb(Game.tqView(patient), part) == nil
    end
    if procId == "tourniquetOff" then return Game.tqView(patient)[part] ~= nil end
    if procId == "cauterize" then return Core.canCauterize(w) end
    if procId == "reduceFracture" then
        return w.fractureTime > 0 and not Game.md(patient).reduced[part] and Game.isResting(patient)
    end
    if procId == "debride" then return Core.canDebride(w) end
    return false
end

function KFM_ProcedureAction:hasItem(item)
    if isClient() then return self.character:getInventory():containsID(item:getID()) end
    return self.character:getInventory():contains(item)
end


-- Revalidate required resources on both peers. A missing item ID can reconstruct as nil in MP.
function KFM_ProcedureAction:hasRequiredItems()
    if self.item and not self:hasItem(self.item) then return false end
    if self.item2 and not self:hasItem(self.item2) then return false end
    if self.procId == "irrigate" then
        return self.item ~= nil and Game.waterKind(self.item) ~= nil
    elseif self.procId == "tourniquet" then
        if not self.item then return false end
        local ft = self.item:getFullType()
        return (ft == Game.ITEM_TOURNIQUET or ft == Game.ITEM_BELT) and not self.item:isWorn()
    elseif self.procId == "cauterize" then
        return self.item ~= nil and Game.isBlade(self.item) and Game.isFireSource(self.item2)
    elseif self.procId == "debride" then
        return self.item ~= nil and self.item:getFullType() == Game.ITEM_SCALPEL
    elseif self.procId == "exam" then
        return (self.item == nil or self.item:getFullType() == Game.ITEM_STETHOSCOPE)
            and (self.item2 == nil or self.item2:getFullType() == Game.ITEM_TONGUE)
    end
    return true
end

function KFM_ProcedureAction:isValid()
    if Game.patientMoved(self.character, self.otherPlayer, self.patientX, self.patientY) then return false end
    if not self:hasRequiredItems() then return false end
    return KFM_ProcedureAction.applies(self.procId, self.otherPlayer, self.bodyPart)
end

function KFM_ProcedureAction:waitToStart()
    if self.character == self.otherPlayer then return false end
    self.character:faceThisObject(self.otherPlayer)
    return self.character:shouldBeTurning()
end

function KFM_ProcedureAction:setPanelAction(active)
    if not (ISHealthPanel and ISHealthPanel.setBodyPartActionForPlayer) then return end
    if active then
        ISHealthPanel.setBodyPartActionForPlayer(self.otherPlayer, self.bodyPart, self, getText(KFM_ProcedureAction.LABEL[self.procId]), { kfm = true })
    else
        ISHealthPanel.setBodyPartActionForPlayer(self.otherPlayer, self.bodyPart, nil, nil, nil)
    end
end

function KFM_ProcedureAction:update()
    if self.character ~= self.otherPlayer then self.character:faceThisObject(self.otherPlayer) end
    self:setPanelAction(true)
    self.character:setMetabolicTarget(Metabolics.LightDomestic)
end

function KFM_ProcedureAction:start()
    if isClient() then
        if self.item then self.item = self.character:getInventory():getItemById(self.item:getID()) end
        if self.item2 then self.item2 = self.character:getInventory():getItemById(self.item2:getID()) end
    end
    if self.character == self.otherPlayer then
        self:setActionAnim(CharacterActionAnims.Bandage)
        if ISHealthPanel and ISHealthPanel.getBandageType then
            self:setAnimVariable("BandageType", ISHealthPanel.getBandageType(self.bodyPart))
        end
        self.character:reportEvent("EventBandage")
    else
        self:setActionAnim("Loot")
        self.character:SetVariable("LootPosition", "Mid")
        self.character:reportEvent("EventLootItem")
    end
    self:setOverrideHandModels(nil, nil)
    local snd = KFM_ProcedureAction.SOUND[self.procId]
    if snd then self.sound = self.character:playSound(snd) end
end

function KFM_ProcedureAction:stopSound()
    if self.sound and self.character:getEmitter():isPlaying(self.sound) then
        self.character:stopOrTriggerSound(self.sound)
    end
end

function KFM_ProcedureAction:stop()
    self:stopSound()
    self:setPanelAction(false)
    ISBaseTimedAction.stop(self)
end

function KFM_ProcedureAction:perform()
    self:stopSound()
    self:setPanelAction(false)
    ISBaseTimedAction.perform(self)
end

-- Feedback for the doctor (translation key): direct in SP, server command in MP.
function KFM_ProcedureAction:notify(key)
    if isServer() then
        sendServerCommand(self.character, Game.MODULE, "result", { key = key })
    elseif KFM.Client and KFM.Client.say then
        KFM.Client.say(self.character, key)
    end
end

local Effects = {}
KFM_ProcedureAction.Effects = Effects

function Effects.exam(self, cfg)
    local v = Game.collectVitals(self.otherPlayer)
    local report = Core.buildExamReport(v, self.effLevel, cfg, { tongue = self.item2 ~= nil })
    if self.item2 then Game.removeItem(self.character, self.item2) end
    if Game.hasSomethingToDiagnose(v) then
        Game.grantXp(self.character, self.otherPlayer, "exam", nil, Core.EXAM_XP_COOLDOWN_HOURS)
    end
    local payload = { patient = self.otherPlayer:getDisplayName(), self = (self.character == self.otherPlayer), lines = report }
    if isServer() then
        sendServerCommand(self.character, Game.MODULE, "exam", payload)
    elseif KFM.Client and KFM.Client.showExam then
        KFM.Client.showExam(payload)
    end
end

function Effects.irrigate(self, cfg)
    local kind = Game.waterKind(self.item)
    if not kind then return end
    local bp = self.bodyPart
    local level, infect = Core.irrigate(bp:getWoundInfectionLevel(), self.doctorLevel, cfg, kind == "dirty")
    bp:setWoundInfectionLevel(level)
    if infect then bp:setInfectedWound(true) end
    Game.useWater(self.item)
    Game.addPain(self.character, bp, Core.procedurePain("irrigate", self.doctorLevel, cfg, false))
    Game.sync(bp)
    if not infect then Game.grantXp(self.character, self.otherPlayer, "irrigate", Game.partName(bp)) end
    self:notify(infect and "IGUI_KFM_Result_IrrigateDirty" or "IGUI_KFM_Result_IrrigateOk")
end

function Effects.tourniquet(self, cfg)
    local bp = self.bodyPart
    local extra = (self.item:getFullType() == Game.ITEM_BELT) and Core.BELT_EXTRA_FAIL or 0
    local failed = Core.roll(Core.failChance("tourniquet", self.doctorLevel, cfg, extra), Game.rng)
    Game.addPain(self.character, bp, Core.procedurePain("tourniquet", self.doctorLevel, cfg, false))
    if failed then
        Game.sync(bp)
        self:notify("IGUI_KFM_Result_TourniquetFail")
        return
    end
    local wasBleeding = bp:getBleedingTime() > 0
    local fullType = self.item:getFullType()
    Game.removeItem(self.character, self.item)
    Game.applyTourniquet(self.otherPlayer, bp, fullType)
    Game.sync(bp)
    if wasBleeding then Game.grantXp(self.character, self.otherPlayer, "tourniquet", Game.partName(bp)) end
    Game.pushTq(self.otherPlayer, self.character)
    self:notify("IGUI_KFM_Result_TourniquetOk")
end

function Effects.tourniquetOff(self, cfg)
    local fullType = Game.removeTourniquet(self.otherPlayer, Game.partName(self.bodyPart))
    if fullType then Game.giveItem(self.character, fullType) end
    Game.pushTq(self.otherPlayer, self.character)
    self:notify("IGUI_KFM_Result_TourniquetRemoved")
end

local function procedureInfection(self, procId)
    local gloves, mask = Game.surgicalProtection(self.character)
    return Core.roll(Core.infectionChance(procId, gloves, mask), Game.rng)
end

function Effects.cauterize(self, cfg)
    local bp = self.bodyPart
    if self.item2 then self.item2:UseAndSync() end
    Game.hemophobia(self.character)
    local failed = Core.roll(Core.failChance("cauterize", self.doctorLevel, cfg), Game.rng)
    if failed then
        bp:setBleedingTime(bp:getBleedingTime() * 0.5)
    else
        bp:setDeepWounded(false)
        bp:setDeepWoundTime(0)
        bp:setBleedingTime(0)
        bp:setBleeding(false)
    end
    bp:setBurnTime(math.max(bp:getBurnTime(), Core.cauterizeBurnTime(Game.rng)))
    bp:setNeedBurnWash(true)
    if procedureInfection(self, "cauterize") then bp:setInfectedWound(true) end
    Game.addPain(self.character, bp, Core.procedurePain("cauterize", self.doctorLevel, cfg, Game.painkillers(self.otherPlayer)))
    Game.sync(bp)
    Game.grantXp(self.character, self.otherPlayer, "cauterize", Game.partName(bp))
    self:notify(failed and "IGUI_KFM_Result_CauterizeFail" or "IGUI_KFM_Result_CauterizeOk")
end

function Effects.reduceFracture(self, cfg)
    local bp = self.bodyPart
    local failed = Core.roll(Core.failChance("reduceFracture", self.doctorLevel, cfg), Game.rng)
    bp:setFractureTime(Core.reduceFracture(bp:getFractureTime(), self.doctorLevel, cfg, failed))
    if not failed then Game.md(self.otherPlayer).reduced[Game.partName(bp)] = true end
    Game.addPain(self.character, bp, Core.procedurePain("reduceFracture", self.doctorLevel, cfg, Game.painkillers(self.otherPlayer)))
    Game.sync(bp)
    Game.grantXp(self.character, self.otherPlayer, "reduceFracture", Game.partName(bp))
    self:notify(failed and "IGUI_KFM_Result_ReduceFail" or "IGUI_KFM_Result_ReduceOk")
end

function Effects.debride(self, cfg)
    local bp = self.bodyPart
    Game.hemophobia(self.character)
    local failed = Core.roll(Core.failChance("debride", self.doctorLevel, cfg), Game.rng)
    local level, stillInfected = Core.debrideResult(bp:getWoundInfectionLevel(), failed)
    if not stillInfected and procedureInfection(self, "debride") then
        level, stillInfected = 1, true
    end
    bp:setWoundInfectionLevel(level)
    bp:setInfectedWound(stillInfected)
    bp:setBleedingTime(math.max(bp:getBleedingTime(), Core.debrideBleedTime(Game.rng)))
    bp:setBleeding(true)
    Game.addPain(self.character, bp, Core.procedurePain("debride", self.doctorLevel, cfg, Game.painkillers(self.otherPlayer)))
    Game.sync(bp)
    Game.grantXp(self.character, self.otherPlayer, "debride", Game.partName(bp))
    self:notify(failed and "IGUI_KFM_Result_DebrideFail" or "IGUI_KFM_Result_DebrideOk")
end

function KFM_ProcedureAction:complete()
    local cfg = Game.cfg()
    if not cfg.Enabled or (self.procId == "exam" and not cfg.ExamEnabled) then return true end
    if not self:isValid() then return true end
    local level = Game.effectiveLevel(self.character, self.procId, 0)
    if self.procId ~= "exam" and not Core.canPerform(self.procId, level, cfg, Game.hasHelper(self.character, self.otherPlayer)) then
        return true
    end
    local fn = Effects[self.procId]
    if fn then fn(self, cfg) end
    return true
end

function KFM_ProcedureAction:getDuration()
    if self.character:isTimedActionInstant() then return 1 end
    local extra = 0
    if self.procId == "cauterize" and not self.noHeat then extra = Core.EXTRA_HEAT_TICKS end
    return Core.duration(self.procId, self.doctorLevel, extra)
end

function KFM_ProcedureAction:new(character, otherPlayer, bodyPart, procId, item, item2)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.doctor = character
    o.otherPlayer = otherPlayer
    o.bodyPart = bodyPart
    o.procId = procId
    o.item = item
    o.item2 = item2
    o.doctorLevel = Game.doctorLevel(character)
    local extra = (procId == "exam" and item ~= nil) and 1 or 0
    o.effLevel, o.noHeat = Game.effectiveLevel(character, procId, extra)
    o.stopOnWalk = bodyPart:getIndex() > BodyPartType.ToIndex(BodyPartType.Groin)
    o.stopOnRun = true
    o.patientX = otherPlayer:getX()
    o.patientY = otherPlayer:getY()
    o.maxTime = o:getDuration()
    return o
end
