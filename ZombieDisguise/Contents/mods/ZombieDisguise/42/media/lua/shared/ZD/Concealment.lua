-- Public built-in invisibility, explicitly approved by the user. No roles or external agent.
local C=require "ZD/Core"
local B={VERSION=1,TTL_MS=5000,owned={}}
local function finite(v)return type(v)=="number"and v==v and v~=math.huge and v~=-math.huge end
local function now()return getGameTime():getWorldAgeHours()end
local function millis()return getTimestampMs()end
local function invisible(player)
 local ok,value=pcall(function()return player:isInvisible()end)
 return ok and type(value)=="boolean",value
end
function B.available(player)
 local ok,methods=pcall(function()return player~=nil and player.setInvisible~=nil and player.isInvisible~=nil end)
 if not ok or not methods then return false end
 -- Installed42.19.2 PlayerCheats.set refuses ordinary SP, including the forced overload.
 if not isClient()and not isServer()then
  local allowed,value=pcall(function()return getDebug()end)
  if not allowed or value~=true then return false end
 end
 local readable=invisible(player)
 return readable
end
function B.clear(player)
 if not player then return true end
 local md=player:getModData()
 local marker=md.ZD_invisibility
 local own=B.owned[player]
 if not own and not(type(marker)=="table"and marker.version==1 and marker.owned==true)then return true end
 local ok,value=invisible(player)
 if ok and value then
  local changed=pcall(function()player:setInvisible(false,true)end)
  ok,value=invisible(player)
  if not changed or not ok or value then
   own=own or {};B.owned[player]=own
   if not own.warned then print("[ZD] Could not clear mod-owned invisibility; cleanup will retry.");own.warned=true end
   return false
  end
 elseif not ok then return false end
 B.owned[player]=nil;md.ZD_invisibility=nil
 return true
end
function B.apply(player,expires,authorisedReplica)
 local time=now();local wall=millis()
 if not B.available(player)or not finite(expires)or expires<=time or expires>time+8 then return false end
 local _,current=invisible(player)
 local own=B.owned[player]
 if own then
  if not current then B.owned[player]=nil;player:getModData().ZD_invisibility=nil;return false end
 else
  -- Only a validated server lease may adopt vanilla replication on a client.
  -- The authoritative server always rejects an already invisible actor.
  if current and not(authorisedReplica==true and isClient())then return false end
  own={started=time};B.owned[player]=own
  player:getModData().ZD_invisibility={version=1,owned=true}
  local changed=true
  if not current then changed=pcall(function()player:setInvisible(true,true)end)end
  local readable,enabled=invisible(player)
  if not changed or not readable or enabled~=true then B.clear(player);return false end
 end
 own.expires=expires;own.wall=wall
 return true
end
function B.active(player)
 local own=B.owned[player]
 local ok,value=invisible(player)
 return own~=nil and ok and value==true
end
function B.tick()
 local cfg=C.config(SandboxVars and SandboxVars.ZombieDisguise)
 local time,wall=now(),millis()
 for player,own in pairs(B.owned)do
  local invalid=not cfg.Enabled or player:isDead()or not finite(own.expires)or time>=own.expires
   or not finite(own.wall)or wall<own.wall or wall-own.wall>=B.TTL_MS or (own.started and time<own.started)
   or(cfg.BreakOnRun and(player:isRunning()or player:isSprinting()))or(cfg.BreakOnAttack and player:isAttacking())
  if invalid then B.clear(player)end
 end
end
function B.reset()
 local players={};for player in pairs(B.owned)do players[#players+1]=player end
 for _,player in ipairs(players)do B.clear(player)end
end
Events.OnTick.Add(B.tick)
Events.OnDisconnect.Add(B.reset)
Events.OnGameStart.Add(B.reset)
Events.OnSave.Add(B.reset)
return B
