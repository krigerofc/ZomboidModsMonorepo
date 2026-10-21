# Passive Skills — B42 e VHS

Estado: proposta. Pedido confirmado: apenas B42, com novas fitas de habilidades.

## Preservar

Revistas existentes, seus IDs, a leitura única por personagem, o feedback e a quantidade atual de XP: cinco volumes somam 2775 XP no padrão. Não mudar nem zerar registros já gravados da v2. Tornar a retirada do suporte B41 explícita no pacote, geradores, testes e descrição; o histórico Git conserva a versão antiga.

## VHS propostos

Usar fitas reproduzidas em televisão/vídeo compatível do jogo; carregar a fita no inventário não ensina. Conteúdo original de programas/instrução plausíveis para 1993, com título e legendas PT-BR/EN.

Primeiro catálogo proposto: 16 fitas, duas para cada habilidade de Carpintaria, Mecânica, Primeiros Socorros, Elétrica, Metalurgia, Forja, Alvenaria e Costura. Expansões futuras não são condição para entregar esse catálogo.

Equilíbrio proposto: 250 XP base por fita completa, sujeitos aos multiplicadores e ao limite nativo de aprendizado por mídia; até500 XP base adicionais por habilidade nesse catálogo; opção própria de XP e raridade de VHS, incluindo desligar as fitas. As revistas mantêm o XP independente e fixo já existente, sem assumir para VHS as mesmas regras. Escolha registrada: usar a reprodução e o histórico nativos, sem duplicar a concessão de XP. Isso é uma escolha do Codex para revisão, não um valor já solicitado.

Cada personagem aprende cada trecho de uma fita uma única vez. Duas cópias físicas do mesmo programa compartilham essa identidade. Assistir novamente, rebobinar, interromper, mudar de TV e reconectar não podem repetir XP já concedido. Vários personagens podem assistir à mesma sessão e progredir separadamente. Conservar o progresso parcial.

## Implementação a provar

A instalação local registra mídia em RecordedMedia/ISRecordedMedia.lua por register/addLine e contém códigos nativos de habilidade. A API pública oferece registro e histórico por linha. Confirmar os códigos e o caminho de XP de cada habilidade antes de escolher entre integração nativa e adaptador; não conceder XP pelo evento de inserir a fita.

Não modificar as fitas vanilla nem seus IDs. Não duplicar tabelas inteiras de distribuição de loot. Medir a raridade de fitas separadamente da chance atual de revistas, cujo padrão permanece 12%.

## Aceite

Catálogo e legendas completos em ambos os idiomas, teste de cada habilidade, posse sem reprodução dá zero XP, progressão parcial, repetição/cópias, energia desligada, aparelho incompatível, distância de quem assiste, espectadores múltiplos, host/dedicado e save/load/restart. Validar total real de XP; não assumir que códigos vanilla equivalem aos números de XP do catálogo.

Fontes: https://demiurgequantified.github.io/ProjectZomboidJavaDocs/zombie/radio/media/RecordedMedia.html e MediaData.html; fontes locais media/lua/shared/RecordedMedia.
