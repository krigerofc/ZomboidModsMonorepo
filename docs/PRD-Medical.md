# PRD — Mod Médico irmão (nome de trabalho: "Field Medicine '93" / "Medicina de Campo")

> Documento autocontido para revisão e co-trabalho entre IAs (Claude / ChatGPT) e o dono dos mods.
> Legenda obrigatória:
> - **[DECIDIDO]** = Decidido pelo usuário (não alterar sem perguntar).
> - **[PROPOSTA]** = Proposta (validar com usuário). Números são chutes iniciais calibráveis.
> - **[FATO-VANILLA]** = verificado lendo o código vanilla local (42.19.2).

Data: 2026-10-17 · Autor do mod: Kriger (usuário) · Redação: Claude · Revisão de entrega: Codex (17/10/2026)

---

## 0. Identidade e decisões já tomadas

| Item | Valor |
|---|---|
| Natureza | Mod **irmão** do Basic Vehicle Maintenance v2 (mesmo tema "gambiarra realista com risco, sistema melhor"), focado em **saúde/medicina** [DECIDIDO] |
| Relação com vanilla | **complementar, não substituir** o sistema de saúde vanilla [DECIDIDO] |
| Balanceamento | **não pode ser OP** [DECIDIDO] |
| Idiomas | PT-BR + EN [DECIDIDO — regra de ouro] |
| Qualidade | test-driven, sem conflitos/erros no jogo [DECIDIDO] |
| Sinergia | com futuras profissões do KRjobs (ex.: cirurgião especialista) [DECIDIDO] |
| Ordem de trabalho | último da fila: ReduceMetal → PassiveSkills → KRjobs → Vehicle v2 → **Medical** [DECIDIDO] |
| Nome / mod id | [PROPOSTA] nome "Field Medicine '93", mod id `KRFieldMedicine`, prefixo Lua `KFM` |
| Dev atual | `C:\Users\pedro\Zomboid\Workshop\FieldMedicine\` com git |

Todo o desenho abaixo (§1–§14) é **[PROPOSTA]** salvo indicação em contrário.

---

## 1. Visão / Porquê

O sistema de saúde vanilla é bom em **feridas isoladas** (bandagem, sutura, tala, remover vidro/bala, desinfetar), mas:
- O jogador quase nunca **sabe** o que está acontecendo além do que a UI mostra; Stethoscope e TongueDepressor existem como item e **não têm uso** [FATO-VANILLA: `item Stethoscope`/`TongueDepressor` em `scripts/generated/items/normal.txt` sem ação associada].
- Não há **procedimento intermediário** entre "bandagem" e "cicatrizar sozinho": nada de irrigação de ferida, torniquete, cauterização, redução de fratura, debridamento.
- A habilidade Médico já reduz dor/tempo e revela informações no painel (níveis >2, >4, >6, >8 [FATO-VANILLA: `ISHealthPanel.lua` linhas ~633–830]), mas não abre **novas capacidades**.
- Em MP, "o médico do grupo" é pouco diferente de qualquer um com bandagens.

Visão: **um kit de medicina de campo de 1993** — procedimentos reais da época (manual de primeiros socorros da Cruz Vermelha, medicina militar de campo, pronto-socorro de cidade pequena), com materiais improvisados e risco real, onde a skill Médico e profissões de saúde fazem diferença **sem** virar cura mágica.

## 2. Público
- Jogadores solo que sobrevivem a lesões graves e querem algo a fazer além de "dormir e esperar".
- Grupos MP que querem um papel de **médico** de verdade (tratar outros jogadores).
- Jogadores de KRjobs (profissões de saúde: cirurgião especialista, paramédico, enfermeira, médico militar).

## 3. Objetivos
| # | Objetivo | Métrica |
|---|---|---|
| O1 | Dar uso real a itens médicos vanilla órfãos (Stethoscope, TongueDepressor) e a sucata comum | ≥ 2 itens vanilla sem uso ganham função |
| O2 | 4–6 procedimentos novos que preenchem lacunas do vanilla | nenhum duplica ação vanilla existente |
| O3 | Skill Médico desbloqueia capacidades (gating), não só bônus numérico | tabela §6.3 |
| O4 | Tratar outro jogador funciona em MP sem dessync | teste com 2 clientes |
| O5 | Zero erros no `console.txt`; 100% PT-BR/EN | grep + `-debugtranslation` |
| O6 | Tudo configurável por Sandbox | §8 |

## 4. Não-objetivos
- Não criar novas doenças/epidemias, sistema de pressão arterial/órgãos/sangue tipado.
- Não adicionar UI nova de corpo inteiro; estender o **ISHealthPanel** vanilla (menu de contexto por parte do corpo e tooltip) e usar um painel simples só para o laudo de exame.
- Não fazer amputação (já existe em mods populares, ex. "The Only Cure"; seria conflito e escopo).
- Não mexer em loot de hospitais além de spawnar os poucos itens novos.

## 5. Anti-objetivos (proibido)
- **Curar ou diagnosticar com certeza a infecção zumbi (Knox).** O exame nunca diz "você está infectado". No máximo mostra **febre** com causa ambígua (ferida infectada comum também dá febre). Isso preserva o medo central do jogo.
- **Ser OP**: nenhum procedimento cura instantaneamente; tudo **reduz tempo** ou **troca um risco por outro** (dor, sangramento, queimadura, infecção).
- Substituir ações vanilla (bandagem, sutura, tala, remover bala/vidro, desinfetar). Só adicionamos.
- Lógica no cliente: toda alteração em `BodyPart`/stats ocorre em `complete()` + `syncBodyPart`.
- Itens "futuristas" para 1993 (nada de oxímetro de dedo comum, desfibrilador portátil doméstico, etc.).

---

## 6. Features priorizadas

### 6.0 Resumo
| Prioridade | Feature |
|---|---|
| MVP | F1 Exame clínico (Stethoscope/TongueDepressor/mão) com laudo graduado por skill |
| MVP | F2 Irrigação de ferida (soro caseiro) — reduz infecção de ferida |
| MVP | F3 Torniquete (improvisado ou de cinto) — controla hemorragia grave com custo |
| MVP | F4 Gating e qualidade por skill Médico (+ XP sem farm) |
| MVP | F5 Traduções PT-BR/EN + Sandbox + raiz B41 reduzida |
| v1.1 | F6 Cauterização (faca aquecida) — fecha corte profundo sem sutura, com queimadura |
| v1.1 | F7 Redução de fratura — acelera consolidação, muito doloroso, exige ajudante ou skill |
| v1.1 | F8 Debridamento (bisturi) — trata ferida muito infectada, causa sangramento |
| v1.1 | F9 Crafting médico improvisado (soro, sutura de linha de pesca, torniquete, compressa) |
| Futuro | F10 Prontuário (item "Ficha médica") e acompanhamento de paciente |
| Futuro | F11 Hooks KRjobs (cirurgião especialista, paramédico, médico militar) |
| Futuro | F12 Revistas médicas (sinergia PassiveSkills) |

### 6.1 F1 — Exame clínico (MVP)
Ação "Examinar" no painel de saúde (próprio corpo ou de outro jogador; outro jogador exige proximidade como `ISHealthPanel.DidPatientMove` [FATO-VANILLA]).
- Duração: 150 ticks (−5/nível Médico; mín. 80). Com Stethoscope: +1 nível efetivo de diagnóstico. TongueDepressor (consumido) permite checar "garganta/hidratação".
- Laudo (texto traduzido, por faixas):

| Informação | Nível Médico necessário (efetivo) | Fonte de dados |
|---|---|---|
| Estado geral (bom / estável / grave / crítico) | 0 | saúde total do BodyDamage |
| Febre (sim/não, sem causa) | 1 | `CharacterStat.TEMPERATURE` |
| Desidratação / desnutrição | 2 | THIRST / HUNGER / peso |
| Estimativa de dias para fratura consolidar | 3 (faixa) / 6 (±1 dia) | `getFractureTime()` |
| Ferida "com cara de infecção" antes do vanilla mostrar | 4 | `getWoundInfectionLevel()` acima de limiar |
| Sangramento interno "provável" (perda de sangue alta) | 5 | saúde vs feridas visíveis |
| Pulso/respiração descritivos (calmo / acelerado / fraco) | 2 | PANIC, ENDURANCE, saúde |

Regra Knox: febre de infecção zumbi é **reportada igual** a febre comum. Nunca existe linha "infecção zumbi".
O vanilla já mostra muita coisa por nível (>2, >4, >6, >8); o laudo foca em **prognóstico e sinais sistêmicos**, que o vanilla não dá.
XP: 2 XP Médico por exame em paciente com algo a diagnosticar; anti-farm 1×/paciente/6h de jogo.

### 6.2 F2 — Irrigação de ferida (MVP)
- Alvo: parte com arranhão/corte/corte profundo/mordida **não suturada e não enfaixada**.
- Materiais: 0,25 L de **água fervida/potável** (Fluid B42) ou "Soro caseiro" (F9). Água suja = **aumenta** infecção.
- Efeito: `setWoundInfectionLevel(max(0, atual − R))`, R = 1,5 + 0,25×Médico (máx. 4). Se a ferida ainda não infectou, reduz a chance futura (modData marca "limpa" por 6h, e o mod reduz a infecção acumulada nesse período — **validar** se é possível sem hook por tick; senão só o efeito imediato).
- Custo: +5 de dor (`setAdditionalPain`), 120 ticks.
- Não substitui desinfetar (álcool): é complementar e mais fraco, mas usa água.

### 6.3 F4 — Gating e qualidade por skill Médico (MVP)

| Procedimento | Nível mín. | Ajudante (outro jogador) reduz req. em | Falha base | Redução de falha por nível |
|---|---|---|---|---|
| Exame | 0 | — | — | — |
| Irrigação | 0 | — | 0% | — |
| Torniquete | 1 | 1 | 5% | 0,5 p.p. |
| Cauterização | 3 | 1 | 20% | 2 p.p. (mín. 3%) |
| Redução de fratura | 5 | 2 | 30% | 3 p.p. (mín. 5%) |
| Debridamento | 6 | 1 | 25% | 3 p.p. (mín. 5%) |

Falha = o custo do procedimento acontece, o benefício não (ou só metade). Hemofobia: +50 PANIC como em `ISStitch:complete` [FATO-VANILLA]. Luvas cirúrgicas (`Gloves_Surgical`): −30% chance de infecção causada pelo procedimento. Máscara cirúrgica: −10%.

### 6.4 F3 — Torniquete (MVP)
- Item: "Torniquete improvisado" (RippedSheets 2 + Stick/vara curta) ou cinto (`Belt` vanilla, **validar fullType B42**). Só em braços/pernas (UpperArm/ForeArm/UpperLeg/LowerLeg).
- Efeito: sangramento da parte e das partes distais para enquanto aplicado (`setBleedingTime(0)`, reaplicado se voltar — **validar** se exige hook `OnPlayerUpdate`; preferir `EveryOneMinute` no servidor).
- Custo: a partir de 2h de jogo aplicado, a parte perde saúde (−1/10 min) e ganha dor; após 6h, risco de "dano permanente" = fratura/dor crônica longa (`setFractureTime` alto). Remover é ação rápida.
- Uso esperado: "comprar tempo" até suturar. Não é tratamento.

### 6.5 F6 — Cauterização (v1.1)
- Materiais: faca/lâmina **aquecida** (isqueiro/fósforo + 60 ticks extras; detecção de fogão/fogueira é proposta futura), álcool opcional.
- Efeito: corte profundo → `setDeepWounded(false)`, `setBleeding(false)`, cria queimadura `setBurnTime(15–25)` + `setNeedBurnWash(true)`; dor +60 −2×Médico.
- Alternativa pior que sutura, melhor que sangrar. Não funciona em mordida.

### 6.6 F7 — Redução de fratura (v1.1)
- Requisito: fratura sem tala ou com tala; nível 5 (ou 3 com ajudante); paciente deitado ou sentado.
- Efeito em sucesso: `setFractureTime(atual × (0,75 − 0,02×Médico))` (máx. −40%); 1× por fratura (modData `KFM.reduced = true`).
- Falha: dor +80, fractureTime +10%.
- Analgésico (`Pills`) tomado < 1h antes: dor do procedimento −50%.

### 6.7 F8 — Debridamento (v1.1)
- Requisito: ferida com `isInfectedWound()` e infecção alta; Scalpel; nível 6.
- Efeito: `setWoundInfectionLevel(0)` e `setInfectedWound(false)`, mas gera sangramento (`setBleedingTime(5–10)`) e dor +70. Exige bandagem depois.
- Nunca afeta infecção zumbi.

### 6.8 F9 — Crafting médico improvisado (entrega parcial; demais receitas futuras)
Receitas `craftRecipe` B42 (validar sintaxe em `media/scripts/generated/recipes`):

| Item novo | Receita | Uso |
|---|---|---|
| Soro caseiro (garrafa) | 1 L água fervida + Salt (pitada) | Irrigação ×4 (melhor que água: R +0,5) |
| Sutura improvisada | Needle + FishingLine (ou Thread) + álcool | Usada com SutureNeedle vanilla? **Não**: cria agulha de sutura de baixa qualidade que funciona na ação vanilla de sutura via tag, com +chance de infecção (**validar se a ação vanilla aceita item por tag**) |
| Torniquete improvisado | RippedSheets 2 + vara curta | F3 |
| Compressa estéril | RippedSheets fervidos (panela + água) | Bandagem com menor infecção que RippedSheets puro — **cuidado: pode sobrepor "bandagem esterilizada" vanilla; validar se já existe** |

### 6.9 Futuro
- F10 Prontuário: item escrito pelo médico com o laudo do paciente (útil em MP; o paciente carrega a ficha).
- F11 KRjobs (interface básica implementada; extensões futuras): traits/profissões dão "nível efetivo" extra só para gating/diagnóstico (ex.: Cirurgião Especialista +2 em Debridamento/Redução; Paramédico +1 em Torniquete/Exame; Médico Militar: cauterização sem penalidade de calor). API: `KFM.registerProfessionBonus(id, { procedures = {...}, effectiveLevel = 2 })`. Soft dependency.
- F12 Revistas: "Manual de Primeiros Socorros da Cruz Vermelha (1991)" ensina receitas F9.

---

## 7. Arquitetura técnica

### 7.1 APIs vanilla verificadas (42.19.2) [FATO-VANILLA]
- `BodyPart` setters usados no vanilla: `setBleeding`, `setBleedingTime`, `setDeepWounded`, `setDeepWoundTime`, `setFractureTime`, `setSplint(bool, factor)`, `setSplintItem`, `setStitched`, `setStitchTime`, `setWoundInfectionLevel`, `setInfectedWound`, `setHaveBullet(bool, doctorLevel)`, `setHaveGlass`, `setBurnTime`, `setNeedBurnWash`, `setCut`, `setScratched(bool, bool)`, `setAdditionalPain`, `setAlcoholLevel`, fatores de cataplasma (`setPlantainFactor` etc.). Getters correspondentes + `isGetStitchXp/isGetSplintXp/isGetBandageXp`.
- Padrão de ação médica: `ISStitch`, `ISSplint`, `ISDisinfect`, `ISRemoveBullet`, `ISCleanBurn` em `media/lua/shared/TimedActions/`. Todos aplicam efeito em `complete()` e chamam `syncBodyPart(bodyPart, flags)`. Médico em MP com capability `CanMedicalCheat` vira nível 10.
- Flags conhecidas de `syncBodyPart` (compostas, copiadas do vanilla):

| Ação vanilla | Campos (comentário vanilla) | Valor |
|---|---|---|
| ISStitch | additionalPain, stitched, infectedWound, stitchTime, bleeding, bleedingTime, deepWounded, deepWoundTime | `0x00570188` |
| ISRemoveBullet | additionalPain, bleedingTime, bleeding, haveBullet, deepWounded, deepWoundTime | `0x40460108` |
| ISDisinfect | alcoholLevel, additionalPain, IsInfected, WoundInfectionLevel | `0x00608200` |
| ISCleanBurn | additionalPain, needBurnWash, lastTimeBurnWash, burnTime | `0x380400000` |
| ISSplint | splint, splintFactor, splintItem | `0x430000000` |
| ISRemoveGlass | additionalPain, haveGlass | `0x00480000` |
| ISApplyBandage | bandaged, bleeding, infected, bitten, cut, … | `0xc001966b8e` |

  Dedução: additionalPain = `0x400000`, haveGlass = `0x80000`. **Kahlua (Lua 5.1) não tem operadores bitwise**: combinar flags com soma só de bits distintos, num helper testado por unidade. Flag de `fractureTime` **não encontrada** em uso vanilla → validar (provavelmente via teste em debug MP).
- Stats: `getStats():add(CharacterStat.PANIC, 50)` + `syncPlayerStats(chr, 0x00000100)` (flag de PANIC) [FATO-VANILLA].
- XP: `addXp(chr, Perks.Doctor, n)`. Profissão Doctor vanilla: `XPBoosts = Doctor=6;SmallBlade=1` (`character_professions.txt`).
- Itens vanilla relevantes: Stethoscope, TongueDepressor(Box), SutureNeedle, SutureNeedleHolder, Tweezers, Scalpel, Gloves_Surgical, Hat_SurgicalMask, AlcoholWipes, Disinfectant, CottonBalls, Bandage, AlcoholBandage, Bandaid, Splint, Pills, Antibiotics, cataplasmas (Comfrey/Plantain/WildGarlic).

### 7.2 Estrutura entregue
- shared/KFM/Core.lua: fórmulas puras, gating, constantes e flags.
- shared/KFM/Game.lua: adaptador do jogo, estado, itens, XP e sincronização.
- shared/TimedActions/KFM_ProcedureAction.lua: ação única dos procedimentos.
- client/KFM/KFM_Client.lua: menu, laudo e mensagens.
- server/KFM/KFM_Server.lua: sangramento/torniquete e eventos do servidor.
- 42/media/scripts/KFM_items.txt e KFM_recipes.txt: item e receita do torniquete.
- common/media/lua/shared/Translate/{EN,PTBR}/*.json.
- tests/core_spec.lua e tests/glue_spec.lua. Não existe módulo SyncFlags.lua separado.


## 8. Sandbox options [PROPOSTA — página "Field Medicine '93"]
| Chave | Tipo | Padrão | Faixa |
|---|---|---|---|
| KFM.Enabled | bool | true | — |
| KFM.ExamEnabled | bool | true | — |
| KFM.ShowFeverInExam | bool | true | — (servidores hardcore podem desligar) |
| KFM.SkillRequirementOffset | int | 0 | −3..+3 |
| KFM.FailChanceMultiplier | double | 1.0 | 0–3 |
| KFM.ProcedurePainMultiplier | double | 1.0 | 0–2 |
| KFM.IrrigationStrength | double | 1.0 | 0–2 |
| KFM.TourniquetSafeHours | int | 2 | 1–8 |
| KFM.FractureReductionMax | double | 0.40 | 0–0.6 |
| KFM.XPMultiplier | double | 1.0 | 0–5 |

## 9. Compatibilidade da versão entregue
- Build 42 apenas: common/ + 42/; nenhuma implementação B41. Registro de decisão: DECISIONS-Medical.md (ORQ).
- versionMin=42.15, por depender de traduções JSON. Fontes locais de referência: 42.19.2; alvo de validação: 42.21.
- A antiga proposta B41 reduzida fica fora desta entrega.
- Testar junto a outros mods médicos; hooks devem encadear o vanilla.


## 10. Traduções [DECIDIDO PT-BR + EN]
- B42 JSON: `common/media/lua/shared/Translate/EN|PTBR/{IG_UI,ContextMenu,ItemName,Recipes,Sandbox,Tooltip}.json`.
- B41 não é distribuído nesta entrega; traduções TXT seriam necessárias apenas em uma futura implementação específica.
- Prefixos `IGUI_KFM_`, `ContextMenu_KFM_`, `Sandbox_KFM_`. Termos médicos em PT-BR revisados (ex.: "debridamento", "redução de fratura", "torniquete", "soro fisiológico caseiro").

## 11. MP / servidor (B42.13+)
- Todos os procedimentos são TimedActions em `shared` com efeito em `complete()` + `syncBodyPart` (flags §7.1) e consumo de item com `UseAndSync`/`sendRemoveItemFromContainer`.
- Tratar outro jogador: `self.otherPlayer`, checagem de movimento (`DidPatientMove`) e distância como `ISStitch`.
- Torniquete por tempo: lógica só no servidor (`if isClient() then return end`) e estado em `player:getModData().KFM` (sincronizar com `transmitModData` se necessário — validar).
- Laudo de exame: calculado no servidor e enviado ao médico via `sendServerCommand` (o cliente do médico não tem os dados exatos do corpo do paciente em MP — **validar**).

## 12. Plano de testes (test-driven) [DECIDIDO a abordagem]
1. Sintaxe: luaparse em todos os `.lua`.
2. Unitário (fengari) em `Core.lua` e helpers de flags em Core.lua: tabelas de gating, fórmulas de falha (pisos), irrigação nunca negativa, redução de fratura 1× e cap, laudo **nunca** contém infecção zumbi para qualquer entrada, soma de flags sem bits duplicados.
3. In-game SP `-debug -debugtranslation`: usar cheats de saúde do ISHealthPanel para criar cada lesão; roteiro em `MANUAL_TEST.md`.
4. MP: médico tratando outro jogador; conferir painel de saúde dos dois lados após cada procedimento.
5. `console.txt`: grep `error|exception|KFM` sem erros.

## 13. Riscos
| Risco | Mitigação |
|---|---|
| Efeitos de BodyPart sobrescritos pelo update vanilla do Java (ex.: sangramento volta) | testar cada setter em debug; usar tick no servidor só onde necessário |
| Flag de sync desconhecida (fractureTime) | teste MP; fallback sync completo se existir API |
| Sobreposição com vanilla (bandagem esterilizada, cataplasmas) | auditoria de receitas vanilla antes de F9 |
| Vazamento de diagnóstico Knox | teste unitário obrigatório + revisão de texto |
| Conflito com mods médicos populares | teste de carga conjunta; hooks encadeados |
| OP percebido (redução de fratura) | cap 40%, 1×, sandbox |

## 14. Decisões e propostas ainda abertas
Consulte DECISIONS-Medical.md para os registros ORQ e as escolhas propostas por Claude. O resumo de entrega e os critérios adicionais na seção 15 distinguem implementação, proposta e evidência de teste. A revisão não presume aprovação humana adicional.


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
| MED-01 | Exame usa faixas e sinais observáveis; não lê nem identifica Knox e não informa dias exatos de consolidação | Guarda estática + core/glue passaram; SP/MP pendente |
| MED-02 | ExamEnabled=false bloqueia exame também na conclusão autoritativa, mesmo que a ação já tenha sido enfileirada | Nova regressão falhou antes e passou depois |
| MED-03 | Irrigação consome 0,25 L; água contaminada piora infecção; ferida enfaixada/suturada é recusada | Glue passou; Fluid/MP real pendente |
| MED-04 | Torniquete aplica-se a braços/pernas, um por membro, consome e devolve o item uma vez; sangramento e dano tardio seguem configuração | Core/glue passaram; atualização Java e restart pendentes |
| MED-05 | Cauterização não serve para mordida e conserva custos, queimadura e chance de falha | Core/glue passaram |
| MED-06 | Redução exige repouso e skill/ajudante, respeita cap e só tem sucesso uma vez por fratura | Core/glue passaram; persistência pendente |
| MED-07 | Debridamento preserva coerência entre nível e flag de infecção inclusive se o procedimento recontaminar | Nova regressão falhou antes e passou depois |
| MED-08 | XP respeita cooldown por paciente/procedimento/parte e não é concedido por exame de pessoa saudável | Glue passou |
| MED-09 | Materiais em bolsa são transferidos antes; requisitos são revalidados; cancelamento não aplica efeitos | Inspeção do fluxo; confirmar em SP/MP |
| MED-10 | Interface chama ação vanilla original e conserva tratamentos já existentes | Smoke test passou; carga com mods médicos pendente |

Estado atual: sete ações incluindo remoção do torniquete; receita implementada apenas para o torniquete improvisado. A integração básica opcional com o cirurgião KRjobs existe; os demais bônus pré-registrados só têm efeito se essas identidades existirem. Soro, sutura improvisada, compressa nova, prontuário e novos manuais permanecem propostas futuras. A proteção de seis horas após irrigação não está implementada.

Riscos que impedem declarar pronto para publicar: serialização real de BodyPart/itens em TimedAction no servidor; persistência de modData; regeneração de sangramento pelo Java entre ticks; escalas reais dos sinais vitais; traduções e input de controle na UI. A capa de medicina e parte dos ícones continuam provisórios.

Decisões de produto a confirmar: identidade pública registrada pelo orquestrador; intensidade dos procedimentos avançados; presença de febre ambígua no laudo; profissões adicionais com bônus. Esta revisão não mudou esses números nem adicionou procedimentos.
