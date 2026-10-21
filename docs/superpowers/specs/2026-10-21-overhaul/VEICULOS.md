# Basic Vehicle Maintenance — oficina pessoal

Estado: desenho da reestruturação, ainda não implementado.

## Experiência

O jogador recupera um veículo encontrado, mantém sua utilidade e o personaliza com escolhas moderadas. Reparos caseiros servem em expedições; trabalho mais durável exige habilidade e recursos. Carga, desempenho e aparência passam a ser escolhas do proprietário.

Cobrir veículos vanilla e veículos de mods que usam peças genéricas existentes no jogo é requisito. Não basear o suporte em uma lista fechada de nomes de carros. Sistemas/peças exclusivos de um mod estão fora do suporte obrigatório.

## Recuperar

Três operações com efeitos distintos:
- Remendo emergencial: barato e limitado; usa materiais comuns e acumula histórico de remendos.
- Reparo durável: exige materiais apropriados; recupera a peça sem gerar automaticamente mais um remendo precário.
- Restauração profissional: habilidade, ferramentas e instalação adequadas; reduz parte da penalidade de remendos e aproxima a peça de seu estado original sem superar o original.

Manter configurações por família para carroceria, portas, capô, janelas quando suportadas, bancos, elétrica, bateria, tanque, motor, freios, pneus e suspensão. Janela destruída ou peça ausente não deve ser magicamente recriada como “reparo”; requer substituição ou receita de fabricação específica. Luzes/peças consumíveis que precisam de reposição devem mostrar esse motivo.

A revisão atual aumenta o contador de remendos em todos os níveis: corrigir essa progressão. O novo reparo deve atualizar condição, estado do item, estatísticas físicas e replicação conforme a peça exige.

## Melhorar

Valores iniciais propostos, calculados sobre a base original por veículo/peça:
| Melhoria | Limite proposto |
|---|---|
| Organização de porta-malas | níveis +10% e +20%; acréscimo máximo 40 unidades |
| Organização de porta-luvas | +25% e +50%; acréscimo máximo 5 unidades |
| Afinação de motor | +5% e +10% de potência; não altera qualidade/ruído sem motivo |
| Velocidade máxima | até +5%, somente se persistência e recriação física forem comprovadas |

Os valores são escolhas do Codex para revisão. Não somar melhorias repetidas nem multiplicar o valor já melhorado. Habilidades e ferramentas crescem por nível; o topo exige trabalho de oficina. Nenhum ajuste pode converter qualquer motor em desempenho de esportivo.

Custo de materiais e tempo é exigido também em melhorias sem chance de falha. Mostrar benefício, custo, requisito e risco antes da ação. Não adicionar manutenção periódica obrigatória ou quebra aleatória só por instalar o mod.

## Personalizar

Pintura por cor selecionada, com tinta/utensílios e tempo; remoção gradual de ferrugem com materiais; lavagem de sangue aproveitando a ação vanilla com água.

Pintura/ferrugem são aparência: não reparam a carroceria ou concedem proteção escondida. Limpeza não duplica a ação vanilla. Se a textura de um mod não aceitar a mesma coloração, desabilitar só a pintura com explicação e permitir as outras operações compatíveis.

## Veículos de outros mods

Identificar capacidades reais da peça e suas referências a itens/funções genéricos do jogo. Modelos novos que mantêm peças genéricas devem receber os mesmos reparos/melhorias sem precisar de um cadastro por nome de carro.

Não confundir inventário de carga com ar de pneu ou tanque. Contêineres especiais de animais, peças sem equivalente genérico e sistemas exclusivos de outros mods não recebem operações presumidas. Desabilitar apenas a operação incompatível com motivo EN/PTBR.

Não é necessário criar uma infraestrutura pública de adaptadores para peças exclusivas nesta versão. Um veículo que usa parte das peças genéricas pode usar as operações dessas peças, sem prometer suporte ao resto.

Validação: modelos vanilla e fixtures de scripts de modelos novos com peças genéricas, inclusive IDs de modelo desconhecidos e peças renomeadas com funções equivalentes. Nos testes reais, registrar o mod/modelo efetivamente usado; não declarar compatibilidade só pelo teste de um clone em fixture.

## Estado e multiplayer

Servidor valida ator, distância à área de trabalho e mesmo piso, veículo parado/motor desligado quando necessário, acesso e configuração do servidor, identidade da peça, recursos e concorrência. Cliente envia intenção, não percentuais ou capacidade final confiáveis.

Estado versionado separado para histórico de reparos e melhorias. O método atual addPatch substitui a tabela MVR da peça; não reutilizar essa tabela de forma que um reparo apague melhorias.

Baselines registrados antes da primeira melhoria. Restaurar a partir desses baselines ao remover; nunca esvaziar/ejetar silenciosamente carga se a capacidade nova for menor que a ocupação. Melhorias de contêiner acompanham a peça física; troca por outra peça não herda bônus gratuitamente. Motor intrínseco usa estado do veículo.

Persistir, revalidar após load/instalação/reparo e replicar apenas mudanças autoritativas. Não modificar VehicleScript compartilhado para melhorar um único carro. Se outro mod recalcular estatísticas, o adaptador deve compor valores ou recusar a melhoria conflitante.

## Viabilidade já investigada

Cor, ferrugem e potência possuem API por instância e campos persistidos na instalação local. Pacote VehicleEngine transmite potência/qualidade/ruído. Isso não substitui prova em jogo.

Capacidade pode ser recalculada por doInventoryItemStats; precisa de integração consistente, não apenas setCapacity uma vez. maxSpeed é redefinido em createPhysics e não consta no save/load examinado: sua reaplicação é um bloqueio técnico próprio. Não anunciar velocidade máxima melhorada antes de provar esse caminho.

## Aceite

Mesmos modelos lado a lado não compartilham melhorias; tiers não acumulam; reparo e reinstalação preservam o estado correto; reset não perde itens; recursos saem exatamente uma vez. Cobrir veículo com peças renomeadas, trailer e contêiner especial em testes automatizados. A validação real deve incluir pelo menos um veículo de mod usando peças genéricas, com nome/versão registrados, além de vanilla; peças exclusivas não fazem parte do aceite.

Exigir SP, host e dedicado com dois clientes: operações simultâneas, cancelamento, troca da peça em fila, mudança de piso, veículo movendo, reconexão e reinício. Verificar cor, ferrugem, carga e desempenho observados pelos dois clientes.
