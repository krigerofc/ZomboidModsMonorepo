# Decisões - Basic Vehicle Maintenance v2 (More Vehicles Repairs)

Data: 2026-10-17 · Repo: `C:\Users\pedro\Zomboid\Workshop\BasicVehicleMaintenance` (commit inicial `2ec5ee7`, branch `main`).
Legenda: **[ORQ]** = decidido pelo orquestrador em nome do usuário · **[CLAUDE]** = decidido pela Claude (validar com o usuário) · **[FATO]** = verificado no vanilla 42.19.2 / jar.

Referência de mods populares: **Vehicle Repair Overhaul** (Workshop 2757712197) adiciona opções de reparo com sucata/barra de metal via `fixing` e exige skills (Mecânica/Metalurgia) por receita; serviu de base para gating por skill e "trabalho a quente exige Metalurgia". Nenhum mod B42 popular faz "consertar sem peça" com teto + risco, então os números seguem o PRD.

## Respostas às perguntas abertas do PRD (§14)

| # | Pergunta | Decisão | Tipo |
|---|---|---|---|
| 1 | Nome no Workshop | "Basic Vehicle Maintenance"; mod id `MoreVehiclesRepairs` e Workshop id 3643006111 mantidos | ORQ |
| 2 | Falha grave | −20 de condição (mín. 0), 40% das falhas; desligável no sandbox | ORQ |
| 3 | B41 | Só B42. Raiz tem só `mod.info` (+ pôster/ícone) dizendo para usar B42; nenhum `media/` B41 | ORQ |
| 4 | Histórico de remendos reduz teto | Sim: −3 por remendo bem-sucedido, mín. 30; zera quando o InventoryItem instalado muda (ID diferente). Sandbox `PatchHistoryEnabled` | CLAUDE |
| 5 | Risco de incêndio ao soldar tanque | Não no MVP (só queimadura de mão em peças "calor"). Fogo real envolve IsoFire/sync, risco de bug MP | CLAUDE |
| 6 | Faixas Reparo/Revisão | Feitas já (v1.1 entregue junto), atrás de `QualityTiersEnabled` | CLAUDE |
| 7 | Peças fabricáveis (F10) | Fora do escopo desta versão | CLAUDE |

## Escopo entregue

- MVP: F1 (todos os bugs da v1), F2, F3, F4, F5. F6 trocado por "B42-only" (ORQ).
- v1.1: F7 (inspeção + histórico), F8 (oficina parcial), F9 (faixas). Futuro (F10–F12): não feito.

## Decisões técnicas

| Tema | Decisão | Tipo |
|---|---|---|
| Arquitetura | `shared/MVR/Config.lua` (dados), `shared/MVR/Core.lua` (toda a lógica pura e helpers compartilhados, incl. busca em bolsas via adapter), `shared/MVR/Game.lua` (cola com API do jogo), `shared/TimedActions/MVR_RepairAction.lua`, `client/MVR/Menu.lua` | ORQ/CLAUDE |
| MP | Sem `sendClientCommand`. B42 reconstrói a ação no servidor chamando `new()` com os campos de mesmo nome dos parâmetros (`NetTimedAction` lê `numParams/locvars` do protótipo de `new`) → `new(character, part, tierId, dark)`; teste unitário garante o contrato | FATO/CLAUDE |
| Autoridade | `complete()` reavalia tudo (materiais, ferramentas, teto, skill) e só então consome/rola/aplica. Config e duração vêm do servidor, nunca do cliente | CLAUDE |
| Escuro | Calculado no cliente (`tooDarkToRead`) e passado como parâmetro: servidor dedicado não simula luz. Exploit possível vale só 5 p.p. | CLAUDE |
| Sync | `DoRemoveItem` + `sendRemoveItemFromContainer(container do item)` (padrão `ISRepairEngine`); drenáveis com `UseAndSync()` por uso; `sendItemStats` no desgaste; `syncBodyPart(bp, 0xFFFFFFFFFFF)` (máscara do vanilla `ClientCommands`); `transmitPartCondition` + `transmitPartModData`; tudo `send*` só se `isServer()` | FATO |
| Feedback | `sendServerCommand(chr,"MVR","result")` com `onlineId`; cliente acha o jogador local certo (splitscreen ok). SP chama direto. Fala + HaloText | CLAUDE |
| Drenáveis | Quantidade = usos (DuctTape 2 = 2 de 4 usos do rolo). Gasta primeiro o rolo mais vazio | CLAUDE |
| Ferramentas | Tags `ItemTag.WRENCH/SCREWDRIVER/SEWING_NEEDLE`, não quebradas, busca recursiva (`getFirstTagEvalRecurse`, igual `ISVehicleMechanics:getWrench`) | FATO |
| Substitutos | SheetMetal 1 ↔ SmallSheetMetal 2; RippedSheets ↔ DenimStrips; Seat: LeatherStrips 3 / RippedSheets 4 / DenimStrips 4 | CLAUDE |
| Peças | Toda peça instalada (com InventoryItem) ganha config; ids desconhecidos (mods) → Default. Aliases extras: HoodOrnament/TruckBed/Trailer*/GloveBox → Default; `Light/Lamp/Bulb/lightbar` → não reparável (opção desabilitada com dica, sem crash). Teste cobre os 56 ids vanilla | CLAUDE |
| Engine | Pede ScrapMetal 4 + SheetMetal 1 (PRD; v1 pedia 2) e abre/fecha o capô como `onRepairEngine` | FATO/CLAUDE |
| Fórmulas | As do PRD §6.2. Extras: chance final limitada a 95% (multiplicador 3); crítico máx. 50%; falha leve não baixa abaixo de 1 (nem sobe de 0) | CLAUDE |
| Teto máximo | Remendo 75, Reparo 78, Revisão 80 (PRD: Revisão máx. 80; Reparo ficou intermediário) | CLAUDE |
| XP | 3/5/1 × sandbox; anti-farm com `getMechanicsItem/addMechanicsItem` (retorna `Long`, confirmado no jar), chave `mechanicalID..partId.."MVR"`, 1×/peça/veículo/24h de jogo | FATO/CLAUDE |
| Infelicidade | `CharacterStat.UNHAPPINESS` +5 na escala 0–100 (slider debug vanilla usa passo 1); sync com `SyncPlayerStatsPacket.getBitMaskForStat` se exposto, senão máscara cheia | CLAUDE (risco) |
| Oficina (F8) | Coberto = square do **veículo** `not isOutside()` (−3 p.p.); escuro +5; macaco (`Base.Jack`, sem tag no vanilla) −15% tempo em pneu/freio/suspensão. **Bancada não detectada** (sem propriedade B42 confiável) | CLAUDE |
| Faixas (F9) | Reparo: Mecânica 3, coberto ou macaco, Metalurgia 2 se calor, mat ×1,5, tempo ×1,5, teto +10. Revisão: Mecânica 6, Metalurgia 4 + 3 usos de maçarico se calor, Elétrica 3 em bateria/rádio, ×2, +20 | CLAUDE |
| Inspeção (F7) | Ação só-cliente de 300 ticks (padrão `ISOpenMechanicsUIAction`, sem `complete`), exige luz, mostra `ISModalRichText`. Mecânica ≥4 vê % exata, abaixo vê faixa baixo/médio/alto | CLAUDE |
| Aviso vanilla | Tooltip avisa quando `FixingManager.getFixes` tem receita e o jogador carrega um fixer (aproximação: não confere skill/ferramenta da receita) | CLAUDE |
| Menu | Hook pós-original em `ISVehicleMechanics:doPartContextMenu`; zera `self.context` antes para não escrever em menu velho quando o vanilla sai cedo; tudo em `pcall`. Removido o hook especulativo `ISCarMechanicsOverlay` | CLAUDE |
| Traduções | `common/.../Translate/{EN,PTBR}/{ContextMenu,Tooltip,IG_UI,Sandbox}.json` (nomes de arquivo do vanilla; PRD dizia `IGUI.json`). Fonte única `tools/translations.js`; teste exige paridade e placeholders iguais | CLAUDE |
| Sandbox | 13 opções do PRD §8 na página `MVR` ("Manutenção Básica de Veículos"); `CapOffset` inteiro, multiplicadores `double` | CLAUDE |
| Imagens | pôster 512, ícone 64 (raiz e `42/`), preview 256 (mesmo padrão do PassiveSkills) | CLAUDE |
| Fonte v1 | `Zomboid\mods\VehicleMod` apagada; backup no scratchpad `steamcmd/.../3643006111` | ORQ |

## Riscos não verificados in-game

1. Formato `type = double` no sandbox-options (sem exemplo local).
2. `SyncPlayerStatsPacket.getBitMaskForStat` exposto ao Lua; escala de UNHAPPINESS.
3. Ação só-cliente de inspeção no MP B42 (vanilla tem padrão igual, mas não testado).
4. `transmitPartModData` atualizar o histórico no cliente (tooltip).
5. `getMechanicsItem` expira entradas sozinho? (o mod compara o timestamp, então funciona dos dois jeitos).
6. Serialização de `VehiclePart` + string + boolean nos argumentos da ação (vanilla usa `VehiclePart`; string/boolean presumidos).
7. Nada testado em 42.21; reler o vanilla antes de publicar.
