# More Vehicles Repairs — Descrição Completa do Mod

**ID:** MoreVehiclesRepairs  
**Autor:** Kriger  
**Versão alvo:** Build 42  
**Multiplayer:** Sim

---

## O que é

Adiciona um sistema de **reparo caseiro (gambiarra)** para qualquer peça de veículo.  
Com materiais de sucata encontrados no mundo, você conserta peças danificadas — mas com risco. Não é reparo perfeito: cada ação pode causar ferimentos, queimar a mão, quebrar a ferramenta, ou simplesmente dar errado.

---

## Como usar

1. **Clique direito** em qualquer peça do veículo na tela de mecânica.
2. A opção **"Casual Repair"** aparece em todas as peças.
3. Se a peça estiver reparável, a opção fica ativa; caso contrário, aparece desabilitada com um tooltip explicando o motivo.
4. Tenha os **materiais e ferramentas** no inventário antes de iniciar.
5. A ação é temporizada — o personagem executa a animação de reparo até concluir.

### Quando a opção fica bloqueada (tooltip explica)

| Situação | Motivo exibido |
|---|---|
| Condição já em 100% | "Part is undamaged. Nothing to repair." |
| Condição acima do cap da peça | "Part is too well-maintained for casual repair." |
| Peça não instalada no veículo | "Part is not installed on the vehicle." |
| Faltam materiais ou ferramentas | Lista do que está faltando |

---

## Regra do Cap de Condição

Cada peça tem um **teto máximo** que o reparo caseiro consegue atingir.  
Abaixo do teto → opção habilitada. Acima → bloqueada.  
O reparo adiciona um ganho fixo à condição atual, **clampeado no teto** se ultrapassar.

> Exemplo: Motor com condição 45 → após reparo vira 63 → clampeado em 60 (cap do motor).

---

## Tabela de Peças

| Peça | Materiais necessários | Ferramentas | Ganho | Cap máximo | Risco de falha | Tempo |
|---|---|---|---|---|---|---|
| **Motor** | ScrapMetal x4, SheetMetal x2, Screws x4, DuctTape x2 | Screwdriver, PipeWrench | +18 | 60% | 20% | ~7,5 min |
| **Freios** | ScrapMetal x3, RippedSheets x2, DuctTape x1 | Screwdriver, PipeWrench | +15 | 60% | 20% | ~4 min |
| **Suspensão** | ScrapMetal x3, Wire x2, Screws x4, DuctTape x1 | Screwdriver, PipeWrench | +15 | 60% | 20% | ~4,5 min |
| **Pneu** | DuctTape x2, Glue x1 | *(nenhuma)* | +12 | 50% | 15% | ~3,5 min |
| **Porta** | SheetMetal x2, Screws x4, DuctTape x1 | Screwdriver | +15 | 65% | 10% | ~3,5 min |
| **Vidro / Parabrisa** | DuctTape x2, RippedSheets x3 | *(nenhuma)* | +10 | 40% | 30% | ~2,5 min |
| **Capô** | SheetMetal x2, Screws x4, DuctTape x1 | Screwdriver | +15 | 60% | 15% | ~3,5 min |
| **Porta-Malas** | SheetMetal x2, Screws x4, DuctTape x1 | Screwdriver | +15 | 60% | 15% | ~3 min |
| **Escapamento** | SheetMetal x2, ScrapMetal x2, Wire x2, DuctTape x1 | PipeWrench | +15 | 55% | 20% | ~4 min |
| **Tanque de Combustível** | SheetMetal x3, ScrapMetal x2, Glue x2, DuctTape x2 | Screwdriver, PipeWrench | +12 | 50% | 25% | ~5,5 min |
| **Bateria** | ElectronicsScrap x3, ElectricWire x2, DuctTape x1 | Screwdriver | +12 | 45% | 30% | ~3,5 min |
| **Banco** | LeatherStrips x3, Thread x1, DuctTape x1 | Needle | +15 | 70% | 10% | ~3 min |
| **Rádio** | ElectronicsScrap x2, ElectricWire x2, Screws x2, DuctTape x1 | Screwdriver | +12 | 45% | 35% | ~3,5 min |
| **Farol / Luz** | ❌ **Não reparável** | — | — | — | — | — |
| **Outras peças** (bumper, espelho, antena…) | ScrapMetal x2, DuctTape x1 | Screwdriver | +12 | 50% | 25% | ~3,5 min |

> **Farol não é reparável por design:** lâmpada estourada se substitui, não se conserta com fita.

---

## Influência da Habilidade de Mecânica

A habilidade **Mechanics** reduz a chance de falha:

- Efeito começa a partir do **nível 2** de Mechanics.
- Cada nível acima de 2 reduz o risco em **-2% por nível**.
- O risco **nunca cai abaixo de 5%**, mesmo com skill máximo.

> Exemplo: Reparar a bateria (30% base) com Mechanics 5 → 30% − (3×2%) = 24%.

---

## Eventos Aleatórios

Durante qualquer reparo, eventos aleatórios podem ocorrer:

| Evento | Chance | Efeito |
|---|---|---|
| 🤕 Ferimento na mão | 5% | Arranha a mão do personagem; ele diz "Ouch, cut my hand!" |
| 🔥 Queimadura | 3% | Queima a mão — **só acontece em peças que usam solda** (Motor, Escapamento, Tanque) |
| 🔧 Ferramenta quebra | 5% | Uma ferramenta do inventário é removida |
| 📦 Material extra | 10% | O servidor concede material bônus ao jogador |
| ⭐ Crítico | 5% | O servidor aplica um ganho de condição extra além do normal |
| 😓 Estresse | 10% | Aplica estresse ao personagem |

---

## Peças com Solda (requiresHeat)

As peças abaixo usam improviso de solda na lógica do reparo, o que **habilita o evento de queimadura**:

- Motor
- Escapamento
- Tanque de Combustível

---

## Suporte a Veículos

O mod cobre **todos os veículos do jogo**, incluindo vans, caminhonetes, viaturas policiais e veículos moddados, via dois hooks:

- `ISVehicleMechanics.doPartContextMenu` — hook principal (maioria dos veículos)
- `ISCarMechanicsOverlay.doPartContextMenu` — hook secundário (veículos que usam overlay alternativo no B42)

---

## Multiplayer

- A **validação** (materiais, condição, consumo) ocorre no **servidor**.
- O cliente envia o pedido; o servidor executa e responde com o resultado.
- Eventos como critSuccess e extraMaterial são decididos com autoridade no servidor.

---

## Configuração / Debug

Para desenvolvedores ou quem quiser ver logs no `console.txt`:

```lua
-- Em CasualRepairConfig.lua, linha 4:
MVR_RepairConfig.DEBUG = true   -- liga logs de partId não mapeado e hits do menu
MVR_RepairConfig.DEBUG = false  -- (padrão) console limpo
```
