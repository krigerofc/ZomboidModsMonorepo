Prompt de Planejamento — Refatoração do Mod de Reparo Caseiro
Contexto
Existe um mod funcional em Mymod/ que atualmente repara apenas suspensão de veículos no Project Zomboid Build 42. Quero expandir o escopo dele para um sistema de reparo caseiro universal de peças de veículos.

Antes de planejar qualquer coisa, faça:

Ler guia.md completo, focando nas seções de:
BaseVehicle / classe Java de veículos
VehiclePart e tipos de peça (engine, brake, suspension, tire, window, door, gas tank, battery, radio, seat, trunk, muffler, etc.)
Eventos: OnVehicleDamageTexture, OnPlayerUpdate, eventos de uso de item, OnFillInventoryObjectContextMenu, OnFillWorldObjectContextMenu
Sistema de TimedAction / ISBaseTimedAction (para barras de progresso de reparo)
Recipe e InventoryItem (materiais e ferramentas)
Skills do player (Mechanics, Maintenance) e como ler nível
Sistema de loot de partes (VehiclePart:setCondition, getCondition, getInventoryItem)
Listar todos os arquivos atuais do Mymod/ (estrutura, mod.info, scripts Lua) para entender o que reaproveitar.
Mapear nominalmente quais peças existem por categoria de veículo (normal, esportivo, pesado) — se na Build 42 elas compartilham a mesma interface VehiclePart, NÃO precisa código específico por tipo de carro, basta operar sobre o VehiclePart genérico. Confirmar isso na doc.
Requisitos da nova feature
Escopo funcional
Cobertura universal: todo VehiclePart reparável (engine, brakes, suspension, tires, doors, windows, hood, trunk lid, muffler, gas tank, battery, seats, radio, headlights, etc.) deve ter opção de reparo caseiro.
Tipos de veículo: funciona em qualquer veículo do jogo — normais, esportivos, pesados (vans/trucks), policiais, etc. Não criar lista hardcoded; operar via API genérica.
Coexistência: reparo caseiro é uma alternativa, não substituto. O reparo normal vanilla (com peça nova ou kit de mecânico) continua funcionando.
Mecânica do reparo caseiro
Aspecto	Regra
Material principal	Sucata barata e abundante (ex: Scrap Metal, Duct Tape, Glue, Wire, Sheet Metal, Rags, Wood Plank) — variando por peça
Ferramentas	Conjunto básico (ex: Screwdriver, Wrench, Hammer, Lighter/Torch dependendo da peça) — confirmar nomes exatos no guia.md
Skill requerida	Bem baixa (mecânica nível 1-2) ou nenhuma — é justamente para sobreviventes sem expertise
Tempo de execução	Maior que reparo profissional (TimedAction longo, ex: 200-400 ticks dependendo da peça)
Ganho de condição	Parcial — recupera apenas X% da condição atual (não restaura a 100%). Sugestão inicial: +25 a +40 de condição, com cap em 60-70 (peça nunca fica "como nova" via reparo caseiro)
Risco de quebra: 20%	Em 20% dos reparos a peça quebra completamente (condição vai a 0 ou peça é destruída). Modificador: skill alta de mecânica reduz esse risco (ex: cada nível acima de 2 reduz 2%, mínimo 5%)
Eventos imprevistos (random events)
Durante ou ao fim do reparo, com probabilidade definida, disparar eventos secundários além do resultado normal. Sugestões (a serem validadas/expandidas no plano):

Evento	Probabilidade base	Efeito
Ferimento leve	~5%	Player toma scratch/laceration em braço ou mão
Queimadura	~3% (só em reparos que usam fogo/solda)	Burn leve
Ferramenta quebra	~5%	A ferramenta usada perde condição significativa ou quebra
Consumo extra de material	~10%	Gasta 1 unidade adicional de material sem benefício
Sucesso crítico	~5%	Reparo restaura mais condição que o normal (sem 20% de quebra nesse caso)
Sujeira/Stress	~10%	Player ganha unhappiness ou boredom
Importante: balancear para que o resultado esperado ainda seja útil — a soma de eventos ruins não pode tornar o reparo inviável. Player deve sentir que vale a pena tentar.

UX / Interface
Menu de contexto ao clicar com botão direito numa peça do mecânico (mesma janela onde aparece "Install"/"Uninstall"): nova opção "Reparo Caseiro".
A opção só aparece se:
Peça está danificada (condição < 100)
Player tem os materiais E ferramentas necessárias no inventário OU no chão próximo
Tooltip mostrando: materiais necessários, ferramentas, chance de quebra atual (já com modificador de skill), ganho estimado de condição.
Barra de progresso (TimedAction) durante o reparo, cancelável.
Notificação textual ao fim: sucesso / falha / evento imprevisto disparado.
Multiplayer
Lógica de autoridade no server (alteração de condição da peça, destruição da peça em falha, consumo de materiais).
Client envia comando, server valida e executa, server avisa client do resultado.
Sem trust do client em determinar sucesso/falha (anti-cheat básico).
Restruturação do código
Avaliar no plano:

A estrutura atual de Mymod/ (que reparava só suspensão) provavelmente está acoplada à classe Suspension. Decidir se:
Refatorar para um sistema genérico parametrizado por tipo de peça (RECOMENDADO se o código atual for pequeno).
Reescrever do zero mantendo apenas mod.info e poster.
Propor arquitetura modular:
Mymod/media/lua/
  shared/   → tabela central de configuração (materiais, ferramentas, chances por peça)
  client/   → menu de contexto, tooltip, TimedAction
  server/   → executor do reparo, RNG, eventos imprevistos, atualização de condição
Tabela de configuração central (shared/RepairConfig.lua) com entrada por categoria de peça, do tipo:
RepairConfig = {
  Engine = { materials = {...}, tools = {...}, conditionGain = 30, breakChance = 0.20 },
  Brake  = { ... },
  -- ...
}
Isso permite balancear sem mexer em lógica.
Saída esperada do plano
Seguir o formato fixo da zomboid-mod-planner, com ênfase em:

APIs e referências — todas validadas no guia.md, com seção exata.
Estrutura de arquivos — nova organização proposta vs. atual.
Plano passo a passo — implementação incremental, começando por:
Refator do reparo de suspensão usando a nova arquitetura genérica (mantendo paridade funcional)
Generalizar para todas as peças
Adicionar sistema de eventos imprevistos
UI/Tooltip
Multiplayer sync
Riscos e incertezas — destacar especialmente:
Quais peças têm comportamento especial (ex: pneu, vidro, bateria — pode ser que a API de reparo difira do resto)
Se o jogo permite destruir uma peça via Lua ou se "quebrar" significa só setar condição = 0
Compatibilidade com outros mods de veículo populares (se houver menção no guia.md)
Critérios de aceitação — observáveis no jogo, por exemplo:
"Em um veículo policial com freios em 15%, opção 'Reparo Caseiro' aparece com requisito Scrap Metal + Wrench, e em 5 tentativas seguidas com mecânica 0 espera-se ~1 quebra."
O que NÃO planejar agora
Localização (i18n) além de strings em inglês — fica para depois.
Sons/animações customizadas — usar os do jogo.
Balanceamento fino dos números — entregar valores iniciais razoáveis, fácil de ajustar via RepairConfig.
Quando o plano estiver pronto, a próxima etapa é alimentar a zomboid-mod-developer com ele para começar a refatoração.
