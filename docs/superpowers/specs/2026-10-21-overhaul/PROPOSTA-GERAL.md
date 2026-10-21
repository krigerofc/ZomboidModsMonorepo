# Próxima versão dos mods — proposta de 21/10/2026

Estado: desenho consolidado com as respostas do usuário; funcionalidades novas ainda não implementadas. As funcionalidades novas descritas aqui ainda não foram implementadas.

## Objetivo

Manter a identidade dos mods e transformar as atualizações em ferramentas úteis de sobrevivência: transportar materiais, aprender, escolher profissões, recuperar e personalizar veículos, cuidar de doenças e lesões. Todo texto de jogador em PT-BR e EN. Multiplayer é requisito de aceite dos seis mods, incluindo ZombieDisguise. FieldMedicine e ZombieDisguise serão somente B42, conforme decisão final do usuário.

## Pedidos confirmados nesta conversa

| Mod | Novo escopo pedido |
|---|---|
| ReduceMetalWood | Novo nome; incluir minérios e materiais de construção transportados em quantidade |
| Passive Skills | Somente B42; acrescentar VHS que ensinam habilidades |
| KRjobs | Conferir se o conteúdo está completo e se a implementação pode ser considerada concluída |
| Basic Vehicle Maintenance | Reformulação grande; reparos caseiros, mais reparos, capacidade, desempenho e aparência; veículos vanilla e de mods |
| FieldMedicine | Reformulação grande; doenças comuns, contaminação por sangue, medicamentos e tratamentos, queimaduras, fraturas, danos musculares e nervosos |
| Todos | Multiplayer e equilíbrio; manter PT-BR + EN |

A aprovação anterior de enviar o PR de importação não significa que estas funcionalidades já existam. O PR #1 foi incorporado à main externamente durante esta conversa e contém a base revisada (head 21d3a7b). As especificações descrevem a próxima etapa; os dois commits posteriores do relatório de servidor permanecem na branch de atualização, ainda fora da main.

## Decisões propostas pelo Codex

- Novo nome público do mod de peso: **Build & Haul — Lightweight Materials / Materiais Leves**. Manter o Workshop ID e o mod ID antigo para continuidade.
- Redução padrão continua 50%; materiais de construção entram, produtos finais, ferramentas, alimentos e armas completas não.
- Passive Skills deixa de distribuir B41. KRjobs e o mod de materiais mantêm B41. Medicina e veículos continuam B42.
- VHS são conteúdo original adicional; revistas mantêm seus valores de XP. Ver proposta de equilíbrio no documento próprio.
- Doenças novas decorrem de exposição e condições identificáveis, com sinais graduais. Complicações graves sem tratamento poderão matar gradualmente; mortalidade e contágio entre jogadores serão configuráveis. Não alterar a transmissão Knox.
- Lesões nervosas serão recuperáveis por padrão. Sequelas permanentes ficam fora da primeira versão.
- Os mods funcionam separadamente; integração com profissões é opcional e limitada.
- Fases podem ser testadas separadamente, mas nenhuma fase incompleta será anunciada como entrega de todo o novo escopo.

Estas são escolhas de implementação do Codex, separadas das decisões explícitas do usuário.

## Ordem de entrega proposta

1. Materiais ampliados e renomeação.
2. Passive Skills B42 com VHS.
3. Corrigir autoridade dos kits KRjobs, conferir receitas, balanceamento, traduções e ícones.
4. Oficina de veículos: base compatível, reparos, personalização e melhorias.
5. Medicina: base de episódios, doenças/contaminação e tratamentos; depois músculos/nervos e reabilitação.
6. Validação combinada dos seis mods em SP, host e servidor dedicado com dois clientes.

## Critério comum de pronto

Testes automatizados passando não bastam. Exigir instalação limpa, interface em EN/PT-BR, gravação e recarga, reconexão, reinício, ações concorrentes e falhas controladas. Informar exatamente a versão do jogo e os mods de veículos testados. Para B41, validar materiais e profissões em instalação real antes de certificar suporte.

Não anunciar compatibilidade universal com qualquer mod existente: a arquitetura deve ser ampla, as operações incompatíveis devem ser isoladas e os adaptadores/testes devem nomear quais integrações estão comprovadas.

## Documentos

- [Materiais](MATERIAIS.md)
- [Passive Skills e VHS](PASSIVE-SKILLS-VHS.md)
- [Conferência do KRjobs](KRJOBS.md)
- [Oficina e personalização](VEICULOS.md)
- [Doenças e medicina](MEDICINA.md)
- [Dez doenças e quadros](DOENCAS-10.md)
- [Disguise e multiplayer](DISGUISE-MULTIPLAYER.md)
- [Evidências da auditoria](AUDITORIA.md)

## Limites desta etapa

Nenhum código de produto foi alterado para implementar esta proposta. Nenhum jogo foi atualizado ou executado. Não houve upload Steam nem merge realizado pelo Codex. O PR inicial foi mesclado externamente na main; nenhuma funcionalidade desta proposta foi enviada para lá. Os testes automatizados da base passaram em 21/10; o relatório novo de servidor confirma um boot anterior em 42.19.2, sem cliente, e não certifica gameplay ou 42.21.

## Decisões finais do usuário

- Doenças/complicações negligenciadas podem causar morte gradual; opção de sandbox para desativar.
- Gripe e viroses podem transmitir entre jogadores; opção de sandbox para desligar.
- Compatibilidade de veículos de mods restrita aos que utilizam peças genéricas já existentes no jogo; não exige peças ou sistemas exclusivos.
- Catálogo de aproximadamente dez doenças/quadros.
- FieldMedicine e ZombieDisguise somente B42. ZombieDisguise será expansão dependente do FieldMedicine, integrando sangue, exposição, feridas e penalidades prolongadas.
- Nova capa do Disguise no mesmo estilo 3D aprovado; arte já gerada nos tamanhos1024/512/256/64.

Os valores de tuning/capacidade e catálogo de VHS continuam escolhas de implementação do Codex, documentadas para revisão e ajuste de equilíbrio.
