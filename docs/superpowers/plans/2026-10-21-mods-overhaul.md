# Mods Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** Deliver the six updated mods described in the confirmed scope, retaining honest separation between offline verification and actual game/network tests.
**Architecture:** Keep each mod independent except ZombieDisguise, which depends on KRFieldMedicine on B42. Use pure state/policy modules with engine adapters, server-authoritative changes, versioned per-character/per-vehicle state, and generated EN/PTBR resources.
**Tech Stack:** Lua5.1 subset/Kahlua, PZ B42 scripts/registries/RecordedMedia, Node tests with luaparse and Fengari.
**Spec:** ../specs/2026-10-21-overhaul/PROPOSTA-GERAL.md and linked subsystem specifications.

## Global Constraints

- User confirmed: FieldMedicine and ZombieDisguise B42-only; PassiveSkills B42-only.
- Materials/KRjobs retain B41+B42.
- Ten illness conditions, gradual death from neglected serious complications with sandbox option, person-to-person viral transmission with off switch.
- Mod vehicles only need support when using existing generic game parts; no bespoke systems promised.
- All UI PTBR+EN. Preserve Workshop and mod IDs, except new medicine has no published ID.
- No Steam upload, game update, existing-save changes or main merge.
- Work in the already separate checkout on feat/mods-overhaul-20261021. Original Workshop sources remain unchanged.
- Product defaults proposed in specs can be adjusted for actual engine constraints, but record any change before claiming a feature.
- Actor/resource/state changes must be authoritative. No shared VehicleScript mutation, XP replay or layered identical disease effects.

## Review Focus

- Two players mutating the same part/patient must not duplicate resources, effects, XP or disease rolls.
- Values reconstructed by the engine or another mod must not silently erase upgrades or overwrite unrelated symptoms.
- Save/reconnect/disable paths must preserve items and remove only effects owned by this system.
- Fixture-backed API claims are not proof of real target-build or network behavior.
- Cosmetic/art changes must not accidentally promise mechanical protection or diagnose Knox.

## Task1: Expand and rename materials

Files: ReduceMetalWood/.../Classifier.lua and Core.lua (both builds), tools/gen-translations.js, mod.info, workshop.txt, tests/core_spec.lua, fixtures and tests/run.js.
Interfaces: Classifier.classify(info) returns material,included,reason; preserve computeWeight and runtime baseline behavior. Add ore/construction classes with correct Core counters.
- [ ] Add regression assertions: ores included; concrete/clay/sand/gravel/brick inputs included; empty containers/tools/finished doors excluded; no double reduction; drainable empty transformation retains vanilla baseline.
- [ ] Run existing runner with new cases; expected failure on new inclusion boundaries.
- [ ] Implement classifications/metadata and regenerate translations, maintain original IDs and 50% default. Avoid falsely reducing an item only because used in a recipe.
- [ ] Run full material suite, generated-resource and B41 parity checks; expected all pass.
- [ ] Root reviews diff, records outcomes and commits.

## Task2: PassiveSkills B42-only and real playable VHS

Files: PassiveSkills/tools/{data,gen}.js, Contents/mods/PassiveSkills/42 + common, remove active root B41 payload, new recorded-media integration module and tests/vhs_spec.lua plus runner.
Interfaces: keep all magazine IDs and read-once keys. New tape/line identities must be unique and stable, integrate with native TV/VHS.
- [ ] Add regression cases for no root B41 payload; unchanged magazine XP/read history; media registration; no gain from possession; partial viewing/repeat/two copies/two viewers; loading after reconnect; unsupported device.
- [ ] RED: full runner fails on absent tape behavior/new layout.
- [ ] Verify actual local native media registration/code/learning path before implementation. Do not invent a generic callback or award XP on tape insertion. If fixed XP cannot use native route, prove an authoritative adapter before offering that guarantee.
- [ ] Implement16 original tapes for eight skills with localized titles/lines and separate rarity/XP options; preserve magazine behavior and existing v2 save keys.
- [ ] GREEN: full npm test and generator --check; log exact native/API constraints still requiring game test.
- [ ] Root reviews diff and commits.

## Task3: KRjobs multiplayer kit authority

Files: KRjobs/src/lua/KRjobs/Core.lua, src/lua/KRjobs_Main.lua, generator mirrors, tests/kits_spec.lua and docs decisions.
Interfaces: onNewGame(player,square), giveKit respects authoritative engine context and records successful per-item progress to avoid losing remaining kit on failure.
- [ ] Add tests with separate client/server representations, repeated event, item addition failure and retry, new character; RED.
- [ ] Match vanilla server authority pattern for supported builds; keep IDs/perk/traits/recipes unchanged.
- [ ] Generate, run full npm test including icons; GREEN.
- [ ] Update completion matrix and commit. Do not call gameplay/MP certified.

## Task4: Vehicle repair progression, personalization and bounded upgrades

Files: BasicVehicleMaintenance/42/media/lua/{shared/MVR/{Config,Core,Game,Upgrades}.lua, shared/TimedActions/MVR_RepairAction.lua and new customization action, client/MVR/Menu.lua}; sandbox, tools/translations.js, tests/{core,game}_spec.lua, new upgrades_spec.lua, runner.
Interfaces: pure upgrade functions read immutable baseline and selected tier, not upgraded current value. Identify generic part capabilities, independent of model name. Engine-adapter functions apply/restore server-side with per-instance state.
- [ ] Regressions first: professional work doesn't add emergency patch penalty; repair history doesn't replace upgrade state; unknown model with generic parts works; air/fuel/special cargo not treated as trunk.
- [ ] Add state/policy cases for +10/20% cargo capped40, +25/50% glovebox capped5, +5/10% engine power, non-stacking, same-model isolation, swap/reinstall/repair, capacity downgrade with occupied inventory.
- [ ] RED then implement pure Upgrades policy and versioned separate history/upgrades storage.
- [ ] Implement server-validated repair/customization actions, paint/rust operations, reuse native washing, bounded power and cargo application/replication. Validate actor, area/floor, stationary/access, resources, part identity and concurrent action.
- [ ] Implement top-speed adjustment only with a proven persistence/reapply path; otherwise explicitly ledger as technical blocker, not shipped.
- [ ] Update localized discovery/menu/options and descriptions. Never use cheat-only commands as production authority.
- [ ] GREEN full vehicle suite, check game-specific setters/packets from installed vanilla. Record game-test matrix before commit.

## Task5: Medicine fixes and shared condition engine

Files: FieldMedicine/42/media/lua/shared/KFM/{Core,Game,Conditions,Illness}.lua; TimedActions/KFM_ProcedureAction.lua; server/KFM/KFM_Server.lua; client/KFM/KFM_Client.lua; scripts/items/recipes, sandbox, tools/i18n.js, tests/core/glue/new illness specs and runner.
Interfaces: versioned per-patient episodes; pure advance(state,context,elapsed,rng,cfg) produces proposed state/effects; engine adapter owns only additional effects, server owns exposure/progression/treatment/XP and mirroring. Public server-only exposure API for Disguise, stable source IDs and explicit removal.
- [ ] Permanent regressions first for disabled old tourniquet, nil-first optional item transfer, actual belt identity/state, zero-benefit irrigation XP, belt tooltip chance.
- [ ] RED then minimal fixes; full suite GREEN before broad additions.
- [ ] Add tests for ten distinct condition definitions, staged transitions, one episode per cause, native symptom deduplication, offline pause, deterministic hourly windows, mortality off/on, eligible-person contact/cross-floor/barrier exclusion.
- [ ] Implement server state/schema/migration and exposure API; ten conditions with symptoms, treatment, recovery and complications—not labels alone. Native cold/poison/injury already active becomes observed base, not duplicated damage.
- [ ] Add limited medicines/treatments with intervals and caps, meaningful evaluation/follow-up, burn/fracture/muscle/nerve episode support and no Knox diagnosis. First-aid quality helps but total recovery reduction capped40%.
- [ ] UI/localized content and sandbox include frequency, severity, contact spread and mortality switches. Death only follows severe untreated progression with warnings; no instant catch-up damage.
- [ ] GREEN full suite and script/reference checks, record remaining actual engine/network scenarios and commit.

## Task6: ZombieDisguise B42 health expansion and cover

Files: ZombieDisguise/Contents/mods/ZombieDisguise/42/{mod.info,media/lua/{client,server,shared}}; common translations; workshop.txt and new tests/package/tooling; preview/poster/icon.
Interfaces: require=KRFieldMedicine; consume server exposure API from Task5, never run independent illness-stat assignments.
- [ ] Regressions for invalid/moved corpse, no elapsed action, actor mismatch/splitscreen, interrupted action, expiry, washing vs wetness, reconnect/no duration reset, death/disable/protection ownership and single health exposure; RED.
- [ ] Replace empty unvalidated protection command with verified authoritative timed action/protocol. Same-floor corpse source/duration and resources/context checked server-side.
- [ ] Implement120-minute proposed camouflage, running/attack breaks, expiration doesn't remove residual blood exposure, health API registers/removes source exactly once. Preserve externally owned protection.
- [ ] Remove B41 payload, add all EN/PTBR resources, new image assets from outputs/zomboid-game-style-v2/zombie-disguise and image metadata references.
- [ ] GREEN independent new suite plus health+disguise contract tests, missing dependency fallback and migration; commit.

## Final verification

- [ ] Per-task implementers report exact RED→GREEN checks/full suites, modified paths, and unresolved engine limits; no subagent staging/commits while sharing checkout.
- [ ] Root independently reviews combined diff and runs all six suites plus existing icon test, generators --check and diff --check.
- [ ] Fresh whole-branch reviewer checks source/MP boundaries and side effects. Reproduce confirmed issues before fix.
- [ ] Save a clear release matrix: offline verified versus real SP/host/dedicated/B41/target build still not run. No certification beyond evidence.
- [ ] Do not overwrite working sources or publish remotely until concrete change is reviewable. Preserve original repositories.
