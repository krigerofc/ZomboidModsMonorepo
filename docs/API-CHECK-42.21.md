# Checagem de API B42 → 42.21 (5 mods)

Data: 2026-10-17. Escopo: todo Lua em `Contents/mods/*/42/` e scripts `42/media/scripts/*.txt` dos 5 mods.

## Fontes

- Stubs PZ-Umbrella tag `42.21.0` (release sem assets → zip do tag), extraídos em
  `%TEMP%\claude\...\scratchpad\umbrella\Umbrella-42.21.0\library` (`java/`, `lua/`, `events.lua`). Nada executado.
- Stubs Umbrella `42.19.0` para diff 42.19→42.21 (jogo local é 42.19.2).
- Patch notes 42.21.0: pzwiki `Build_42.21.0?action=raw` e fórum TIS tópico 101693. **Nenhuma renomeação de API/Lua,
  item, receita, trait, perk ou tag anunciada.** Itens relevantes: `loadstring` reabilitado; Welder começa com receitas
  de Welding; **"RuntimeException when missing translations, missing recipes etc. are detected"** (antes só `System.err`)
  → ids de receita/tradução inválidos agora derrubam o boot.
- Javadocs (demiurgequantified) não consultados: os stubs Umbrella são gerados das mesmas classes expostas e cobrem tudo.

## Método

Script `scratchpad\tools\apicheck.js` (indexa stubs 42.21 e 42.19; extrai do código: `Events.*`, enums
`Perks/CharacterStat/ItemTag/CharacterTrait/CharacterProfession/BodyPartType/ItemBodyLocation`, chamadas `:metodo(`,
nomes de método em string para `pcall`, globais, membros de classes Lua vanilla). Depois: checagem por classe exata
(com herança) dos receptores principais, diff de assinaturas 42.19→42.21 de todo método usado, hooks Lua vanilla,
nomes dinâmicos (`Perks[...]`, `ItemTag[...]`, `ItemBodyLocation[...]`) e ids `Base.*` contra `ItemKey.*` 42.21.

## Resultado por mod

| Mod | refs API únicas | ids `Base.*` | faltando 42.21 | corrigido |
|---|---|---|---|---|
| ReduceMetalWood | 37 | 50 | 1 (pré-existente, protegido) | 0 |
| PassiveSkills | 37 (+34 perks) | 1 | 0 | 0 |
| KRjobs | 13 (+57 receitas, perks XPBoosts) | 18 | 0 | 0 |
| BasicVehicleMaintenance | 172 | 17 | 0 | 0 |
| FieldMedicine | 227 | 15 | 0 | 0 |

`npm test`: os 5 passam (ALL TESTS PASSED). Nenhum commit de código foi necessário.

## Faltando / renomeado

- `ReduceMetalWood/42/media/lua/shared/ReduceMetalWood/Core.lua:92` — `Item:getMetalValue()` **não existe** no `Item`
  de script (nem 42.19 nem 42.21; só `InventoryItem:getMetalValue`). Já está em `pcall` → retorna 0; a regra
  "MetalValue" do `Classifier.lua:236-239` fica inerte no B42 (tags/nome continuam classificando). Não é quebra da 42.21.
- Nenhum `Events.*`, enum, global ou método usado foi removido/renomeado entre 42.19 e 42.21.
- `ItemKey` 42.21 == 42.19 (5097 chaves, 0 removidas) → nenhum item vanilla renomeado. Todos os `Base.*` usados existem,
  exceto entradas B41-only intencionais em `ReduceMetalWood/.../Classifier.lua:112,134,135` (`Base.PlankNail`,
  `Base.TreeBranch`, `Base.WoodenStick`, chaves de tabela, inofensivas) e o item próprio `Base.KFM_ImprovisedTourniquet`.

## Mudanças de assinatura 42.19→42.21 que tocam APIs usadas (compatíveis)

- `getText(txt, ...)`: sobrecargas fixas viraram varargs (`getText(txt, args)`) — chamadas com 1..N args seguem válidas.
- `BaseVehicle:getPartById/getPartByIndex/getPartCount` movidos para a interface `VehiclePartOwner`, que `BaseVehicle`
  implementa — `BasicVehicleMaintenance/.../MVR/Game.lua`, `Menu.lua` OK.
- `IsoGridSquare:getDoor(boolean)` → `getDoor(GridSquareEdge…)`; os mods só usam `VehiclePart:getDoor()`
  (`BasicVehicleMaintenance/.../client/MVR/Menu.lua:140,143`) — sem impacto.
- `Events.OnFillContainer`: só o tipo do 3º parâmetro renomeado (`ItemPickerJava.ItemPickerContainer`) — sem impacto.
- `Events.LevelPerk` agora (Server); novo `Events.AcceptedMedicalCheck` — não usados.

## Verificado explicitamente (amostra)

- Hooks vanilla inalterados: `ISHealthPanel.{doBodyPartContextMenu,getBandageType,setBodyPartActionForPlayer,DidPatientMove}`,
  `ISReadABook:{new,isValid,perform,complete}`, `ISVehicleMechanics:doPartContextMenu`, `ISVehicleMenu.onExit`,
  `ISVehiclePartMenu.toPlayerInventory`, `VehicleUtils.RequiredKeyNotFound`, `ISPathFindAction:pathToVehicleArea`,
  `ISInventoryTransferUtil.newInventoryTransferAction`, `ISTimedActionQueue.add`, `ISBaseTimedAction:{new,perform,stop,derive}`.
- Enums: `Perks.*` (34 nomes do Catalog + Fitness/Strength), `ItemTag.{SCREWDRIVER,SEWING_NEEDLE,WRENCH,SHARP_KNIFE,START_FIRE,MAGAZINE}`,
  `ItemBodyLocation.{HANDS,HANDS_LEFT,HANDS_RIGHT,MASK}`, `CharacterStat.{UNHAPPINESS,PANIC,TEMPERATURE,THIRST,HUNGER,ENDURANCE}`,
  `CharacterTrait.{HEMOPHOBIC,get,register}`, `CharacterProfession.register`, `Capability.CanMedicalCheat`,
  `ItemType.{LITERATURE,NORMAL}`, `ModelKey.{MAGAZINE,MAGAZINE_GROUND,RIPPED_SHEETS}`.
- Globais: `addXp/addXpNoMultiplier(player, perk, amount)`, `syncBodyPart(bp, int)`, `syncPlayerStats(player, int)`,
  `sendItemStats`, `send{Add,Remove}Item*Container`, `instanceItem`, `getScriptManager():getAllItems()/FindItem()` — assinaturas iguais.
- `KRjobs/.../KRjobs/Core.lua:19` `player:HasTrait` não existe no B42, mas é fallback B41 após o caminho
  `CharacterTrait.get(ResourceLocation.of(id))` + `hasTrait` — correto.

## Incertos (não verificáveis só com stubs)

1. **Receitas vanilla em `GrantedRecipes`** (`KRjobs/42/media/scripts/KRjobs_traits.txt`, ex. linhas 34, 46, 112; 57 ids
   únicos) — confirmadas no 42.19.2 local; Umbrella não traz registro de craftRecipe. Patch notes não citam renomeação,
   mas 42.21 agora lança RuntimeException em receita ausente → **validar no boot 42.21**.
2. `FieldMedicine/42/media/scripts/KFM_recipes.txt:5,7,8` — `timedAction = Making`, `Tags = InHandCraft;Health`,
   `category = Medical` (ok no 42.19.2; sem registro nos stubs).
3. Ícones por nome (`Icon = Rag` em `KFM_items.txt`, `MagazineSkillsPhoto` em `PassiveSkills_Magazines.txt`) — texturas não constam nos stubs.
4. `FieldMedicine/.../KFM/Game.lua:66-71` — casa ids via `tostring(CharacterProfession)` / `tostring(CharacterTrait)`;
   `toString()` existe, formato `"krjobs:surgeon"` só confirmável em jogo (já em `pcall`).
5. `getText` varargs (acima) — esperado compatível; confirmar textos com argumentos no teste em jogo.
6. `Item:getMetalValue` (acima) — regra inerte no B42; decidir se vale ler `MetalValue` de outra forma.

Total incertos: 6. Nenhum guard extra adicionado: os pontos de código já estão em `pcall`/checagem de nil.
