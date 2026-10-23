# Native extension installation

**2026-10-23: native startup integration withdrawn.** The user reported that Project Zomboid stopped opening after installation. The five launch files have been restored byte-for-byte from the pre-installation backups, and the installed agent JAR removed. The exact launch failure has not been captured; native fixtures and offline tests did not validate the normal executable launcher. Do not install or publish the native companion as ready until the startup failure is diagnosed and real launcher acceptance passes. No game was launched for this rollback; restoration is verified, successful opening still needs user confirmation. The Lua mods and existing saves were preserved. Disguise camouflage is unavailable while the companion is disabled.

The historical native backend belongs to **Zombie Disguise**. **Field Medicine '93** is optional. Installation is suspended; the commands below are retained for development/rollback reference. It filters zombie perception in memory; it does not make the wearer invisible to human players or grant administrator permissions.

## Windows

Close the game first. Use the provided installer with the actual game folder and local ZombieDisguise mod folder:

~~~powershell
node tools/native-install.js install --game "E:/SteamLibrary/steamapps/common/ProjectZomboid" --mod "C:/Users/pedro/Zomboid/mods/ZombieDisguise" --agent "native/dist/zombie-disguise-agent.jar" --backup "PATH/TO/A/NEW-BACKUP-FOLDER"
~~~

The installer copies the companion JAR into the local mod's native/ folder and adds one JVM argument to the client launcher configuration and supported batch launchers. Existing options are preserved. It creates a manifest and original-file backups before changing launch files. Do not reinstall the withdrawn native backend to test this independence update.

Multiplayer requires the same compatible native companion on the server **and every client**. Hosted servers inherit the companion through the supported host launcher integration. A client missing the extension keeps camouflage unavailable; a cosmetic blood coating is not presented as protection.

The companion is pinned to specific engine class hashes. Unsupported builds must keep camouflage unavailable. A Steam update may replace launcher settings: check the extension status again after updating. Do not replace projectzomboid.jar or copy loose patched game classes.

## Remove the extension

Close the game before removing the extension.

~~~powershell
node tools/native-install.js uninstall --manifest "PATH/TO/BACKUP/manifest.json"
~~~

If launch files still match the installer output, their exact originals are restored. If client options were subsequently edited, only this extension's JVM argument is removed. An independently changed JAR is preserved with a warning. Existing saves and Workshop sources are not touched.

## Português

Feche o jogo antes de instalar. A extensão acompanha o mod e precisa ser instalada também nos clientes e no servidor do multiplayer. O instalador mantém suas opções, cria cópias de segurança e fornece um manifesto para desfazer a instalação. A instalação está suspensa. Medicina de Campo é opcional; não reinstale a extensão retirada para testar esta atualização.

O efeito atua somente na detecção dos zumbis: não concede modo fantasma, invulnerabilidade ou privilégios administrativos. A compatibilidade depende da versão exata do jogo. Consulte o relatório de testes da entrega; os testes de lógica e de classes nativas não substituem a validação de uma sessão multiplayer com clientes conectados.
