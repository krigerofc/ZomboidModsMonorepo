# Viabilidade da expansão de saúde — 22/10/2026

## Parecer

É possível construir boa parte da proposta em B42 com episódios próprios, observações regionais, ações com recursos reais e apresentação de sintomas. O ganho mais próximo é ligar diagnóstico incerto, lesão regional, cuidado específico e acompanhamento. A lista inteira descreve vários módulos de grande porte; não é uma alteração pequena nem está toda implementada.

Alvo já definido: **B42 e multiplayer**. Esta investigação leu a instalação local **42.19.2**, o código FieldMedicine e suas provas existentes. **42.21 não foi executada**. Não houve alteração de código de produção, abertura de partida, servidor, commit ou publicação nesta investigação. O texto anexado foi tratado como proposta para avaliação, não como autorização para implementar cada item. O código compartilhado estava em edição simultânea; os detalhes abaixo são um retrato de leitura, não uma declaração de versão publicada.

Legenda: **V** = recurso vanilla a reutilizar; **A** = viável por código próprio e integração atual; **F** = módulo futuro maior, arte/dependências/novas transações; **X** = conflito com escopo aprovado; **U** = suporte específico ainda não comprovado. U não significa impossível.

## O que existe hoje e o que continua pendente

* O vanilla já tem feridas regionais, fraturas/talas, sutura, remoção de vidro/bala, desinfecção e limpeza de queimadura. Portanto a premissa “só bandagem, pinça e desinfetante” subestima a base. Fontes: `media/lua/client/XpSystem/ISUI/ISHealthPanel.lua:1494–1662,1799–1812`; ações `media/lua/shared/TimedActions/{ISStitch,ISSplint,ISRemoveGlass,ISRemoveBullet,ISDisinfect,ISCleanBurn}.lua`.
* FieldMedicine tem procedimentos de exame, irrigação, torniquete, cauterização, redução de fratura e desbridamento, com regras de habilidade/XP/tempo/falha. Fontes: `FieldMedicine/Contents/mods/KRFieldMedicine/42/media/lua/shared/KFM/Core.lua:77–95,183–299`; `shared/TimedActions/KFM_ProcedureAction.lua`.
* Há infraestrutura própria de episódios: causa, região, latência, gravidade, recuperação, complicação, intervalo de cuidado e teto de benefício. O catálogo observado inclui as dez doenças iniciais, queimadura/fratura/músculo/nervo e as extensões garganta, síndrome febril de verão, calor e mãos frias. São **síndromes de jogo**, sem identificação de patógeno nem Knox. Fontes: `shared/KFM/Conditions.lua`, `Illness.lua:9–54,65–134`, `Health.lua:13–43,62–108,147–209`.
* Há código de exposição ambiental, máscaras/roupa/luvas, contato e cuidados com itens; estados reversíveis cardiorrespiratórios e psicológicos; sintomas de tosse/fadiga e efeitos pessoais de visão/desmaio/percepção. Fontes: `Environment.lua:6–42`, `Risks.lua`, `Dynamics.lua`, `Symptoms.lua`, `client/KFM/HealthEffects.lua`. Isso é existência de implementação e harness, não comprovação completa em partida/MP.
* O exame detalhado tem quatro abas, regiões, prioridades e cuidados, mas **ainda revela nomes exatos, fase e horas restantes**: `ExamModel.lua:48–54,59–60,85–98`; `Health.snapshot` envia `condition` e `remaining` em `Health.lua:147–160`. A antiga lista textual tem níveis de habilidade (`Core.buildExamReport`, linhas338–400), porém isso não comprova incerteza na nova janela nem privacidade no pacote recebido.
* O trabalho regional atual já distingue braços, pernas/pés e costas e evita duplicar penalidade de ferida nativa. `Strain.lua:1–48`, `Health.lua:168–186,406–428`, `server/KFM/KFM_Server.lua:43–75,98–99`. Braço usa dor nativa; perna usa maior custo de resistência em movimento; costas usam fadiga sob carga. Não equivale a uma animação de mancar, diminuição direta de sprint, luxação ou hérnia anatômica.
* Existem testes puros, de ligação e de apresentação em `FieldMedicine/tests/{illness,phase2,strain,exam,effects,glue}_spec.lua`. Não foram reexecutados por esta investigação durante as alterações do responsável. `MANUAL_TEST.md` continua a exigir cenários de reconexão, dois jogadores e recursos. Sem prova nova de execução MP aqui.

Nas referências ao mod acima e abaixo, `shared/KFM/`, `client/KFM/` e `server/KFM/` são relativos a `FieldMedicine/Contents/mods/KRFieldMedicine/42/media/lua/`.

## Matriz da proposta completa

| Proposta | Classe | Viabilidade e distância da implementação observada |
|---|---|---|
| Sintoma antes do nome; exame por nível e instrumentos | A | Prioridade viável. Gerar no servidor uma visão por observador/nível/instrumento, sem mandar diagnóstico oculto para depois escondê-lo só na UI. A janela atual ainda entrega nomes exatos. |
| Distensão por corrida/carga/golpes pesados | A | A base regional de esforço já existe; ajustar causas comprovadas e efeitos em vez de criar lesão a cada golpe. “Sem aquecer” requer nova ação/estado, não é observação nativa demonstrada. |
| Entorse de tornozelo por queda/janela/terreno; mancar/sprint | A/U | Episódio em `Foot_L/R` ou `LowerLeg_L/R` é viável. Eventos genéricos de dano não trazem região. Terreno irregular e alteração direta da marcha/sprint ainda exigem prova de gatilho/efeito; custo adicional de resistência é a alternativa atualmente comprovada no código. |
| Luxação de ombro/dedo, redução e imobilização | A/F | Ombro pode mapear `UpperArm`; dedo mapear `Hand`, com diagnóstico próprio. Não há dedo/articulação independente na anatomia verificada. Redução, teste/minijogo e reincidência são novas regras; animação específica é produção adicional. |
| Tendinite/LER e hérnia por repetição/carga | A/F | Trilhas próprias de duração, repouso e recaída são possíveis. Esforço de combate/árvore tem adaptadores atuais; serrar/cavar e penalidade ao agachar precisam observar as ações concretas. Hérnia real não é estado nativo verificado. |
| Concussão, costela trincada, hematoma interno | A/F | Episódios em Head/Torso, sintomas e exame são possíveis. Lesão interna, respiração dolorosa e deterioração precisam de modelo próprio. Não assumir que evento de dano identifica automaticamente cabeça/costela; rever a regra de sono abaixo. |
| Queimaduras de três graus, bolhas, infecção | V/A/F | Reutilizar queimadura/limpeza nativas; graus, bolhas e evolução específica são dados/arte próprios. Não são três graus já expostos pelo setter de tempo de queimadura. |
| Tendão rompido; impedir arma de duas mãos | A/U | Estado em mão/antebraço viável. Impedimento consistente de equipar/usar, recarga e compatibilidade com armas precisam de adaptadores comprovados; não se deduz de dor adicional. |
| Perfuração com vidro/estilhaço/prego retido | V/A | Vidro e bala já têm presença/remoção nativas e ações que causam dor. Novos tipos de objeto e sangramento ao remover precisam de regra/identidade própria; não transformar qualquer perfuração em `haveGlass`. |
| Mordida de animal, raiva e tétano | F/U | Episódios e fontes específicas são possíveis. Disponibilidade do animal e callback real de ataque por espécie não foram comprovados; cão/rato não podem ser presumidos a partir do evento de zumbi. Vacina/soro exigem estado próprio. |
| Frio, gangrena, pé de trincheira | A/F | Mãos frias e umidade já têm base; pé pode receber trilha própria. Gangrena é complicação nova; não implica amputação disponível. Dedos individuais e lesão permanente de tecido não existem como regiões nativas verificadas. |
| Infecção local → celulite/abscesso/sepse | A | Há cadeia própria `wound → deep → systemic`; nomes/estágios específicos e drenagem precisam de definição. Isso não prova que o vanilla possui sepse nem que toda infecção percorra obrigatoriamente a cadeia. |
| Fungos, urinária, gastroenterite, dental | A/F | Pele/fungo/alimento/viral já têm episódios próximos. Urinária/dental são novos módulos, fontes e cuidados; urina/dente não são órgãos/regiões nativos aqui. Diarreia pode ser sintoma abstrato, com animação/sistema corporal posterior. |
| Estações/clima/sono/fome/sujeira e imunidade | A | Exposição acumulada com mês, temperatura, umidade, roupa e condição corporal é viável e parcialmente codificada. Estação não deve criar doença instantânea. “Imunidade” é modelo do mod; não há variável universal de defesa clínica demonstrada. |
| Contágio de proximidade em MP | A | Política de contato/máscara/barreira existe (`Health.contact`, `Illness.contactEligible`). Precisa prova em dois clientes, autoridade, reconexão e prevenção de exposição duplicada. Não é efeito automático de `modData`. |
| Todas as classes de medicamentos listadas | V/A/F | Reutilizar identidades e efeitos vanilla quando compatíveis; classes/indicações específicas, antivirais, corticoides, anti-histamínicos, vacina/soro/adrenalina/morfina demandam catálogo próprio e balanceamento. Ter um item chamado medicamento não comprova farmacologia dessa classe. |
| Comprimido/xarope/pomada/injeção e seringa estéril/usada/contaminada | A/F | Formas e identidades de item são possíveis. Injeção precisa ação e transação no servidor, consumo, contaminação, conversão de estado e validação do paciente. Não está pronta só por declarar `OnEat`/`OnUse`. |
| Dosagem, overdose, interações, tolerância, abstinência, validade | F | Subsistema comum com relógio de personagem, registro por produto/substância, identificação do item, validade/lote e transação única. Persistir a última utilização não é modelo completo; evitar tabelas de doses médicas reais. |
| Estimulantes/opioides/álcool/cigarro e dependência | V/F | O jogo fornece intoxicação e abstinência de nicotina entre os stats verificados; dependência multissubstância, crash e interação são módulo próprio. Não representar “álcool piora sangramento” como efeito nativo demonstrado. |
| Chás, mel, carvão, antibiótico veterinário | V/A/F | Receitas e integração com coleta são possíveis. Identidades, efeitos de jogo, procedência e riscos dependem de design. A proposta não foi validada como instrução de preparo ou tratamento real. |
| Tala, gesso, tipoia, muleta, bengala | V/F | Tala nativa é reutilizável. Gesso/tipoia visíveis precisam arte/vestimenta; muleta funcional exige equipamento de mão, animação, deslocamento, combate, escadas/veículos e MP. Não é só novo ícone. |
| Sutura comum/cirúrgica/grampeador | V/A | Reutilizar sutura e materiais vanilla; níveis e grampeador são novos recursos com compatibilidade/consumo. |
| Desbridar, drenar abscesso, cauterizar, reduzir luxação, extrair dente | V/A/F | FM já tem desbridamento/cauterização; drenagem, luxação e dental precisam de seus próprios episódios/alvos/itens. |
| Soro IV e fisioterapia | A/F | Reabilitação/repouso com intervalo já existem. IV requer item, sessão, interrupção, paciente parado, consumo e autoridade; suporte visual pode vir depois. Não está implementado como hidratação intravenosa. |
| Amputação por gangrena, próteses | F | Grande sistema anatômico/visual/de equipamento/animação/rede próprio; não há remoção de membro por `BodyPart` comprovada. Uma ferida grave não retira o membro do esqueleto. |
| Amputação para impedir Knox/curar mordida zumbi | X | Contraria o escopo aprovado: não ler/diagnosticar/alterar Knox nem introduzir cura/amputação contra Knox. Não implementar como opção escondida de sandbox. |
| Trauma por matar conhecido, ver morte, cerco, isolamento, escuro | A/U/F | Contadores/contexto são possíveis; “era conhecido” requer identidade/relação própria. Eventos de morte não fornecem automaticamente testemunhas/linha de visão/vínculo. Cerco, isolamento e escuro precisam critérios observáveis e tempo, sem inferência narrativa automática. |
| TEPT/flashback, insônia, depressão, ansiedade e tratamento | A/F | Há estados de jogo reversíveis próximos: hipervigilância, humor baixo, sono perturbado, resiliência. Não são diagnósticos clínicos completos. Detecção de tiros/gritos, companhia, rotina, diário e pet dependem de adaptadores; latência de antidepressivo demanda registro de uso ao longo dos dias. |
| Alucinação por sono/droga, som/vulto/porta/luz | A/F | Som de UI/overlay pessoal são viáveis e parcialmente implementados. Vulto requer render/arte própria. Porta/luz devem permanecer **percepções individuais**; nunca abrir porta, alterar luz, criar zumbi ou ruído mundial para simular a ilusão. |
| Tremor de mão, recarga lenta; olho/ouvido | A/U/F | Dor de mão tem penalidades de acerto/combate comprovadas. Tremor visual, tempo de recarga e audição precisam efeitos próprios verificados. Olho/ouvido podem ser subtrilhas de Head, não novas partes nativas; overlay visual existe, alteração real de campo de visão/audição ainda não foi demonstrada. |
| Pulmão (pneumonia/asma), estômago (úlcera), pé | A/F | Mapear Torso/Foot e episódios é viável; não há órgão pulmonar/estomacal independente verificado. Tosse e custo de resistência existem como mecanismos próximos; gatilho por alimento específico depende dos dados de ingestão. |
| Profissões e traits positivos/negativos listados | V/A/F | Reutilizar médico/enfermeiro e traits vanilla compatíveis. Novos antecedentes requerem registro B42 e integração de efeitos; diabete/insulina, hemofilia, alergias e dependência têm sistemas próprios. Registro no parser não comprova seleção/efeito na tela ou MP. |
| Adquiridos: cicatriz, dor crônica, vício, imunidade pós-gripe, TEPT | A/F | Guardar estados do mod com início/fim/recorrência, sem adicionar traits nativos permanentes a cada tick. Cicatriz visual, vício e memória imunológica são extensões próprias; não estão todos implementados pelos estados reversíveis atuais. |
| Silhueta colorida, painel e prontuário longitudinal | V/A | `ISPanel`/`ISCollapsableWindow` e painel corporal vanilla permitem UI própria; uma silhueta pode mostrar subtrilhas conceituais. Prontuário de eventos com data, exame, cuidado, produto e vacina continua pendente; `treatments` por episódio/último uso não é histórico completo. |
| Termômetro/estetoscópio/pressão/respiração/glicemia/pupilas/raio X | V/A/U/F | Estetoscópio existe como item; temperatura central possui getter verificado. Pressão, frequência cardíaca/respiratória e glicemia medidos não foram verificados; valores próprios devem aparecer como **estimativas simuladas**. Pupila e raio X podem ser resultados do modelo/instrumento, com arte/itens, não exames reais disponibilizados pelo motor. |
| Moodles customizados e integração com outros mods | A/F/U | Painel próprio evita dependência obrigatória. Framework de moodles exigiria verificar identidade/versão/licença/API B42/MP; o nome genérico na proposta não é dependência comprovada. Compatibilidade Workshop precisa versões concretas e testes, sem prometer suporte geral. |
| Ícones, áudio, modelos 3D, sandbox por módulo | A/F | Ícones/sons/modelos são produção de assets com referências, licenças e teste de carga. Limites “500 tris” e “uma hora” são estimativas do texto, não restrições comprovadas do motor. Há switches atuais; cada módulo novo precisa desligamento/limpeza compatíveis. |

## APIs e limites que a evidência realmente sustenta

### Anatomia e efeitos

`zombie/characters/BodyDamage/BodyPartType.class` SHA256 `a53f28819b9eebddcc789b8e2769270f32cb0466cd7efa852fe3cf146f8b4f30` contém **17 regiões**: mãos, antebraços, braços, dois torsos, cabeça, pescoço, virilha, coxas, pernas e pés; `MAX` é sentinela. Não contém dedos, olhos, ouvidos, dentes, pulmões ou vértebras independentes. Um mapa corporal pode representar essas estruturas como dados próprios ligados à região, sem fingir que são BodyParts nativas.

`BodyPart` tem campos/procedimentos de ferimento; getters/setters não demonstram por si só qual efeito funcional o motor calcula. A prova `outputs/reestruturacao-mods-2026-10-21/regional-mobility-native-bytecode.txt` registra `IsoGameCharacter.class` SHA256 `d9073f19cf93dcab217cd046ae4c2218ac0133ca12226a0d4c21bb24c2b301d2`: `calculateCombatSpeed()F @202` chama `getArmsInjurySpeedModifier()F`; este chama `calculateInjurySpeed(BodyPart,Z)F` com `true` em @16/@44/@72. No cálculo, a ramificação de dor @302–328 só roda com esse booleano verdadeiro. O cálculo de pés chama com `false` (@38–39). Logo **dor adicional isolada na perna não prova mancar**. Não criar ferida/fratura falsa para produzir uma animação. O código regional atual usa custo de resistência em movimento, explicitamente distinto de velocidade direta.

`cold-hands-native-bytecode.txt` documenta `CombatManager.getPainPenalty`, cálculo de acerto e `BodyPart.getPain/getAdditionalPain`, base para a penalidade por mãos frias. A existência desse caminho não garante cada arma/animação/latência MP em jogo.

### Sinais vitais

`Stats.class` SHA256 `54c4a8272b481c08fcc482f773a5c33cdaf0fba107753e6db9786c0aabc5761f` expõe `get(CharacterStat)F` / `set(CharacterStat,F)Z`. `CharacterStat.class` SHA256 `ea336254ccc3688132a59d69592cc336663b1726a4f21fe47ba57affd50ee84b` tem ENDURANCE, FATIGUE, PANIC, THIRST, TEMPERATURE etc.; não inclui frequência cardíaca, pressão arterial ou frequência respiratória. Esses getters também não foram encontrados nas classes BodyDamage/Thermoregulator inspecionadas. Resultado: **U**, não alegação de inexistência global no motor.

`Thermoregulator.class` SHA256 `8509250f440a74ee79e668779f28c93f8343ced86bcc8a87e6a63790f52df384` expõe `getCoreTemperature()F` e `getCoreTemperatureUI()F`. Deve-se confirmar a semântica/unidade na integração antes de mostrar número clínico. O coletor atual usa `CharacterStat.TEMPERATURE` (`Game.lua:343–351`). Pulso e respiração no relatório atual são inferências de saúde/pânico/endurance (`Core.lua:354–360`), **não medições de frequência**. Não apresentar essas inferências como sensor nativo.

### Eventos: emissão, argumentos e autoridade

Os nomes abaixo foram conferidos em chamadas reais de `LuaEventManager.triggerEvent`, não apenas em registro/lista de eventos. Descritores `String,Object...` têm um Object por argumento Lua; offsets são do método indicado.

| Evento | Emissão local verificada | Argumentos e cuidado |
|---|---|---|
| EveryDays | `GameTime.update(Z)V @983/986` e @1108/1111 | **Existe**, zero argumentos; a grafia do anexo está correta. Caminho cliente processa `serverNewDays` (@844–989); outro caminho atualiza calendário (@992–1111). Não é callback exclusivo do servidor. |
| EveryTenMinutes / EveryOneMinute | Mesmo método @1368/1371 e @1407/1410 | Zero argumentos. Selecionar jogadores e impedir execução clínica duplicada em clientes; FM já usa `if isClient() then return end`. |
| OnPlayerUpdate | `IsoPlayer.updateInternal2()Z @1130–1134` | Jogador. Não comprova uma execução autoritativa única; reservar apresentação local/leituras leves, evitar progressão por frame. |
| OnWeaponHitCharacter | `IsoGameCharacter.Hit(HandWeapon,IsoGameCharacter,FZFZ)F @115–125` | Atacante, alvo, arma, dano. **Sem região**. O evento ocorre antes da continuação do processamento do hit; não é contrato de lesão regional confirmada. |
| OnPlayerGetDamage | Mesmo Hit @128–139; `BodyPart.DamageUpdate()V @253–265` | Personagem, motivo (`WEAPONHIT`, `BLEEDING` etc.), dano. Sem região; sangramento pode disparar repetidamente. Filtrar jogador e não criar concussão/entorse por todo callback. |
| OnZombieDead | `IsoZombie.onKilled(IsoGameCharacter,HandWeapon,Z)V @48–52` | Zumbi, sem lista de testemunhas/relação. Também aparece em caminhos de fogo de IsoGameCharacter. Guardar identidade/consumo para não duplicar trauma. |
| OnCreatePlayer | `GameLoadingState.exit()V @77–89` | Índice do jogador, objeto jogador. Criação de objeto/entrada não equivale sempre a personagem novo; inicialização persistente idempotente. |
| OnNewGame | `IsoWorld.init()V @4501–4508` e @5320–5327 | Dois objetos; a assinatura usada pelo vanilla em `shared/Items/SpawnItems.lua:142,299` é `(playerObj,square)`. Não usar como rotina de reconexão. |

Hashes adicionais: GameTime `d3fbefaa2b7f9b4184fe36d331d22f4e42a562736eb3c128b89f886dbe1172ba`; IsoPlayer `a6ca92e52ff958520b7d10d4e68772f676e90440254cdfd1d52ab3581e96b342`; BodyPart `621f81a768ac36388a811057ab2e08c194c913b93e5d5934f7f1e457bee9959a`; IsoZombie `ac1db2c6b90985ba6af45fc441c2f31d32c0952cb523f7d441de14ae7a773c81`; GameLoadingState `d044281b4d5c8036bb39c2b723b5a4d8d5aafe804f822ff1c4ec3885d32141ff`; IsoWorld `38af109ca77df11ee9ddf6acbbe1ede63ea89cb65792810f05f2ee7cefaf7d21`.

A existência da chamada não determina sozinha em qual máquina cada via de combate/rede será executada no MP. A integração precisa dono da simulação, servidor autoritativo, deduplicação e confirmação do resultado. Eventos não trazem automaticamente membro exato, familiaridade, testemunha ou diagnóstico.

### Persistência, rede e percepções

`Game.md` guarda estado versionado no `player:getModData().KFM`; `Health.push` envia snapshots explícitos (`Health.lua:162–166`) e `Game.lua:275–276` já explica que o cliente MP não recebe automaticamente o modData do servidor. **Guardar não é sincronizar**, e encontrar sendClientCommand/sendServerCommand não prova transação segura. Tratamento precisa revalidar paciente, alcance, consentimento, episódio, habilidade, item real, intervalo e resultado no servidor; FM já faz parte dessas validações (`Health.treat:224–283`). Ampliações exigem também replay, concorrência entre médicos, recursos e retorno após reconectar.

Incerteza diagnóstica deve ser aplicada antes de serializar dados para o observador; receber `condition` e apenas esconder o texto deixa o segredo exposto. Um prontuário deve registrar fatos e resultados históricos próprios; não acumular snapshots completos sem limite.

`psychological-sound-native.txt` registra SoundManager SHA256 `72facbb7bce33905ba19ad9d1a1b8787d9539834d943efe147d5283c4c10e804`, `playUISound(String)J`, uso do uiEmitter @51–57. O adaptador atual usa som de UI/overlay pessoal, sem mudar porta ou luz real. Som local pode ser ouvido no mesmo cliente em tela dividida; privacidade por ouvido/personagem não foi demonstrada. Tosse que atrai zumbi é uma ação de mundo separada e precisa teste MP próprio.

## Correções de premissa para o desenho

* Tétano não deve ser “metal enferrujado = doença”: a fonte é contaminação por esporos ambientais em feridas. [CDC — causas do tétano](https://www.cdc.gov/tetanus/causes/index.html).
* Resistência antimicrobiana pertence aos germes; não é uma barra universal do personagem nem consequência instantânea garantida de cada comprimido inadequado. Antibióticos não tratam vírus. [CDC — resistência](https://www.cdc.gov/antimicrobial-resistance/about/), [CDC — uso de antibióticos](https://www.cdc.gov/antibiotic-use/about/index.html).
* Remover a regra genérica “dormir nas primeiras horas após concussão é perigoso”. O NHS admite dormir quando cansado após lesão leve avaliada; como jogo, modelar observação/deterioração e gravidade sem transformar sono em causa universal de morte. [NHS — lesão de cabeça e concussão](https://www.nhs.uk/conditions/head-injury-and-concussion/).

Estas correções são de premissa de design. Não foram produzidas doses, receitas ou instruções clínicas reais.

## Próximo recorte recomendado para avaliação, sem ampliar automaticamente o escopo

1. **Incerteza do exame**: sintomas e observações visíveis em nível baixo; suspeita com confiança limitada; resultado mais específico só quando o modelo/instrumento realmente permite. Filtrar pacote no servidor para paciente e examinador, inclusive cuidados/tempos que denunciem o diagnóstico.
2. **Consolidar trilhas regionais dirigidas por fatos**: braços/antebraços por esforço confirmado; pernas/pés por deslocamento e exaustão; costas por deslocamento sob carga. Manter a precedência da lesão vanilla e os efeitos já comprovados. Novos gatilhos de queda/janela só depois de provar região/resultado.
3. **Cuidados próprios por trilha e acompanhamento**: repouso/proteção/reabilitação conforme região e momento, consumo finito quando aplicável e intervalos. Um cuidado deve tratar o episódio correto; não reduzir toda lesão indiscriminadamente.
4. **Prontuário longitudinal limitado**: horário de observação, nível/instrumento, achado/suspeita, cuidado e recurso consumido, reavaliação e resolução. Vacinas/doses só entram quando houver o respectivo módulo de itens/transações.
5. **Aceite verificável**: níveis diferentes mostram informações diferentes; pacote baixo não vaza diagnóstico; evento repetido não cria episódios duplicados; dois médicos não consomem o mesmo item nem concedem XP duplicado; reconexão restaura estado; desligar módulo remove apenas efeitos próprios; UI abre em partida e dois clientes observam resultados consistentes. Harness e inspeção de bytecode são etapas, não substitutos desse aceite.

Concluir esse ciclo produz uma experiência de primeiros socorros mais profunda usando a estrutura existente. Farmacologia completa, dependência, amputação/prótese, muletas funcionais e órgãos detalhados devem ser decisões futuras separadas.
