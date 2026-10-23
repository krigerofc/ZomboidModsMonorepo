# Native zombie camouflage - approved direction

User22October2026 explicitly approved an additional native extension installed in game and multiplayer server/clients, after requesting a fully functional disguise. This supersedes the earlier Lua-only backend constraint. Keep current isolated clone and branch; no Steam publication, no changes to existing saves.

Deliver selective native zombie perception and attack filtering for a server-authorized temporary blood disguise. Ordinary players retain human visibility, collision, thirst, damage from other causes, and roles/capabilities. No ghost/invisible/god state, global zombie freeze or installed-jar overwrite.

Architecture: version-pinned Java instrumentation agent distributed with source and reversible launcher integration, plus the existing Lua action/health adapter. Instrument installed42.19.2 classes in memory only; strict SHA256 compatibility gate and clear startup error for unknown builds. No claims of42.21 support until verified.

Bridge interface added as public instance methods on IsoGameCharacter, exposed naturally to Lua: getZombieDisguiseBridgeVersion():int; setZombieDisguiseLease(double gameExpiryHours,double leaseSeconds):boolean; clearZombieDisguiseLease():void. Version1. Native lease identity uses the actual character object (weak keys), bounded real-time lease<=15seconds, finite future world expiry<=8hours. Game-hour expiry and monotonic TTL both enforced. Native effects never persist in saves.

Lua authority grants only after completed validated corpse action and successful health registration. Server broadcasts versioned epoch/revision leases to all clients, not merely wearer: the client simulating a zombie may be another player. Refresh1second real time, active leaseTTL5seconds; version/epoch/identity/revision/finite expiry validation, server-only grant, full resync/revocation, clear local lease cache on reset/disconnect/death/disable. SP uses the same native adapter without packets.

Fresh and repeated acquisition, explicit target assignment, aggro/path restoration and already-running attacks must not select a disguised character. Selectively forget only disguised targets and matching memory, preserving other player aggro, sound/location goals and wandering. Expiry/run/attack/washing/health-disable removes native disguise promptly; residual blood exposure remains until actual washing.

Acceptance: RED/GREEN Lua contracts; native transformer tests for known hash/unknown hash, idempotence, identity/TTL/NaN, other targets and no protected-state use; actual installed-engine ordinary-player tests before availability enabled. Test both already-tracking and newly spotted targets, attack prevention, expiry and other-player targeting. Installation backups/hash manifest/uninstall plus verified startup flags; source and logs accompany deliverable. Native UI/MP tests must be reported separately from mock/bytecode proof.
