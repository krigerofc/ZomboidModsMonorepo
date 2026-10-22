# Zombie Disguise B42 - development foundation

Requires KRFieldMedicine and retains mod ID ZombieDisguise. B41 payload removed per the user decision. New game-style artwork is included at512/256/64pixels. No Steam upload.

Implemented: corpse-only native timed action with server start/stop and completion progress validation; actor/corpse/square/movement checks; server-only state and finite duration; run/attack/death/disable lifecycle; actual regional blood coverage and washing; shared medical Exposure API v1; localized menus and sandbox options.

Current hard gate: CONCEALMENT_READY=false. Availability identifies missing medical API, disabled health and the missing perception backend separately. It never applies blood when health is disabled or exposure registration rejects the operation. Washing reconciles old exposure sources even while the camouflage backend is disabled.

Native42.19.2 evidence: setZombiesDontAttack(boolean) requires UseZombieDontAttackCheat. Clearing targets in OnZombieUpdate is insufficient because native spotting reacquires later in the same update. Public setInvisible(boolean,isForced) exists, but it changes ghost/invisibility, human visibility, sound and other gameplay branches, so it is not a selective camouflage substitute. No Role mutation, capability grants, private reflection, global zombie freezing or ghost protection was added.

Official API reference: https://projectzomboid.com/modding/zombie/characters/IsoGameCharacter.html#setInvisible(boolean,boolean)

Tests use Fengari and simulated engine objects. They prove state/action/exposure contracts, not actual camouflage, ordinary-client multiplayer or zombie ownership migration. Keep the flag false until native gameplay proof exists.

Remaining: supported selective perception route, authoritative lease replication for each zombie simulation owner, close-range and already-pursuing encounters, two ordinary clients and ownership handoff. The expansion should not be installed as working camouflage yet.
