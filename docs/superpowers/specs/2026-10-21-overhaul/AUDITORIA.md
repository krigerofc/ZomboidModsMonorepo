# Auditoria de base para a reestruturação — 21/10/2026

Somente leitura; os subagentes não editaram arquivos nem executaram jogo/servidor. Foram lidos os mods, os documentos, as fontes Lua e, quando indicado, métodos/bytecode da instalação local. A base importada teve os cinco runners e o teste de ícones KRjobs aprovados em 21/10.

## Medicina: cenários adicionais

O harness Fengari existente foi exercitado em memória, sem editar os testes no disco. A suíte original retornou zero falhas. Isso é reprodução com simulação da engine, não jogo real.

- P1: KFM_Server.lua processa torniquete antigo com Enabled=false; a ação bloqueia também a remoção. Cenário reproduzido: dano e fratura mesmo com a opção desativada.
- P2: KFM_Client.lua usa ipairs({item,item2}); quando item é nil e só item2 existe, não transfere o item da bolsa.
- P2: o torniquete guarda só fullType e recria outro objeto; cinto perde identidade, condição e nome personalizado.
- P2: irrigação limpa concede XP sobre ferida já com infecção zero, sem benefício.
- P2: chance mostrada para cinto não inclui os cinco pontos percentuais aplicados ao executar.

Guardar provas permanentes de regressão no plano de implementação antes de corrigir cada caso. Não confundir essas falhas reproduzidas com riscos ainda não observados, como serialização real de TimedAction.

## KRjobs

Core.lua altera ModData/AddItem no evento compartilhado sem selecionar autoridade. Vanilla SpawnItems.OnNewGame retorna se isClient(). A justificativa antiga de kit vanilla client-side precisa ser corrigida. Não foi observada duplicação numa partida; a suíte existente só repete o mesmo objeto e não prova exclusividade entre cliente e servidor.

Conteúdo principal: 24 profissões B42 e 20 B41; pedidos exemplificados presentes; 57 IDs únicos de receitas B42; 13 ícones próprios ainda provisórios. Não houve gameplay, B41 real ou boot42.21 comprovados.

## Veículos

- Classificação por substring e fallback não significa compatibilidade semântica com qualquer peça de mod.
- Peça intrínseca sem InventoryItem só é aceita para ID exato Engine.
- Todos os tiers adicionam histórico de remendo; revisão também degrada teto futuro.
- Core.addPatch substitui a tabela MVR inteira; futuras melhorias nessa tabela seriam perdidas.
- Validação atual usa distância ao centro; ampliação precisa de área/piso, movimento, motor e acesso no servidor.
- Diferença entre recálculo/transmissão do mod e vanilla exige teste físico de pneus/freios/suspensão; não foi provado defeito por essa diferença isolada.

### API investigada

Cor/ferrugem: setters e transmitters em VehicleCommands.lua; persistência examinada.
Sangue: lavagem vanilla ISWashVehicle consome recursos e trabalha por áreas.
Potência: setEngineFeature por veículo, persistência e campo VehicleEngine do pacote transmitem qualidade/ruído/potência.
Capacidade: setters existem, mas doInventoryItemStats recalcula pela peça/condição.
Velocidade máxima: setter existe; createPhysics repõe valor do script; reaplicação e persistência precisam de solução.
Contêiner: pneus e tanques não são porta-malas; TrailerAnimalFood/Eggs têm lógica especial.

## Fontes técnicas externas consultadas

- https://github.com/PZ-Umbrella/Umbrella
- https://demiurgequantified.github.io/ProjectZomboidJavaDocs/zombie/radio/media/RecordedMedia.html
- https://demiurgequantified.github.io/ProjectZomboidJavaDocs/zombie/radio/media/MediaData.html
- https://demiurgequantified.github.io/ProjectZomboidJavaDocs/zombie/characters/BodyDamage/BodyPartType.html

A versão alvo da conversa é42.21, e a instalação examinada é a fonte histórica42.19.2. Não houve checagem de atualização Steam nem certificação de “versão mais recente”.

## ZombieDisguise

A revisão estática confirmou ausência de validação autoritativa do cadáver/duração, seleção ambígua do ator em tela dividida, remoção baseada em wetness, reconciliação de estado incompleta, sintomas com valores sobrescritos e falta de traduções. Ver DISGUISE-MULTIPLAYER.md para referências e critérios. Nenhum teste em jogo/servidor foi executado.
