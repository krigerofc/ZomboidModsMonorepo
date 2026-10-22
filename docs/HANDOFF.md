# HANDOFF — Mods Project Zomboid do Kriger

> Estado atual (21/10/2026): a reestruturação está na cópia separada work/ZomboidModsMonorepo, branch feat/mods-overhaul-20261021. As seções datadas de17/10 abaixo são histórico da base importada. Consulte docs/superpowers/plans/2026-10-21-mods-overhaul.md e as especificações vinculadas para o escopo atual. Não reaplique patches nem sobrescreva os repositórios Workshop originais.


> Arquivo de passagem de bastão entre IAs (Claude, ChatGPT) e o dono dos mods (usuário "Kriger").
> Leia isto **antes** de qualquer trabalho. Atualize a seção "Registro de decisões" e "Status" ao terminar uma sessão.
> Legenda: **[DECIDIDO]** = decidido pelo usuário · **[PROPOSTA]** = sugestão de IA, validar com o usuário · **[PENDENTE]** = aguardando resposta do usuário.

Última atualização: 2026-10-17 (Claude — status final dos 5 mods, auditoria de conflitos, plano de teste unificado)

---

## 1. Regras globais [DECIDIDO]

1. O usuário é o dono/autor de todos os mods (autor "Kriger").
2. **Regra de ouro: todo mod em PT-BR + EN.** Nenhum texto hardcoded.
3. Desenvolvimento **test-driven**; objetivo é **zero conflitos e zero erros no jogo**.
4. Ordem de trabalho: **ReduceMetal → PassiveSkills → KRjobs → Vehicle v2 → Medical** (todos implementados; falta teste in-game).
5. Compatibilidade: raiz `media/` = **B41**; `common/` + `42/` = **B42**. Alvo **42.21 estável**. Jogo local para teste: **42.19.2** em `E:\SteamLibrary\steamapps\common\ProjectZomboid` — **ler o Lua/scripts vanilla de lá** para confirmar APIs reais (não confiar em memória/wiki).
6. MP B42.13+: mudanças de item/condição/corpo no servidor, dentro de `TimedAction:complete()`; sincronizar com `sendRemoveItemFromContainer` / `sendAddItemToContainer` / `UseAndSync` / `sendItemStats` / `syncBodyPart` / `syncPlayerStats`.
7. Traduções: B42 JSON em `common/media/lua/shared/Translate/EN|PTBR/*.json`; B41 TXT em `media/lua/shared/Translate/EN/*_EN.txt` e `PTBR/*_PTBR.txt`.

## 2. Regras de colaboração entre IAs [DECIDIDO]

- Trabalhar sempre em **branch** (`feat/<mod>-<tema>`, `fix/...`); nunca direto na `main` sem o usuário pedir.
- **Não reescrever commits de outra IA/pessoa** (sem `rebase -i`, `commit --amend` ou `push --force` sobre trabalho alheio). Para corrigir, novo commit.
- **Registrar toda decisão neste HANDOFF** (seção 6), separando o que o usuário decidiu do que é proposta.
- Commits da Claude terminam com `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Antes de afirmar "funciona", rodar os testes (§4) e dizer o que **não** foi testado (ex.: in-game).

## 3. Caminhos

| O quê | Caminho |
|---|---|
| Dev (um repo git por mod) | `C:\Users\pedro\Zomboid\Workshop\<Mod>\` (layout `Contents/mods/<id>/...`, `workshop.txt`, `tests/`, `package.json`) |
| Docs (este repo git) | `C:\Users\pedro\Zomboid\Workshop\docs\` |
| Template | `C:\Users\pedro\Zomboid\Workshop\ModTemplate\` |
| Fontes antigas (pré-repo) | removidas; `C:\Users\pedro\Zomboid\mods\` só tem `examplemod` |
| Capas/artes (por mod) | `C:\Users\pedro\Documents\Codex\2026-10-17\estilo-base-colar-no-fim-de-2\outputs\zomboid-game-style-v2\` (subpastas `reduce-metal-and-wood`, `passive-skills`, `krjobs`, `vehicle-maintenance-v2`; `LEIA-ME.md`, `prompts.json`) |
| Jogo (vanilla para consulta) | `E:\SteamLibrary\steamapps\common\ProjectZomboid\media\lua` e `\media\scripts\generated` |
| Log do jogo | `C:\Users\pedro\Zomboid\console.txt` |

## 4. Padrão de testes (herdado do ReduceMetalWood)
1. `npm install` (devDeps `luaparse@0.3.1`, `fengari@0.1.4`) e `npm test` → `tests/run.js`: valida sintaxe de todos os `.lua` com luaparse e roda `*_spec.lua` em fengari.
2. Lógica pura isolada em módulos sem dependência do jogo; APIs do jogo (`SandboxVars`, `ZombRand`, inventário, BodyPart) mockadas.
3. In-game: iniciar com `-debug` e `-debugtranslation`; roteiro em `MANUAL_TEST.md` do repo.
4. Depois de jogar: `grep -iE "error|exception|stack trace|<prefixo do mod>" console.txt`.
5. MP: host + servidor dedicado local, 2 clientes.

---

## 5. Status final dos 5 mods (2026-10-17)

Todos os 5 mods estão **implementados, com `npm test` = ALL TESTS PASSED, e nenhum foi testado dentro do jogo**. O PZ carrega mods locais direto de `C:\Users\pedro\Zomboid\Workshop\<X>\Contents\mods\<Mod>\` (layout conferido abaixo); `C:\Users\pedro\Zomboid\mods\` só tem `examplemod` (as fontes v1 de PassiveSkills/KRjobs/VehicleMod foram removidas).

| Mod (nome / mod id) | Repo | Commit | Testes | Builds | Workshop id | Decisões |
|---|---|---|---|---|---|---|
| Reduce Metal&Wood v2 / `ReduceMetal&Wood50x` | `Workshop\ReduceMetalWood` | `0bde254` | PASS (core 32/32 + runtime B41/B42) | B41 + B42 | 3140965857 | este HANDOFF §5.1 + `MANUAL_TEST.md` |
| Passive Skills v2 / `Passiveskillskr` | `Workshop\PassiveSkills` | `39e710b` | PASS (core + glue, B41/B42) | B41 (24 skills) + B42 (33 skills) | 3477846890 | §5.2 abaixo |
| KRjobs v2 / `Krjobs` | `Workshop\KRjobs` | `47f771c` | PASS (inclui kits B41/B42) | B41 (20 prof.) + B42 42.13+ (24 prof.) | 3149644183 | `docs/DECISIONS-KRjobs.md` |
| Basic Vehicle Maintenance / `MoreVehiclesRepairs` | `Workshop\BasicVehicleMaintenance` | `2ec5ee7` | PASS (game_spec 60 checks + core) | só B42 (raiz B41 = stub mod.info) | 3643006111 | `docs/DECISIONS-Vehicle.md` |
| Field Medicine '93 / `KRFieldMedicine` | `Workshop\FieldMedicine` | `6bf70cc` | PASS (core + glue) | só B42 (sem raiz B41) | — (novo; `workshop.txt` sem id) | `docs/DECISIONS-Medical.md` |

**Layout conferido (todos):** `workshop.txt` + `preview.png` na raiz do repo; `Contents\mods\<Mod>\` com `common\` (traduções JSON EN/PTBR), `42\` (`mod.info` com `versionMin`, `media\`, `poster.png`, `icon.png`) e, quando há B41, `mod.info` + `media\` na raiz da pasta do mod.

**Auditoria de conflitos entre os 5 (estática, 2026-10-17) — nenhum conflito real encontrado:**
- Mod ids distintos. Nenhum arquivo `.lua` com o mesmo caminho relativo em dois mods (cada um usa pasta própria: `ReduceMetalWood/`, `PassiveSkills/`, `KRjobs/`, `MVR/`, `KFM/`; TimedActions `MVR_RepairAction.lua` / `KFM_ProcedureAction.lua`). Arquivos de mesmo nome são só os que o jogo mescla por mod (`sandbox-options.txt`, `Translate/*/*.json|txt`, `mod.info`).
- Globais Lua distintos: `MVR`, `MVR_RepairAction`, `MVR_InspectAction`, `KFM`, `KFM_ProcedureAction`, `KRjobsB41` (resto é `local`).
- Wraps de vanilla: cada função é embrulhada por um único mod e todos chamam o original — `ISReadABook.new/isValid/complete|perform` (PassiveSkills), `ISHealthPanel.doBodyPartContextMenu` (FieldMedicine), `ISVehicleMechanics.doPartContextMenu` (BVM); todos com guarda contra dupla instalação ou pcall.
- Sandbox: páginas/prefixos `ReduceMetalWood`, `PassiveSkills`, `MVR`, `KFM` — sem repetição. Chaves de tradução sem colisão (só `name`/`description` dos `Mod.json`, que são por mod).
- Itens/receitas/traços: `Base.Magazine<Skill>_<n>` (PassiveSkills), `Base.KFM_ImprovisedTourniquet` + `KFM_MakeImprovisedTourniquet` (FieldMedicine), `krjobs:<id>` (KRjobs) — nenhum colide entre si nem com o vanilla 42.19.2.
- ReduceMetalWood só mexe em itens com DisplayCategory `Material`/`MaterialWeapon`: revistas (`SkillBook`), torniquete (`FirstAid`) e kits KRjobs (itens vanilla de ferramenta/roupa) **não** são afetados. Os insumos vanilla da receita do torniquete (galho/vara) ficam mais leves, como esperado.
- Integração soft: FieldMedicine dá bônus a `krjobs:surgeon` (existe); `krjobs:paramedic/militarymedic/nurse` não existem no KRjobs — inofensivo.

### 5.1 ReduceMetalWood — riscos não verificados
- Aplicação de peso via eventos (`OnInitGlobalModData` / `OnServerStarted` / `OnGameStart`) em MP dedicado; itens de outros mods carregados depois. Roteiro: `MANUAL_TEST.md`.

### 5.2 PassiveSkills — decisões [PROPOSTA] e riscos
- Decisões da Claude (validar com o usuário): XP 75/150/300/750/1500 sem multiplicador + sandbox `XpPercent` (100); `SpawnChance` 12% via `OnFillContainer` (1 revista por contêiner elegível, pesos 40/25/18/11/6%); páginas 10–30; leitura 1× por personagem em `player:getModData().PassiveSkills`; registro global da v1 não migrado; `MagazineWelding_*` legado = MetalWelding; fonte única `tools/data.js` → `npm run gen`.
- Riscos: persistência do modData do jogador no servidor B42 após restart; `addXpNoMultiplier` vs. multiplicador global; B41 `AddXPNoMultiplier`, `HaloTextHelper`, `ignoreAction`; item criado em `OnFillContainer` no servidor chegar ao cliente; modelos `Magazine`/`MagazineGround` no B41.

### 5.3 KRjobs — riscos
- Receitas validadas contra 42.19.2 (renomeação na 42.21 → RuntimeException no boot); B41 só contra fixtures; kits agora são autoritativos: `giveKits` retorna no cliente e grava progresso por item; recuperação automática de entrega parcial está em revisão nesta branch; ícones por nome em `media/textures` no B42; 13 profissões com ícone placeholder vanilla (prompts em `docs/ICON-PROMPTS.md`).

### 5.4 Basic Vehicle Maintenance — riscos
- `type = double` no sandbox; `SyncPlayerStatsPacket.getBitMaskForStat`; ação de inspeção só-cliente no MP; `transmitPartModData`; serialização de `VehiclePart` + string + boolean nos argumentos da ação; nada testado na 42.21.

### 5.5 Field Medicine '93 — riscos
- Servidor recriar `KFM_ProcedureAction` (BodyPart, nil, procId); `setBleedingTime(0)` por minuto segurar o sangramento; escalas de `woundInfectionLevel`/PANIC/TEMPERATURE; formato do id de profissão para o bônus KRjobs; modData no servidor após restart; `type = double/boolean` e `mode:destroy`; precisa de Workshop id novo no primeiro upload.

### 5.6 Plano de teste in-game unificado
1. Preparar: jogo em **42.21** (ou 42.19.2 local), iniciar com `-debug -debugtranslation`. Apagar/renomear `C:\Users\pedro\Zomboid\console.txt` antes.
2. Menu Mods: ativar **os 5 juntos** nesta ordem — ReduceMetalWood, PassiveSkills, KRjobs, Basic Vehicle Maintenance, Field Medicine '93. Conferir nome/descrição/pôster de cada um em EN e PT-BR.
3. **Novo save** (Apocalypse, sandbox): conferir as páginas de sandbox `ReduceMetalWood`, `PassiveSkills`, `MVR`, `KFM` (textos traduzidos, sem `Sandbox_...` cru).
4. Checagens por mod:
   - **ReduceMetalWood**: Plank, Log, Nails, SheetMetal, MetalBar com ~50% do peso vanilla; martelo, serra, revistas e torniquete com peso normal.
   - **PassiveSkills**: spawnar `Base.MagazineCarving_one` (debug), ler → XP + fala; ler de novo → "já li"; achar revistas em estantes/mesas.
   - **KRjobs**: criação de personagem lista as 24 profissões com ícone, descrição e custo; escolher Cirurgião → kit (bisturi, pinça, porta-agulha) só uma vez; testar uma com receitas (Serralheiro).
   - **BVM**: veículo danificado → Mecânica → clique na peça → opções de reparo improvisado + inspeção; consertar uma peça; conferir XP e consumo de materiais.
   - **Field Medicine**: Painel de Saúde → clique numa parte → exame, irrigação, torniquete (aplicar/remover), cauterização, redução de fratura, debridamento; craftar torniquete improvisado; com o Cirurgião KRjobs conferir o bônus.
5. Salvar, sair, recarregar: kits não repetem, revistas lidas continuam lidas, torniquete/histórico de remendo persistem.
6. MP: host + 1 cliente (depois servidor dedicado) repetindo PassiveSkills, BVM e Field Medicine.
7. Log: `grep -inE "error|exception|stack trace|attempted index|\[ReduceMetalWood\]|\[PassiveSkills\]|\[MVR\]|\[KFM\]|KRjobs|krjobs:|Passiveskillskr|KRFieldMedicine|MoreVehiclesRepairs|RuntimeException|missing translation" C:\Users\pedro\Zomboid\console.txt`.

### 5.7 Próximos passos
1. **Atualizar o jogo para 42.21** e reler o vanilla (receitas KRjobs, `ISHealthPanel`, `ISVehicleMechanics`, `ISReadABook`, formato de sandbox) antes do teste.
2. Rodar o plano §5.6 (SP depois MP); corrigir o que aparecer no `console.txt`, rodar `npm test` e commitar por repo.
3. Validar com o usuário as [PROPOSTA] de PassiveSkills e as decisões dos `DECISIONS-*.md`.
4. **Ícones próprios**: gerar as 13 profissões KRjobs e a capa do Field Medicine com `docs/ICON-PROMPTS.md`; substituir os placeholders em `tools/data.js` do KRjobs → `npm run gen` → `npm test`.
5. **Upload no Workshop pelo uploader do jogo** (menu principal → Workshop → selecionar `Workshop\<X>`): os 4 com id fazem update; Field Medicine '93 cria item novo e o id gerado deve ser gravado no `workshop.txt` e commitado.
6. Depois do upload: assinar pela Steam numa instalação limpa e repetir um teste rápido com os 5 juntos.

---

## 6. Registro de decisões

| Data | Mod | Decisão | Tipo | Quem |
|---|---|---|---|---|
| 2026-10-17 | Todos | PT-BR + EN obrigatório | DECIDIDO | usuário |
| 2026-10-17 | Todos | Ordem: ReduceMetal → PassiveSkills → KRjobs → Vehicle v2 → Medical | DECIDIDO | usuário |
| 2026-10-17 | Todos | Test-driven; zero conflitos/erros | DECIDIDO | usuário |
| 2026-10-17 | ReduceMetalWood | Concluído (commit 0bde254); falta teste in-game | DECIDIDO | usuário |
| 2026-10-17 | PassiveSkills | Spawn 10–15%; XP em todas as skills; Say após ler; 1× por personagem; 5 revistas ≈ nível 5 | DECIDIDO | usuário |
| 2026-10-17 | PassiveSkills | Revistas para skills faltantes (exceto Fitness/Strength): +13 skills (lista em §5.2); B41 só skills existentes no B41 | DECIDIDO | usuário |
| 2026-10-17 | PassiveSkills | v2 concluída (a8c78ba/39e710b); fonte v1 apagada; falta teste in-game | DECIDIDO | usuário |
| 2026-10-17 | PassiveSkills | XP sem multiplicador (todos ganham igual) + sandbox XpPercent; SpawnChance 12% via OnFillContainer; pesos 40/25/18/11/6; páginas 10–30; registro v1 não migrado; Welding legado = MetalWelding | PROPOSTA | Claude |
| 2026-10-17 | KRjobs | B42 via scripts + registries.lua; profissões 90s incomuns; balanceado; skills B42; traits por profissão | DECIDIDO | usuário |
| 2026-10-17 | Vehicle v2 | Nova versão muito melhorada do item 3643006111; corrigir lista de bugs da v1 | DECIDIDO | usuário |
| 2026-10-17 | Medical | Mod irmão, complementa vanilla, não OP, sinergia KRjobs | DECIDIDO | usuário |
| 2026-10-17 | Vehicle v2 / Medical | Conteúdo detalhado dos PRDs | PROPOSTA | Claude |
| 2026-10-17 | Todos | Os 5 mods implementados (testes passam); auditoria estática de conflitos sem problemas; plano de teste unificado em §5.6; prompts de ícones em `ICON-PROMPTS.md` | PROPOSTA | Claude |

## 7. Perguntas abertas prioritárias (consolidado)
1. PassiveSkills: validar as PROPOSTAS de §5.2 (XP sem multiplicador vs. respeitar profissão; não migrar registro v1; pesos de volume; nomes PT vanilla como "Caça"/"Discrição").
2. Vehicle v2: nome no Workshop ("More Vehicles Repairs" vs "Basic Vehicle Maintenance")?
3. Vehicle v2: falha grave −20 de condição (proposto) ou "vai a 0" como na v1?
4. Medical: nome/mod id e se o exame pode mostrar febre (ambígua quanto a Knox)?
5. B41: Vehicle v2 e Medical em versão reduzida (proposto) ou só B42?
6. KRjobs: lista final de profissões e quais terão bônus nos mods Vehicle/Medical.


## 8. Revisão Codex — rotina de 17/10/2026 às 19h30

- Cinco mods e este repo docs agora estão em `fix/codex-review-20261017`, com mudanças locais **ainda sem commit**. Os HEADs-base da tabela anterior foram preservados.
- Corrigidos: reparo/inspeção do Engine intrínseco sem InventoryItem; WeldingRods fora da redução por getter ausente; flag de infecção inconsistente após debridamento; exame executando mesmo com ExamEnabled=false.
- Testes de regressão foram executados antes: Reduce 3 checks falhando por build, BVM 5, medicina 2. Depois da correção, os cinco runners `node tests/run.js` passaram.
- BVM agora tem Mod.json EN/PTBR. Descrições de todos os mods, fontes geradoras e workshop.txt atualizados; entradas B41 têm descrição bilíngue. Removidas garantias públicas de MP/saves não comprovadas.
- versionMin B42 foi corrigido para 42.15 nos cinco mods por depender de tradução JSON. Não é certificação de todas as versões intermediárias. Jogo local continua 42.19.2; falta validação em 42.21.
- PRD-Medical.md e PRD-VehicleMaintenance-v2.md reconciliados com a entrega B42-only e acrescidos de critérios de aceite e dependências na seção 15. Features/números propostos não se tornam aprovados pelo fato de já terem código.
- Nenhum teste real em jogo, nenhuma publicação Workshop e nenhuma arte substituída nesta rotina.
- Pacote de passagem, PRDs revisados, descrições, logs e patches: C:\Users\pedro\Documents\Codex\2026-10-17\estilo-base-colar-no-fim-de-2\outputs\revisao-mods-2026-10-17.
- Claude: ler REVISAO-E-PASSAGEM.md desse pacote antes de continuar. **Não reaplicar os patches** nas árvores atuais; as alterações já estão aplicadas. Revisar/commitar por repo e executar testes SP/host/dedicado com dois clientes.

## Continuação Codex — comportamento e recuperação

Corrigida validação de ferramentas/materiais na medicina (11 checks de regressão), identidade da peça do veículo durante fila/reconstrução (3 checks; 70 checks glue atuais), fila duplicada e recuperação de XP do PassiveSkills (8 checks por build). Os cinco runners passaram novamente após esta rodada. Revisão adicional dos diffs não encontrou regressão concreta. Nenhum teste real de jogo/MP pelo Codex. Consulte o pacote outputs/revisao-mods-2026-10-17/CONTINUACAO-OFFLINE.md e tests-offline-after.json. A frente de APIs42.21 e smoke test de servidor continua com Claude; não há confirmação de conclusão nesta entrada.

## Checagem API 42.21 (Claude, 17/10/2026)

- Lua B42 + scripts dos 5 mods checados contra stubs PZ-Umbrella `42.21.0` (diff vs `42.19.0`) e patch notes 42.21 (wiki + fórum 101693). Detalhes: `docs/API-CHECK-42.21.md`.
- **0 quebras confirmadas**: nenhum evento/enum/global/método usado sumiu ou mudou de forma incompatível; `ItemKey` 42.21 idêntico ao 42.19 (sem renomeação de itens). Nenhum commit de código; `npm test` passa nos 5.
- Checagem feita sobre as árvores de trabalho atuais (incluindo mudanças Codex ainda sem commit).
- Pré-existente: `Item:getMetalValue` não existe no Item de script B42 (ReduceMetalWood, em `pcall`, regra MetalValue inerte).
- 6 incertos para o boot 42.21 (agora RuntimeException em receita/tradução ausente): 57 `GrantedRecipes` do KRjobs, campos da craftRecipe do KFM, ícones por nome, `tostring` de profissão/trait no KFM, `getText` varargs, MetalValue.

## Encerramento do acompanhamento Codex
As seis verificações automáticas terminaram em 17/10/2026, após cerca de uma hora. Nenhuma prorrogação. Confirmei no log isolado o carregamento dos cinco mods e os contadores RMW de 148 itens com redução50%, sem reaplicar no OnServerStarted. Não há SMOKE-TEST.md ou confirmação final do Claude; não é certificação de gameplay/MP/42.21. Relatório: C:/Users/pedro/Documents/Codex/2026-10-17/estilo-base-colar-no-fim-de-2/outputs/revisao-mods-2026-10-17/ENCERRAMENTO-ACOMPANHAMENTO.md. Alterações locais preservadas; não reaplicar patches.

## Atualização do monorepo — 21/10/2026

O relatório SMOKE-TEST.md foi recebido após a importação e seus logs foram conferidos independentemente. Confirma inicialização dos cinco mods em 42.19.2 e correção do excesso de traces de getMetalValue; a correção já estava na cópia do monorepo. Isso resolve a ausência do relatório, não os testes de cliente/SP/MP/42.21. Os cinco runners passaram sobre os arquivos importados em 21/10; nenhum runtime mudou neste complemento. Veja IMPORTACAO-2026-10-21.md e smoke-log-verification-2026-10-21.json.
