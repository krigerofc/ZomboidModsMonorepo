# Zombie Disguise Lua delivery —23 October2026

The user approved temporary built-in invisibility on 23 October2026. This replaces the withdrawn native integration. No extension, launcher change or FieldMedicine dependency is installed. The user confirmed the game opened after the earlier rollback.

## Behaviour

A completed, server-validated zombie-corpse timed action grants bounded camouflage. Running or attacking (sandbox controlled), washing below the required blood coverage, expiry, death, disconnect and saving cancel the effect. The authoritative server rejects actors already invisible; only a validated server lease may adopt vanilla-replicated invisibility on a client. Identity, session, epoch, protocol2, revision and serial checks prevent stale grants. Heartbeats refresh once per second and expire after five real seconds; a newer valid heartbeat can recover a temporary timeout without reviving a genuinely revoked serial.

The public setInvisible(value,true) call is verified by reading isInvisible back. This mode also changes human-player visibility and may change sound reactions. It is not selective zombie perception. Independent client-only mods writing the same flag, or another system changing that flag during a lease, cannot be reliably distinguished. Avoid combining such systems until tested.

Ownership markers allow cleanup after reconnect; saved data never authorizes restoring camouflage. Saving deliberately ends the temporary effect. Rejected application rolls back medical exposure and blood visuals. Cleanup retries if the public setter refuses to clear owned invisibility.

FieldMedicine remains optional. When its enabled Exposure API v1 is present, blood exposure and washing are integrated; standalone mode adds no disease simulation.

## Confirmed engine limitation

Read-only inspection of installed42.19.2 bytecode shows both setInvisible overloads eventually call PlayerCheats.set. Its permission gate allows debug, GameClient or GameServer contexts. Ordinary non-debug single-player is therefore unsupported and the mod refuses before smearing blood. No roles, Core.debug changes, hidden cheat storage, native agents or game-class patches are used. Debug single-player and multiplayer are implementation targets, not gameplay-certified modes.

ConnectedPacket and ExtraInfoPacket can replicate the vanilla invisible flag before the custom lease. Client adoption is restricted to an already validated server lease; ordinary server grants never adopt an existing flag.

## Verification

Three offline Lua suites pass: visibility adapter, standalone loading and authoritative action/packet integration. These use Fengari and simulated engine objects. They cover setter refusal/errors, ownership, lease bounds, timeout recovery, pre-replicated flags, action proof, rollback, optional medicine and stale identity/packet rejection. They do not establish actual zombie behaviour, human visibility, UI action execution, saving or connected multiplayer correctness.

No game, server or client was launched for2.2.0. The withdrawn native sources/install tools remain historical development material outside Contents. Do not run the archived installer. See ../ZombieDisguise/MANUAL_TEST.md and ../ZombieDisguise/IMPLEMENTATION_NOTES.md.
