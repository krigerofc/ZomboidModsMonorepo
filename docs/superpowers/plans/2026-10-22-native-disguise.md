# Native Zombie Disguise Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans. Follow RED/GREEN and independent review.

**Goal:** Provide selective blood camouflage for ordinary players through a reversible native companion and authoritative Lua lifecycle.

**Architecture:** Java instrumentation modifies supported engine classes in memory; added public bridge methods provide finite object-identity leases. Lua validates actions/health and sends bounded grants to every zombie simulation owner.

**Tech Stack:** Lua5.1/Kahlua; Node/Fengari; Java instrumentation/ASM; pinned official compiler tooling if required.

**Spec:** ../specs/2026-10-22-native-disguise-design.md

## Global Constraints
- Installed42.19.2 source hash pin; unknown builds fail closed. No gamejar replacement, roles/capabilities, ghost/god/invisibility or Steam publication.
- Work in existing isolated clone; preserve other mods and existing saves. Root owns install/integration; no simultaneous same-file editing.
- Exact bridge methods: getZombieDisguiseBridgeVersion():int; setZombieDisguiseLease(double,double):boolean; clearZombieDisguiseLease():void.

## Review Focus
- Zombie ownership migration and other player targets must survive selective forgetting.
- Active action cancellation/health failure cannot leave blood, protection or renewed duration.
- Stale/replayed/foreign-epoch packets and reused IDs cannot reactivate protection.
- Unsupported hash/partial instrumentation or missing clients cannot silently claim functional camouflage.
- Reconnect/offline/reset/disable must remove only native effects owned by this mod.

### Task1: Native agent and tests (owner native_disguise_bridge)
Files: ZombieDisguise/native/src, native/tests, native/tools, native/build outputs only. No Lua/install edits.
- [x] Inspect all acquisition/memory/attack routes and exact supported class identities.
- [x] Write failing transformer/lease tests and run RED.
- [x] Implement strict version gate, three injected bridge methods, finite leases and selective perception/attack hooks.
- [x] Build/test with pinned official dependencies; prove Java verification, unknown build rejection and no protected flags; report exact limits.

### Task2: Lua bridge and replication (owner disguise_native_lua)
Files: existing ZombieDisguise Lua, tests, i18n, metadata only; no native files/install.
- [x] Write RED contracts for missing bridge, successful native lease, registration rollback, expiry/revoke and stale/foreign packets.
- [x] Replace old protected-flag mutations with bridge calls; preserve medical exposure and corpse action checks.
- [x] Broadcast epoch/revision complete leases to all clients, monotonic refresh/resync and cleanup.
- [x] Run full disguise and dependent health suites; return proof/remaining limits.

### Task3: Independent validation and install (root plus reviewer)
- [x] Review assembled native/Lua diff independently and fix confirmed issues.
- [x] Run isolated actual-engine ordinary-player checks; record SP/MP separately, no success by mock alone.
- [x] Prepare reversible launch integration, backup current game launcher config and dedicated settings; validate exact paths/hashes and restart requirement.
- [x] Install approved extension and updated local mod only after compatibility checks; push code and delivery report. Never claim100percent without the executed acceptance proof.

## Completion scope and remaining acceptance

Implementation, offline suites, native fixture checks, reversible local installation and documentation are complete. Independent review identified real path-cache and installer defects; both corrected. Native path fix was rereviewed, final installer regression fix has six passing tests but follow-up review was interrupted by agent usage limits. Root finished packaging/integration inline.

The actual-engine fixture passed104 checks; it is not a two-client multiplayer pass. Full corpse timed-action UI, connected clients and ownership migration remain pending. The final client attempt reached main menu without completed assertions. The latest user instruction forbids further game launches; remaining work uses offline verification only. See docs/NATIVE-DISGUISE-2026-10-22.md for the exact evidence and limits.
