# Field Medicine '93 — validação no jogo

Build em desenvolvimento, alvo B42. Testes automatizados usam parser Lua 5.1 e VM com mocks; não certificam interface, tela de criação, áudio/animação ou multiplayer. Fontes nativas: 42.19.2. Validar no alvo 42.21 em cópia isolada. Não alterar saves originais.

## Preparação e procedimentos

- Repetir EN/PT-BR, host/dedicado com dois clientes, paciente/médico/observador e reconexão. Registrar versões e logs reais, sem erros/chaves cruas. Conferir itens, receitas, distribuição e sandbox.
- Criação de personagem: verificar os quatro históricos `kfm:respiratory`, `kfm:cardiac`, `kfm:stresssensitivity`, `kfm:resilience`, com um estado recuperável por escolha. Cadastro nativo dos quatro históricos foi comprovado no dedicado42.19.2; seleção e apresentação na tela de criação continuam pendentes.
- Exame: cinco abas (incluindo Histórico), prioridade por gravidade, região, sintomas, cuidados/intervalos/habilidade e guia. Exposição não vira diagnóstico. Nomes não injetam marcação. Instrumentos/habilidade ampliam achados; abaixador de língua é consumido. Febre continua inespecífica mesmo após mordida; nunca consultar/identificar/alterar Knox.
- Outro paciente precisa aceitar a permissão específica do mod, revogável e válida por uma hora de jogo. Médicos não compartilham permissão. Revalidar distância, andar, alcance, episódio, habilidade e recurso na conclusão.
- Irrigação consome 0,25 L de água real; água suja tem risco. Curativo/sutura impede procedimentos incompatíveis. Cauterização exige faca/isqueiro e uso real; não fecha mordida. Debridamento exige instrumentos/habilidade e reabre sangramento.
- Torniquete mantém item real no inventário do paciente, vinculado ao ID. Retirá-lo, vesti-lo, destruí-lo, morrer ou desativar o mod libera o suporte, sem duplicar item. Feridas não tratadas voltam a sangrar. Isquemia prolongada causa dano nativo e episódio nervoso.
- Redução de fratura exige repouso, tem limite cumulativo por lesão e novo orçamento após trauma realmente novo. XP exige procedimento/cuidado útil e intervalo por paciente.

## Doenças e exposições

Catálogo: 14 definições de doenças/exposição e quatro trilhas de lesão (queimadura, fratura, músculo, nervo). Nomes descrevem quadros do jogo sem identificar patógeno real.

- Resfriado, intoxicação, ferida infectada, queimadura e fratura nativos têm precedência; não duplicar sintomas nem aplicar mortalidade genérica a quadros leves.
- Sangue/sujeira persistente, pele úmida/suja, ferida aberta e refeição concluída com mãos sujas têm vias distintas. Limpar/remover a fonte interrompe exposição; atualizar curativo/máscara não reinicia a dose.
- Gripe: contato próximo prolongado, mesmo andar, sem barreira. Gastroenterite: cuidado realmente concluído sem proteção, nunca simples proximidade. Afastar, desconectar ou resolver o quadro encerra contato.
- Frio úmido acumula risco de garganta/mãos; luvas ajudam nas mãos. Calor úmido acumula risco térmico. Mosquitos exigem verão quente, ambiente externo e pele exposta durante tempo suficiente. A estação sozinha não cria doença.
- Máscara apropriada reduz vias pertinentes e parcialmente exposição facial; não protege totalmente olhos/pele/feridas e não reduz mosquito na pele. Roupas/repelente usam observações/recursos reais; repelente dura quatro horas simuladas.
- Conferir cuidados específicos: suporte, água limpa, antibiótico apenas para complicação elegível, pomada, secagem, queimadura, tala, garganta, febre, aquecimento/resfriamento. Medicamento vazio, item ausente/vinculado ou intervalo repetido não consome recurso nem concede cuidado/XP.
- Cuidados combinados removem no máximo 40% do curso base, sem cura instantânea. Complicações graves negligenciadas avisam antes de dano gradual. Desligar mortalidade remove dano adicional; gravidade multiplica esse dano uma única vez.

## Distensões regionais

Rigidez/fadiga comum após exercício permanece nativa. Distensão exige esforço exausto sustentado, com fôlego abaixo de 20%, sem sorteio de dano.

| Causa sustentada | Região do motor | Limitação |
|---|---|---|
| Pelo menos 12 golpes reais de ferramenta por janela de 10 min, acumulando 40 min exaustos | ForeArm_R; ForeArm_L também se ambas as mãos usam a ferramenta | Dor adicional 12 antes de gravidade/cuidados, com penalidade nativa de armas; ferramenta acrescenta pequena fadiga |
| Pelo menos 12 acertos reais de arma corpo a corpo por janela, acumulando 40 min exaustos | UpperArm_R; UpperArm_L também se ambas as mãos trabalham | Dor nativa de manejo de armas, sem segundo multiplicador de combate |
| Corrida exausta acumulando 40 / 60 min | LowerLeg_L/R / Foot_L/R | Custo limitado de fôlego em movimento |
| Movimento acima da capacidade de carga por 30 min exaustos | Torso_Lower, representação de tronco inferior/lombar | Fadiga limitada apenas durante movimento sobrecarregado |

- Pausas reduzem a dose. Reconexão/primeira observação não acrescenta dez minutos fictícios. Janela perdida não conta como trabalho contínuo. Acertos multi-alvo no mesmo instante não multiplicam dose.
- Trilhas coexistentes usam o maior custo, sem somar cada perna/pé. Rigidez, ferida, queimadura ou fratura nativa na região tem precedência sobre efeitos adicionais. Uma distensão real pode continuar em recuperação após a rigidez comum passar. Não fabricar fratura/arranhão/velocidade ou anatomia. Dor adicional sozinha não demonstrou provocar mancar nas pernas.
- Exame identifica região, limitação e três cuidados: repouso orientado (6h, sem material), reabilitação (12h, Primeiros Socorros 2, faixa consumida), suporte (4h, sachê consumido). Repouso/reabilitação exigem paciente em repouso. Repouso acelera recuperação; atividade a retarda.
- Ao resolver/desativar, retirar apenas dor própria. Escritores externos têm precedência; um escritor que reproduza exatamente o mesmo valor não pode ser distinguido.

## Estados temporários e sintomas

- Históricos selecionados/contexto prolongado geram vulnerabilidade respiratória/cardíaca, hipervigilância, humor baixo, sono desregulado e resiliência. Recuperam; não adicionar traço nativo adquirido permanente nem pontos de criação.
- Conferir custo de fôlego/fadiga no esforço cardiorrespiratório, duração de procedimentos com humor baixo e benefício modesto de recuperação em repouso com resiliência. Cuidados têm recursos, habilidade e intervalos próprios.
- Tosse adicional usa chamada nativa finita sem criar resfriado. Não duplicar tosse nativa. Conferir áudio/transmissão real do motor.
- Alteração visual usa sobreposição breve própria. Desmaio: blackout de três segundos, interrompe mira/ação, solicita animação de sentar, bloqueia movimento somente se adquirir esse bloqueio. Não ocorre dentro de veículo. Preservar restrições anteriores e conferir restauração.
- Portas/rangidos/cintilação psicológicos são percepções locais finitas; não abrir portas, alterar luzes/objetos ou gerar som mundial para zumbis. Tela dividida tem imagem por viewport, mas áudio do aplicativo compartilhado.
- Desmaio tem prioridade sobre percepção simultânea. Desligar apenas percepções psicológicas não cancela desmaio. Morte, expiração/sandbox limpam exclusivamente efeitos próprios.

## Persistência e compatibilidade

- Desconectar/reconectar: sem progresso/cuidado/exposição offline. Fonte repetida não recria episódio resolvido; fonte realmente nova pode gerar outro.
- Conferir sincronização de dor/fôlego/sede/fadiga para o dono; snapshot para paciente/médico autorizado; nenhum efeito local em observador remoto.
- Repetir com mods médicos: menus vanilla preservados e dor externa com precedência. Integração com ZombieDisguise compartilha a exposição regional; não ativar a camuflagem desabilitada desse outro mod.
- Anexar logs de host/dedicado/clientes, capturas da janela e resultado de cada cenário. A suíte automatizada não substitui esse roteiro.

## Protocolo clínico e histórico — 22/10/2026

- Nível efetivo0–2: observações;3–5: suspeita de síndrome;6–10: avaliação clínica conforme instrumento. Estetoscópio para quadros respiratórios/cardíacos; abaixador de língua para garganta; observação regional/pele não exige estetoscópio arbitrário. Mesmo avaliação clínica não identifica patógeno/Knox.
- Exame autoriza apenas episódios/condições observados naquele momento por uma hora simulada. Complicação ou novo episódio exige reavaliação. Remover instrumento reutilizável reduz informação/cuidados dependentes. Abaixador descartável consumido no exame não precisa reaparecer para validar esse exame concluído.
- Rotas públicas usam identificadores opacos e informação filtrada pelo servidor; nada de causa, fase exata ou contagem secreta de horas em menus/sync/fallback. Episódios latentes não são apresentados.
- Histórico por personagem: até64eventos, exibe20mais recentes; exames iguais do mesmo observador coalescem por1h. Registro de exame preserva o achado conhecido então; eventos de cuidado mostram intervenção/recurso. Um novo personagem na mesma conta não herda as observações do antigo.
- Testar três janelas abertas: revogar/expirar consentimento fecha todas sem erro. Reconectar/trocar personagem fecha relatórios antigos. Dois clientes devem confirmar isso de verdade.
- Checks locais:31arquivos Lua,16JSON,299chaves EN/PTBR e9suítes; não equivalem a aceite de gameplayMP.
