# Vehicle workshop implementation — 2026-10-22

Scope: BasicVehicleMaintenance / MoreVehiclesRepairs only. Workshop ID 3643006111 and mod IDs are preserved. No game installation, save, server profile, Steam item or shared VehicleScript was changed by this implementation.

## Delivered

- Emergency patches add one patch penalty; durable repairs preserve history; professional overhauls remove one penalty. History-only overhauls are allowed above the repair ceiling when a penalty remains: successful work preserves the existing condition and pays the normal materials/time. Destroyed windows require replacement.
- Generic item families select repair rules even when a mod renames a part or uses an unknown vehicle model. Cargo upgrades accept physical NormalTrunk/BigTrunk/SmallTrunk/TrailerTrunk items; glove boxes and the intrinsic Engine have their own bounded policies. Fuel, tire air, animal trailers and animal food/egg containers are excluded from cargo upgrades.
- Cargo tiers add 10%/20% of the original item capacity, capped at +40. Glove-box tiers add 25%/50%, capped at +5. Engine power adds 5%/10% of the original per-instance power. Integer engine APIs require rounded capacity/power values. Removing an upgrade restores the saved original value; no resource refund is promised.
- Tier I requires Mechanics 3. Tier II requires Mechanics 6 and a sheltered vehicle. Removal requires Mechanics 2 and one screw before the material-cost multiplier. Both upgrade tiers need a wrench and screwdriver, screws, scrap and sheet metal. Time and material sandbox multipliers apply. This deterministic work grants no XP.
- Painting offers ten colors backed by native Paint<Color> items, a paintbrush and four paint uses before the material multiplier. Mechanics 1. Native isDoColor=false disables painting with a localized explanation.
- Rust removal consumes scrap and cloth, requires a screwdriver and Mechanics 2, and removes at most 0.2 rust per application. Paint and rust never repair body condition or provide protection.
- Washing delegates directly to ISVehicleMenu.onWash, retaining the game's normal water consumption and chained washing action.
- The mechanics menu preserves the original callback/menu chain. Every operation has EN/PTBR status, cost, skill, tool and time feedback. Separate server sandbox switches enable upgrades and appearance work.

## Authority and lifecycle

MVR_WorkshopAction is shared and uses constructor-named fields: character, part, operation, choice, expectedItemId, expectedRevision. The native B42 examples examined were ISInstallVehiclePart:new(character,part,item,maxTimeInit) and ISWashVehicle:new(character,vehicle,id,area). Server reconstruction tests rebuild the action with the original scalar intention and identity fields.

The applying simulation checks the actor, same floor, native work area, distance, stopped vehicle, engine off, native key/door/window access, installed physical item, server settings, revision and current resources. Client authoring is rejected. A per-vehicle revision invalidates an overlapping stale action before consumption. Material plans are rebuilt at completion. No cheat command is used as production authority.

Key checks mirror vanilla access semantics while omitting its client-only ISVehicleMechanics.cheat dependency. Fractional vehicle physics height on the same floor is permitted; another floor is rejected.

Removable capacity upgrades live in the physical inventory item's MVRUpgrade record (version 1); part MVR.upgrade is a replicated mirror. Replacing a part does not inherit the former item's upgrade. The intrinsic engine keeps its record in its own per-vehicle Engine part mod data. Repair history preserves these separate fields.

Native doInventoryItemStats reads the upgraded item maxCapacity, preserving native container damage rules. Native install and engine-repair completion wrappers preserve their original callbacks, then reapply upgrades. A server scan of loaded vehicles runs every 60 ticks and sends packets only when a value or mirror actually changes. Non-baseline, non-owned changes to item or container capacity/power suspend further modification with a conflict reason.

Vanilla TrailerTrunk.setCondition hard-codes max(80,condition), even after doInventoryItemStats. The ordinary generic TrailerTrunk exception reapplies the bounded original-capacity bonus after that native reset. Clients reconstruct only this local capacity cache from the item/record published by the server, every 60 ticks; that replica path never creates records, consumes resources, changes item capacity or transmits. The native damaged trailer floor is retained. Animal food/egg systems reusing the same physical item remain excluded.

Disabling upgrades restores baseline power/capacity when contents fit. Overloaded cargo keeps its existing capacity until sufficient cargo is removed. Re-enabling uses the same original baseline. No inventory contents are discarded.

## Installed-source evidence

Read-only inspection of E:/SteamLibrary/steamapps/common/ProjectZomboid/media and projectzomboid.jar:

- Vehicles/VehicleCommands.lua: setColorHSV + transmitColorHSV; setRust + transmitRust.
- Vehicles/ISUI/ISVehicleMenu.lua: onWash delegates to pathfinding and ISWashVehicle using native selected area and water rules.
- shared/Vehicles/TimedActions/ISInstallVehiclePart.lua and ISRepairEngine.lua: native authoritative complete() patterns.
- server/Vehicles/Vehicles.lua: mechanic key/access checks and item max-capacity initialization.
- generated/vehicles/template_trunk.txt: ordinary TrailerTrunk, animal food/egg reuse, condition rules.
- generated/items/drainable.txt: Paint<Color> is drainable, UseDelta=0.1; Paintbrush exists in normal.txt.
- VehiclePart.doInventoryItemStats: capacity reads InventoryItem.maxCapacity and optional getNumberByCondition(base,condition,5).
- VehiclePart.setCondition: synchronizes the installed item condition; ordinary TrailerTrunk then overwrites capacity with max(80,condition).
- InventoryItem.save/load: maxCapacity is serialized; VehiclePart.save/load serializes item/container/mod data.
- BaseVehicle.save/load: HSV, rust and engine power/quality/loudness persist per instance.
- BaseVehicle.setEngineFeature: loudness argument is divided by 2.7 then cast to an integer. The adapter supplies ceil(currentLoudness*2.7+0.5), preserving the current integer noise rather than repeatedly shrinking it. Unchanged power skips the setter. A 100-reapply regression preserves quality/noise.
- network/fields/vehicle/VehicleEngine: native packet reads/writes engine quality, loudness and power.

Full native disassembly evidence: outputs/reestruturacao-mods-2026-10-21/vehicles-native-bytecode.log outside this mod. tools/inspect-native.py is a development-only stdlib class-file inspection helper.

## Rulings and limits

1. Top-speed upgrades are NOT delivered. The inspected createPhysics path restores maxSpeed from the shared script, and the examined save/load does not persist it. A proven restoration/replication path is required before shipping this operation.
2. Occupied downgrade checks use a conservative native damage calculation for generic containers whose exposed API does not identify conditionAffectsCapacity. A damaged non-trailer container that ignores damage may require extra unloading before removal. Ordinary TrailerTrunk uses its proven native rule. This conservatism avoids item loss.
3. Conflicts that produce a new foreign raw capacity, foreign effective capacity or foreign engine power are refused rather than multiplied or overwritten. A reconstruction to the known original baseline can be reapplied. Bespoke vehicle systems/adapters remain outside scope.
4. Painting is limited to native color-enabled models; no custom texture adapter is provided.
5. Native source/packet inspection and mocked reconstruction tests are not live gameplay or multiplayer certification.

## Verification

RED → GREEN observed for: absent production workshop; client discovery; fractional same-floor work; authoritative lifecycle scan; history-only overhaul; destroyed glass; native repair access; complete locked previews; dedicated access without client UI; foreign capacity ownership; false key lookup; renamed generic repair family; ordinary trailer and special-container distinction.

Full offline suite covers Lua 5.1 parsing, layout/IDs/assets, generated translations and sandbox parity, 858 pure repair checks, game adapter/menu/action tests, and pure upgrade policy checks. The exact final npm test output is retained in outputs/reestruturacao-mods-2026-10-21/vehicles-workshop-green.log.

Actual target-build SP, hosted two-client MP, dedicated two-client MP, reconnect/restart and a real third-party generic-parts vehicle are pending. See MANUAL_TEST.md. No claim of actual multiplayer validation is made here.
