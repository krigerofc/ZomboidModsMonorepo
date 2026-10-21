# Passive Skills v2 — B42 / Guia manual e evidências

PT-BR: esta versão distribui somente B42. Mod ID `Passiveskillskr`, Workshop `3477846890`. As revistas preservam IDs, XP, feedback e chaves de leitura da v2. O jogo não foi iniciado nesta etapa.
EN: this package ships B42 only. Magazine IDs, XP, feedback and v2 read keys are preserved. No game was launched during this work.

Referência local / local reference: arquivos instalados documentados como 42.19.2; alvo solicitado / requested target: 42.21. A inspeção local não certifica 42.21 / local inspection does not certify 42.21.

## Comportamento / Behavior

| PT-BR | EN |
|---|---|
| 33 habilidades, cinco volumes, 2775 XP fixos por habilidade no padrão. Chance de revista: 12%. | 33 skills, five volumes, 2775 fixed XP per skill at defaults. Magazine chance: 12%. |
| 16 programas VHS originais, dois para cada uma das oito habilidades abaixo; cinco legendas por programa, EN/PTBR. | 16 original VHS programs, two per skill below; five captions per program, EN/PTBR. |
| VHS usa o item do jogo `Base.VHS_Retail`, com dados de mídia próprios. Inserir, transportar ou pegar a fita não ensina. | VHS uses the native `Base.VHS_Retail` item with its own recorded program. Inserting, carrying or picking up a tape does not teach. |
| Chance de VHS: 2%, independente da revista, nos mesmos contêineres elegíveis. 0 impede novas fitas; fitas existentes permanecem reproduzíveis. | VHS chance: 2%, independent of magazines, in the same eligible containers. 0 stops new tapes; existing tapes remain playable. |
| XP de VHS: 100% oferece 250 XP **base** por fita, 50 por trecho. Multiplicadores normais e `LevelForMediaXPCutoff` do jogo se aplicam. Não existe garantia de 250 XP finais. | VHS XP: 100% offers 250 **base** XP per tape, 50 per line. Normal multipliers and the game's `LevelForMediaXPCutoff` apply. Final XP is not guaranteed to equal 250. |
| Cada personagem aprende cada trecho uma vez pelo histórico nativo; cópias, rebobinar e trocar de TV usam a mesma identidade. | Native per-character line history prevents replay through copies, rewinding or another TV. |
| XP de VHS em 0 desativa aprendizado sem marcar novos trechos como vistos. XP de revistas é separado. | VHS XP 0 disables learning without consuming unseen lines. Magazine XP is separate. |
| A regra nativa marca o trecho visto antes do limite de nível e do intervalo de 30 ticks por habilidade. Duas TVs ensinando a mesma habilidade ao mesmo tempo podem consumir um trecho sem dar XP. Assistir uma fita por vez evita essa disputa. | Native logic marks a line seen before the level cutoff and 30 tick same-skill cooldown. Concurrent TVs can consume a line without XP. Watch one tape at a time to avoid that contention. |
| Adormecido, morto, fora do alcance de 5 quadrados em cada eixo, em outro piso ou do outro lado da separação interior/exterior não aprende, conforme o código nativo. | Native checks reject sleeping/dead viewers, viewers beyond 5 tiles on either axis, another floor or the opposite inside/outside boundary. |

## Catálogo / Catalog

| Habilidade / Skill | Código nativo / Native code | Programas EN / PTBR |
|---|---|---|
| Carpintaria / Carpentry (`Woodwork`) | CRP | The Square Start / O começo no esquadro; Sunday Shelf Workshop / Oficina da prateleira de domingo |
| Mecânica / Mechanics (`Mechanics`) | MEC | Driveway Checks with Dale / Revisão na garagem com Dale; The Wheel Routine / A rotina das rodas |
| Primeiros Socorros / First Aid (`Doctor`) | DOC | Community First Aid: First Minutes / Primeiros socorros: primeiros minutos; Community First Aid: Clean Dressings / Primeiros socorros: curativos limpos |
| Elétrica / Electrical (`Electricity`) | ELC | The Dead Circuit Rule / A regra do circuito desligado; Bench Radio: Finding the Fault / Rádio de bancada: encontrando a falha |
| Metalurgia / Welding (`MetalWelding`) | MTL | Weld Shop: Preparation Pays / Oficina de solda: preparar compensa; Weld Shop: A Steady Bead / Oficina de solda: cordão constante |
| Forja / Blacksmithing (`Blacksmith`) | BLA | Morning at the Forge / Manhã na forja; Forge Practice: Hook and Eye / Prática de forja: gancho e olhal |
| Alvenaria / Masonry (`Masonry`) | MAS | Masonry Corner: The First Course / Canto da alvenaria: primeira fiada; Masonry Corner: The Brick Rhythm / Canto da alvenaria: ritmo dos tijolos |
| Costura / Tailoring (`Tailoring`) | TAI | The Mending Basket / O cesto de consertos; A Working Hem / Uma barra bem feita |

## Verificação automatizada / Automated verification

`npm test` executa / runs:

- Geração atualizada, layout somente B42, sintaxe Lua 5.1, 170 revistas e paridade de todas as chaves EN/PTBR / generated-resource checks, B42-only layout, Lua 5.1 syntax, 170 magazine definitions and EN/PTBR key parity.
- Lógica e integração existentes das revistas, inclusive histórico v2 pré-existente e alias Welding / existing magazine logic/glue, including pre-existing v2 read history and the Welding alias.
- Registro de 16 programas, identidades estáveis, itens VHS do jogo, spawn independente e nenhum XP por posse / registration of 16 programs, stable identities, native VHS items, independent spawning and no possession XP.
- Integração com o arquivo **real instalado** `media/lua/shared/RadioCom/ISRadioInteractions.lua`, carregado no Fengari com objetos de motor simulados. Inclui todas as oito habilidades, duas pessoas, interrupção/repetição/cópias, mudança de posição da TV, histórico restaurado, distância/piso/sono, multiplicadores, cutoff, XP 0, cooldown e passagem inalterada de mídia de outros autores / real installed native Lua under Fengari with engine objects stubbed, covering all eight skills and these scenarios.

Defina / set `PZ_MEDIA` para / to the installed game's `media` directory if needed. When it is unavailable the runner prints an explicit native-integration SKIP; it does not replace the native handler with a synthetic XP implementation. O runner informa SHA256 da fonte usada / the runner prints the native source SHA256.

`node tools/gen.js --check` deve sair 0 / must exit 0. Não instala dependências / installs no dependencies.

## Fontes e limites da API / API evidence and limits

Inspecionados somente em leitura / inspected read-only:

- `media/lua/shared/RecordedMedia/ISRecordedMedia.lua`: `OnInitRecordedMedia`, `register`, `setTitle`, `setSubtitle`, `setAuthor`, `addLine`.
- `media/lua/shared/RadioCom/ISRadioInteractions.lua`: oito códigos acima, `OnDeviceText`, 50×valor do código via `addXp`, gates de espectadores, cooldown e `isKnownMediaLine/addKnownMediaLine`.
- `media/lua/client/RadioCom/RadioWindowModules/RWMMedia.lua`: teclado/controle procuram os tipos exatos `Base.VHS_Retail` e `Base.VHS_Home`.
- `projectzomboid.jar`, classes `RecordedMedia`, `DeviceData`, `IsoGameCharacter`: registro e índices persistentes; categoria não-CD é mídia tipo1; tabelas de spawn varejista usam somente `Retail-VHS`; inserção não concede XP; reprodução verifica energia/volume e emite `OnDeviceText` durante cada linha; histórico nativo tem save/load por personagem.

O adaptador só escala códigos dos80GUIDs próprios e chama o handler nativo uma vez. Nenhuma recompensa direta, timer próprio ou comando cliente de XP foi adicionado / the adapter scales only its 80 owned GUIDs and delegates native handling once. It adds no direct XP reward, custom playback timer or client XP command.

Reproduzir a inspeção / reproduce the class inspection: `python tools/inspect-native.py <projectzomboid.jar>`. O resultado registra hashes de classe e instruções relevantes / output records class hashes and relevant bytecode. Isso comprova as referências locais, não execução real de Java ou rede / this checks local references, not actual Java or network execution.

## Roteiro no jogo — ainda pendente / In-game matrix — still pending

Use uma instalação de teste isolada e um mundo descartável; não altere saves ou fontes originais / use an isolated test install and disposable world; preserve original saves and sources.

| Verificação / Check | Resultado esperado / Expected result |
|---|---|
| Menu Mods e sandbox EN/PTBR / Mods menu and sandbox | Somente B42, quatro opções localizadas, nenhum texto cru de chave / B42 only, four localized settings, no raw translation keys. |
| Revistas / Magazines | IDs e nomes antigos; sem Fitness/Força; cinco volumes dão 75/150/300/750/1500 sem multiplicadores; balão e halo originais / old IDs/names; no Fitness/Strength; fixed tier XP and original speech/halo. |
| Histórico v2 e legado / v2 history and legacy | Revista já lida continua bloqueada; `Welding` compartilha chave com `MetalWelding`; morte/nova pessoa tem histórico novo / saved reads stay blocked, alias shares key, new character has fresh history. |
| Spawn 0/100 e raridades / spawn 0/100 and rarity | Configurações de revista/VHS independentes; contêiner elegível gera no máximo uma revista e uma fita do mod; mídia vanilla não muda / independent settings, at most one mod magazine and one mod tape per eligible fill, unchanged vanilla media. |
| Inventário e inserção / Inventory and insertion | Nenhum XP por pegar, carregar, inserir ou retirar fita / no XP on pickup, carrying, insertion or removal. |
| Televisão compatível / Compatible TV | Teclado e controle inserem VHS; títulos e cinco legendas legíveis nos dois idiomas; XP em cada trecho reproduzido / keyboard/controller insertion, readable title and five captions in both languages, XP on played lines. |
| TV sem energia/desligada/volume0 / Unpowered/off/muted TV | Sem XP; retomar restaura comportamento nativo / no XP; restoring playback follows native behavior. |
| Rádio/CD/aparelho incompatível / Radio/CD/unsupported device | Fita não entra em aparelho incompatível; sem XP / incompatible insertion rejected, no XP. |
| Interromper após dois trechos / Stop after two lines | Apenas 100 XP base antes de multiplicadores; repetir não dá XP nos dois trechos; restantes aprendem / 100 base XP before multipliers, seen lines do not replay, unseen lines can teach. |
| Duas cópias/TVs / Two copies/TVs | Mesmas identidades impedem XP repetido; duas TVs simultâneas podem disputar cooldown nativo / shared identity prevents duplicates; concurrent TVs can contend for native cooldown. |
| Distância, piso, sono, interior/exterior / Distance, floor, sleep, inside/outside | Gates nativos aplicados; também testar paredes e obstáculos e registrar limitações reais / native gates apply; test walls/obstacles and record real limitations. |
| Profissão/livro/cutoff / Profession/book/cutoff | VHS usa multiplicadores/limite nativos; revista mantém XP fixo; cutoff pode marcar trecho visto sem XP / VHS follows native multipliers/cutoff, magazines remain fixed; cutoff may consume seen line. |
| Host e dedicado com 2 clientes / Host and dedicated with 2 clients | Ambos assistem à mesma sessão e têm progresso próprio; confira XP no servidor e no dono, nenhum duplicado entre cliente/servidor / independent progress, matching owner/server XP, no client/server duplicate. |
| Reconectar/save/load/reiniciar / Reconnect/save/load/restart | XP e histórico parcial mantidos, índices de mídia estáveis, nenhum ganho repetido; novo personagem aprende / XP/history/index persistence, no replay, new character learns. |
| Desativar e reativar mod / Disable/re-enable mod | Verificar preservação da fita física e histórico; registrar como mídia ausente aparece durante desativação / verify physical tape/history preservation and missing-media presentation while disabled. |
| Console | Nenhuma exceção do mod, nenhuma tradução ou perk faltando / no mod exception, missing translation or invalid perk. |

PT-BR: preencher versão exata do executável, SP/host/dedicado, idiomas, total real de XP e logs antes de anunciar compatibilidade.
EN: record exact executable version, SP/host/dedicated mode, languages, actual XP totals and logs before claiming compatibility.
