# Zombie Disguise 2.1.0

B42 only; requires KRFieldMedicine and the native camouflage companion on every client and server. The previous hard-disabled Lua foundation is superseded by the native bridge implementation. Existing mod ID ZombieDisguise and game-style artwork are retained.

Native support is pinned to the installed 42.19.2 class hashes. The companion transforms eleven classes in memory, with no game JAR replacement or administrative/ghost/invisibility flags. Public character bridge methods manage finite, weak-object-identity leases. Unknown or partially unsupported builds leave camouflage unavailable.

Production Lua validates the corpse timed action on the server, registers regional medical exposure and rolls back rejected grants. Versioned snapshots refresh short leases across peers; stale/foreign snapshots, disconnected peers, running/attacking, expiry, death and disabled health revoke protection. Washing reconciles residual medical exposure independently of native availability. Active native protection is never restored from persisted modData after a process restart.

Real native fixtures passed spotting, existing pursuit/cache cancellation, late path callbacks, attacks, expiry and production Lua health registration/revocation. Offline Lua tests cover action and packet contracts. Full UI corpse-action completion and two connected ordinary clients are still pending; no multiplayer gameplay certification is claimed.

See [delivery evidence](../docs/NATIVE-DISGUISE-2026-10-22.md), [native implementation](native/README.md) and [reversible installation](INSTALL-NATIVE.md). The user requested no further game launches; continue code-only verification.
