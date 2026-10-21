# KRjobs v2 - decisões

Repo: `C:\Users\pedro\Zomboid\Workshop\KRjobs` (commit 47f771c). Mod id `Krjobs`, Workshop 3149644183. Fonte única: `tools/data.js` -> `npm run gen` -> `npm test`.
Decidido sem o usuário (ausente), com base no vanilla 42.19.2 e em mods de profissão populares (More Professions / Profession Framework: profissão + traço de profissão + receitas + kit inicial pequeno).

## Arquitetura
- **B42 (42.13+)**: `42/media/registries.lua` (`CharacterTrait.register` / `CharacterProfession.register`, ids `krjobs:<id>`), scripts `KRjobs_professions.txt` / `KRjobs_traits.txt`, traduções JSON em `common/.../Translate/{EN,PTBR}/UI.json` (+ Mod.json, como no PassiveSkills). `versionMin=42.13.0`. Nenhuma ProfessionFactory/TraitFactory.
- **Scripts em `module Base`**: nomes de receita sem prefixo resolvem igual ao vanilla (a 42.21 lança RuntimeException para receita inexistente; evita depender de resolução por módulo).
- **B41**: `media/lua/shared/NPCs/KRjobs_Professions.lua` gerado; registro idempotente em OnGameBoot + OnCreateLivingCharacter (corrige duplicação do v1), perk desconhecido é ignorado (corrige crash do Fighter). Traduções `UI_EN.txt` (UTF-8) / `UI_PTBR.txt` (latin1/Cp1252).
- **Tipos B41 do v1 mantidos** (`Hitman`, `Architect`, `blacksmith`, `Survivalist`, `Car Modifier`, `Mailman`, `Fighter`) para não quebrar saves; novos usam `KRjobs_<Nome>`.
- **Descrições**: o jogo já anexa `+N Habilidade` e nomes de traços (BaseGameCharacterDetails.SetProfessionDescription / SetTraitDescription), então o texto só traz a frase e, no traço, receitas/kit. Não duplicamos as linhas de boost.
- **Efeito Lua**: só kit inicial (1-3 itens vanilla) dado uma vez em OnNewGame, marcado em ModData `KRjobsKitGiven`. `Core.lua` idêntico nas duas builds (B42 `CharacterTrait.get(ResourceLocation.of(id))`, B41 `HasTrait`).
- **Receitas**: só receitas vanilla com `needTobeLearn = true` (B42, 345 no 42.19.2); B41 só nomes presentes no Recipes_EN 41.78 e usados por profissões vanilla B41.
- **4 profissões só B42** (Ferrador, Soprador de Vidro, Taxidermista, Arqueólogo): dependem de Blacksmith/Husbandry/Glassmaking/Pottery/Butchering/Carving/FlintKnapping, inexistentes ou inúteis na B41. B41 = 20.
- Custos B41 ajustados onde a troca de skills muda o valor (Arquiteto 0, Eng. Químico 0).

## Fórmula de balanceamento (`tools/balance.js`)
V = Σ peso×níveis (profissão + traços) + valor de receitas (0 / 1 se 1-5 / 2 se 6+) + 1 por kit + valor de traço vanilla concedido (nightowl 1, mechanics2 2, desensitized 6...).
Pesos: 2 = combate/físicas e skills "porteiras" (Electricity, MetalWelding, Mechanics, Blacksmith); 1,5 = Maintenance; 1 = demais.
Custo esperado = 8 − V (desempregado = +8). Calibração nas 25 profissões vanilla B42: erro médio 1,36 pts (outliers vanilla: Engineer, Fisherman, Park Ranger).
Regras testadas: |custo − esperado| ≤ 2, custo em [−8, +2], 3-9 níveis totais, nenhuma skill > 6, ≤ 7 níveis em skills de peso 2, 1-2 traços próprios.

## Profissões (B42; custo B41 entre parênteses quando difere ou "—" se só B42)

| Profissão (EN / PT) | XP | Traço de profissão | Custo | V / esperado | Ícone |
|---|---|---|---|---|---|
| Hitman / Matador de Aluguel | Aiming 2, SmallBlade 2, Sneak 1, Lightfoot 1 | Cold-Blooded: Reloading +1 | −6 | 14 / −6 | próprio (gun) |
| Architect / Arquiteto | Woodwork 3, Masonry 2 (B41: Woodwork 3, Maint 1) | Draftsman: Elec +1, Carving +1, kit lápis+caderno | −2 (0) | 9 / −1 | próprio |
| Ornamental Ironworker / Serralheiro (ex-blacksmith) | MetalWelding 2, Blacksmith 1, Strength 1 | Forge Hand: 5 receitas Forge_*, máscara de solda | −2 | 10 / −2 | próprio |
| Survivalist / Sobrevivencialista | Forage 2, Trapping 2, Fishing 1, FlintKnapping 1 | Bushcraft: Tracking +1, Carving +1, 5 armadilhas | −2 | 9 / −1 | próprio (kit2) |
| Hot Rod Builder / Preparador de Carros (ex-Car Modifier) | Mechanics 3, MetalWelding 1, Elec 1 | Gearhead: chave inglesa + fenda; + base:mechanics2 | −4 | 13 / −5 | próprio (car) |
| Rural Mail Carrier / Carteiro Rural (ex-Mailman) | Fitness 1, Sprinting 2, Lightfoot 1 | Knows the Route: Forage +1, bolsa | −2 | 10 / −2 | próprio (email) |
| Amateur Boxer / Boxeador Amador (ex-Fighter) | Fitness 2, Strength 2, SmallBlunt 1 | Ring Conditioning: Sprinting +1, Nimble +1 | −6 | 14 / −6 | próprio (boxe) |
| Navy Rescue Diver / Mergulhador de Resgate | Fitness 2, Strength 1, Doctor 1, Fishing 1 | Rescue Swimmer: Doctor +1, óculos natação + corda | −2 | 10 / −2 | vanilla fisher2* |
| Navy SEAL | Aiming 2, Fitness 2, Sneak 1, SmallBlade 1 | Hell Week Graduate: Reloading +1, faca de caça | −8 | 15 / −7 | vanilla veteran2* |
| Fighter Pilot / Piloto de Caça | Aiming 1, Mechanics 1, Elec 1, Fitness 1 | SERE Training: Forage +1, Trapping +1, 2 armadilhas | −4 | 11 / −3 | vanilla engineer* |
| Firearms Instructor / Instrutor de Tiro | Aiming 3, Reloading 2, Maint 1 | Range Master: abafador + óculos de tiro | −4 | 12,5 / −4,5 | vanilla policeofficer2* |
| Specialist Surgeon / Cirurgião Especialista | Doctor 6, SmallBlade 1 | Steady Hands: Tailoring +1, bisturi, pinça, porta-agulha | −2 | 10 / −2 | vanilla doctor2 |
| Systems Analyst / Analista de Sistemas | Elec 3, Maint 1 | Hardware Tinkerer: 5 receitas de rádio/lanterna, chave de fenda; + base:nightowl | −2 | 10,5 / −2,5 | vanilla electrician* |
| Chemical Engineer / Engenheiro Químico | Elec 1, Doctor 1, Farming 1, Cooking 1 | Applied Chemistry: Glassmaking +1, 10 receitas (bombas aerossol/fogo/fumaça, defensivos, filtros) | −2 (0) | 8 / 0 | vanilla engineer* |
| Robotics Engineer / Engenheiro de Robótica | Elec 2, Mechanics 1, MetalWelding 1 | Servo Technician: controles remotos V1-V3, gatilho, timer, chave de fenda | −2 | 10 / −2 | vanilla mechanic* |
| Bomb Disposal Technician / Técnico Antibombas | Elec 2, Nimble 1, Lightfoot 1 | EOD Training: pipe bomb, timer/gatilho/sensor em bomba, noise maker | −2 | 9 / −1 | vanilla engineer* |
| Smokejumper / Bombeiro Paraquedista | Fitness 2, Axe 1, Strength 1, Forage 1 | Fireline Crew: machadinha | −2 | 10 / −2 | vanilla fireofficer2 |
| Farrier / Ferrador | Blacksmith 2, Husbandry 2, Strength 1 | Hoof and Anvil: 5 receitas Forge_* | −2 (—) | 9 / −1 | vanilla smither |
| Glassblower / Soprador de Vidro | Glassmaking 3, Pottery 1, Maint 1 | Studio Glassworks: 7 receitas de vidro | 0 (—) | 7,5 / 0,5 | vanilla smither* |
| Oil Rig Roughneck / Peão de Plataforma | Strength 2, Mechanics 1, MetalWelding 1, Maint 1 | Rig Hand: chave de cano + capacete | −2 | 10,5 / −2,5 | vanilla constructionworker2* |
| Taxidermist / Taxidermista | Butchering 3, Tailoring 2, Carving 1 | Specimen Mounting: troféu de cervo + 4 receitas osso/couro, bisturi | 0 (—) | 8 / 0 | vanilla rancher* |
| Power Lineman / Eletricista de Rede | Elec 3, Fitness 1, Strength 1 | High-Voltage Safety: luvas de couro + capacete | −4 | 11 / −3 | vanilla electrician |
| Locksmith / Chaveiro | Nimble 1, MetalWelding 1, Maint 1, Woodwork 1 | Key Cutter: CopyBuildingKey (só B42), chave de fenda | 0 | 8,5 / −0,5 | vanilla burglar2* |
| Field Archaeologist / Arqueólogo de Campo | FlintKnapping 2, Carving 1, Masonry 1, Forage 1 | Experimental Archaeology: Tracking +1, 5 receitas de pedra | 0 (—) | 7 / 1 | vanilla parkranger2* |

Referência vanilla: Veteran −8, Police −4, Doctor 0, Electrician −2, Mechanic −4, Smither −6, Fitness Instructor −6.

## Ícones
Reusados do v1 (renomeados `profession_krjobs_*.png`, 64×64, em `media/textures` — o jogo resolve `media/textures/<nome>.png` via Texture.trygetTexture): hitman, architect, ironworker, survivalist, hotrodder, mailcarrier, boxer.
Vanilla adequados: Cirurgião (doctor2), Bombeiro Paraquedista (fireofficer2), Eletricista de Rede (electrician), Ferrador (smither).
**Precisam de ícone próprio (marcados * na tabela, hoje com placeholder vanilla)**: Mergulhador, Navy SEAL, Piloto de Caça, Instrutor de Tiro, Analista de Sistemas, Eng. Químico, Eng. de Robótica, Técnico Antibombas, Soprador de Vidro, Peão de Plataforma, Taxidermista, Chaveiro, Arqueólogo (13).
Capas: poster 512 / icon 64 / preview 256 da pasta `zomboid-game-style-v2/krjobs` (mesmo padrão do PassiveSkills).

## Riscos não verificados
- Nada testado dentro do jogo (ver MANUAL_TEST.md no repo). Validado só contra arquivos do 42.19.2 local; receitas renomeadas na 42.21 causariam RuntimeException.
- B41 sem instalação local: perks/receitas/itens/ícones verificados contra fixtures (PassiveSkills + traduções oficiais 41.78), não contra o jogo. `NightOwl`/`Mechanics2` e `SetTraitDescription` assumidos da B41.78.
- Kits via OnNewGame: autoridade corrigida para o servidor/simulação solo; teste real com dois clientes e persistência continua necessário.
- Ícones de mod por nome em `media/textures` (mesmo mecanismo do v1); confirmar no B42.

## Referências
- Vanilla `media/scripts/generated/characters/*.txt` (42.19.2), `MainCreationMethods.lua`, classes `CharacterProfessionDefinitionScript`/`CharacterTraitDefinitionScript` (chaves aceitas).
- testmod_registries (pz-wiki-modding/Archive.Project-Zomboid-Modding, TIS guides B42 unstable MP).
- TheIndieStone/ProjectZomboidTranslations (41.78) Recipes_EN / ItemName_EN; PZwiki Occupation; notas 42.21.0.

## Correção Codex — 21/10/2026

Kits deixam de ser criados na representação cliente. O servidor/solo registra cada slot entregue e marca o conjunto completo somente após sucesso; falhas parciais permitem repetir sem duplicar os itens já entregues. Regressões de cliente/servidor e falha parcial falharam antes (4 por build) e passaram depois; runner e teste de ícones passaram. Isso corrige a autoridade no código, mas não substitui validação real de OnNewGame/replicação/reconexão em B41/B42.
