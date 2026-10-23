# Native camouflage companion v1

**2026-10-23: native startup integration withdrawn.** The user reported that Project Zomboid stopped opening after installation. The five launch files have been restored byte-for-byte from the pre-installation backups, and the installed agent JAR removed. The exact launch failure has not been captured; native fixtures and offline tests did not validate the normal executable launcher. Do not install or publish the native companion as ready until the startup failure is diagnosed and real launcher acceptance passes. No game was launched for this rollback; restoration is verified, successful opening still needs user confirmation. The Lua mods and existing saves were preserved. Disguise camouflage is unavailable while the companion is disabled.

Windows / installed Project Zomboid **42.19.2** class identities only. This companion transforms eleven exact engine classes in memory. It does not replace the game JAR, enable ghost mode, grant capabilities or persist native protection in saves. Unsupported classes leave camouflage unavailable and allow the game to start unchanged.

Public character bridge: getZombieDisguiseBridgeVersion(), setZombieDisguiseLease(worldExpiryHours, ttlSeconds), clearZombieDisguiseLease(). Protection uses weak object identity, a finite game-hour expiry and a monotonic wall-clock TTL. The Lua server approves the blood action and distributes short leases to all participating clients. Every client and server must install the compatible companion.

Zombie hooks filter fresh/repeated spotting, character targets, aggro, matching remembered paths, attack states, bite damage and grapples involving a concealed wearer. Cancelled disguise paths discard cached and late path results; new legitimate goals can restart normally. Other player targets and sound/location goals retain native behavior.

## Build

Use Python3 and the installed game Java runtime:

~~~text
python ZombieDisguise/native/tools/bootstrap.py
python ZombieDisguise/native/tools/build.py "E:/SteamLibrary/steamapps/common/ProjectZomboid"
~~~

The bootstrap fetches pinned ECJ3.43.0 and ASM9.8 dependencies from official Maven Central HTTPS and verifies recorded SHA256. The compiler is build-time only. The resulting self-contained agent is written to outputs/native-disguise/ under the repository, alongside native tests, installed-class verification and unsupported-class startup results. The runtime includes ASM; its license accompanies the artifact.

The build runs native lease/transformer tests and JVM -Xverify:all against the real installed classes. These checks are separate from actual game-world, timed-action and connected-client multiplayer acceptance. Consult the delivery report for executed scenarios; do not describe tests with native fixture actors as a completed multiplayer game.

## Install / remove

See ../INSTALL-NATIVE.md. The prebuilt artifact and its checksum are in dist/. The installer preserves existing launcher options, records original files, supports normal client launch and dedicated server batch launch, and propagates the agent to the game's hosted server process. Close the game before installation or removal.

Compatibility is hash-pinned: do not remove hash checks to run an unverified game build. A changed engine needs inspection, rebuilt hooks and new acceptance evidence.
