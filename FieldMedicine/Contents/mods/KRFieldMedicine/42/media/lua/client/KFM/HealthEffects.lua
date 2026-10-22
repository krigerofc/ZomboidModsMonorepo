-- Personal perceptions only: no doors, lights, zombie world noise, or remote players are mutated.
require "ISUI/ISPanel"
local Game=require "KFM/Game"
local P=require "KFM/Symptoms"
local E={active={}}
KFM.ClientEffects=E
local Overlay=ISPanel:derive("KFM_SymptomOverlay")
function Overlay:prerender()
 local entry=self.entry
 local now=getTimestampMs()
 if entry.kind=="faint"then self:drawRect(0,0,self.width,self.height,0.95,0,0,0)
 elseif entry.kind=="flicker"then
  local alpha=math.floor(now/120)%2==0 and 0.32 or 0.06
  self:drawRect(0,0,self.width,self.height,alpha,0,0,0)
 elseif entry.kind=="blur"then
  -- Owned translucent haze/vignette, rather than altering global camera/postprocessing settings.
  local strength=entry.strength or 0.2
  self:drawRect(0,0,self.width,self.height,strength*0.35,0.55,0.6,0.58)
  local edge=math.max(10,self.width*strength*0.2)
  self:drawRect(0,0,edge,self.height,strength,0.15,0.18,0.16)
  self:drawRect(self.width-edge,0,edge,self.height,strength,0.15,0.18,0.16)
 end
end
function Overlay:onMouseDown()return false end
function Overlay:onMouseUp()return false end
local SOUNDS={knock="WoodShackDoorCreak",door="WoodShackDoorOpen",flicker="LightFlicker"}
function E.localActor(id)
 for i=0,getNumActivePlayers()-1 do local p=getSpecificPlayer(i);if p and p:getOnlineID()==id then return p end end
 return nil
end
function E.clear(id)
 local entry=E.active[tostring(id)]
 if not entry then return end
 if entry.panel then entry.panel:removeFromUIManager()end
 if entry.ownedBlock and entry.player:isBlockMovement()then entry.player:setBlockMovement(false)end
 E.active[tostring(id)]=nil
end
function E.receive(args)
 if type(args)~="table"or not P.KNOWN[args.kind]or args.kind=="cough"then return false end
 local player=E.localActor(args.id)
 if not player then return false end
 local cfg=Game.cfg()
 if not cfg.Enabled or not cfg.IllnessEnabled then E.clear(args.id);return false end
 if P.PSYCH[args.kind]and(not cfg.PsychologicalConditionsEnabled or not cfg.PsychologicalEffectsEnabled)then
  local current=E.active[tostring(args.id)]
  if current and current.psych then E.clear(args.id)end
  return false
 end
 if args.kind=="blur"and not cfg.SymptomEffectsEnabled then return false end
 if args.kind=="faint"and not cfg.FaintingEnabled then return false end
 local md=player:getModData();local seq=tonumber(args.seq)
 if not seq or seq<=(md.KFM_effectSeq or 0)then return false end
 md.KFM_effectSeq=seq
 local current=E.active[tostring(args.id)]
 local priority={faint=3,blur=2,door=1,knock=1,flicker=1}
 if current and args.kind~="clear" and getTimestampMs()<current.untilMs and (priority[current.kind]or 0)>(priority[args.kind]or 0)then return true end
 E.clear(args.id)
 if args.kind=="clear"then return true end
 local duration=P.DURATION[args.kind]
 if not duration or player:isDead()then return false end
 local entry={player=player,kind=args.kind,strength=math.max(0,math.min(0.35,tonumber(args.strength)or 0.2)),untilMs=getTimestampMs()+duration,psych=P.PSYCH[args.kind]==true}
 if args.kind=="faint"then
  if player:getVehicle()then return false end
  if ISTimedActionQueue then ISTimedActionQueue.clear(player)end
  player:nullifyAiming()
  player:reportEvent("EventSitOnGround")
  if not player:isBlockMovement()then player:setBlockMovement(true);entry.ownedBlock=true end
 end
 local slot=player:getPlayerNum()
 local panel=Overlay:new(getPlayerScreenLeft(slot),getPlayerScreenTop(slot),getPlayerScreenWidth(slot),getPlayerScreenHeight(slot))
 panel:initialise();panel.background=false;panel.entry=entry;panel:addToUIManager();entry.panel=panel
 E.active[tostring(args.id)]=entry
 if SOUNDS[args.kind]then getSoundManager():playUISound(SOUNDS[args.kind])end
 return true
end
function E.update()
 local cfg=Game.cfg();local now=getTimestampMs()
 for id,entry in pairs(E.active)do
  if entry.player:isDead()or not cfg.Enabled or not cfg.IllnessEnabled or now>=entry.untilMs
   or(entry.psych and(not cfg.PsychologicalEffectsEnabled or not cfg.PsychologicalConditionsEnabled))
   or(entry.kind=="blur"and not cfg.SymptomEffectsEnabled)or(entry.kind=="faint"and not cfg.FaintingEnabled)then E.clear(id)end
 end
end
Events.OnTick.Add(E.update)
return E
