# Zombie Disguise 2.1.0 — delivery and verification

Native selective camouflage is implemented and installed with the B42 Lua mod. Requires KRFieldMedicine and the matching native companion on the server and every client. Supported engine: installed 42.19.2 with eleven exact class hashes; other builds keep camouflage unavailable. No game JAR replacement, player role/capability changes, ghost mode or Steam upload.

## Behavior

- Server validates corpse identity, reach, movement and native timed-action completion. Blood exposure is registered with FieldMedicine before granting protection; failed registration rolls back the grant.
- Short native leases filter zombie spotting, targeting, remembered paths, attack and bite/grapple routes for the wearer. Other player targets and sound/location navigation retain normal behavior. Running, attacking, death, expiry, disable and lost client readiness revoke protection.
- Matching cached paths and late pathfinding callbacks are discarded. A new legitimate navigation goal can restart. Native leases use weak character object identity, world-time bounds and monotonic expiry.
- Lua replication broadcasts to all clients and rejects stale revisions, foreign epochs and reused actor identities. Missing native support on a peer disables/revokes camouflage. These network contracts have offline tests; connected-client acceptance remains pending.

## Executed evidence

| Check | Result and scope |
|---|---|
| Native Java tests | 65 assertions passed; transformer/lease contracts, supported bytecode identities, unknown hashes, idempotence and hosted-server argument propagation |
| JVM class verification | Supported installed classes passed -Xverify:all; separate altered-class fixture remained unavailable and continued without instrumentation |
| Isolated dedicated engine fixture, run 05 | 104 checks, zero failures; actual ordinary-role IsoPlayer/IsoZombie objects, spotting/attack, cached and late paths, expiry and production Lua grant/revoke with actual FieldMedicine exposure registration |
| Disguise Lua | Syntax, translation generation and Fengari contracts passed |
| FieldMedicine Lua | 31 Lua files, 16 JSON files, 300 matching EN/PTBR keys, nine suites passed |
| Installer | Six tests passed: reversible launch settings, preserving later options, quoted agent paths/options, conservative handling of unknown leftover references |
| Installed payload | 18 mod source files match repository source; installed JAR matches final SHA256 |
| Single-player client run 02 | Reached native bridge readiness, fixture load and main menu; exited without completed acceptance. This is not a gameplay pass. |

The 104-check engine fixture used constructed native actors on a disposable dedicated server. It did not connect two network clients, complete the corpse action through the player's UI or prove zombie ownership handoff. Earlier failed fixture runs remain historical; run 04 failed because its test helper had not exposed Path to Lua, then run 05 corrected the helper and passed. Logs include vanilla engine warnings and a test-environment warning; no clean-log claim is made.

An independent review found cached-path and installer issues which were corrected. The native path correction was rereviewed. The final installer tokenization correction passed regression tests but its follow-up independent review could not run because the agent usage limit was reached.

## Installation and rollback

Local mod: C:/Users/pedro/Zomboid/mods/ZombieDisguise

Installed companion: C:/Users/pedro/Zomboid/mods/ZombieDisguise/native/zd-native-agent.jar

SHA256: c3cb2becd3309c89020771aef53cf076dcfe8012869b781996380b7421e22a14

Launcher backup/rollback manifest: outputs/native-disguise-install-20261022-01/launcher-backup/manifest.json in the chat workspace. The full installation record is installed.json in the parent folder; the previous mod is preserved in mod-before-native/. Five launcher configuration/batch files received the companion JVM argument, preserving existing options. No existing save or Workshop source was changed.

See ZombieDisguise/INSTALL-NATIVE.md for install/uninstall commands. Test-only path exposure and loading-continuation helpers are excluded from the distribution and local production installation.

## Remaining acceptance

Full single-player corpse-action gameplay, two ordinary connected clients, reconnect and zombie ownership migration remain unverified. Native support for 42.21 or any changed class build requires a new inspected and tested adapter. This is a test build, not a claim of 100% multiplayer certification.

The user subsequently requested development without opening the game. No more game/client/server launches are authorized for this continuation; finish with offline code checks and leave in-game acceptance for the user. The prior isolated client process was already absent when checked.
