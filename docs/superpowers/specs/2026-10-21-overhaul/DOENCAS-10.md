# Catálogo inicial — dez doenças e quadros

Estado: desenho de jogo para implementação; aproximadamente dez quadros foram pedidos pelo usuário. Os nomes clínicos indicam o quadro simulado, não diagnóstico real.

| # | PT-BR / EN | Entrada no sistema | Utilidade dos cuidados |
|---|---|---|---|
| 1 | Quadro gripal / Flu-like illness | Exposição respiratória a personagem sintomático e causas ambientais modeladas | Repouso, hidratação e alívio limitado dos sintomas |
| 2 | Gastroenterite viral / Viral gastroenteritis | Contato/exposição contaminada por uma via observável no jogo | Controle da perda de hidratação e recuperação; remédio não encerra o episódio instantaneamente |
| 3 | Intoxicação alimentar / Foodborne illness | Comida/água imprópria com integração ao episódio vanilla correspondente | Suporte e acompanhamento; não aplicar duas intoxicações pela mesma ingestão |
| 4 | Infecção de ferida / Wound infection | Ferida aberta contaminada e higiene inadequada | Limpeza, proteção e tratamento da complicação |
| 5 | Infecção cutânea profunda / Deep skin infection | Possível agravamento do quadro local negligenciado | Tratamento mais exigente, sem empilhar o episódio anterior |
| 6 | Infecção sistêmica / Systemic infection | Complicação rara de infecção grave não cuidada | Urgência de atendimento; risco de morte gradual se mortalidade estiver ligada |
| 7 | Complicação respiratória / Pneumonia-like illness | Possível evolução de quadro respiratório negligenciado | Atendimento especializado e suporte; não inventar identificação de patógeno |
| 8 | Conjuntivite / Conjunctivitis | Exposição persistente de face/olhos sujos | Higiene e cuidado local, penalidade visual/de ação limitada |
| 9 | Dermatite de contato / Contact dermatitis | Irritação por sujeira e contato prolongado com sangue | Limpeza, proteção da pele e recuperação; não contagiosa |
| 10 | Micose cutânea / Fungal skin condition | Umidade/higiene prolongada em regiões elegíveis | Cuidados locais e secagem, evolução lenta e baixa gravidade |

## Regras do catálogo

Dez quadros não significam dez novos sorteios independentes sobre a mesma causa. Os quadros4→5→6 e1→7 são cadeias de possível progressão: um episódio muda de estágio/diagnóstico, sem somar todas as penalidades anteriores.

Diferenciar gravidade: dermatite, micose e conjuntivite não viram quadros fatais por um cronômetro genérico. Mortalidade adicional se aplica a complicações sistêmicas graves e negligenciadas, com avisos e janela de reação.

Contágio entre jogadores é confirmado pelo usuário e pode ser desligado no sandbox. Proximidade, mesmo piso, barreiras/ambiente e tempo de contato são relevantes para a via respiratória. Outras vias não devem ser simuladas como “qualquer doente transmite pelo ar”. Não transmitir fraturas, distensões ou lesões nervosas.

Uma fonte de exposição só pode receber identidade de patógeno se o próprio sistema a conhece. Sangue visual desconhecido não equivale a vírus/bactéria identificados. Exames mostram suspeita/confiança e gravidade por faixa; não detectam Knox.

Definir constantes iniciais por quadro na implementação, com testes determinísticos e sandbox para frequência/gravidade. Não anunciar uma doença como entregue só porque há um nome traduzido: exigir causa, sintomas, tratamento, progressão e resolução testados.

A proposta utiliza doenças/quadro comuns e suas complicações para manter escopo verificável. Acrescentar tétano, leptospirose ou enfermidades raras exigiria definir novas causas, itens e formas de diagnóstico; não entram automaticamente só para aumentar a contagem.
