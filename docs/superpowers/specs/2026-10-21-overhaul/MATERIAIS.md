# Build & Haul — materiais leves

Estado: proposta. Fonte: ReduceMetalWood atual, sem reescrita do runtime de peso como primeira medida.

## Comportamento

Redução padrão de 50%, configurável entre 0 e 99%, preservando a prevenção de aplicação duplicada. Separar a classificação em madeira, metal, minério e construção mineral para permitir conferência do catálogo. Manter um controle global nesta versão; classificação por família serve ao catálogo e diagnóstico. Não multiplicar duas reduções sobre o mesmo item. Escolha registrada do Codex: sliders separados por família ficam para eventual ampliação.

Nome público proposto: Build & Haul — Lightweight Materials; PT-BR: Build & Haul — Materiais Leves. Preservar id ReduceMetal&Wood50x, Workshop 3140965857, namespace de sandbox e leitura de configuração antiga. A pasta interna pode continuar ReduceMetalWood; a renomeação visível não deve criar um segundo mod.

## Catálogo inicial

Além de tudo que já estava corretamente incluído:
- IronOre, CopperOre, Hematite, HematiteLarge, Malachite e MalachiteLarge.
- Stone2, StoneBlock, Limestone e FlintNodule como insumos; não ferramentas/armas de pedra.
- Clay, Claybag, Gravelbag, Sandbag, ConcretePowder e PlasterPowder.
- ClayBrick, ClayShingle, ClayTile e suas formas não queimadas: são peças de construção, não edifícios/objetos acabados.
- Baldes de argamassa, concreto e gesso, incluindo equivalentes de madeira esculpida, enquanto contêm o material elegível.

Os IDs acima foram encontrados no catálogo local B42.19.2. Confirmar novamente contra a versão alvo antes do lançamento. IDs ausentes em B41 não são gerados artificialmente.

## Fronteira

Portas completas, móveis, bancadas, máquinas, armaduras, ferramentas, armas, veículos, contêineres vazios e combustíveis ficam normais. “Usado em uma receita” sozinho não é critério suficiente. Não usar nome parcial como único motivo para reduzir um produto acabado.

Para itens de outros mods: regras por categoria/tags e registro explícito de inclusão/exclusão. Exceções do usuário têm precedência, com explicação no diagnóstico. Não inferir que toda pedra ou todo balde é material elegível.

## Peso de conteúdo variável

A redução precisa acompanhar o material restante sem tornar o balde vazio mais leve nem deixar peso residual ao transformá-lo em outro item. Validar cheia, metade e vazia contra a fórmula vanilla antes de incluir cada família de drenáveis; uma família sem suporte correto não pode ser anunciada como entregue.

## Aceite

Conferir catálogo completo, falsos positivos, todos os seis minérios, blocos/tijolos, produtos finais e nomes semelhantes de outros mods. Testar redução 0/50/99%, reload, duas passagens, host, dedicado, criação/troca de itens e instalação B41. Descrições e arte devem corresponder ao catálogo efetivo.
