# Smoke test — servidor dedicado PZ 42.19.2 com os 5 mods

Data: 2026-10-17/21. Jogo local: `E:\SteamLibrary\steamapps\common\ProjectZomboid` (42.19.2).

## Método

- Isolado: `-cachedir=%TEMP%\claude\...\scratchpad\pzserver` (nada em `C:\Users\pedro\Zomboid` tocado).
- Comando = java de `ProjectZomboidServer.bat` (`zombie.network.GameServer`, `-Xmx3072m`, ZGC) +
  `-nosteam -cachedir=... -adminpassword test -servername smoke -debug`, iniciado via `Start-Process` (PID próprio).
- Mods copiados de `Workshop/*/Contents/mods/<Mod>` (working tree) para `<cachedir>\mods\`.
  `Server\smoke.ini`: `Mods=ReduceMetal&Wood50x;Passiveskillskr;Krjobs;MoreVehiclesRepairs;KRFieldMedicine`, `UPnP=false`.
  `Saves` apagado antes de cada run (mundo novo).
- Pronto = `LuaNet: Initialization [DONE]` + UDP 16261 aberto + loop de jogo rodando (`Reseeding weather`); +20 s; depois
  `taskkill /PID <pid> /F` só no PID iniciado.
- Análise: stdout, stderr (traces Kahlua vão para stderr) e `server-console.txt`/`Logs` (rotacionam — boot completo só no stdout).
  Assinaturas de `ERROR|WARN|Exception|STACK TRACE|attempted index|Tried to call nil|non-table|Unexpected symbol|missing|not found|Failed`
  normalizadas (números → N) e comparadas com baseline sem mods.

## Runs

| Run | Mods | Resultado |
|---|---|---|
| base | nenhum | sobe. Ruído vanilla: sprites duplicados, `Missing ThumpSound`, `Could not find icon` (servidor sem texturas), `IsoPropertyType ... ladderW/Countertop`, `recursive require() WorldGen`, `refusing to list examplemod` |
| run1 | 5 | sobe; os 5 `loading <id>`. **10526 stack traces** `no method getMetalValue` (ReduceMetalWood, `Core.lua:34`, 2 passes × 5263 itens) |
| run2 | 5 (com fix) | sobe; stdout e stderr **idênticos ao baseline** fora das linhas de log dos mods. Limpo |

## Erros encontrados / corrigidos

- **ReduceMetalWood** — `Core.call` fazia `error("no method ...")` dentro de `pcall` para métodos inexistentes
  (`Item:getMetalValue` não existe no B42, já listado em API-CHECK-42.21). Em `-debug` cada erro capturado despeja stack
  trace completo → 10526 traces/boot. Fix: lookup fora do `pcall`, retorna `false` sem `error()` (B42 + B41).
  Commit `ddee1e0` (ReduceMetalWood). `npm test` OK.
- PassiveSkills, KRjobs, BasicVehicleMaintenance, FieldMedicine: nenhum erro/aviso novo vs baseline.

## Confirmações de carga

- `loading ReduceMetal&Wood50x / Passiveskillskr / Krjobs / MoreVehiclesRepairs / KRFieldMedicine`; overrides de
  translate JSON + `sandbox-options.txt` registrados.
- `smoke_SandboxVars.lua` gerado com blocos `ReduceMetalWood`, `PassiveSkills`, `MVR`, `KFM` (KRjobs não tem sandbox).
- ReduceMetalWood: `loaded v2.0.0`; `applied (OnInitGlobalModData, server) ... changed=148 failed=0 scanned=5263`;
  `OnServerStarted` idempotente (`changed=0 unchanged=148`).
- Scripts (itens/receitas KFM, revistas PassiveSkills, traits/profissões KRjobs) parseados sem warning de script/receita/tradução.
  Os outros 4 mods não imprimem linha de boot no servidor.

## Não coberto / restante

- Lua `media/lua/client` não roda no servidor dedicado (PassiveSkills, BVM, FieldMedicine têm 1 arquivo client cada) —
  menus de contexto, UI e ações de jogador não exercitados. Sem cliente conectado: `OnFillContainer`, timed actions,
  leitura de revistas, criação de personagem com profissões KRjobs não testados.
- Teste em 42.19.2; a 42.21 transforma receita/tradução ausente em RuntimeException — os itens "Incertos" de
  API-CHECK-42.21 (GrantedRecipes KRjobs, `KFM_recipes.txt`) seguem a validar num boot 42.21 (aqui não deram nem aviso).
- Os runs usaram o working tree, que tinha edições não commitadas de outro agente em ReduceMetalWood (Classifier, mod.info, Mod.json…).
