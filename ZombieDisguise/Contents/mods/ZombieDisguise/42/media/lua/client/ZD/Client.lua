local G=require "ZD/Game"
require "TimedActions/ZDDisguiseAction"
local Client={}
ZD.Client=Client
G.mirror=G.mirror or {}
function Client.localActor(id)
 for i=0,getNumActivePlayers()-1 do local p=getSpecificPlayer(i);if p and p:getOnlineID()==id then return p end end
 return nil
end
function Client.findCorpse(objects)
 local function match(obj)
  if obj and instanceof(obj,"IsoDeadBody") and obj:isZombie() then return obj end
  return nil
 end
 if type(objects)=="table" then
  for _,obj in pairs(objects) do local body=match(obj);if body then return body end end
 elseif objects and objects.size then
  for i=0,objects:size()-1 do local body=match(objects:get(i));if body then return body end end
 end
 local fetch=ISWorldObjectContextMenu and ISWorldObjectContextMenu.fetchVars
 return fetch and match(fetch.body) or nil
end
function Client.onServerCommand(module,command,args)
 if module~="ZombieDisguise" or command~="state" or not args or not Client.localActor(args.id) then return end
 G.mirror[tostring(args.id)]={version=2,active=args.active==true,expires=args.expires,coverage=args.coverage or 0}
end
function Client.onMenu(playerNum,context,objects,test)
 if test then return end
 local player=getSpecificPlayer(playerNum)
 if not player then return end
 local body=Client.findCorpse(objects);local state=G.view(player)
 if not body and not state.active then return end
 local name=state.active and getText("ContextMenu_ZD_Status",tostring(math.max(0,math.ceil(((state.expires or G.now())-G.now())*60)))) or getText("ContextMenu_ZD_Apply")
 local opt=context:addOption(name,player,function()
  if body then ISTimedActionQueue.add(ZDDisguiseAction:new(player,body)) end
 end)
 local reason="Tooltip_ZD_Risk"
 opt.notAvailable=state.active or not G.available() or not G.cfg().Enabled or not body or not G.valid(player,body)
 if not G.available() then reason=G.unavailableReason()
 elseif state.active then reason="Tooltip_ZD_Active"
 elseif not body or not G.valid(player,body) then reason="Tooltip_ZD_Reach" end
 if ISWorldObjectContextMenu and ISWorldObjectContextMenu.addToolTip then opt.toolTip=ISWorldObjectContextMenu.addToolTip()
 elseif ISToolTip then opt.toolTip=ISToolTip:new();opt.toolTip:initialise() end
 if opt.toolTip then opt.toolTip.description=getText(reason) end
end
function Client.onCreatePlayer(_,player)
 if not player then return end
 if isClient() then sendClientCommand(player,"ZombieDisguise","sync",{})
 elseif ZD.Server then ZD.Server.reconcile(player) end
end
Events.OnServerCommand.Add(Client.onServerCommand)
Events.OnFillWorldObjectContextMenu.Add(Client.onMenu)
Events.OnCreatePlayer.Add(Client.onCreatePlayer)
return Client
