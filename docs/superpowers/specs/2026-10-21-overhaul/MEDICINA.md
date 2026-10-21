# Field Medicine '93 — doenças, lesões e recuperação

Estado: proposta da reestruturação. Mecânicas de jogo, sem pretensão de fornecer orientação médica real.

## Experiência

Doenças e lesões têm causa, evolução perceptível, tratamento e recuperação. O médico ganha decisões úteis, e o jogador solo tem meios de se cuidar. O melhor atendimento ajuda, mas não apaga imediatamente consequências graves.

Build: somente B42. ZombieDisguise é uma expansão dependente, não uma segunda implementação do sistema de doença.

Adicionar conteúdo pedido: quadros gripais/virais, outras doenças, contaminação prolongada por sangue, medicamentos, queimaduras, fraturas, lesões musculares/nervosas e reabilitação. Não limitar a atualização a corrigir os sete procedimentos atuais.

## Um episódio de saúde

Representar condição com identidade, causa/exposição, região corporal quando aplicável, gravidade, estágio, início/último processamento, tratamentos e evolução. Fluxo: exposição ou trauma → latência → sintomas → cuidado → recuperação ou complicação limitada → resolução.

Não sortear um novo episódio em todo tick, ao abrir painel ou ao reconectar. Um episódio persistido conserva seu sorteio e sua evolução. Tempo avança por relógio do jogo no servidor enquanto o personagem está simulado; episódios ficam pausados enquanto o personagem está desconectado. Ao carregar, não aplicar dano acumulado pelo período offline nem repetir sorteios. Esta é uma escolha técnica proposta para revisão.

## Famílias previstas

1. Quadro respiratório/gripal: integrar resfriado nativo, sem duplicar sintomas. Diagnóstico por confiança e sinais; não afirmar distinguir um vírus exato sem sistema que modele essa distinção.
2. Síndrome gastrointestinal: uma doença comum diferente da respiratória, ligada a exposição de jogo verificável; não duplicar penalidades de intoxicação vanilla quando já representam o mesmo episódio.
3. Infecção comum de ferida/contaminação: limpeza, proteção e evolução posterior passam a ter benefício observável e limitado.
4. Queimaduras e fraturas: aproveitar a lesão nativa, acrescentar avaliação, qualidade do tratamento, revisão e recuperação.
5. Distensão/lesão muscular: diferente da rigidez normal após exercício; sobrecarga/trauma e recuperação progressiva.
6. Lesão nervosa: condição regional própria, sintomas funcionais limitados e recuperação longa. Padrão proposto: recuperável; sequelas permanentes não entram nesta versão.

Na instalação examinada BodyPartType é enum Java com 17 regiões. As novas lesões se associam às regiões existentes; não prometer dedos/órgãos novos no esqueleto nativo. Anatomia nova exigiria outro projeto técnico.

## Sangue e higiene

Acumular exposição por tempo e intensidade no rosto ou em regiões com ferida aberta; roupa e curativo válidos podem proteger onde fizer sentido. Limpeza remove a exposição superficial futura; não cura instantaneamente um episódio já iniciado.

Proposta de equilíbrio inicial: 60 minutos de jogo de tolerância antes de considerar exposição persistente, uma avaliação de risco por hora depois disso, risco-base baixo no rosto e maior em ferida aberta, todos configuráveis. Fechar os números após simulação da dose acumulada, antes de release; a especificação não aprova mortalidade aleatória.

Visual:getBlood informa sangue por região, mas não sua origem ou patógeno. O sistema modela risco geral de sujeira/contaminação; não deve alegar que identificou sangue de zumbi infectado. Não criar transmissão Knox por sangue nem cura Knox, e não revelar esse diagnóstico no exame.

Fonte de sangue compartilhada com ZombieDisguise exige um adaptador de exposição para não aplicar duas doenças/penalidades sobre a mesma causa.

## Medicamentos e atendimento

Reutilizar água, curativos, desinfetante, analgésicos, talas e instrumentos existentes quando servem. Acrescentar poucos itens novos com papéis diferentes: tratamento de complicação bacteriana, alívio de sintomas comuns, cuidado de queimaduras e material de reabilitação. Confirmar antes o que o vanilla já oferece para não criar duplicatas sem função.

Medicamentos têm unidade exclusivamente de jogo, duração, intervalo e limite de efeito; antibiótico não cura virose. Tratamento não é soma infinita de bônus. Não conceder XP por repetir uma ação sem benefício ou alteração clínica do episódio.

Exame deve orientar decisões: achado, gravidade por faixa, o que falta fazer e o que acompanhar depois. Mostrar ações indisponíveis e seus requisitos. Tratamento de outro jogador mantém consentimento vanilla; paciente e médico recebem o estado relevante.

Cuidado de queimadura, limpeza/irrigação, estabilização, imobilização, redução de fratura, desbridamento e reabilitação precisam ter situações de uso distintas. Torniquete serve para ganhar tempo até atendimento, não para vencer bandagens em qualquer ferida. Cauterização mantém função de último recurso.

Habilidade melhora diagnóstico, eficiência e acesso a procedimentos. Jogador solo recebe cuidados básicos; procedimentos complexos exigem preparação e podem ser menos eficientes sozinho. Bônus de profissões é opcional, não requisito de instalação.

## Limites de equilíbrio propostos

- Benefícios de recuperação combinados limitados a 40%; nunca instantâneos.
- Sintomas da mesma família usam o efeito predominante com teto, não a soma de mod + vanilla.
- Rigidez pós-exercício não vira dano nervoso e fratura não surge de cansaço normal.
- Episódios leves têm recuperação acessível; quadros graves dão avisos e tempo de reação.
- Doenças novas surgem de exposição evitável/trauma como padrão; não adoecer ao acaso só por existir o mod.
- Desativar uma família suspende seus efeitos adicionais e permite remover equipamentos/tratamentos persistentes.

Esses limites são propostas do Codex, separadas do pedido de conteúdo.

## Segurança do estado e multiplayer

Servidor controla exposição, trauma, sorteios, tratamento, XP e recuperação. Espelho mínimo para UI, com versão e identidade do episódio. Um médico não pode tratar o mesmo episódio em paralelo e duplicar efeito/XP. Separar consentimento, distância e recursos no servidor.

Preservar o item real usado como torniquete: identidade, condição, nome e propriedades ao devolver. Definir migração do estado antigo baseado só em fullType; não inventar propriedades que já foram perdidas.

Ao desativar, não manter um torniquete lesando o personagem enquanto sua remoção fica bloqueada. Doenças desativadas deixam de impor efeitos; não zerar indiscriminadamente valores que pertencem ao vanilla ou a outro mod.

## Etapas internas

A. Corrigir os cinco defeitos confirmados da base; implementar schema de episódios, migração e avaliação acionável.
B. Contaminação + doenças respiratória/gastrointestinal + medicamentos/cuidado e interface.
C. Queimaduras/fraturas acompanhadas + lesão muscular e reabilitação.
D. Lesões nervosas, integração de sintomas e compatibilidade com outros sistemas.

Estas etapas formam o escopo completo; terminar A não significa concluir a reestruturação.

## Aceite

Testes de episódios/reconexão, exposição curta/longa, lavagem, curativo, sintomas nativos existentes, medicamento inadequado, repetição/XP, tratamento interrompido, concorrência e desativação. Cada família deve ter caminho completo de causa, sintomas, cuidado e resolução.

No jogo: queimadura/fratura real, rigidez pós-exercício e lesão muscular distinta, evolução de doenças, sintomas funcionais nervosos, médico/paciente e dois clientes. Validar duração e incidência em partidas, sem alegar que testes por mocks provam simulação clínica ou sincronização.

Fontes: API BodyPartType/BodyPart/BodyDamage; vanilla ISWashYourself, ISHealthPanel, Fitness e ClientCommands. A existência de getters/setters não comprova o efeito funcional de qualquer diagnóstico ou medicamento novo.

## Decisões adicionais confirmadas

Catálogo inicial de dez quadros: ver DOENCAS-10.md. Complicações graves negligenciadas podem matar por progressão, com NewDiseaseMortalityEnabled configurável; contágio entre jogadores controlado por ContactTransmissionEnabled. Valores padrão propostos: ambos ligados, sempre com avisos e tempo de intervenção. Não causar morte instantânea ao carregar ou reconectar. A opção de mortalidade dos quadros novos não remove dano/morte vanilla por ferimentos, fome ou Knox.
