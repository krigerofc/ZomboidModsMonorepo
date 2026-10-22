# Clinical assessment and care Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Deliver useful symptom-led examination, targeted care and bounded history in FieldMedicine.
**Architecture:** Keep raw clinical state server-only; build observer-specific view through a focused assessment module and bounded history module. Existing Health adapter owns identity, consent, resources and synchronization. UI consumes filtered view only.
**Tech Stack:** Lua5.1/PZ42.19.2 installed APIs, Node/Fengari regressions, generated EN/PTBR JSON.
**Spec:** docs/superpowers/specs/2026-10-22-clinical-assessment-design.md

## Global Constraints
B42-only; MP server authority; primitive versioned state; EN/PTBR; no Knox; preserve native precedence/finite resources/XP; original Workshop/saves untouched; no publication.

## Review Focus
- Routine sync and fallback/menu leakage, not only the new exam window.
- Different observer, reconnection/revocation and stale episode/care identifiers.
- Missing/removed/invalid instrument and forged fields at completion.
- No history explosion or retrospective upgrading of earlier observations.
- Module-disabled and old/missing payload migration paths.

### Task1: Clinical view, care and history (cohesive protocol change)
**Files:** Create shared/KFM/Assessment.lua and History.lua as needed under FieldMedicine/Contents/mods/KRFieldMedicine/42/media/lua; modify Health.lua, ExamModel.lua, KFM_Client.lua, KFM_Server.lua, KFM_ProcedureAction.lua and KFM_CareAction.lua; related tools/exam-text.js, generated translations, tests/run.js and clinical_spec.lua; update MANUAL_TEST.md/HEALTH-PHASE2.md. Keep unrelated modules intact.
**Interfaces:** Preserve KFM.Exposure.version/register/remove and raw H.state internal semantics. Produce filtered observer-specific snapshot/assessment and serializable history. The implementer selects concrete names consistent with actual call sites and documents them in report.
- [ ] Write regression scenarios for all acceptance criteria; run failing tests before implementation.
- [ ] Implement observer filtering and exact server-side exam/tool validation across routine/exam/menu/fallback paths.
- [ ] Implement filtered care routes, stale identity validation and versioned bounded immutable-at-time history.
- [ ] Integrate fifth History tab and generated EN/PTBR explanations; verify every visible care action still targets real server episode.
- [ ] Run full FieldMedicine runner, translation --check, dependent ZD contracts and git diff --check; self-review; report exact RED/GREEN evidence.
- [ ] Independent scoped spec+quality review; fix findings and re-review.

### Task2: Native integration validation
**Files:** work/overhaul-smoke-20261021 driver/owned caches outside repo and outputs reports; no original source/saves.
- [ ] Boot copied six-mod snapshot in a new localhost-only nosteam dedicated cache. Record hashes/source paths and verify24KR professions/traits and4FM starting traits plus real script load errors.
- [ ] Compare errors to vanilla baseline; reproduce/fix only confirmed new failures via owner+regression. Reboot changed snapshot if fixes affect load.
- [ ] Publish local report/checkpoint; distinguish dedicated load from actual client/treatment/MP tests.
