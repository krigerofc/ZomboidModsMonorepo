# Zomboid Mods

Versões atuais dos mods de Kriger, importadas dos repositórios locais em 21/10/2026 com as correções da revisão conjunta. Esta branch organiza o código; a validação completa dentro do jogo continua pendente.

| Pasta | Mod ID | Builds previstas | Situação |
|---|---|---|---|
| ReduceMetalWood | ReduceMetal&Wood50x | B41 + B42 | Implementado; testes automatizados passaram |
| PassiveSkills | Passiveskillskr | B41 + B42 | Implementado; testes automatizados passaram |
| KRjobs | Krjobs | B41 + B42 | Implementado; testes automatizados e de ícones passaram |
| BasicVehicleMaintenance | MoreVehiclesRepairs | B42 | Implementado; testes automatizados passaram |
| FieldMedicine | KRFieldMedicine | B42 | Implementado; testes automatizados passaram; capa provisória |
| ZombieDisguise | ZombieDisguise | B42 declarada no pacote antigo | Preservado do repositório anterior; revisão e testes pendentes |

RetroProfessions foi substituído por KRjobs. VehicleMaintenance foi substituído por BasicVehicleMaintenance. Os identificadores de jogo das versões atuais foram preservados; ZombieDisguise não recebeu alterações de código nesta importação.

## O que foi preservado

- Materiais de madeira e metal, incluindo peças de ferreiro, recebem a redução padrão de 50%; itens acabados mantêm o peso e a redução não acumula.
- Passive Skills mantém a quantidade anterior de XP, leitura única por volume por personagem e feedback PT-BR/EN. A proposta de revistas para habilidades adicionais continua fora do escopo aprovado.
- Os cinco mods revisados incluem descrições e traduções PT-BR/EN, testes, ferramentas de geração e roteiro manual.
- PRDs e decisões de medicina e veículos ficam em docs/. Propostas futuras nos documentos não são funcionalidades já implementadas.

## Validação e pendências

Em 21/10/2026, os cinco runners tests/run.js passaram na cópia importada; KRjobs também passou em tests/icons.js. Os testes verificam sintaxe, fixtures e lógica com simulação da engine; não substituem uma sessão real do jogo.

A revisão anterior tinha como alvo 42.21. O boot real documentado foi observado em 42.19.2: carregou os cinco mods e confirmou a redução de 148 materiais sem aplicação duplicada. Isso não comprova ações, interface ou sincronização entre clientes. A versão instalada não foi atualizada nem novamente verificada nesta importação.

Antes de publicar:
1. Validar em jogo na versão alvo, primeiro em save novo, depois persistência ao salvar/carregar.
2. Testar host e servidor dedicado com dois clientes, reconexão e reinício.
3. Validar revistas/XP/spawn, profissões/kits/receitas, reparos e procedimentos médicos.
4. Concluir o relatório do teste de servidor; SMOKE-TEST.md não estava disponível no fechamento anterior.
5. Revisar ZombieDisguise, incluindo suporte de idioma e comportamento em rede. Ele não faz parte das cinco suítes aprovadas.
6. Decidir se a capa de FieldMedicine e os ícones provisórios de profissões precisam de substituição.

Nada foi enviado ao Steam Workshop nesta importação. Os IDs existentes em workshop.txt foram mantidos; FieldMedicine e ZombieDisguise ainda precisam de ID de publicação válido antes de upload.

## Desenvolvimento

Cada mod tem sua própria pasta Contents/ e workshop.txt. Ferramentas e testes ficam fora de Contents/ e não pertencem ao pacote enviado ao jogo.

Dentro de cada uma das cinco pastas revisadas, instale as dependências de desenvolvimento e execute:

~~~sh
npm install
npm test
~~~

Os quatro projetos com package-lock.json permitem npm ci. BasicVehicleMaintenance ainda não tinha lockfile na fonte importada. Alguns checks consultam a instalação local do jogo; veja MANUAL_TEST.md e os comentários do runner de cada mod.

## Evidências e histórico

- [Estado da importação e testes atuais](docs/IMPORTACAO-2026-10-21.md)
- [Origem e hashes dos arquivos importados](docs/SOURCE-SNAPSHOT.json)
- [Relatório da API alvo](docs/API-CHECK-42.21.md)
- [Encerramento da revisão anterior](docs/review-2026-10-17/ENCERRAMENTO-ACOMPANHAMENTO.md)
- [PRD de medicina](docs/PRD-Medical.md)
- [PRD de veículos](docs/PRD-VehicleMaintenance-v2.md)

guia.md, review.md e o pipeline de skills na raiz são documentos históricos do repositório antigo. Não constituem aprovação das versões importadas e podem descrever APIs de uma versão anterior.

## English

This repository contains the five updated mod sources plus the unchanged legacy ZombieDisguise. Automated tests passed for the five updated mods on October 21, 2026. Full gameplay and multiplayer validation is still pending; ZombieDisguise has not been reviewed or validated. B41 support is planned for ReduceMetalWood, PassiveSkills and KRjobs only. No Steam Workshop upload was performed.
