# guia.md — Workspace PZ Mods

> Fonte de verdade do workspace. Gerado pelo zomboid-guia-bootstrapper em 2026-05-23.
> Não edite à mão sem rodar de novo o bootstrapper.

## Versão alvo
- Build: **Build 42 (42.13.x)**
- Última atualização: 2026-05-23

## Docs canônicas
| Recurso | URL |
|---|---|
| Lua API (B42, versão 42.13.0) | https://demiurgequantified.github.io/ProjectZomboidLuaDocs/ |
| Java API (B42) | https://demiurgequantified.github.io/ProjectZomboidJavaDocs/ |
| Modding wiki | https://pzwiki.net/wiki/Modding |
| Lua events stubs | https://github.com/demiurgeQuantified/PZEventStubs |
| Modding guide (comunidade) | https://github.com/FWolfe/Zomboid-Modding-Guide |
| Awesome B42 | https://github.com/JBD-Mods/awesome-project-zomboid-build42-resources |
| B42 mod template | https://github.com/LabX1/ProjectZomboid-Build42-ModTemplate |
| Tutorials (MrBounty) | https://github.com/MrBounty/PZ-Mod---Doc |
| Lua (API) wiki | https://pzwiki.net/wiki/Lua_(API) |

## Estrutura de mod B42 (canônica)
```
<ModName>/
├── Contents/mods/<ModName>/
│   ├── mod.info            # raiz — exigido
│   └── 42/
│       ├── mod.info        # duplicado, versionado B42 — exigido
│       ├── media/
│       │   ├── lua/{client,server,shared}/
│       │   ├── scripts/    # .txt (item, craftRecipe, evolvedrecipe, fixing, sound, vehicle)
│       │   └── Translate/EN/<ModName>_EN.txt
│       ├── poster.png      # opcional, referenciado por mod.info
│       └── icon.png        # opcional
├── preview.png             # 256×256 — exigido pelo Steam
└── workshop.txt            # gerado pelo in-game uploader
```

## Campos do mod.info (B42)
| Campo | Obrigatório | Notas |
|---|---|---|
| `name` | sim | Display name |
| `id` | sim | Identificador único; usado em `require=` por outros mods |
| `description` | sim | 1-2 linhas; mostrado in-game |
| `poster` | sim | Caminho de arquivo dentro do mod (PNG) |
| `icon` | sim | PNG menor |
| `author` | recomendado | — |
| `require` | opcional | Lista separada por vírgula com id de outros mods |
| `pack`, `tiledef` | opcional | Tile packs / .tiles |
| `versionMin`, `versionMax` | opcional | Faixa de build compatível |

## Eventos mais usados (assinaturas)
> Lista completa (170+ eventos): `.claude/.doc/research-findings.md` §1.2.

### Periódicos / lifecycle
| Evento | Assinatura | Quando |
|---|---|---|
| `Events.OnGameBoot` | `()` | Após startup do jogo |
| `Events.OnGameStart` / `OnLoad` | `()` | Cliente entra no mundo |
| `Events.OnNewGame` | `(player, square)` | Primeiro load do player |
| `Events.OnInitGlobalModData` | `(newGame: boolean)` | ModData global inicializa |
| `Events.OnSave` / `OnPostSave` | `()` | Durante / após save |
| `Events.EveryOneMinute` | `()` | A cada 1 min in-game — **preferir ao OnTick** |
| `Events.EveryTenMinutes` | `()` | A cada 10 min in-game |
| `Events.EveryHours` | `()` | Início de cada hora |
| `Events.EveryDays` | `()` | 0:00 in-game |
| `Events.OnTick` | `(tick: double)` | **CARO — evitar** |
| `Events.OnTickEvenPaused` | `(tick: double)` | **CARO** |

### Player / character
| Evento | Assinatura |
|---|---|
| `Events.OnPlayerUpdate` | `(player: IsoPlayer)` — hot path |
| `Events.OnPlayerMove` | `(character: IsoPlayer)` — mais barato |
| `Events.OnPlayerDeath` | `(player: IsoPlayer)` |
| `Events.OnPlayerGetDamage` | `(character, damageType, damage)` |
| `Events.OnEquipPrimary` / `OnEquipSecondary` | `(character, item)` |
| `Events.OnHitZombie` | `(zombie, attacker, bodyPart, weapon)` |
| `Events.AddXP` | `(character, perk, amount)` |
| `Events.LevelPerk` | `(character, perk, level, increased)` |

### UI / Input (B42)
| Evento | Assinatura |
|---|---|
| `Events.OnPreUIDraw` / `OnPostUIDraw` | `()` |
| `Events.OnMouseDown` / `OnMouseUp` | `(x: double, y: double)` |
| `Events.OnRightMouseDown` / `OnRightMouseUp` | `(x: double, y: double)` |
| `Events.OnKeyStartPressed` | `(key: integer)` |
| `Events.OnKeyPressed` | `(key: integer)` (key liberada) |
| `Events.OnKeyKeepPressed` | `(key: integer)` (frame a frame com key segurada) |
| `Events.OnFillInventoryObjectContextMenu` | `(playerNum, context, items)` |
| `Events.OnFillWorldObjectContextMenu` | `(playerNum, context, worldobjects, test)` |
| `Events.OnPreFillInventoryObjectContextMenu` | `(playerNum, context, items)` |
| `Events.OnPreFillWorldObjectContextMenu` | `(playerIndex, context, worldobjects, test)` |

### Vehicle
| Evento | Assinatura |
|---|---|
| `Events.OnEnterVehicle` / `OnExitVehicle` | `(character)` |
| `Events.OnUseVehicle` | `(character, vehicle: BaseVehicle, pressedNotTapped)` |
| `Events.OnSwitchVehicleSeat` | `(character)` |
| `Events.OnVehicleDamageTexture` | `(driver)` |
| `Events.OnMechanicActionDone` | `(character, success, vehicleId, partType, itemId, installing)` |

### Multiplayer
| Evento | Assinatura |
|---|---|
| `Events.OnClientCommand` | `(module, command, player, args)` (server-side) |
| `Events.OnServerCommand` | `(module, command, args)` (client-side) |
| `Events.OnReceiveGlobalModData` | `(key, data: table\|false)` |
| `Events.OnConnected` / `OnDisconnect` | `()` |
| `Events.OnServerStarted` | `()` |

## APIs proibidas / mudadas em B42
| Item | B41 | B42 | Migração |
|---|---|---|---|
| Receitas | `recipe X { ... }` (top-level) | `module M { craftRecipe X { tags, requirements, ... } }` | Reescrever toda receita (sistema novo, sintaxe diferente, tags/categoria) |
| Mod Config | Dependência do mod "Mod Config Menu" | `PZAPI.ModOptions` nativo | Substituir API (mais simples agora) |
| Folder structure | Direto em `Contents/mods/<Mod>/` | Subfolder `42/` obrigatório | Adicionar `Contents/mods/<Mod>/42/{mod.info, media/}` |
| Right-click barricade vanilla | Disponível | Removido em B42 | Usar mod `BarricadeContextMenu` ou recriar |
| Crafting UI | janela B41 | nova janela B42 com tags/categorias | Receitas precisam de `category` e `tags` no novo formato |
| Eventos UI | warnings sobre `OnPreUIDraw`/`OnKey*` | Agora oficiais | Já reconhecidos; warnings antigos = mod desatualizado |

## Pitfalls a evitar (top 10)
> Lista completa (23 pitfalls): `.claude/.doc/research-findings.md` §2.

1. **Não use `OnTick`/`OnTickEvenPaused`** para lógica recorrente. Use `EveryOneMinute`/`EveryTenMinutes` ou contador em `OnPlayerUpdate`.
2. **Sempre nil-check** `getSpecificPlayer(N)`, `getInventory()`, `getItems()` — retorno pode ser nil em save/load/MP.
3. **`Events.X.Add(fn)` sem parênteses.** `fn()` chama a função; `fn` passa referência.
4. **Java List é 0-indexed**, não use `ipairs`/`#`/`[]`. Use `for i=0, list:size()-1 do list:get(i) end`.
5. **`local` para TUDO.** Namespace global do PZ já está poluído.
6. **ModData NÃO sincroniza automaticamente.** Use `sendClientCommand`/`sendServerCommand` para dados grandes, `ModData.transmit` só para pequenas.
7. **Server NUNCA confia em payload de cliente** em MP — valide tudo server-side antes de modificar estado autoritativo.
8. **`mod.info` em DOIS lugares**: `Contents/mods/<Mod>/` E `Contents/mods/<Mod>/42/`.
9. **`preview.png` deve ser 256×256** (PNG). Steam rejeita outros tamanhos pelo in-game uploader.
10. **Não sobrescreva funções vanilla** sem guardar referência:
    ```lua
    local orig = SomeClass.fn
    SomeClass.fn = function(self, ...) orig(self, ...); -- extra end
    ```

## Multiplayer: padrão canônico
```lua
-- Client envia ação
sendClientCommand("MyMod", "DoThing", { foo = 1 })

-- Server escuta, valida e responde
local function onClientCmd(module, command, player, args)
    if module ~= "MyMod" then return end
    if command == "DoThing" then
        -- 1. valida args (cliente é untrusted)
        -- 2. executa lógica autoritativa
        -- 3. responde ao cliente
        sendServerCommand(player, "MyMod", "DoThingResult", { ok = true })
    end
end
Events.OnClientCommand.Add(onClientCmd)

-- Cliente recebe resultado
local function onServerCmd(module, command, args)
    if module ~= "MyMod" then return end
    if command == "DoThingResult" then
        -- atualizar UI client-side com o resultado autoritativo
    end
end
Events.OnServerCommand.Add(onServerCmd)
```

Guards de contexto: `isClient()`, `isServer()`, `isCoopHost()`.
Player ID: `player:getOnlineID()` (cliente) ↔ `getPlayerByOnlineID(id)` (server).

## ModData (sync limitado)
```lua
-- get ou cria
local data = ModData.getOrCreate("MyMod_State")
data.foo = 1

-- transmit (small payloads only!)
ModData.transmit("MyMod_State")

-- listen
Events.OnReceiveGlobalModData.Add(function(key, data)
    if key ~= "MyMod_State" then return end
    -- usar data (pode ser false em alguns casos)
end)
```

## Timed action (custom)
```lua
require "TimedActions/ISBaseTimedAction"
MyTimedAction = ISBaseTimedAction:derive("MyTimedAction")

function MyTimedAction:isValid()       return true end
function MyTimedAction:waitToStart()   return false end
function MyTimedAction:start()         end
function MyTimedAction:update()        end
function MyTimedAction:stop()          ISBaseTimedAction.stop(self) end
function MyTimedAction:perform()       ISBaseTimedAction.perform(self) end

function MyTimedAction:new(character)
    local o = {}
    setmetatable(o, self); self.__index = self
    o.character = character
    o.maxTime = 30
    if o.character:isTimedActionInstant() then o.maxTime = 1 end
    return o
end

-- uso:
ISTimedActionQueue.add(MyTimedAction:new(player))
```
Local do arquivo: `media/lua/client/TimedActions/`.

## Scripts (.txt) — blocos por tipo (B42)
| Bloco | Sintaxe-chave |
|---|---|
| `module X { ... }` | container; itens são `X.NomeDoItem` |
| `imports { Base }` | usar nomes sem prefixo |
| `item X { prop = val, ... }` | item; usa `=` |
| `craftRecipe X { ... }` | receita B42 (novo); usa `prop:val` e `tags`, `category`, `requirements` |
| `evolvedrecipe X { BaseItem:Y, ResultItem:Z, ... }` | transformação |
| `fixing X { Require:Y, Fixer:Z=N }` | reparo (Require/Fixer) |
| `sound X { category=Item, clip { event=..., distanceMax=... } }` | áudio; `distanceMax` controla raio MP |
| `vehicle X { ... }` | veículo |

> Receitas B41 (`recipe`) **não funcionam em B42** — precisam ser reescritas como `craftRecipe`.

## Convenções do workspace
- Pasta de cada mod: `<ModName>/Contents/mods/<ModName>/42/...`
- Código em **inglês** (identificadores, comentários inline). Output ao usuário em **PT-BR**.
- Comentários apenas para "por quê" não-óbvio; nunca narrar "o quê".
- Sem `print()` em produção (use `[Mod] DEBUG: ...` com flag se necessário, e remova antes de publicar).
- Translations em `media/lua/shared/Translate/EN/<ModName>_EN.txt` (e `PT/`, etc.).
- Namespace via tabela local: `local MOD = MOD or {}; ...; return MOD`.
- Prefixo nos nomes de classes e timed actions: `<ModPrefix>_<Nome>` (ex.: `MVR_RepairAction`).

## Logs do jogo
- Windows: `%UserProfile%\Zomboid\console.txt` + `%UserProfile%\Zomboid\Logs\*.zip` (rotativos)
- Linux: `~/Zomboid/console.txt`
- MP server: `coop-console.txt` na mesma pasta
- Debug mode: launch options Steam → `-debug` (libera F11 e console expandido)

## Pipeline de skills deste workspace
```
guia-bootstrapper → planner → developer → reviewer → ingame-tester → workshop
                                ↑           ↓
                            debugger ←── BUGS.md
                            migrator (B41→B42)
                            balance-auditor (numbers)
                            orchestrator (triagem)
```
Veja `PIPELINE.md` na raiz para diagrama mermaid e fluxo completo.
