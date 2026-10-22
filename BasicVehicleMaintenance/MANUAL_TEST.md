# Basic Vehicle Maintenance — roteiro de validação

Esta implementação tem verificação automatizada e inspeção de fontes locais. Os cenários abaixo ainda precisam ser executados em jogo. Use um perfil descartável autorizado; não use um save existente para a primeira validação.

Mod ID: MoreVehiclesRepairs. Workshop ID: 3643006111. Somente B42, mínimo declarado 42.15; validar também no build alvo do lançamento. Os fixtures originais foram gerados com a instalação identificada como 42.19.2. A versão do jogo efetivamente usada deve ser registrada no resultado.

## Matriz pendente

| Ambiente | Situação |
|---|---|
| Testes offline / Lua 5.1 / fontes e pacotes locais | Verificados; veja IMPLEMENTATION_NOTES.md e log final |
| SP no build alvo | Pendente |
| Host + dois clientes | Pendente |
| Dedicado + dois clientes | Pendente |
| Reconexão e reinício do perfil de teste | Pendente |
| Veículo de mod real com peças genéricas | Pendente; registrar nome/versão do mod e modelo |
| Sistemas exclusivos de outros mods | Fora do suporte obrigatório |

## Descoberta e recursos

1. Abra Mecânica e o menu de uma peça instalada: reparo, inspeção e Oficina do veículo devem coexistir com as opções vanilla. Teste pausa, personagem dentro do carro e menu anterior aberto.
2. Confira EN e PTBR, sem chaves cruas. A página sandbox tem 15 opções, incluindo melhorias e personalização.
3. Teste Mecânica 0, 3 e 6. Mesmo opções bloqueadas devem explicar ferramentas, custos e habilidade. Nível II exige veículo coberto.
4. Materiais/ferramentas em bolsas devem ser transferidos antes do trabalho. Ferramentas quebradas e materiais perdidos após entrar na fila devem impedir o efeito sem consumo parcial adicional.
5. Em servidor dedicado, teste sem a interface de Mecânica do cliente no servidor. Chave correta, porta/janela acessível e veículo trancado devem seguir as regras nativas de acesso.

## Reparos

- Remendo soma uma penalidade; reparo durável preserva a quantidade; revisão remove uma. Repare uma peça já melhorada e confira preservação da melhoria.
- Uma revisão com histórico restante, mesmo acima do teto ou em 100%, pode limpar uma penalidade; sucesso preserva a condição existente e consome os custos normais.
- Janela destruída precisa de substituição. Lâmpadas e peças ausentes não são reconstruídas.
- Confira condição do item e da peça, estatísticas físicas, XP diário e estado visto pelo outro cliente.
- Tente outro piso, veículo em movimento, motor ligado, fora da área nativa e peça trocada durante a fila. Nenhum efeito ou custo deve ser aplicado.

## Carga, porta-luvas e potência

1. Coloque dois veículos iguais lado a lado. Aplique níveis I/II apenas em um. Porta-malas: +10%/+20%, adicional máximo 40; porta-luvas: +25%/+50%, máximo 5. Os valores base são por peça física e usam arredondamento inteiro.
2. Repita o mesmo nível: não deve empilhar nem cobrar novamente. Troque de I para II e confirme cálculo sobre a base original.
3. Repare, desinstale e reinstale a mesma peça, depois substitua por outra. A melhoria deve acompanhar a peça antiga; a substituta não recebe bônus gratuito.
4. Teste trailer comum (TrailerTrunk), inclusive abaixo de 80% de condição. O bônus soma à capacidade nativa; ração/ovos e trailers de animais não recebem melhoria presumida.
5. Retire uma melhoria com carga acima da nova capacidade: bloquear. Em peças danificadas pode ser necessário descarregar mais por prudência. Nunca descartar ou ejetar conteúdo.
6. Desative melhorias no sandbox: potência volta à base; carga volta quando o conteúdo permitir. Reative e confira a mesma base original.
7. Afinação I/II: +5%/+10% de potência; qualidade e ruído precisam permanecer idênticos. Confira repetidas aplicações, carga do veículo, reconexão e reinício.
8. Velocidade máxima não faz parte desta versão.
9. Se outro sistema alterar capacidade/potência para valores diferentes da base ou do bônus conhecido, a oficina deve suspender a melhoria com explicação, preservando a alteração externa.

## Aparência e lavagem

- Pinte com as dez tintas nativas e pincel. Consumo base: quatro usos por trabalho. Modelos sem coloração nativa devem desabilitar somente pintura.
- Remova ferrugem em aplicações de até 20 pontos percentuais. Pintura/ferrugem não alteram condição ou proteção.
- Confira cor/ferrugem no segundo cliente, após reconexão e reinício.
- Lave sangue pelo menu: deve usar a ação vanilla, descontar água e continuar pelas áreas como a lavagem normal. Sem água/sangue, mostrar motivo. Não duplicar lavagem nem conceder XP pela oficina.

## Concorrência e persistência

Com dois personagens no mesmo veículo, inicie ações equivalentes e com cores/níveis diferentes ao mesmo tempo. Somente uma intenção com a revisão inicial pode concluir; a outra deve parar sem consumo duplicado. Repita com troca de peça, retirada de materiais, deslocamento, morte/cancelamento e reinício.

Registre sempre build do jogo, ambiente, mods/modelos, materiais antes/depois, capacidade efetiva, potência/qualidade/ruído, observação de ambos os clientes e erros do console. Separe inicialização sem erro de validação completa de jogabilidade.
