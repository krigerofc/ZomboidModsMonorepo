# Zombie Disguise 2.1.1

**2026-10-23: native startup integration withdrawn.** The user reported that Project Zomboid stopped opening after installation. The five launch files have been restored byte-for-byte from the pre-installation backups, and the installed agent JAR removed. The exact launch failure has not been captured; native fixtures and offline tests did not validate the normal executable launcher. Do not install or publish the native companion as ready until the startup failure is diagnosed and real launcher acceptance passes. No game was launched for this rollback; restoration is verified, successful opening still needs user confirmation. The Lua mods and existing saves were preserved. Disguise camouflage is unavailable while the companion is disabled.

B42 only; KRFieldMedicine is optional. The existing perception backend needs a native companion, whose startup integration is currently withdrawn. The previous hard-disabled Lua foundation is superseded by the native bridge implementation. Existing mod ID ZombieDisguise and game-style artwork are retained.

Native support is pinned to the installed 42.19.2 class hashes. The companion transforms eleven classes in memory, with no game JAR replacement or administrative/ghost/invisibility flags. Public character bridge methods manage finite, weak-object-identity leases. Unknown or partially unsupported builds leave camouflage unavailable.

Production Lua validates the corpse timed action on the server, registers regional medical exposure and rolls back rejected grants. Versioned snapshots refresh short leases across peers; stale/foreign snapshots, disconnected peers, running/attacking, expiry and death revoke protection. Washing reconciles residual medical exposure independently of native availability. Active native protection is never restored from persisted modData after a process restart.

Real native fixtures passed spotting, existing pursuit/cache cancellation, late path callbacks, attacks, expiry and production Lua health registration/revocation. Offline Lua tests cover action and packet contracts. Full UI corpse-action completion and two connected ordinary clients are still pending; no multiplayer gameplay certification is claimed.

See [delivery evidence](../docs/NATIVE-DISGUISE-2026-10-22.md), [native implementation](native/README.md) and [reversible installation](INSTALL-NATIVE.md). The user requested no further game launches; continue code-only verification.

## Independence update — 2026-10-23

Zombie Disguise 2.1.1 no longer requires KRFieldMedicine. It loads without importing medical files; server player enumeration is local and client leases do not depend on medical settings. When a compatible FieldMedicine Exposure API v1 is present and enabled, medical registration, rejected-grant rollback and washing cleanup remain integrated. Disabled or absent medicine does not block the backend. Standalone mode adds no replacement disease simulation.

The native startup integration remains withdrawn. The user confirmed the game opens after rollback. This change removes the medical dependency only; it does not deliver an extension-free perception backend or restore camouflage. No game, server or client was launched and no native extension or launcher changes were installed. Offline standalone and medical integration specs passed; connected gameplay is unverified.
