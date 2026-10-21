# PRD — Basic Vehicle Maintenance v2 (More Vehicles Repairs)

> Documento autocontido para revisão e co-trabalho entre IAs (Claude / ChatGPT) e o dono dos mods.
> Legenda obrigatória em todo o documento:
> - **[DECIDIDO]** = Decidido pelo usuário (não alterar sem perguntar).
> - **[PROPOSTA]** = Proposta (validar com usuário). Números são chutes iniciais calibráveis.
> - **[FATO-VANILLA]** = verificado lendo o código vanilla do jogo local (42.19.2).

Data: 2026-10-17 · Autor do mod: Kriger (usuário) · Redação: Claude · Revisão de entrega: Codex (17/10/2026)

---

## 0. Identidade

| Campo | Valor |
|---|---|
| Nome público atual | Basic Vehicle Maintenance (mod id MoreVehiclesRepairs preservado; registro ORQ) |
| Workshop ID | **3643006111** [DECIDIDO — é uma nova versão do mesmo item] |
| mod id | `MoreVehiclesRepairs` [PROPOSTA — manter para não quebrar saves/servidores] |
| Fonte anterior (v1) | Código legado substituído; não usar a antiga pasta Zomboid/mods/VehicleMod como fonte atual |
| Dev v2 atual | C:/Users/pedro/Zomboid/Workshop/BasicVehicleMaintenance/ |
| Capa/arte | `C:\Users\pedro\Documents\Codex\2026-10-17\estilo-base-colar-no-fim-de-2\outputs\zomboid-game-style-v2\vehicle-maintenance-v2` |
| Mod irmão | `PRD-Medical.md` (mesma filosofia "gambiarra realista com risco", foco em saúde) |

---

## 1. Visão / Porquê

No vanilla, consertar veículo depende de **peça reserva** ou de receitas `fixing` específicas (solda + chapa, etc.), que cobrem só parte das peças. No fim de jogo o carro "morre" por falta de peça, não por falta de habilidade. A v1 trouxe o "Casual Repair": consertar qualquer peça com sucata, com teto de condição e risco de quebra.

A v2 transforma isso num **sistema de manutenção** coerente com o realismo do PZ e com os anos 90:
1. **Saber antes de mexer** (inspeção/diagnóstico com habilidade).
2. **Consertar com o que tem** (gambiarra: teto baixo, risco) **ou do jeito certo** (oficina, ferramentas, peças improvisadas fabricadas).
3. **Aprender fazendo** (XP de Mecânica, sem farm).
4. **Funcionar perfeitamente em MP** (autoridade no servidor, padrão B42.13+).

Regra central: **complementar, nunca substituir o vanilla**. Instalar/desinstalar, `fixing` vanilla e "Reparar motor" com EngineParts continuam sendo o caminho "bom"; o nosso é o caminho "possível".

---

## 2. Público

- Jogador solo B42 em runs longas, que fica sem peças.
- Servidores MP (PT-BR e EN): precisa ser à prova de dessync e de exploit.
- A entrega atual é B42 apenas; a entrada B41 é informativa e não adiciona gameplay.
- [PROPOSTA] Jogadores de KRjobs: profissões ligadas a mecânica ganham bônus via hook opcional (§6.8).

---

## 3. Objetivos

| # | Objetivo | Métrica de sucesso |
|---|---|---|
| O1 | Zero erro Lua no `console.txt` em SP, host e servidor dedicado | grep `ERROR`/`STACK TRACE` = 0 em 3 cenários [DECIDIDO "sem conflitos/erros"] |
| O2 | 100% do texto em PT-BR + EN [DECIDIDO — regra de ouro] | `-debugtranslation` sem chaves faltando |
| O3 | Toda mudança de item/condição feita no servidor | teste MP com 2 clientes sem dessync de inventário |
| O4 | Todo conserto tem trade-off (tempo, material, risco, teto) | nenhuma peça chega a 100 só com gambiarra |
| O5 | Progressão: nível 0 consegue remendar; nível 8+ faz manutenção quase profissional | curvas da §6 cobertas por teste unitário |
| O6 | Tudo configurável via Sandbox | constantes de balanceamento em `sandbox-options.txt` |

## 4. Não-objetivos

- Não adicionar veículos, modelos 3D ou peças com modelo novo.
- Não mudar física/dirigibilidade além do que a condição vanilla já faz.
- Não reescrever a UI de mecânica vanilla (`ISVehicleMechanics`); só **estender** menu de contexto e tooltip.

## 5. Anti-objetivos (o que NÃO pode acontecer)

- **Ser OP**: gambiarra nunca leva a 100% e nunca supera a peça nova vanilla.
- **Sobrepor o vanilla**: não duplicar "Reparar motor", "Tirar peças do motor", `fixing` de solda. Se existe reparo vanilla possível com os itens que o jogador carrega, o tooltip avisa.
- **Farm de XP**: repetir conserto na mesma peça não dá XP infinito.
- **Quebrar saves**: chaves de modData estáveis; remover o mod não corrompe veículo.
- **Lógica autoritativa no cliente** (a v1 fazia efeitos via `getSpecificPlayer(0)` no cliente).
- **Depender de API inexistente no 42.19/42.21** (ver §7.1).
- Criar um sistema paralelo de "desgaste por km" que brigue com o vanilla.

---

## 6. Features priorizadas

### 6.0 Resumo

| Prioridade | Feature | Status |
|---|---|---|
| MVP | F1 Correção de todos os bugs da v1 | [DECIDIDO — lista de bugs do usuário] |
| MVP | F2 Reparo Improvisado reescrito (server-side, data-driven) | [DECIDIDO existência] / números [PROPOSTA] |
| MVP | F3 XP de Mecânica com anti-farm | [DECIDIDO "sem XP" é bug] / regra [PROPOSTA] |
| MVP | F4 Materiais em bolsas (busca recursiva) + tooltip `<LINE>` | [DECIDIDO bug] |
| MVP | F5 Traduções PT-BR/EN + Sandbox | [DECIDIDO] |
| MVP | F6 Compatibilidade da entrega | B42 apenas; raiz B41 informa a limitação, conforme registro ORQ |
| v1.1 | F7 Inspeção / Diagnóstico + histórico de remendos | [PROPOSTA] |
| v1.1 | F8 Bônus de oficina (garagem/bancada/luz/macaco) | [PROPOSTA] |
| v1.1 | F9 Faixas de qualidade (Remendo / Reparo / Revisão) + gating por skill | [PROPOSTA] |
| Futuro | F10 Peças improvisadas fabricáveis (`craftRecipe` B42) | [PROPOSTA] |
| Futuro | F11 Revista/manual de manutenção (sinergia PassiveSkills) | [PROPOSTA] |
| Futuro | F12 Hooks para KRjobs | [PROPOSTA] |

### 6.1 F1 — Bugs da v1 [DECIDIDO]

| Bug | Causa (lida no código v1) | Correção v2 |
|---|---|---|
| Crash nil no servidor para Headlight | `CasualRepairServer.lua` usa `config.conditionCap` sem checar nil (`getConfigForPart` retorna nil para `notRepairable`) | checar nil → `reason="not_repairable"` |
| Dessync MP de inventário | `inventory:Remove()` no servidor sem notificar cliente | `Remove` + `sendRemoveItemFromContainer(inv, item)` [FATO-VANILLA: `ISSplint:complete`]; drenáveis com `UseAndSync()` |
| `SetScratchedWindow` não existe no 42.19 | API inventada | `bodyPart:setScratched(true, true)` ou `bodyPart:setCut(true)` [FATO-VANILLA: `Tutorial/Steps.lua`, `Trailer2_LimpWPScenario.lua`] |
| `setBurned()` não existe | API inventada | `bodyPart:setBurnTime(x)` + `setNeedBurnWash(true)` [FATO-VANILLA: ambos usados em vanilla]; x proposto 10–20 |
| `get/setUnhappyness` não existe | API B41 | `getStats():add(CharacterStat.UNHAPPINESS, v)` [FATO-VANILLA: `ISInventoryTransferAction` usa `rate/100`] — **validar escala (0–1 vs 0–100) em debug** |
| Efeitos só no cliente, via `getSpecificPlayer(0)` | não autoritativo; quebra splitscreen | efeitos no `complete()` com `self.character` + `syncBodyPart`/`syncPlayerStats` |
| Só inventário principal | `inventory:getItems()` | busca `...Recurse` (`getFirstTypeRecurse`, `getCountTypeRecurse`, `getFirstTagEvalRecurse`) e transferência prévia para o inventário principal (padrão `ISVehiclePartMenu.toPlayerInventory`) [FATO-VANILLA] |
| Chances hardcoded (10%, 5%) | literais em 2 arquivos | config + sandbox |
| Sem XP de Mecânica | — | F3 |
| Tooltip usa `\n` | `ISToolTip` é rich text | ` <LINE> ` e `<RGB:r,g,b>` (ver `ISVehicleMechanics.ghs/bhs`) [FATO-VANILLA] |
| Helpers duplicados em 3 arquivos | countItem/hasItem/consume/computeNewCondition | módulo único `shared/MVR/Core.lua` (lógica pura testável) |
| Raiz B41 vazia | só `mod.info` + imagem | F6 |
| Texto hardcoded em EN | `"Casual Repair"`, `Say("Ouch...")` | `getText("IGUI_MVR_...")` |
| Ferramenta exata `Base.PipeWrench` | exclui chaves equivalentes | usar tags `ItemTag.WRENCH` / `ItemTag.SCREWDRIVER` com predicado "não quebrado" [FATO-VANILLA: `ISVehicleMechanics:getWrench`] |
| Desgaste de ferramenta −30 | escala errada (condição de item vanilla é ~0–10/15) | −1 a −3 + `sendItemStats(item)` |

### 6.2 F2 — Reparo Improvisado (núcleo)

Fluxo [PROPOSTA]:
1. Clique direito na peça (janela de mecânica) → `Reparo improvisado` (com submenu de faixas se F9 ativo).
2. Tooltip: materiais (verde/vermelho, contando bolsas), ferramentas, ganho, teto, chance de falha **já ajustada pela skill**, tempo, aviso "existe reparo vanilla" quando `FixingManager.getFixes(part:getInventoryItem())` tem opção viável.
3. Ação: `ISPathFindAction:pathToVehicleArea` [FATO-VANILLA] → abre capô se for motor (como `onRepairEngine`) → transfere itens → TimedAction.
4. `complete()` (servidor ou SP): revalida, consome com sync, rola resultado, `setCondition`, `vehicle:transmitPartCondition(part)`, XP, efeitos.

Resultado (rolagem única) [PROPOSTA]:

| Resultado | Chance | Efeito |
|---|---|---|
| Sucesso crítico | 5% + 0,5 p.p./nível de Mecânica | ganho ×1,5 (respeita teto) |
| Sucesso | restante | ganho normal |
| Falha leve | 60% da chance de falha | material perdido, condição −5 (mín. 1) |
| Falha grave | 40% da chance de falha | condição −20 (mín. 0). Substitui o "vai a 0" da v1, punitivo demais |

Fórmulas [PROPOSTA]:
```
falha = clamp(base_peça − 0,025 × max(0, Mecânica − 1) − bônusOficina, 0,03, 0,60) × SandboxFailMult
ganho = round(ganhoBase × (1 + 0,05 × Mecânica) × SandboxGainMult)
teto  = min(75, tetoBase + 2 × Mecânica − 3 × remendosAnteriores + SandboxCapOffset)   (mín. 30)
novo  = min(teto, atual + ganho)   — em sucesso nunca reduz a condição
```
Exemplo: Freio, Mecânica 0 → falha 20%, ganho 15, teto 55. Mecânica 8 → falha 2,5%→3% (piso), ganho 21, teto 71.

Tabela de peças [PROPOSTA — herdada da v1 com ajustes; tempo em ticks]:

| Config | Materiais | Ferramentas (tag) | Ganho | Teto base | Falha base | Tempo | Calor |
|---|---|---|---|---|---|---|---|
| Engine | ScrapMetal 4, SheetMetal 1, Screws 4, DuctTape 2 | Wrench, Screwdriver | 15 | 50 | 25% | 450 | sim |
| Brake | ScrapMetal 3, RippedSheets 2, DuctTape 1 | Wrench | 15 | 55 | 20% | 250 | não |
| Suspension | ScrapMetal 3, Wire 2, Screws 4, DuctTape 1 | Wrench | 15 | 55 | 20% | 280 | não |
| Tire | DuctTape 2, Glue 1 | — | 12 | 45 | 15% | 200 | não |
| Door / Hood(EngineDoor) / TrunkLid(TrunkDoor) | SheetMetal 2 (ou SmallSheetMetal 4), Screws 4, DuctTape 1 | Screwdriver | 15 | 60 | 12% | 200 | não |
| Window / Windshield | RippedSheets 3, DuctTape 2 | — | 10 | 35 | 30% | 150 | não |
| Muffler | SheetMetal 1, ScrapMetal 2, Wire 2, DuctTape 1 | Wrench | 15 | 50 | 20% | 240 | sim |
| GasTank | SheetMetal 2, ScrapMetal 2, Glue 2, DuctTape 2 | Wrench, Screwdriver | 12 | 45 | 25% | 320 | sim |
| Battery | ElectronicsScrap 3, ElectricWire 2, DuctTape 1 | Screwdriver | 12 | 45 | 30% | 220 | não |
| Seat | LeatherStrips 3 (ou RippedSheets 4), Thread 1 | Needle | 15 | 70 | 10% | 180 | não |
| Radio | ElectronicsScrap 2, ElectricWire 2, Screws 2 | Screwdriver | 12 | 45 | 35% | 220 | não |
| Luzes (Headlight etc.) | **não reparável** — lâmpada se troca [DECIDIDO na v1]. v2: opção desabilitada com tooltip "substitua a lâmpada", sem crash | — | — | — | — | — | — |
| Default (cosméticos) | ScrapMetal 2, DuctTape 1 | Screwdriver | 12 | 50 | 20% | 200 | não |

Materiais aceitam substitutos (lista ordenada; ex.: `SheetMetal 1` ou `SmallSheetMetal 2`) [PROPOSTA]. Aliases de ID de peça mantêm a ordem "mais específico primeiro" da v1 (EngineDoor antes de Door).

Efeitos colaterais (no servidor) [PROPOSTA]:

| Evento | Chance base | Efeito |
|---|---|---|
| Corte na mão | 5% − 0,4 p.p./nível; luvas −50% | `setScratched(true,true)` (70%) ou `setCut(true)` (30%) em Hand_L/Hand_R + `syncBodyPart` |
| Queimadura | 4% só com calor; luvas −75% | `setBurnTime(10–20)` + `setNeedBurnWash(true)` |
| Desgaste de ferramenta | 15% | condição −1..−3 + `sendItemStats` |
| Desperdício | 10% | +1 unidade de um material |
| Frustração | 10% (só em falha) | UNHAPPINESS +5 (escala a validar) |

### 6.3 F3 — XP de Mecânica [PROPOSTA]
- Sucesso 3 XP, crítico 5 XP, falha 1 XP ("aprende errando"), × `SandboxVars.MVR.XPMultiplier`.
- Anti-farm com a API vanilla `chr:addMechanicsItem(key, part, millis)` / `chr:getMechanicsItem(key)` [FATO-VANILLA: `ISRepairEngine`, `ISInstallVehiclePart`]. Chave: `vehicle:getMechanicalID() .. part:getId() .. "MVR"`. XP cheia 1× por peça/veículo a cada 24h de jogo; senão 0.

### 6.4 F4 — Inventário e tooltip [DECIDIDO bug]
Busca recursiva em bolsas equipadas; antes de agir, enfileirar transferência para o inventário principal. Tooltip rich text com cores vanilla.

### 6.5 F7 — Inspeção / Diagnóstico (v1.1) [PROPOSTA]
O vanilla já mostra a condição % de todas as peças, então a inspeção **não esconde números**; ela entrega o que o vanilla não dá:
- Ação "Inspecionar veículo" (300 ticks, exige luz: lanterna ou ambiente). Resultado em painel/tooltip: peças < 25%, quais têm reparo vanilla possível com os itens atuais, quantos remendos cada peça já recebeu, risco do próximo remendo.
- **Histórico de remendos** em `part:getModData().MVR = { patches = n, last = "patch" }`: cada remendo reduz o teto em 3 (mín. 30), incentivando trocar a peça. Peça nova instalada (item diferente) zera o histórico.
- Mecânica ≥ 4: mostra chance exata; < 4: faixa ("baixa/média/alta").

### 6.6 F8 — Bônus de oficina (v1.1) [PROPOSTA]
- Interior/garagem (square com teto): falha −3 p.p.
- Bancada/mesa de trabalho num raio de 3 tiles: falha −3 p.p., tempo −10% (**validar quais objetos/propriedades B42 identificam bancada**).
- `Base.Jack` no inventário (Tire/Brake/Suspension): tempo −15%.
- Escuro sem lanterna: falha +5 p.p.
- Soma de bônus limitada a −8 p.p.

### 6.7 F9 — Faixas de qualidade e gating (v1.1) [PROPOSTA]

| Faixa | Requisito | Teto | Materiais | Tempo |
|---|---|---|---|---|
| Remendo | Mecânica 0 | teto base | tabela §6.2 | 1× |
| Reparo | Mecânica 3 (+ Metalurgia 2 se calor) + garagem ou macaco | +10 | ×1,5 | 1,5× |
| Revisão | Mecânica 6 (+ Elétrica 3 em Battery/Radio; Metalurgia 4 + BlowTorch se calor) | +20 (máx. 80) | ×2 | 2× |

### 6.8 Futuro [PROPOSTA]
- F10 Peças improvisadas via `craftRecipe` B42 (ex.: "Pastilha de freio improvisada", "Remendo vulcanizado de pneu"): usadas no reparo dão +5 de teto. Validar sintaxe em `media/scripts/generated/recipes`.
- F11 Revista "Manual de Manutenção Automotiva '93" (integração com PassiveSkills ou receita concedida).
- F12 KRjobs: API pública `MVR.registerProfessionBonus(professionId, { failReduction = 0.05, xpMult = 1.2 })`. Soft dependency (nunca `require` obrigatório).

---

## 7. Arquitetura técnica

### 7.1 APIs vanilla verificadas no 42.19.2 [FATO-VANILLA]
- `ISVehicleMechanics:doPartContextMenu(part, x, y)` cria `self.context`; hook pós-original (como a v1) continua válido. Ele sai cedo se o jogo está pausado ou o jogador está dentro do veículo (não-admin).
- TimedAction B42: `isValid / waitToStart / start / update / stop / perform / complete / getDuration`. **`complete()` é onde muda item/condição** (roda no servidor em MP). Ex.: `ISFixVehiclePartAction:complete()` → `setCondition`, `doInventoryItemStats`, `updatePartStats`, `transmitPartItem`.
- Sync: `sendRemoveItemFromContainer`, `sendAddItemToContainer`, `item:UseAndSync()`, `sendItemStats(item)`, `syncBodyPart(bp, flags)`, `syncPlayerStats(chr, flags)`, `addXp(chr, Perks.Mechanics, n)`.
- Stats: `getStats():add/set(CharacterStat.X, v)`.
- `fixing` de veículo vanilla em `media/scripts/generated/vehicles/vehiclesfixing.txt` (10 receitas, ex.: "Fix Gas Tank Welding" com BlowTorch + SheetMetal, MetalWelding 3 / Mechanics 2).
- Hooks Lua de peças: `Vehicles.Create.*`, `Vehicles.Init.*`, `Vehicles.Update.*` em `media/lua/server/Vehicles/Vehicles.lua` (não precisamos alterar).

### 7.2 Estrutura entregue
- shared/MVR/Config.lua: dados de peças e faixas.
- shared/MVR/Core.lua: fórmulas puras, consumo e histórico.
- shared/MVR/Game.lua: adaptador do jogo e avaliação comum ao cliente/servidor.
- shared/TimedActions/MVR_RepairAction.lua: ação autoritativa.
- client/MVR/Menu.lua: extensão do menu, inspeção e feedback.
- common/media/lua/shared/Translate/{EN,PTBR}/{Mod,ContextMenu,Tooltip,IG_UI,Sandbox}.json.
- tests/core_spec.lua e tests/game_spec.lua. A entrada raiz B41 não possui media/ de gameplay.


### 7.3 Migração v1 → v2
A v1 não grava modData → nada a migrar. Globais `MVR_RepairConfig` e `MVR_CasualRepairAction` somem; opcionalmente manter alias por 1 versão.

---

## 8. Sandbox options [PROPOSTA — página "Basic Vehicle Maintenance"]

| Chave | Tipo | Padrão | Faixa |
|---|---|---|---|
| MVR.Enabled | bool | true | — |
| MVR.MaterialCostMultiplier | double | 1.0 | 0.25–4 |
| MVR.ConditionGainMultiplier | double | 1.0 | 0.25–3 |
| MVR.CapOffset | int | 0 | −30..+20 |
| MVR.FailChanceMultiplier | double | 1.0 | 0–3 |
| MVR.SevereFailEnabled | bool | true | — |
| MVR.SideEffectsEnabled | bool | true | — |
| MVR.InjuryChanceMultiplier | double | 1.0 | 0–3 |
| MVR.XPMultiplier | double | 1.0 | 0–5 |
| MVR.TimeMultiplier | double | 1.0 | 0.25–3 |
| MVR.PatchHistoryEnabled | bool | true | v1.1 |
| MVR.WorkshopBonusEnabled | bool | true | v1.1 |
| MVR.QualityTiersEnabled | bool | true | v1.1 |

Leitura sempre via helper com fallback (`SandboxVars.MVR` pode ser nil em menus/testes).

---

## 9. Compatibilidade da versão entregue
- Build 42 apenas. A entrada raiz B41 é um aviso e não contém gameplay.
- versionMin=42.15 por depender de traduções JSON; padrão de TimedAction baseado no vanilla 42.19.2.
- Jogo-alvo para publicação: 42.21, ainda sem teste real desta revisão.
- Não anunciar suporte B41 funcional ou multiplayer validado.


## 10. Traduções [DECIDIDO PT-BR + EN]
- B42: `common/media/lua/shared/Translate/EN/*.json` e `PTBR/*.json` (JSON chave→texto; ver `Translate/EN/ContextMenu.json` vanilla). Arquivos: `IG_UI.json`, `ContextMenu.json`, `Sandbox.json`, `Tooltip.json`.
- B41: `media/lua/shared/Translate/EN/IGUI_EN.txt` (`IGUI_EN = { ... }`) e `PTBR/IGUI_PTBR.txt`, idem Sandbox/ContextMenu.
- Prefixos: `IGUI_MVR_`, `ContextMenu_MVR_`, `Sandbox_MVR_`, `Tooltip_MVR_`. Falas (`Say`) traduzidas com 2–3 variações.

## 11. MP / servidor (B42.13+)
- Item, condição, corpo, stats e XP mudam só em `complete()`; cliente monta menu e mostra feedback.
- `isValid()` revalida: distância ≤ 3 tiles da área da peça, peça instalada, itens presentes (no MP usar `containsID` como `ISStitch:isValid`).
- Feedback `Say`: validar se replica a partir do servidor; senão `sendServerCommand(player, "MVR", "feedback", { key = ... })`.
- Splitscreen: nunca `getSpecificPlayer(0)`; usar `self.character` / `playerNum`.

## 12. Plano de testes (test-driven) [DECIDIDO a abordagem]
1. **Sintaxe**: luaparse em todos os `.lua` (`npm test` → `tests/run.js`, igual ReduceMetalWood).
2. **Unitário (fengari)** em `Core.lua` com mocks (RNG determinístico, SandboxVars, peça/inventário falsos): limites da fórmula (0,03/0,60), ganho/teto, sucesso nunca reduz, histórico reduz teto e zera com peça nova, anti-farm, alias (EngineDoor→Hood antes de Door), luzes → "não reparável" sem nil, materiais substitutos.
3. **In-game SP** com `-debug -debugtranslation`: roteiro em `MANUAL_TEST.md` (cada peça, materiais na mochila, sem ferramenta, com luvas, no escuro, idioma PT-BR e EN).
4. **MP**: host + servidor dedicado local com 2 clientes; conferir inventário e condição dos dois lados.
5. **Log**: `grep -iE "error|exception|stack trace|MVR" "%UserProfile%\Zomboid\console.txt"` sem erros.
6. Regressão de conflito com mods populares de mecânica (lista a definir).

## 13. Riscos
| Risco | Mitigação |
|---|---|
| APIs mudarem entre 42.19 e 42.21 | reler vanilla na 42.21 antes do release |
| Escala de `CharacterStat` (0–1 vs 0–100) | medir em debug antes de fixar números |
| `Say` / feedback não replicar a partir de `complete()` | fallback `sendServerCommand` |
| Detecção de bancada/garagem frágil | v1.1, atrás de sandbox |
| Percepção de sobreposição com vanilla | tooltip aponta o reparo vanilla quando possível |
| Atualizar item Workshop existente muda comportamento de quem já usa | changelog claro + sandbox reproduz comportamento "clássico" |

## 14. Decisões e propostas ainda abertas
Consulte DECISIONS-Vehicle.md para os registros ORQ e as escolhas propostas por Claude. O resumo de entrega e os critérios adicionais na seção 15 distinguem implementação, proposta e evidência de teste. A revisão não presume aprovação humana adicional.


## 15. Revisão de entrega — Codex, 17/10/2026

Esta seção reconcilia o PRD com os arquivos entregues. “Implementado” significa presente no código e verificado pelos testes indicados; a validação no jogo continua pendente. As decisões identificadas como ORQ nos DECISIONS são registros recebidos do orquestrador, sem confirmação humana independente nesta revisão. Números de balanceamento e funcionalidades ainda marcados como proposta não passam a ser aprovados pela existência de código.

A revisão alterou somente correções confirmadas, testes e documentação. Nenhuma funcionalidade nova foi implementada por causa deste PRD. As descrições em inglês e português foram aplicadas nos arquivos locais; nada foi publicado no Workshop.

### Dependências e limites de versão

- Jogo instalado: 42.19.2, confirmado no console.txt e nas fontes locais. Alvo de publicação: 42.21; a atualização do jogo e a validação nessa versão continuam pendentes.
- Metadados B42: versionMin=42.15, por depender do formato de traduções JSON introduzido nessa versão. Esse limite técnico não equivale a certificação de cada versão intermediária.
- Testes de desenvolvimento: Node.js, luaparse 0.3.1 e fengari 0.1.4. Não são dependências distribuídas ao jogador.
- Integrações opcionais não podem exigir instalação de KRjobs, PassiveSkills ou do mod irmão. Carregar sozinho e em conjunto faz parte do aceite.
- Conteúdo e interface: PT-BR e EN; validar textos reais, placeholders e termos no menu, sandbox, feedback e relatórios.

### Portões de publicação

1. Suíte automatizada sem falhas; quaisquer correções devem ter reprodução anterior e teste posterior.
2. Novo save SP em 42.21 com os cinco mods juntos e cada um isolado: fluxos concluídos, inventário, estados e logs verificados.
3. Host e servidor dedicado com dois clientes: efeitos autoritativos, consumo correto, feedback ao jogador certo, sem duplicação e sem estados divergentes.
4. Salvar/reiniciar/reconectar: estados persistentes não se perdem nem se duplicam.
5. Limitar logs ao intervalo do teste; registrar versão, mods ativos, cenário e falhas. Não apagar logs anteriores como pré-requisito.
6. Descrições públicas não devem afirmar “multiplayer seguro”, ausência total de conflitos ou compatibilidade testada em versões que não foram executadas.

### Fontes

- Fontes Lua/scripts instaladas em E:\SteamLibrary\steamapps\common\ProjectZomboid.
- [Migração oficial de traduções 42.15](https://theindiestone.com/forums/topic/92433-modding-migration-guide-4215/).
- [Versão atual no site oficial](https://projectzomboid.com/blog/support/).


### Escopo implementado e critérios de aceite

| ID | Critério verificável | Evidência nesta revisão |
|---|---|---|
| VEH-01 | Engine vanilla, que não possui InventoryItem, recebe menu, avaliação, ação e inspeção | Seis regressões adicionadas: cinco falharam antes; todas passaram depois |
| VEH-02 | Porta/peça removível ausente continua recusada; lâmpadas exigem substituição | Regressões e suíte existentes passaram |
| VEH-03 | Remendo/Reparo/Revisão respeitam requisitos, materiais e tetos máximos 75/78/80 | Core e glue passaram |
| VEH-04 | Materiais em bolsas contam e são consumidos exatamente uma vez; drenáveis gastam usos corretos | Glue passou; replicação real pendente |
| VEH-05 | Reparo do motor consome 4 sucatas, 4 parafusos, 1 chapa e 2 usos de fita no cenário padrão | Nova regressão passou após correção |
| VEH-06 | Falha leve/grave, crítico, ferramentas e ferimentos seguem configuração, sem elevar condição em falha | Core passou; efeitos reais no jogador pendentes |
| VEH-07 | XP 3/5/1, cooldown por peça e veículo; repetir reparo não gera XP infinito | Core/glue passaram; API real de tempo/MP pendente |
| VEH-08 | Histórico reduz teto e reconhece troca de peça; nunca bloqueia motor por inexistência de item | Core/glue passaram; transmissão/restart pendentes |
| VEH-09 | Inspeção conserva condição visível vanilla; risco exato só com Mecânica suficiente; garagem/luz/macaco têm efeitos previstos | Core/glue passaram; UI real pendente |
| VEH-10 | PT-BR/EN inclui nome e descrição no menu B42, não apenas falas e opções | Mod.json EN/PTBR adicionados à fonte geradora e gerados |
| VEH-11 | Hooks encadeiam vanilla e não escrevem em menu antigo quando vanilla retorna cedo | Smoke test passou |

Estado atual: MVP mais inspeção, histórico e faixas de qualidade. Bônus de oficina cobre abrigo, escuridão e macaco; bancada não é detectada. Peças fabricáveis, manual próprio e API de bônus KRjobs continuam propostas futuras. O motor é a exceção explícita à exigência de item instalado; não se liberou genericamente toda peça sem item.

Riscos que impedem declarar pronto para publicar: serialização real de VehiclePart/tier/escuro; consumo/replicação e histórico no servidor; inspeção em multiplayer; sync dos efeitos no jogador; semântica do sandbox na 42.21. O estado de escuridão continua vindo do cliente e não é tratado como garantia contra trapaças.

Decisões de produto: registros ORQ escolhem Basic Vehicle Maintenance, preservam mod id/Workshop id, falha grave de -20 e B42 apenas. Histórico, três faixas e seus números continuam escolhas de implementação registradas por Claude; precisam de avaliação de balanceamento em jogo.
