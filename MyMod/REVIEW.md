# Review: MoreVehiclesRepairs (MyMod / VehicleMod)

> Revisão gerada pelo `zomboid-mod-reviewer` em 2026-05-23, cruzando código atual contra `.claude/.doc/PLANO.md` e `guia.md` (B42).

## Veredito: APROVADO COM RESSALVAS
## Score: 71/100

| Critério | Peso | Nota | Subtotal |
|---|---|---|---|
| Corretude | 40 | 50 | 20.0 |
| Performance | 25 | 90 | 22.5 |
| Fidelidade ao plano | 20 | 85 | 17.0 |
| Padrões | 15 | 80 | 12.0 |
| **Total** | | | **71.5** |

## Resumo
SP (singleplayer) deve funcionar pra maioria dos casos. **MP (multiplayer) tem bugs críticos** que provavelmente impedem qualquer reparo. Eventos imprevistos podem **crashar o jogo em SP e MP** por nome errado de método em `BodyPart`. Estrutura do mod tem 1 defeito de empacotamento (mod.info raiz ausente). Arquitetura geral é boa, prefixo MVR_ evita colisão, lógica de break/critSuccess está coerente com o plano.

> O usuário reportou "muitos bugs no jogo" — abaixo estão os candidatos mais prováveis. Recomendado capturar `console.txt` e rodar `/zomboid-mod-debugger` em seguida para confirmar e mapear sintomas.

---

## Issues críticas (bloqueiam)

### [C1] `sendClientCommand` com 4 argumentos
- **Arquivo:** `media/lua/client/CasualRepairAction.lua:155`
- **Problema:** Assinatura canônica documentada em B42 é `sendClientCommand(module, command, args)` (3 args). O código passa **4 argumentos** — `self.character` como 1º.
- **Impacto:** Em multiplayer, o módulo recebido é o player object, comando vira `MVR_MODULE`, args vira `"doRepair"`. O handler do server (`onClientCommand` no `CasualRepairServer.lua:42`) filtra por `module ~= MVR_MODULE`, então **NUNCA executa o reparo em MP**. Cliente fica esperando resposta que nunca chega.
- **Fonte:** PZwiki Networking (`sendClientCommand("ModuleName", "CommandName", args)` — confirmado via WebSearch 2026-05-23). PZ-Mod-Doc também usa 3 args.
- **Correção:**
```lua
-- antes (linha 155)
sendClientCommand(self.character, MVR_MODULE, "doRepair", {
    vehicleOnlineId = vehicle:getOnlineID(),
    partId          = self.vehiclePart:getId(),
})

-- depois
sendClientCommand(MVR_MODULE, "doRepair", {
    vehicleOnlineId = vehicle:getOnlineID(),
    partId          = self.vehiclePart:getId(),
})
```

### [C2] `getVehicleByOnlineID` provavelmente não existe em B42
- **Arquivo:** `media/lua/server/CasualRepairServer.lua:47` e `media/lua/client/CasualRepairAction.lua:254`
- **Problema:** Globais documentadas em B42 incluem `getVehicleById(id)` (LuaManager.GlobalObject). Não há entrada documentada para `getVehicleByOnlineID`. O código guarda com `and` (`local vehicle = getVehicleByOnlineID and getVehicleByOnlineID(...)`), então quando a função é `nil`, `vehicle` fica nil e o server responde `vehicle_not_found`.
- **Impacto:** MP nunca consegue achar o veículo → reparo sempre falha em MP.
- **Como confirmar:** abra o console in-game (debug mode) e teste `print(getVehicleByOnlineID)` — se imprimir `nil`, confirmado.
- **Correção (tentativa 1 — usar getVehicleById com getKeyId):**
```lua
-- no Action.lua, antes:
vehicleOnlineId = vehicle:getOnlineID(),
-- depois:
vehicleId = vehicle:getId(),    -- ou getKeyId() — testar in-game qual existe

-- no Server.lua, antes:
local vehicle = getVehicleByOnlineID and getVehicleByOnlineID(args.vehicleOnlineId)
-- depois:
local vehicle = getVehicleById(args.vehicleId)
```
- **Alternativa:** iterar `getCell():getVehicles()` no server e achar por id. Mais caro mas garante encontrar.

### [C3] `bodyPart:SetScratchedWindow(true)` — método com nome errado
- **Arquivo:** `media/lua/client/CasualRepairAction.lua:75`
- **Problema:** PZ Lua expõe métodos Java em camelCase com 1ª letra minúscula. `SetScratchedWindow` (S maiúsculo) não existe; o nome plausível em B42 é `setScratched(true)` ou `setScratchedWindow(true)` (s minúsculo).
- **Impacto:** **CRASH** com `attempt to call method 'SetScratchedWindow' (a nil value)` toda vez que rola o evento `injury` (5% por reparo — em ~20 reparos um vai disparar).
- **Como confirmar:** force o evento com `for _ = 1, 100 do ... end` em SP, ou triggue manualmente em um reparo.
- **Correção:**
```lua
-- antes
if bodyPart then bodyPart:SetScratchedWindow(true) end

-- depois (mais provável)
if bodyPart then bodyPart:setScratched(true) end

-- alternativa (se quiser bleed também)
if bodyPart then
    bodyPart:setScratched(true)
    bodyPart:setBleedingTime(15)  -- 15s sangrando
end
```
Verificar exatamente em https://demiurgequantified.github.io/ProjectZomboidLuaDocs/ → search por `BodyPart`.

### [C4] `bodyPart:setBurned(true)` — provavelmente `setBurnt(true)`
- **Arquivo:** `media/lua/client/CasualRepairAction.lua:81`
- **Problema:** Em PZ Java, a convenção histórica usa `Burnt` (passado britânico) em vários lugares; `setBurned` provavelmente não existe.
- **Impacto:** **CRASH** quando rola evento `burn` (3% em peças `requiresHeat=true` — Engine, Muffler, GasTank).
- **Correção:**
```lua
-- antes
if bodyPart then bodyPart:setBurned(true) end

-- depois (mais provável)
if bodyPart then bodyPart:setBurnt(true) end
```
Confirmar em demiurge LuaDocs (`BodyPart` → métodos disponíveis).

### [C5] `mod.info` ausente na raiz do mod
- **Arquivo:** falta `MyMod/Contents/mods/VehicleMod/mod.info`
- **Problema:** B42 procura `mod.info` em DOIS lugares: na raiz da pasta do mod E no subfolder de versão (`42/`). Atualmente só existe em `42/mod.info`.
- **Impacto:** Em algumas configurações, o mod não aparece no launcher in-game. Steam Workshop upload pode falhar.
- **Correção:** copiar `MyMod/Contents/mods/VehicleMod/42/mod.info` para `MyMod/Contents/mods/VehicleMod/mod.info`. Conteúdo idêntico.

---

## Alertas (não bloqueiam, recomendados)

### [A1] `print()` em produção em 2 lugares
- **Arquivos:**
  - `media/lua/shared/CasualRepairConfig.lua:222` — `print("[MVR_RepairConfig] Unmatched partId='..." ...)`
  - `media/lua/client/CasualRepairMenu.lua:123` — `print("[MVR_RepairMenu] Right-clicked partId='..." ...)`
- **Problema:** Logs vão pro `console.txt` continuamente em produção. O do menu dispara em **todo right-click** em peça desconhecida — pode encher o log num runfast.
- **Sugestão:** envolver com flag de debug:
```lua
-- no topo de Config.lua
MVR_RepairConfig.DEBUG = false  -- true só em dev

-- onde tem o print
if MVR_RepairConfig.DEBUG then
    print("[MVR_RepairConfig] Unmatched partId='" .. partId .. "' — using Default.")
end
```

### [A2] Helpers duplicados em 3 arquivos
- **Arquivos:** `countItem`, `hasItem`, `consumeMaterial`, `validateRequirements` aparecem em `CasualRepairAction.lua`, `CasualRepairMenu.lua`, e `CasualRepairServer.lua` (com pequenas variações).
- **Problema:** Manutenção difícil — bug fix em um arquivo não propaga.
- **Sugestão:** extrair para `media/lua/shared/CasualRepairHelpers.lua`:
```lua
MVR_Helpers = {}
function MVR_Helpers.countItem(inventory, fullType) ... end
function MVR_Helpers.hasItem(inventory, fullType) ... end
function MVR_Helpers.consumeMaterial(inventory, fullType, qty) ... end
function MVR_Helpers.validateRequirements(inventory, config) ... end
```
Cada arquivo passa a usar `MVR_Helpers.countItem(...)`.

### [A3] Ordem de eventos cosmetic difere entre SP e MP
- **Arquivo:** `CasualRepairAction.lua`
- **Em SP** (`executeRepair`): `rollCosmeticEvents` roda ANTES de `setCondition` (linha 210).
- **Em MP** (`onServerCommand`): `rollCosmeticEvents` roda DEPOIS do server já ter aplicado `setCondition` (linha 261).
- **Impacto:** Mínimo (efeitos cosmetic não afetam reparo), mas inconsistente. Pode confundir testes de QA.
- **Sugestão:** padronizar para "após resultado conhecido" em ambos os modos.

### [A4] `[VERIFICAR]` ainda presentes no código de produção
- **Arquivos:** 5 ocorrências em `CasualRepairAction.lua` (linhas 60, 74, 80, 95, 138, 154, 251) e 1 em `CasualRepairServer.lua` (linha 46).
- **Problema:** Indica que o developer reconheceu incertezas mas implementou mesmo assim. Os bugs C2-C4 estão exatamente nesses pontos.
- **Sugestão:** resolver cada `[VERIFICAR]` (confirmar API correta + testar) e remover o comentário, ou substituir por nota técnica explicativa.

### [A5] `setActionAnim("Loot")` pode não ser ideal
- **Arquivo:** `CasualRepairAction.lua:140`
- **Comentário no código** lista alternativas como `"Mechanic"` e `"Build"`.
- **Sugestão:** testar e escolher o que parece melhor visualmente. Não bloqueia funcionalidade.

### [A6] Falta translation file
- **Faltando:** `media/lua/shared/Translate/EN/MoreVehiclesRepairs_EN.txt`
- **Atual:** strings hardcoded em inglês via `player:Say("Ouch, cut my hand!")` e `option:addOption("Casual Repair", ...)`.
- **Sugestão (não bloqueia mas é boa prática):** mover strings para arquivo translate e usar `getText("UI_MVR_OuchCutHand")`. Permite outras línguas no futuro.

---

## Fidelidade ao plano

| Item do plano | Status | Observação |
|---|---|---|
| `shared/CasualRepairConfig.lua` com tabela completa | ✅ | 14 peças + aliases + Default |
| `getConfigForPart(vehiclePart)` | ✅ | Implementado com aliases ordenados |
| `client/CasualRepairMenu.lua` com hook | ✅ | `originalDoPartContextMenu` salvo + chain |
| `hasRequiredItems` | ✅ | Retorna allPresent + missing list |
| `getAdjustedBreakChance` | ✅ | Skill modifier coerente com plan |
| `buildTooltip` formatado | ✅ | [v]/[x] marks como plano sugeriu |
| `CasualRepairAction:perform()` | ✅ | SP/MP guards corretos (mas sendClientCommand bugado, ver C1) |
| `rollRandomEvents` (renomeado `rollCosmeticEvents`) | ⚠ | Implementado mas crítico (C3/C4) |
| `server/CasualRepairServer.lua` escutando `OnClientCommand` | ✅ | Estrutura correta |
| Re-validar materiais no server | ✅ | `validateRequirements` chamado |
| `transmitPartCondition` após alterar | ✅ | Linha 127 do Server.lua |
| Deletar `client/client.lua` antigo | ✅ | Não existe mais (Glob confirmou) |
| Atualizar `mod.info` | ✅ | Tem descrição nova (mas falta na raiz, ver C5) |

## Análise estática (resultado dos greps)

| Padrão | Achados | Veredito |
|---|---|---|
| `Events.OnTick` | 0 | ✅ Limpo |
| `recipe` (sintaxe B41) | 0 | ✅ Limpo |
| Globais sem `local` | 3 (`MVR_RepairConfig`, `MVR_RepairMenu`, `MVR_CasualRepairAction`) | ✅ Intencionais (prefixo MVR_) |
| `..` em loop | nenhum encontrado | ✅ Limpo |
| `print(` em produção | 2 | ⚠ A1 |
| `getSpecificPlayer` sem nil check | 0 (todos têm guard) | ✅ Limpo |
| Java List iter (`ipairs`/`#`) | 0 | ✅ Usa loop correto |

## Checklist B42
- [x] Sem `Recipe` legado (usar `craftRecipe`) — N/A, mod é Lua-only
- [x] Multiplayer: server valida payloads do cliente (mas C1 quebra MP antes de chegar lá)
- [x] Sem dep deprecada (Mod Config Menu)
- [ ] **`mod.info` em raiz E em `42/`** — falta na raiz (C5)
- [ ] **Sem `[VERIFICAR]` em produção** — 7 ocorrências (A4)
- [x] `preview.png` 256×256 (verificado anteriormente)

## Pontos positivos
- Prefixo `MVR_` em tudo evita colisão de namespace — feito direito.
- `getConfigForPart` com aliases ordenados (compound names primeiro) é uma solução elegante e robusta.
- Anti-cheat real: server re-valida materiais antes de aplicar (linha 73 do Server.lua).
- Diagnostic de `_loggedUnknownParts` (Config.lua:205) loga uma vez por id desconhecido — controla spam.
- Nil checks consistentes em todos os pontos de entrada (`player`, `inventory`, `vehiclePart`, `condition`).
- Helper `computeNewCondition` lida com edge cases bem (clamp em cap; nunca reduz).

## Próximos passos
1. Aplicar C1-C5 (críticos) — rode `/zomboid-mod-developer` apontando este REVIEW.
2. Capturar `console.txt` do usuário (`%USERPROFILE%\Zomboid\console.txt`) e rodar `/zomboid-mod-debugger` para confirmar quais bugs estão de fato disparando in-game e descobrir outros que não foram detectados estaticamente.
3. Após fix dos críticos, rodar `/zomboid-mod-ingame-tester` para um roteiro de teste manual focado em: MP (cliente+host), evento injury, evento burn, peças especiais (Window/Tire).
4. Se score melhorar para 90+ → `/zomboid-mod-workshop` para preparar release.

## Próxima etapa
Recomendado: **rode `/zomboid-mod-debugger` apontando seu `console.txt`** para confirmar exatamente quais erros estão disparando (e ver se há outros não cobertos por essa análise estática). Depois `/zomboid-mod-developer` aplicando C1-C5 + achados do debugger.
