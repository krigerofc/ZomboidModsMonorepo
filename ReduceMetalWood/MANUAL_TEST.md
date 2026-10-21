# Teste manual — Build & Haul / Materiais Leves

Estado: matriz a executar; nenhum teste dentro do jogo foi realizado nesta atualização.
Referência consultada: arquivos e bytecode da instalação local B42.19.2. Alvo de lançamento B42.21 e B41 ainda requerem validação no jogo.

## Instalação e opções

1. Use uma instalação de teste e um save novo; mantenha só uma cópia do mod ativa.
2. Ative **Build & Haul - Lightweight Materials** / **Build & Haul - Materiais Leves**. O ID continua `ReduceMetal&Wood50x` e o Workshop `3140965857`.
3. Confira EN e PT-BR no menu e na página **Build & Haul** do sandbox. A chave antiga `ReduceMetalWood.WeightReductionPercent` continua válida; padrão 50, faixa 0–99.
4. Repita as medições com redução 0, 50 e 99 em saves de teste.

## Catálogo e pesos a 50%

| Item | Vanilla B42.19.2 | Esperado |
|---|---:|---:|
| Plank | 3 | 1,5 |
| Log | 9 | 4,5 |
| Nails | 0,05 | 0,025 |
| IronIngot | 6 | 3 |
| IronOre / CopperOre | 40 | 20 |
| Hematite / Malachite | 2,5 | 1,25 |
| HematiteLarge / MalachiteLarge | 5 | 2,5 |
| Stone2 / Limestone / FlintNodule | 1 | 0,5 |
| StoneBlock / Clay / ClayBrick / ClayTile / ClayShingle e formas Unfired | 0,3 | 0,15 |
| ConcretePowder / PlasterPowder | 5 | 2,5 |
| Claybag / Sandbag / Gravelbag cheios | 2 | 1,25 |
| BucketClayCement / BucketConcreteFull / BucketPlasterFull cheios | 10 | 5,5 |
| Equivalentes BucketCarved… cheios | 10 | 6 |

Para recipientes drenáveis de construção, só o conteúdo é reduzido. Peso nativo:
`peso = (peso cheio do script − peso do recipiente vazio) × fração restante + peso vazio`.
Com redução 50%, balde metálico cheio/metade/vazio = **5,5 / 3,25 / 1**; balde esculpido = **6 / 4 / 2**; saco = **1,25 / 0,875 / 0,5**.
Com redução 99%, cheios = **1,09 / 2,08 / 0,515**, respectivamente. Nunca podem ficar mais leves que o recipiente vazio.
Conferir por uso real de receita, colocação de areia/cascalho e aplicação de gesso/concreto, até a transformação no recipiente vazio. Verificar que o vazio resultante mantém o peso vanilla e não leva estado residual da forma cheia.

Devem manter peso: PropaneTank, carvão/coque, ferramentas e armas prontas, portas, móveis, máquinas, moldes, cadinhos, baldes vazios, baldes com água/alimento/cola de papel de parede, potes e utensílios de argila. Uso numa receita sozinho não autoriza redução.

## Reaplicação, criação e recarga

- Criar itens novos; medir itens já no inventário, chão e contêineres antes da ativação.
- Salvar/carregar, sair/reabrir e reconectar: pesos não podem cair uma segunda vez. Exemplo Plank 1,5 deve continuar 1,5.
- Repetir com recipientes cheios e usados pela metade; conferir transformação vazia e transferência entre jogadores.
- Confirmar que itens com peso personalizado por outro sistema não são sobrescritos.
- O refresco existente alcança o inventário local no início e apenas itens sem peso personalizado que ainda tenham peso original. Drenáveis têm peso personalizado nativo; itens antigos no chão/contêineres e drenáveis já instanciados exigem conferência explícita após uso/recarga.

## Diagnóstico

Com debug, procurar `[ReduceMetalWood] loaded v2.1.0` e `applied (...)` no console.
O fixture B42.19.2 tem **25 madeira + 123 metal + 6 minério + 22 construção = 176** tipos elegíveis. Outros mods/versões podem alterar os totais; conferir `ore=` e `construction=`, ausência de falhas e `changed=0` na segunda aplicação.
Não deve haver stack trace, WARN de setter ou erro de ScriptManager.

## Host, dedicado e B41

- Repetir com dois clientes em host e dedicado, incluindo entradas simultâneas, reconexão, transferência, carga de contêiner/veículo e reinício do servidor. Comparar pesos e limites de carga entre servidor e clientes.
- Na B41, usar apenas IDs presentes nessa instalação. Conferir Plank, Log, TreeBranch, Nails, MetalPipe, Sandbag, BucketConcreteFull e seus recipientes vazios. Não criar IDs exclusivos B42 artificialmente.
- O teste automatizado da cópia B41 usa amostra manual e a mesma lógica Lua; não certifica o motor B41 nem multiplayer.

## Extensões e decisão de escopo

O controle percentual continua global. Controles por família foram adiados para evitar configuração extra; não há duas reduções multiplicadas.
Materiais de terceiros precisam de categoria Material/MaterialWeapon e tags coerentes (`ironore` / `copperore` / `orematerial` / `constructionmaterial`) ou registro por tipo completo nas tabelas de inclusão/exclusão do Classifier. Exclusão explícita tem precedência. Buckets desconhecidos ficam excluídos; incluir um drenável requer conferir o recipiente de transformação e sua fórmula. Uma baseline vazia não resolvida mantém o item inalterado.
