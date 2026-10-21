# Field Medicine — Zombie Disguise

Estado: desenho da refatoração. Decisão final do usuário: **FieldMedicine e ZombieDisguise somente B42**. ZombieDisguise torna-se uma expansão dependente do mod de saúde; não será feito porte B41.

## Identidade e dependência

Preservar o mod ID ZombieDisguise. Na entrada B42, declarar require=KRFieldMedicine. O jogo deve apresentar a dependência e impedir uso isolado. Remover a distribuição executável B41/stub que possa sugerir suporte e atualizar descrições EN/PTBR. O histórico Git conserva o pacote antigo.

Nome de exibição proposto: Field Medicine: Zombie Disguise / Medicina de Campo: Disfarce Zumbi. A expansão não repete o motor de doenças nem muda arquivos vanilla completos.

## Camuflagem temporária

O jogador aplica sangue de cadáver de zumbi acessível e recebe proteção temporária contra os zumbis. O personagem continua visível/normal para humanos; não usar ghost mode ou invulnerabilidade global.

Duração base proposta:120 minutos do jogo. Correr, atacar ou efetuar ação hostil rompe o disfarce; duração, cobertura necessária e condições de quebra ficam configuráveis. Usar feedback de cobertura/tempo e avisos de risco nos dois idiomas.

A proteção tem limite próprio: acabar a camuflagem não limpa o sangue nem cura exposição. Lavar-se remove cobertura conforme as regiões limpas. Chuva/umidade só contam na medida em que efetivamente removem a cobertura; estar molhado não é sinônimo de estar limpo.

A ação exige validação autoritativa de personagem, cadáver de zumbi, distância, piso, alcance, duração e interrupções. Não conceder proteção com uma mensagem vazia do cliente. Não adicionar item obrigatório para corrigir o protocolo, pois o comportamento aprovado usa o cadáver.

Ao sair, morrer, desativar ou expirar, retirar só o efeito concedido por esta expansão e reconciliar o estado ao reconectar. Não remover proteção externa/admin indiscriminadamente.

## Integração com FieldMedicine

Uma única fonte de verdade para sangue/exposição/feridas/doenças: FieldMedicine. A expansão registra no servidor a aplicação e a remoção da exposição por região e a fonte conhecida do sangue. FieldMedicine decide o risco e a progressão.

Tempo com sangue no rosto ou sobre feridas, intensidade e proteção entram no mesmo modelo médico. Permanecer sujo depois de perder o disfarce continua trazendo risco. Medicamentos e lavagem não renovam automaticamente o disfarce.

Não manter a rotina antiga que atribui valores fixos a náusea, estresse, pânico, infelicidade e fadiga. Isso sobrescreve outros estados e duplicaria penalidades. A exposição originada do Disguise pode ser mais intensa que sujeira comum, mas é tratada como uma só causa.

Mortes por complicação seguem a configuração do FieldMedicine. A expansão não acrescenta transmissão Knox por sangue nem revela se há Knox no diagnóstico. O jogador corre riscos de doenças comuns e contaminação do novo sistema.

## Persistência e protocolo

Persistir versão, identidade da aplicação, regiões/cobertura, início, expiração e origem da exposição. Reconexão recupera o tempo restante sem renovar duração nem refazer sorteios de doença. Não aplicar dano acumulado de período offline.

Comandos/ações identificam o jogador correto, inclusive tela dividida. Estado vem do servidor, e interfaces recebem só os dados necessários. Se a versão do FieldMedicine for incompatível, desativar a operação com motivo em vez de improvisar outro sistema de saúde.

## Auditoria da base antiga

Problemas confirmados: comando sem validação de cadáver/duração, seleção ambígua do ator em tela dividida, limpeza por wetness, reconciliação incompleta, valores de sintomas sobrescritos e texto inglês hardcoded. Esses problemas não foram explorados em servidor e precisam de regressões permanentes antes da correção.

## Arte

Nova capa gerada pelo image_gen integrado no estilo 3D de gameplay aprovado, sem texto/logos. Entregas:
outputs/zomboid-game-style-v2/zombie-disguise/master-1024.png
poster.png512, preview.png256, icon.png64 e alternativa icon-128.png.
O prompt está em prompt.json. A imagem mostra o sobrevivente aplicando sangue e zumbis passando sem reagir.

## Aceite

SP, host, dedicado, dois personagens em tela dividida, pedido inválido/fora de alcance, cadáver movido, interrupção, correr/atacar, morte, lavagem parcial/completa, chuva, expiração, reconexão/restart e desativação. Com FieldMedicine, uma única exposição por aplicação, sem doença/XP/penalidade duplicados. Falta de dependência deve ser clara no menu. Não afirmar compatibilidade real em multiplayer apenas com mocks.
