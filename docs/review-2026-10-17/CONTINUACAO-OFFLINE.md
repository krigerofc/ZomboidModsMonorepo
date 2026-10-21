# Continuação autônoma — 17/10/2026

O usuário pediu continuidade das correções e tentativa de coordenação com Claude enquanto está ausente. Esta rodada continua a revisão das 19h30.

## Coordenação com Claude

Foi localizada a sessão de terminal 304acafc-38be-4697-ab5c-05933cee30b2 e lido seu histórico recente, sem alterar os registros do Claude. Ele anunciou uma checagem de APIs 42.21 por subagente e um teste posterior de servidor dedicado com dados isolados. Essas duas atividades pertencem à frente dele; não foram declaradas executadas pelo Codex.

A mensagem autorizada foi deixada em Workshop/docs/CLAUDE-CODEX.md e referenciada no início do HANDOFF.md. Não existe acesso de entrada naquele terminal por esta sessão e ainda não houve confirmação de leitura da mensagem. A divisão de trabalho é uma proposta, não um acordo confirmado.

## Correções adicionais aplicadas

### Medicina — ferramentas e materiais obrigatórios

A ação aceitava ferramentas ausentes/nulas, inclusive após reconstrução no servidor. Isso permitia debridamento/cauterização sem recursos e erro ao aplicar torniquete sem item.

KFM_ProcedureAction:hasRequiredItems agora valida posse e tipo dos itens, água suficiente, fonte de calor utilizável e cinto não vestido. isValid e complete revalidam as condições; material removido durante a ação impede o efeito. Exames continuam admitindo ausência de instrumentos opcionais.

Onze checks novos falharam antes da correção e passaram depois. Incluem bisturi ausente/removido, torniquete ausente, cinto vestido, lâmina ausente e isqueiro sem usos. Essa reprodução usa o adaptador de engine dos testes; não constitui teste de rede real.

### Veículos — identidade da peça na fila

Uma ação guardava o slot VehiclePart, permitindo que outro jogador trocasse a peça e o reparo incidisse na substituta. Agora o ID original é capturado em expectedItemId, transmitido como parâmetro do construtor da ação e comparado novamente ao concluir. O motor intrínseco usa sentinela vazia e continua funcionando. Peças removíveis trocadas cancelam a ação sem consumo, XP ou histórico.

Três regressões falharam antes; depois a suíte passou com 854 checks de core e 70 de integração/contrato.

### Passive Skills — segunda cópia já enfileirada

Duas cópias podiam entrar na fila antes de a primeira terminar; a segunda continuava válida depois do aprendizado. O hook agora reconsulta o registro por personagem em cada validação e cancela a segunda.

### Passive Skills — recuperação quando XP falha

O registro era marcado como lido antes da concessão de XP. Uma falha ou API ausente consumia definitivamente a oportunidade de aprendizado. Agora o registro é atualizado somente depois da concessão bem-sucedida; erro/retorno falso permite tentar novamente. API de XP ausente retorna falha controlada. Falha na fala de releitura não quebra o construtor vanilla.

As exceções de XP/Say foram simuladas deliberadamente para testar recuperação; não foram observadas em uma sessão real do jogo. O bloqueio de cópia já enfileirada foi reproduzido como fluxo normal.

Oito verificações falharam em cada build antes; todas passaram depois, nas cópias B41 e B42. O gerador foi executado para manter as cópias sincronizadas.

## Resultado e limites

- FieldMedicine, BasicVehicleMaintenance e PassiveSkills passaram nas suítes completas após suas respectivas mudanças.
- ReduceMetalWood e KRjobs não receberam nova mudança de runtime nesta rodada; seus resultados anteriores permanecem no relatório principal.
- Nenhum jogo foi atualizado, nenhum save de usuário foi alterado e nada foi publicado no Workshop pelo Codex.
- Ainda falta validar execução em SP, host e dedicado, especialmente a serialização de expectedItemId e os itens nulos na reconstrução da ação.
- Sem prova estática de perda automática da lista de leitura no restart: a cadeia de salvamento local serializa a tabela de modData. O teste real de reinício continua necessário.
- O loot adicionado sincronamente no OnFillContainer entra na rota normal de replicação local. Não foi acrescentado envio manual duplicado de itens.

Os arquivos de trabalho continuam nas branches de revisão; confira repository-status.json para o estado capturado e não reaplique patches sobre arquivos já corrigidos. Os patches do pacote precisam ser regenerados ao final de cada rodada para incorporar estes últimos ajustes.
