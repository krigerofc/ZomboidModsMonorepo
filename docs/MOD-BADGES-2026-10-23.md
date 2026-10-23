# Atualização dos mods — 23/10/2026

Capas gráficas para KRjobs, Zombie Disguise e Basic Vehicle Maintenance no padrão da referência enviada: emblema central, título/subtítulo em inglês, paleta oliva/creme e textura envelhecida. Geradas pela ferramenta nativa image_gen. Prompts completos em prompts.json. Em cada pasta: master-1024.png, poster.png (512), preview.png (256), icon.png (64) e icon-128.png. Os ícones pequenos mostram o emblema sem texto. As versões anteriores foram preservadas em previous/.

Aplicadas nas fontes do repositório e em C:/Users/pedro/Zomboid/mods/{KRjobs,ZombieDisguise,MoreVehiclesRepairs}. O mod Disguise 2.1.1 foi copiado com todos os arquivos de origem conferidos por SHA256. FieldMedicine é opcional; sem ele não existe simulação médica substituta. A camuflagem permanece indisponível, pois a extensão está retirada e não foi implementado outro sistema de percepção. Não é uma entrega de camuflagem funcional.

Testes offline: Disguise (standalone sem arquivos médicos e integração presente), KRjobs, BasicVehicleMaintenance, FieldMedicine e instalador (6 testes) passaram. A regressão da reversão de sangue sem medicina foi reproduzida antes da correção e passou depois. Não foram executados testes em jogo ou multiplayer conectado.

Os cinco launchers continuam idênticos aos backups originais, e a extensão nativa não está instalada. Nenhum jogo foi aberto. Nenhuma publicação no Workshop.

# English mod descriptions

## KRjobs

24 uncommon professions for Build 42 and 20 for Build 41, inspired by the people and trades of 1993. Choose a new survival background with balanced skill bonuses, profession traits, recipes and small starting kits. Includes English and Brazilian Portuguese. Build 42 profession visibility was checked in the native character-creation menu; multiplayer gameplay and Build 41 acceptance remain pending.

## Basic Vehicle Maintenance

Keep your vehicle useful with emergency patches, durable repairs, overhauls and detailed inspection. Add bounded trunk and glove-box capacity upgrades, modest engine-power upgrades, painting, gradual rust removal and normal vehicle washing. Designed for vanilla vehicles and modded vehicles using standard game parts; unique third-party systems may need an adapter. Build 42, English and Brazilian Portuguese. Live multiplayer acceptance remains pending; top-speed upgrades are not included.

## Zombie Disguise

A standalone Build 42 development mod themed around temporary camouflage using zombie blood. Field Medicine is optional; with its compatible exposure API enabled, applied blood participates in medical contamination and washing cleanup. IMPORTANT: camouflage is currently unavailable because the native startup integration was withdrawn after a launch failure. This independence update does not restore camouflage. Not ready to publish as functional camouflage.
