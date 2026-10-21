# Teste manual - Reduce Metal&Wood v2

Pesos de referência: vanilla B42.19.2. Na 42.21 ou em outros mods os valores originais podem mudar; o que importa é que o novo valor seja `original x (100 - %) / 100`.

## 1. Preparação

1. Não deixe outra cópia do mod ativa (Workshop inscrito ou `Zomboid/mods`): a pasta `C:\Users\pedro\Zomboid\mods\ReducedMetal&Wood50x` já foi removida.
2. No Steam, em PZ > Propriedades > Opções de inicialização, coloque `-debug`.
3. No menu Mods, ative **Reduce Metal&Wood v2** (id `ReduceMetal&Wood50x`).
4. Novo jogo > Sandbox personalizado > página **Reduce Metal&Wood** > "Redução de peso (%)" = **50** (padrão). Confira se o texto aparece em PT-BR e se a dica (tooltip) aparece.

## 2. Pesos esperados (50%)

Pegue cada item pelo painel de debug (Items List / F2 ou o Item Viewer do Admin) e veja o peso no tooltip:

| Item (ID)            | Original | Esperado |
|----------------------|---------:|---------:|
| Base.Plank           | 3.0      | 1.5      |
| Base.Log             | 9.0      | 4.5      |
| Base.TreeBranch2     | 2.0      | 1.0      |
| Base.LargeBranch     | 6.0      | 3.0      |
| Base.Nails           | 0.05     | 0.025 (aparece 0.03 ou 0.02) |
| Base.SheetMetal      | 2.0      | 1.0      |
| Base.IronIngot       | 6.0      | 3.0      |
| Base.SteelBar        | 2.0      | 1.0      |
| Base.ScrapMetal      | 1.0      | 0.5      |
| Base.SwordBlade      | 2.0      | 1.0      |
| Base.WoodAxeHead     | 2.0      | 1.0      |

Estes **não podem mudar**: Base.PropaneTank 10.0, Base.IronOre 40.0, Base.Charcoal 0.8, Base.IronIngotMold 6.0, Base.Hammer 1.5, portas e móveis, armas e ferramentas prontas.

Teste extra: num novo save, coloque 25 → Plank 2.25; com 0 → Plank 3.0 (sem efeito).

## 3. console.txt

Arquivo: `C:\Users\pedro\Zomboid\console.txt`. Busque:

```
[ReduceMetalWood] loaded v2.0.0
[ReduceMetalWood] applied (OnInitGlobalModData, sp): reduction=50% wood=
[ReduceMetalWood] applied (OnGameStart, sp): reduction=50%
[ReduceMetalWood] Base.Plank 3.0 -> 1.5
```

- No vanilla, `wood=` deve ficar perto de 25 e `metal=` perto de 123 (pode subir com outros mods). `failed=0`.
- Na segunda linha `applied` (OnGameStart), `changed=0` e `unchanged=` = total. Se aparecer isso, a reaplicação não está acumulando.
- As linhas por item (`Base.X a -> b`) só aparecem com `-debug`.
- Não pode aparecer: `WARN could not set weight`, `ERROR could not access ScriptManager`, nem stack trace com `ReduceMetalWood`.
- `sandbox vars not ready at OnInitGlobalModData` é aceitável se vier seguido de um `applied (OnGameStart` com o valor certo.

PowerShell: `Select-String -Path $env:USERPROFILE\Zomboid\console.txt -Pattern "ReduceMetalWood"`

## 4. Save existente e multiplayer

1. Salve, saia para o menu e carregue de novo. O Plank continua 1.5 (não pode ir para 0.75).
2. Itens que já estavam no chão ou no inventário antes de ativar o mod: veja se ficaram com o peso novo. O inventário do jogador é corrigido no OnGameStart; itens antigos em contêineres podem manter o peso velho (anote se acontecer).
3. MP: suba o servidor com o mod. O `server-console.txt` deve ter `applied (OnServerStarted, server)` ou `applied (OnInitGlobalModData, server)`. No cliente, `applied (..., client)`, e o peso do Plank deve ser o mesmo no cliente e no servidor (carregue tábuas até o limite e veja se não há "rubber-banding" ou dessincronia de peso).

## 5. Build 41

Rode a branch B41 (Steam > Betas > `legacy41` ou equivalente). Repita as seções 2 e 3 com os IDs B41: Base.Plank, Base.Log, Base.TreeBranch, Base.Nails, Base.SheetMetal, Base.MetalPipe, Base.UnusableMetal (todos devem cair pela metade). Base.PlankNail e Base.PropaneTank não mudam. A tradução PT-BR do sandbox deve aparecer com os acentos certos.
