# KRjobs — conclusão e multiplayer

Estado: auditoria da base e critérios para fechamento.

## Implementado

24 profissões e 24 traços B42; 20/20 B41. Os oito exemplos pedidos pelo usuário estão presentes. Novas habilidades B42, receitas, kits e traduções EN/PT-BR estão no catálogo gerado. As suítes automatizadas e a resolução dos ícones passaram na base importada.

13 profissões ainda usam ícones provisórios/reutilizados. Isso é acabamento pendente, não referência de textura quebrada. O balanceamento por fórmula foi conferido, mas não foi avaliado jogando.

## Correção necessária

Core.onNewGame altera o inventário e marca o personagem sem selecionar autoridade de cliente/servidor. O padrão vanilla SpawnItems.OnNewGame retorna no cliente. Os mocks atuais repetem o evento no mesmo objeto, o que não testa representações separadas de servidor e cliente.

Definir a concessão autoritativa dos kits e garantir entrega única por personagem, inclusive se um item falhar durante a concessão. Não marcar o kit inteiro como entregue antes de saber o resultado. Manter B41 e B42 compatíveis com seus eventos reais; não transpor um protocolo B42 para B41 por suposição.

## Condições para declarar concluído

- Criar personagens de todas as profissões, com ícone, custo, traço e efeitos corretos.
- Conferir as 57 receitas B42 distintas no jogo alvo e os itens dos kits.
- Testar kit em SP, host e dedicado, inventário visível nos dois clientes, reconexão, restart, morte/novo personagem e falha parcial.
- Validar B41 real para as 20 profissões.
- Rever os custos em partidas; sem elevar bônus por causa das integrações médicas/mecânicas.
- Produzir os 13 ícones finais no estilo visual aprovado e conferir legibilidade.
- Corrigir documentos que afirmam que o vanilla concede kits client-side.

Integrações médicas/mecânicas devem funcionar por registro explícito e opcional. Ter a profissão não dispensa ferramentas, recursos e requisitos do servidor.

Resultado da auditoria: conteúdo principal presente; ainda não está 100% concluído/certificado.
