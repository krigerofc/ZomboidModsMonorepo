# Importação do monorepo — 21/10/2026

## Escopo concluído

- Removidas do checkout as pastas antigas RetroProfessions e VehicleMaintenance.
- Importadas as cinco versões atuais, incluindo alterações locais ainda sem commit nos repositórios de origem.
- Preservado ZombieDisguise sem mudança de conteúdo. O pacote foi baixado junto com o clone do repositório antigo.
- Incluídos traduções PT-BR/EN, geradores, testes, capas existentes e documentos de revisão/PRDs.
- Nenhum repositório de origem foi alterado. Não houve execução do jogo nem upload para o Steam.

A lista exata de arquivos e hashes está em SOURCE-SNAPSHOT.json. Esse documento registra uma fotografia das fontes locais; os HEADs citados não incluem, sozinhos, as correções locais copiadas.

## Verificação atual

As suítes foram executadas sobre as pastas importadas. Dependências de desenvolvimento foram resolvidas a partir dos node_modules já existentes nas fontes locais, sem copiá-los para o monorepo.

| Mod | Verificação | Resultado |
|---|---|---|
| ReduceMetalWood | tests/run.js | passou |
| PassiveSkills | tests/run.js | passou |
| KRjobs | tests/run.js e tests/icons.js | passou |
| BasicVehicleMaintenance | tests/run.js | passou |
| FieldMedicine | tests/run.js | passou |
| ZombieDisguise | comparação com a árvore original do Git | conteúdo preservado; sem suíte própria executada |

Resultados detalhados: tests-importacao-2026-10-21.json. Esses resultados verificam sintaxe, fixtures e simulação da engine. O teste de ícones também consultou os recursos locais do jogo. Não comprovam uma sessão SP/MP.

## O que continua faltando

- Certificação real no jogo alvo, incluindo interface, receitas e profissões.
- Host e dedicado com dois clientes, reconexão, restart e save/load.
- Conclusão documentada do smoke test anterior.
- Revisão técnica, PT-BR/EN e testes de ZombieDisguise.
- Arte final opcional para capa de FieldMedicine e ícones provisórios.
- Upload Steam, somente depois da validação e mediante autorização própria.

Os repositórios de origem continuam com suas alterações locais; o commit do monorepo conserva uma cópia dessas correções sem criar commits ou alterar branches na origem.

## Complemento recebido em 21/10/2026

SMOKE-TEST.md agora está disponível. Os logs existentes confirmam 10.526 avisos do getter ausente no primeiro run e zero no run corrigido. O stderr normalizado do segundo run coincide com o baseline sem mods. Os cinco IDs carregaram, LuaNet inicializou e os 148 materiais foram reduzidos sem reaplicação na segunda passagem. A correção de Core.call já estava incluída nos arquivos importados; nenhum código precisou ser alterado. Não houve execução nova de servidor ou cliente nesta conferência. Evidência: smoke-log-verification-2026-10-21.json.
