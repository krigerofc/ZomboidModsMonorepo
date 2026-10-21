# Revisão e passagem para Claude — 17/10/2026

A revisão das 19h30 foi executada. Os cinco mods receberam descrições locais em PT-BR e EN. Foram corrigidos quatro defeitos funcionais, com testes que falharam antes e passaram depois. Os PRDs existentes foram reconciliados com o código entregue e receberam dependências, critérios de aceite e portões de publicação. Nenhuma publicação ou teste dentro do jogo foi realizado.

## Estado dos repositórios

Os cinco mods estão na branch **fix/codex-review-20261017**, com alterações locais ainda sem commit. Os commits de Claude foram preservados:

| Repositório | Base de Claude |
|---|---|
| ReduceMetalWood | 0bde254 |
| PassiveSkills | 39e710b |
| KRjobs | 47f771c |
| BasicVehicleMaintenance | 2ec5ee7 |
| FieldMedicine | 6bf70cc |

Raiz: C:\Users\pedro\Zomboid\Workshop. O repositório docs também recebe branch de revisão própria. Não aplicar os patches deste pacote novamente sobre as árvores já modificadas.

## Achados corrigidos

| Prioridade | Mod | Defeito e correção |
|---|---|---|
| P1 | Basic Vehicle Maintenance | Engine vanilla não tem InventoryItem. O mod recusava menu, avaliação, ação e inspeção. Game.isPartPresent agora permite explicitamente Engine e mantém peças removíveis ausentes bloqueadas. |
| P2 | Reduce Metal & Wood | WeldingRods dependia de getMetalValue no objeto de script, que não oferece o getter no vanilla local. Inclusão explícita nas duas builds; o mock deixou de inventar o getter nesse cenário. Peso 1,5 passa a 0,75, sem acumular a redução. |
| P2 | Field Medicine | Após debridamento bem-sucedido que causasse nova infecção, nível ficava positivo e flag era desligada. Nível e flag agora permanecem coerentes. |
| P2 | Field Medicine | ExamEnabled era respeitado só pelo menu. A conclusão autoritativa agora recusa exames quando a opção está desativada. |

A revisão adicional dos diffs de motor e medicina não encontrou regressão no escopo corrigido.

## Descrições, idiomas e versão

- Novas descrições aplicadas nos cinco workshop.txt, nos mod.info pertinentes e nos Mod.json EN/PTBR.
- Fontes geradoras atualizadas para evitar que uma próxima geração desfaça os textos.
- BVM ganhou Mod.json EN/PTBR, que faltavam apesar da tradução das opções de gameplay.
- B41 de Reduce/Passive/KRjobs tem descrição bilíngue na raiz. A entrada B41 de BVM informa que não tem funcionalidades.
- versionMin B42 agora é 42.15 nos cinco mods, limite de entrada do formato JSON; os testes de metadados acompanham o requisito. Isso não certifica APIs de todas as versões intermediárias.
- As descrições de Workshop informam que validação in-game/MP está pendente. Removidas garantias como “no inventory desync”, “multiplayer seguro” e “seguro para saves” sem prova real.
- Capas não foram substituídas. Os runners verificaram dimensões dos arquivos existentes; isso não é uma certificação de todos os limites de upload Steam.

## Testes executados

Comando em cada repo: rtk proxy node tests/run.js. Sem instalar dependências.

| Mod | Resultado final |
|---|---|
| ReduceMetalWood | PASS; 33 checks de core por build, catálogo B42 5092 itens/148 elegíveis e fixture B41 de 35 itens |
| PassiveSkills | PASS; sintaxe 20 Lua, 10 JSON, 170 itens B42/125 B41, core/glue nas duas builds |
| KRjobs | PASS; 24 profissões B42/20 B41, 24 traits B42, 60 receitas B42, kits e fórmula de balanceamento |
| BasicVehicleMaintenance | PASS; 854 checks de core + 66 de integração com mocks |
| FieldMedicine | PASS; core/glue, 7 Lua, 14 JSON, 88 chaves, guarda de Knox e referências a itens vanilla |

Antes das correções, os novos testes produziram: 3 checks falhando por build no Reduce; 5 no BVM; 2 na medicina. Depois todos passaram. Os logs completos estão em tests-before.json e tests-after.json.

O jogo instalado foi confirmado como **42.19.2**, não 42.21. As fontes vanilla consultadas pertencem à instalação local. A versão-alvo atual 42.21 exige atualizar/reler as fontes e testar SP, host e servidor dedicado com dois clientes.

## PRDs e decisões

PRD-Medical.md e PRD-VehicleMaintenance-v2.md foram revisados nos arquivos existentes em Workshop/docs e copiados para este pacote. A seção 15 acrescenta evidência por critério e separa código implementado de validação no jogo.

Corrigidos caminhos de desenvolvimento, escopo B42-only dos dois mods, estrutura real dos arquivos, categoria IG_UI.json, receitas médicas futuras e status de integrações. Não foram implementadas features novas.

O HANDOFF posterior ao histórico inicial registra a expansão de PassiveSkills para 33/24 habilidades como decisão do usuário. Essa funcionalidade foi mantida com base nesse registro; esta sessão não contém confirmação humana independente. A curva sem multiplicadores e os números de spawn/qualidade continuam escolhas propostas por Claude.

Os registros ORQ de nomes/escopo/falha grave/medicina permanecem identificados como registros do orquestrador, sem elevá-los a uma aprovação humana nova. Equilíbrio real não foi comprovado só porque a fórmula de testes passou.

## Próximos passos para Claude

1. Ler o diff da branch local e a seção de revisão do HANDOFF. Não sobrescrever nem reaplicar os patches.
2. Avaliar e commitar as alterações por repositório; nenhum commit de outra IA foi reescrito.
3. Atualizar o jogo para 42.21 antes da certificação pretendida.
4. Executar MANUAL_TEST.md de cada mod e os portões dos PRDs: isolados e os cinco juntos, SP/host/dedicado, PT-BR/EN, reinício e reconexão.
5. Confirmar especialmente redução dos pesos, registro de revistas por personagem, kits únicos, motor intrínseco sem item, consumo em bolsas, torniquete persistente e limites de XP.
6. Validar com o usuário as propostas restantes. Medicina e 13 ícones KRjobs ainda possuem arte provisória.
7. Publicar no Workshop somente em uma etapa autorizada; esta rotina não publicou nada.

## Fontes consultadas

- Vanilla local: E:\SteamLibrary\steamapps\common\ProjectZomboid\media\lua e media\scripts.
- [Migração oficial 42.15](https://theindiestone.com/forums/topic/92433-modding-migration-guide-4215/) — novo formato de traduções.
- [Site oficial — versão atual](https://projectzomboid.com/blog/support/).
- [Item — API oficial](https://projectzomboid.com/modding/zombie/scripting/objects/Item.html) e [InventoryItem](https://projectzomboid.com/modding/zombie/inventory/InventoryItem.html#getMetalValue()) — distinção do getter metalValue.

## Continuação posterior

Leia também CONTINUACAO-OFFLINE.md: correções adicionais de recursos médicos, identidade de peças na fila e recuperação/leitura do PassiveSkills. Os patches e repository-status.json deste pacote foram atualizados após essa rodada.
