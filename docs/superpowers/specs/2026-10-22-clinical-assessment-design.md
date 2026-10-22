# Clinical assessment and longitudinal care — design

Approved basis: user 22/10/2026 says "oq vc consegue fazer, pode fazer" after the feasibility matrix. Continue existing B42+MP FieldMedicine in the current clone, health first. This slice closes diagnostic uncertainty, regional care and medical history; it does not claim every future wishlist module.

## Intended play
The survivor notices symptoms and affected regions. A low-skill examination reports observations and practical supportive care. A skilled examiner with appropriate tools obtains a more specific, explicitly clinical assessment, never pathogen certainty or Knox information. Examinations and successful care become a bounded per-character medical history, retaining what was known at that moment. Regional strain must change combat/effort and improve through the existing targeted care, without duplicating native stiffness or injuries.

## Product decisions (Codex defaults)
- Use existing Lua architecture, native B42 items and bilingual text. No new framework dependency.
- Three assessment bands: effective skill0–2 observations,3–5 suspected syndrome,6–10 clinical assessment if required instrument is present; without the tool remain suspected. Instruments are revalidated server-side. These are gameplay confidence bands, not laboratory certainty.
- Hide latent episodes from routine observations. No precise remaining recovery hour countdown in clinical views. Show severity and reassessment guidance, not a secret timer.
- Symptoms, location and severity are observable. Exact condition, family-bearing keys, causes, phase and condition-specific care must not leak to low-information payloads (including ordinary health sync, fallback UI, menus, history and debug fields). Snapshot filtering happens on server before send. Clinical authority can retain raw state internally.
- Give generic care only when clinically appropriate: existing support, clean/dry/rest/warm/cool routes as symptoms permit. Specific medication/procedure options require the relevant supported assessment. Care may target opaque episode handles and is revalidated against the actual actor, patient, episode identity, current consent/range, skill, tools, finite inventory item and treatment interval on the server. No client diagnosis assertions.
- A successful exam records findings/assessment as known then; a successful care records region, intervention and actual resource. No historical upgrade to later knowledge. Unsuccessful/replayed/too-early care must consume nothing and record no success/XP.
- Persist primitive-only versioned history; max64 events per character, bounded fields. Examinations coalesce for the same observer/current finding within1 simulated hour. Distinct successful treatment events remain separate. Show latest20 in a fifth History tab.
- Other-player examination/history requires existing consent plus reachability; revoke/expiry/new session removes observer access. Self and doctors get separately filtered views. Do not broadcast patient records.
- Starting selected traits can be self-known; acquired/reversible dynamic conditions follow assessment filtering. Preserve all current switches, symptom precedence, cooldowns, XP rules and ZD Exposure API.

## Non-goals for this slice
No detailed pharmacology/doses/withdrawal, surgery/amputation/prostheses, new locomotion animations, new organs, direct leg-speed claims, Knox cure or changes, new disease catalogue expansion, Steam upload, shared push/merge or modifications to original Workshop sources/saves. Those modules require separate acceptance, not silent completion claims.

## Acceptance
1. Equivalent same-state low/high skill exam produces appropriately different views and tool downgrade. Low network serialization contains no hidden condition/family/timer/cause; latent findings absent.
2. Routine sync and reconnect cannot bypass exam uncertainty. Clients cannot raise knowledge by requesting another id or forging skill/tools.
3. Care menus use filtered offers; genuine treatments still reach the authoritative episode and wrong/stale/expired/forged offers fail before resources or XP.
4. History survives state roundtrip/reconnect, stays bounded/coalesced, captures actual exams/care without future diagnosis leakage.
5. EN/PTBR UI exposes symptoms, region, confidence, next care and history; fallback rendering equally filtered; unknown/old payloads safe.
6. All FieldMedicine tests and dependent ZD contracts pass; native registration/load smoke is separate from actual SP/MP gameplay and reported honestly.
