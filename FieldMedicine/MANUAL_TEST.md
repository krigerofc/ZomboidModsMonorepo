# Teste manual - Field Medicine '93 (KRFieldMedicine)

Testes automáticos (`npm test`) cobrem fórmulas, gating, clamps, referências de itens, paridade EN/PT-BR e a integração com o motor mockado. Este roteiro cobre o que só dá para ver no jogo.
Referência: vanilla B42.19.2 (alvo 42.21). Mod **só B42**. Sem id de Workshop ainda (item novo).

## 1. Preparação
1. Copie/aponte `C:\Users\pedro\Zomboid\Workshop\FieldMedicine` como mod local (pasta `Zomboid\Workshop`).
2. Steam > PZ > Propriedades > Opções de inicialização: `-debug -debugtranslation`.
3. Menu Mods: ative **Medicina de Campo '93** (nome/descrição em PT-BR vêm de `Mod.json`). Ícone/pôster são **placeholder** (cópia do ModTemplate + ícone cinza gerado).
4. Novo jogo > Sandbox > página **Medicina de Campo '93**: 10 opções com textos e tooltips em PT-BR, nenhuma chave crua `Sandbox_KFM_...`.
5. Depois de cada sessão: `grep -iE "error|exception|stack trace|KFM" C:\Users\pedro\Zomboid\console.txt` → nenhum erro do mod.

## 2. Itens e receita
| Passo | Esperado |
|---|---|
| Debug > Items List: `KFM_ImprovisedTourniquet` | "Torniquete Improvisado", categoria Primeiros Socorros, tooltip PT-BR |
| Crafting (aba Médico): 2 `RippedSheets` + 1 `WoodenStick2` | Receita "Fazer Torniquete Improvisado" gera 1 torniquete |

## 3. Lesões de teste
Painel de saúde (debug) > botão direito na parte > **Cheat > Part change**: Toggle Laceration / Deep Wound / Bleeding / Fracture / Infected / Bite. Nível de Primeiros Socorros: Debug > Player Stats (ou "Stats and Body").
Spawnar itens: `Base.Stethoscope`, `Base.TongueDepressor`, `Base.WaterBottle` (encha na pia), `Base.Belt2`, `Base.Scalpel`, `Base.KitchenKnife`, `Base.Lighter`, `Base.Gloves_Surgical`, `Base.Pills`.

## 4. Exame clínico (F1)
| Passo | Esperado |
|---|---|
| Botão direito no Estetoscópio no inventário | "Examinar a si mesmo"; ao fim abre janela "Exame clínico (você mesmo)" |
| Nível 0, sem estetoscópio | Só "Estado geral" + dica "Com mais Primeiros Socorros..." |
| Nível 1 + febre (Debug > Stats and Body > Temperature 38.9) | Linha "Febre alta. Muitas coisas podem causar isso." |
| Personagem mordido (Toggle Bite) com febre | **Mesmo texto** de febre. Nenhuma linha sobre zumbi/infecção zumbi em nenhum nível |
| Nível 3 + fratura | "<parte>: fratura, ..." (faixa) |
| Nível 3 + estetoscópio + ferida com `Infected` ainda não visível | Conta como nível 4: "a ferida parece inflamada" |
| Abaixador de língua no inventário | Consumido; aparecem hidratação e garganta mesmo no nível 0 |
| Sandbox "Exame mostra febre" = falso | Linha de febre some |
| XP | +2 Primeiros Socorros só se houver algo a diagnosticar; repetir no mesmo paciente em < 6 h não dá XP |

## 5. Irrigação (F2)
| Passo | Esperado |
|---|---|
| Laceração sem curativo + garrafa com ≥ 0,25 L de água limpa | Menu "Medicina de Campo > Irrigar ferida > <garrafa>"; água cai 0,25 L; dor +5; balão "Ferida lavada." |
| Com Toggle Infected antes | Infecção diminui (painel debug mostra o nível com `-debug`) |
| Água contaminada (pia sem água tratada) | Balão "Essa água não estava limpa..."; ferida fica infectada |
| Ferida enfaixada/suturada | Opção não aparece |

## 6. Torniquete (F3)
| Passo | Esperado |
|---|---|
| Nível 0, Deep Wound + Bleeding no antebraço | "Aplicar torniquete" aparece **desabilitado** com "Requer Primeiros Socorros nível 1" |
| Nível 1, aplicar no braço (UpperArm) | Item some do inventário; sangramento do braço/antebraço/mão para; balão "Torniquete apertado..." |
| Esperar 1 min de jogo com novo sangramento na mão | Continua parado |
| Avançar > 2 h (sandbox padrão) | Parte perde saúde e dói a cada 10 min |
| Avançar > 6 h | Parte ganha fratura longa (dano duradouro) |
| "Remover torniquete" | Item volta; feridas não tratadas voltam a sangrar; feridas suturadas/enfaixadas não |
| Cinto (`Belt2`, não vestido) | Funciona igual, chance de falha +5 p.p. |
| Torso/pescoço/mão | Sem opção |

## 7. v1.1: cauterização, redução de fratura, debridamento
| Passo | Esperado |
|---|---|
| Nível 3 + faca + isqueiro + Deep Wound | "Cauterizar ferida": demora mais (aquecer), gasta 1 uso do isqueiro, ferida profunda some, queimadura que precisa limpar |
| Nível 2 sozinho | Desabilitado; com outro jogador ao lado do paciente (MP) fica liberado (ajudante −1) |
| Mordida | Sem opção de cauterizar |
| Nível 5 + fratura, paciente em pé | Desabilitado "O paciente precisa estar sentado ou deitado" |
| Sentado, reduzir | Tempo de fratura cai ~35% (nível 5); dor forte (metade com Pills tomadas antes); não aparece de novo para a mesma fratura |
| Nível 6 + bisturi + ferida infectada (Toggle Infected) | "Debridar ferida": infecção zerada, volta a sangrar, pede curativo |
| Hemofóbico | Pânico +50 em cauterização/debridamento |

## 8. Multiplayer (host + dedicado local, 2 clientes)
1. Cliente A pede "Exame médico" (vanilla) em B, B aceita; na janela de saúde de B, botão direito numa parte → submenu "Medicina de Campo".
2. Exame: laudo aparece só para A. Procedimentos: painel de saúde de **ambos** atualiza (sangramento, queimadura, fratura).
3. Torniquete aplicado por A em B: B vê "Remover torniquete" no próprio painel; desconectar/reconectar B e conferir que o torniquete continua (modData no servidor) e que a opção volta.
4. `console.txt` do servidor e dos clientes sem erros `KFM`.

## 9. Compatibilidade
Carregar junto com mods médicos populares (ex.: The Only Cure): o menu vanilla continua inteiro; nosso submenu é acrescentado no fim.
