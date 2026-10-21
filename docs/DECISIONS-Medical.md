# DECISIONS — Field Medicine '93 (KRFieldMedicine)

> Registro das decisões tomadas na construção do mod a partir de `PRD-Medical.md` (2026-10-17), com o usuário ausente.
> Legenda: **[DECIDIDO-ORQ]** = decidido pelo orquestrador (repasse do usuário) · **[PROPOSTA]** = decidido pela Claude, validar com o usuário · **[FATO-VANILLA]** = verificado no Lua/scripts/jar locais 42.19.2.
> Referência de mercado usada só para desenho (sem copiar código), de memória, não reverificada online: The Only Cure (amputação; por isso não fazemos), mods de "exame/diagnóstico" e de itens médicos extras do Workshop (padrão: submenu no painel de saúde, opções desabilitadas com requisito no tooltip, tudo ajustável por sandbox).

Repo: `C:\Users\pedro\Zomboid\Workshop\FieldMedicine\` · commit inicial **`6bf70cc`** (branch `main`, repo novo) · `npm test` = ALL TESTS PASSED.

## 1. Identidade e escopo
| # | Decisão | Tipo |
|---|---|---|
| 1 | Nome "Field Medicine '93" (PT-BR: "Medicina de Campo '93"), mod id `KRFieldMedicine`, prefixo Lua/chaves `KFM`, autor Kriger, versão 1.1.0 | DECIDIDO-ORQ |
| 2 | **Só B42** (`42/` + `common/`, sem `mod.info`/`media` na raiz; teste falha se aparecerem). `versionMin=42.0` | DECIDIDO-ORQ |
| 3 | Exame pode mostrar **febre** (sempre o mesmo texto, "muitas coisas podem causar isso"), nunca a causa nem linha de infecção zumbi | DECIDIDO-ORQ |
| 4 | Entregue MVP (F1–F5) **e** v1.1 F6 cauterização, F7 redução de fratura, F8 debridamento. F9 parcial (só torniquete improvisado). F10–F12 não | PROPOSTA |
| 5 | `workshop.txt` sem `id` (item novo); tags `Build 42;Misc;Realistic` | DECIDIDO-ORQ / PROPOSTA |
| 6 | Capas: **placeholder** — `preview.png` (256) e `poster.png` (512) copiados do ModTemplate; `icon.png` 64×64 cinza com cruz branca gerado por `tools/make_icon.js`. Trocar quando a arte médica for gerada | DECIDIDO-ORQ |

## 2. Arquitetura
| # | Decisão | Tipo |
|---|---|---|
| 7 | `shared/KFM/Core.lua` = lógica pura (fórmulas, gating, laudo, registro de bônus, flags) testada em fengari; `shared/KFM/Game.lua` = cola com o jogo (pcall em APIs não usadas pelo vanilla) | PROPOSTA |
| 8 | **Uma** TimedAction `KFM_ProcedureAction(doctor, patient, bodyPart, procId, item, item2)` para todos os procedimentos, mesma forma de `ISStitch`/`ISDisinfect`: efeito só em `complete()` (servidor no MP), gating **revalidado no servidor** | PROPOSTA |
| 9 | Sync: `syncBodyPart(bp, 0xFFFFFFFFFFF)` (máscara completa) em todos os procedimentos — o vanilla usa exatamente isso em `server/ClientCommands.lua` (cheats de saúde) [FATO-VANILLA]. Evita adivinhar bits (fractureTime não tem flag conhecida). Escrito em decimal (17592186044415) porque fengari quebra hex grande. `Core.combineFlags` (soma de bits distintos) fica pronto e testado para máscaras finas futuras | PROPOSTA |
| 10 | Menu: wrapper encadeado em `ISHealthPanel:doBodyPartContextMenu` (chama o original, depois acrescenta submenu "Medicina de Campo" no menu do jogador). Os handlers vanilla (`BaseHandler`) são `local` e não dá para estender [FATO-VANILLA]. Se o vanilla escondeu o menu por estar vazio, reexibimos | PROPOSTA |
| 11 | Tratar outro jogador = via **"Exame médico" vanilla** (pede consentimento; o painel do paciente abre para o médico). Sem opção nova no menu do mundo (respeita consentimento) | PROPOSTA |
| 12 | Auto-exame sem lesão listada: botão direito no Estetoscópio/Abaixador de língua → "Examinar a si mesmo" (a lista do painel só mostra partes feridas) | PROPOSTA |
| 13 | `ISHealthPanel.DidPatientMove` é client-only; reimplementado em `Game.patientMoved` (mesma regra) para `isValid` no servidor | PROPOSTA |
| 14 | Laudo calculado no servidor e enviado ao médico por `sendServerCommand("KFM","exam")`; cliente traduz chaves + nome da parte | PROPOSTA |
| 15 | Itens usados de bolsas são movidos para o inventário principal antes (ação de transferência vanilla) | PROPOSTA |

## 3. Regras de jogo e números
| # | Decisão | Tipo |
|---|---|---|
| 16 | Gating/falha exatamente a tabela §6.3 do PRD (Torniquete 1, Cauterização 3, Redução 5, Debridamento 6; falhas 5/20/30/25% −0,5/2/3/3 p.p. por nível, pisos 0/3/5/5%); teto global 95% | PRD |
| 17 | "Ajudante" = **terceiro** personagem vivo (nem médico nem paciente) a ≤ 3 tiles do paciente. Reduz só o requisito, não a falha | PROPOSTA |
| 18 | `SkillRequirementOffset` só mexe em procedimentos que já exigem nível (exame, irrigação e remover torniquete ficam nível 0) | PROPOSTA |
| 19 | Bônus de profissão/trait (KRjobs) afeta só gating e diagnóstico (nível efetivo), nunca falha/força. API soft global `KFM.registerProfessionBonus(id, {effectiveLevel ≤3, procedures, noHeatPenalty})`, ids comparados em minúsculas exatos com profissão e traits. Pré-registrados (propostas, inertes se não existirem): `krjobs:surgeon` +2 (exame, cauterização, redução, debridamento), `krjobs:paramedic` +1 (exame, irrigação, torniquete), `krjobs:militarymedic` +1 (torniquete, cauterização, irrigação; sem tempo de aquecer lâmina), `krjobs:nurse` +1 (exame, irrigação). Profissões vanilla (Doctor/Nurse) **sem** bônus (já têm XPBoost) | PROPOSTA |
| 20 | Exame: 150 ticks −5/nível (mín. 80); Estetoscópio = +1 nível efetivo; Abaixador consumido libera hidratação + garganta em qualquer nível. Faixas: febre ≥ 37,5 °C, febre alta ≥ 38,5, frio ≤ 35,5; desidratação THIRST > 0,4 / > 0,7; desnutrido peso < 65, mal alimentado < 75 ou HUNGER > 0,6; pulso fraco saúde < 40, acelerado PANIC > 50; respiração rápida ENDURANCE < 0,3 | PROPOSTA |
| 21 | Fratura no laudo: **faixas** (nível 3: 3 faixas; nível 6: 5 faixas), **sem dias numéricos** — a taxa de consolidação por dia não está verificada | PROPOSTA |
| 22 | "Sangramento interno provável" virou "mais fraco do que as feridas visíveis explicam (perda de sangue, doença, fome, exaustão...)" (nível 5) — PZ não tem sangramento interno e a frase precisa ser ambígua por causa do Knox | PROPOSTA |
| 23 | Knox: o coletor de sinais vitais não lê infecção zumbi; `npm test` falha se qualquer Lua do mod chamar `isInfected/IsInfected/getInfectionLevel/isFakeInfected/...`; teste de propriedade mostra laudo idêntico com/sem campos de Knox | PROPOSTA |
| 24 | XP: exame 2 (cooldown 6 h por paciente, só se houver algo a diagnosticar), irrigação 3, torniquete 4 (só se a parte sangrava), cauterização 10, redução 15, debridamento 15; cooldown 1 h por paciente+procedimento+parte; × `XPMultiplier` | PROPOSTA |
| 25 | Irrigação: 0,25 L de água pura (`Fluid.Water`); R = min(4, 1,5+0,25×nível) × força; alvo: arranhão/corte/profunda/mordida sem curativo e sem sutura; dor +5. Água contaminada é aceita e piora (+2 infecção, ferida infectada). Sem efeito "limpa por 6 h" (exigiria hook por tick mexendo na infecção vanilla) | PROPOSTA |
| 26 | Torniquete: item novo `Base.KFM_ImprovisedTourniquet` (receita 2 tiras de pano + graveto/galho) ou `Base.Belt2` não vestido (+5 p.p. de falha). O item **vai para o membro** (sai do inventário) e volta ao remover. Só UpperArm/ForeArm/UpperLeg/LowerLeg; 1 por membro; controla a parte e as distais. Sangramento é **pausado** (tempo restante guardado, `EveryOneMinute` no servidor) e volta ao remover nas feridas não tratadas. Após `TourniquetSafeHours` (2): −1 saúde e +2 dor a cada 10 min; após 3× (6 h): fractureTime ≥ 30 uma vez (dano duradouro). Falha = só dor, item fica | PROPOSTA |
| 27 | Cauterização: lâmina (`Scalpel` ou tag `base:sharpknife`) + isqueiro/fósforo (1 uso) e +60 ticks de aquecimento; sem detecção de fogão/fogueira. Sucesso fecha ferida profunda e sangramento; falha só reduz sangramento à metade; sempre queimadura 15–25 + precisa lavar; dor 60−2×nível; 5% de infecção (luvas −30%, máscara −10%). Nunca em mordida | PROPOSTA |
| 28 | Redução de fratura: paciente sentado/deitado/no veículo; fator max(1−cap, 0,75−0,02×nível) (cap sandbox 40%); 1× por fratura (flag no modData, limpo quando cura); falha +10% tempo; dor 80 (metade com analgésico ativo, via `getPainReductionFromMeds`) | PROPOSTA |
| 29 | Debridamento: `Base.Scalpel`, ferida com `isInfectedWound` e nível ≥ 4; zera infecção da ferida, sangra 5–10, dor 70−2×nível; falha deixa metade; 15% de reinfecção leve (nível 1) | PROPOSTA |
| 30 | Hemofobia: +50 PANIC (como ISStitch) em cauterização e debridamento | PROPOSTA |
| 31 | Sandbox: as 10 opções do PRD §8 **menos** `ItemSpawnMultiplier` (o mod não spawna loot; torniquete é craftado) | PROPOSTA |
| 32 | F9: não criados soro caseiro (exigiria fluido novo), sutura improvisada (vanilla já sutura com Needle+Thread) nem compressa estéril (vanilla já tem `DisinfectBandage`/`AlcoholRippedSheets` fervendo pano) [FATO-VANILLA] | PROPOSTA |
| 33 | Não usados `BodyPart.SetBleedingStemmed/SetCauterized` (existem no jar, semântica desconhecida) | PROPOSTA |

## 4. MP
| # | Decisão | Tipo |
|---|---|---|
| 34 | Estado do torniquete no modData do **paciente** (servidor). Cliente MP não recebe modData do servidor, então o servidor envia `KFM/tq` ao paciente e ao médico; cliente guarda espelho por onlineID e pede `tqSync` ao entrar/ao abrir o painel de outro jogador | PROPOSTA |
| 35 | Feedback (balão `Say`) via `KFM/result`; itens com `sendRemoveItemFromContainer`/`sendAddItemToContainer`/`UseAndSync`/`sendItemStats` | PROPOSTA |

## 5. Testes
`npm test`: sintaxe luaparse (7 Lua), JSON, layout B42-only, mod.info, workshop sem id, tamanhos de imagem, guarda Knox, chaves/blocos dos scripts, **referências de item existem no vanilla 42.19.2 ou no mod** (15), paridade EN/PTBR + placeholders (88 chaves), sandbox↔traduções↔Core; `core_spec.lua` (fórmulas por nível, clamps, pisos, cap 40%, irrigação nunca negativa, Knox, bônus, flags) e `glue_spec.lua` (motor mockado: exame SP/MP, irrigação, ciclo completo do torniquete com ticks, cauterização com ajudante, redução, debridamento, sandbox desligado, menu encadeado). Roteiro in-game: `FieldMedicine/MANUAL_TEST.md`.

## 6. Riscos não verificados (só in-game resolve)
- Servidor B42 recriar a `KFM_ProcedureAction` com os mesmos argumentos (BodyPart, item2 nil, string procId) como faz com as ações vanilla.
- `setBleedingTime(0)` por minuto realmente segurar o sangramento sem o Java regenerar; restaurar `bleedingTime` ao remover.
- Escala de `woundInfectionLevel` (assumido 0–10, cheat vanilla usa 10) e de PANIC (0–100), TEMPERATURE (°C).
- `getWornItem`, `isSitOnGround`, `getPainReductionFromMeds`, `isHasACold`, `tostring` de profissão/trait (formato do id para o bônus KRjobs).
- Reexibir o menu de contexto quando vazio (foco de joypad não refeito); `getPlayerContextMenu` devolver o mesmo menu montado.
- Persistência do modData do jogador no servidor após restart (mesmo risco do PassiveSkills); flag "fratura já reduzida" não espelhada no cliente MP (opção pode aparecer e o servidor recusar).
- Sintaxe `type = double/boolean` do sandbox e `mode:destroy` na receita (sem exemplo local para comparar).
- Animação/sons reaproveitados (`FirstAidApplyAlcohol/Stitch`).
