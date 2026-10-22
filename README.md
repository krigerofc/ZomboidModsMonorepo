# Zomboid Mods

Reestruturação local de seis mods do Kriger, em desenvolvimento na branch feat/mods-overhaul-20261021. As fontes originais de Workshop e os saves existentes permanecem preservados. Nenhuma alteração desta reestruturação foi publicada na Steam.

| Pasta | Nome / Mod ID | Builds | Estado atual |
|---|---|---|---|
| ReduceMetalWood | Build & Haul — Lightweight Materials / ReduceMetal&Wood50 x | B41+B42 | Materiais ampliados; suíte local e revisão de especificação/qualidade aprovadas |
| PassiveSkills | Passive Skills / Passiveskillskr | B42 | Revistas preservadas e16 VHS nativos; suíte local e revisão aprovadas |
| KRjobs | KRjobs / Krjobs | B41+B42 | 24 profissões B42 confirmadas no menu nativo; kits autoritativos com recuperação limitada |
| BasicVehicleMaintenance | MoreVehiclesRepairs | B42 | Reparos, carga, potência e aparência implementados; validação em partida/MP pendente |
| FieldMedicine | Field Medicine '93 / KRFieldMedicine | B42 | Doenças, lesões regionais, exame e prontuário implementados; build para teste |
| ZombieDisguise | ZombieDisguise | B42 | Expansão dependente de KRFieldMedicine em implementação; camuflagem desativada enquanto o caminho de IA é corrigido |

## Escopo e decisões atuais

- Build & Haul reduz por padrão 50% do peso de176 materiais elegíveis, incluindo madeira, metal, minérios e insumos de construção. Produtos acabados permanecem normais. Em recipientes de construção elegíveis, preserva a massa da embalagem vazia.
- Passive Skills mantém33 habilidades e a progressão fixa das revistas. As16 fitas usam reprodução e histórico nativos:250 XP **base** por fita no padrão, com multiplicadores, cutoff e cooldown do jogo. Não concede XP por inserir ou carregar fita.
- KRjobs: corrigido o carregamento nativo das definições; as24 profissões B42 aparecem traduzidas no widget real de criação. B41 tem20 definições, ainda sem execução real nesta revisão.
- Veículos: melhorias limitadas de capacidade/potência por instância, pintura, remoção de ferrugem e lavagem nativa. Compatibilidade pretendida para modelos com peças genéricas do jogo; sistemas exclusivos de outros mods ficam fora do suporte obrigatório. Velocidade máxima não foi entregue porque a persistência nativa não foi comprovada.
- Medicina: novas doenças sazonais, contaminação, cuidados específicos, lesões por frio, condições cardiorrespiratórias e psicológicas recuperáveis, exame detalhado e efeitos perceptivos locais estão implementados, com exame filtrado por habilidade/instrumento e prontuário por personagem. Ver HEALTH-PHASE2.md no projeto.
- Disguise: somente B42, dependência obrigatória de medicina e exposição compartilhada. O antigo setter de proteção é restrito a permissões de cheat na instalação local; não há promessa de invisibilidade enquanto a alternativa legítima não estiver comprovada.

## Evidência e limites

As suítes locais verificam sintaxe, recursos gerados, traduções e lógica com Fengari/objetos simulados. Algumas executam Lua nativo instalado sob simulação e inspecionam bytecode Java. Isso não certifica gameplay nem multiplayer.

A instalação consultada é 42.19.2; o alvo solicitado 42.21 ainda precisa de execução real. B41 também não foi executada. SP, host, dedicado com dois clientes, interface, ações concorrentes e save/reconnect fazem parte do aceite ainda pendente. Há um boot anterior da base de cinco mods documentado em [SMOKE-TEST.md](docs/SMOKE-TEST.md); ele não valida o código novo.

Cada projeto contém package.json, tests/ e MANUAL_TEST.md. Execute npm test na pasta correspondente com as dependências de desenvolvimento disponíveis. Ferramentas e testes não pertencem ao pacote Contents/.

See [current verification and test-build status](docs/STATUS-2026-10-22.md) before testing. Native server boot and character-creation checks do not certify treatment gameplay or two-client multiplayer.

## Documentos

- [Plano da reestruturação](docs/superpowers/plans/2026-10-21-mods-overhaul.md)
- [Escopo confirmado](docs/superpowers/specs/2026-10-21-overhaul/PROPOSTA-GERAL.md)
- [Medicina dinâmica](FieldMedicine/HEALTH-PHASE2.md)
- [Notas de implementação dos veículos](BasicVehicleMaintenance/IMPLEMENTATION_NOTES.md)
- [Origem da importação](docs/IMPORTACAO-2026-10-21.md)
- [Histórico de passagem](docs/HANDOFF.md)

RetroProfessions e VehicleMaintenance são as versões antigas substituídas por KRjobs e BasicVehicleMaintenance. Docs datados de 17/10 descrevem a base anterior e devem ser lidos como histórico quando conflitarem com o plano atual.

## English

This branch contains the next local versions of six mods. Build & Haul and Passive Skills passed offline verification and task review. Vehicle customization and expanded health are implemented for testing; dependent camouflage remains in development. All24 KRjobs professions and4 starting medical traits were confirmed with translated labels in the native B42 character-creation widgets. No gameplay/multiplayer certification, Steam upload or existing-save changes are claimed.
