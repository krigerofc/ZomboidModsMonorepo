# KRjobs v2 - teste manual no jogo

Os testes automáticos (`npm test`) cobrem sintaxe, IDs, perks, receitas, traduções, balanceamento e os kits em Lua com mocks.
Eles **não** rodam o jogo. Este roteiro cobre o que só dá para ver dentro do Project Zomboid.

Preparação: copiar `Contents/mods/KRjobs` para `%UserProfile%\Zomboid\mods\KRjobs` (ou publicar no Workshop como não listado).
Ativar só o KRjobs (e nada que mexa em profissões) para o primeiro teste. Idioma do jogo: testar em **Português (Brasil)** e em **English**.

## Build 42 (42.19.2 local; alvo 42.21 estável)

1. Iniciar o jogo com o mod ativo. Abrir `%UserProfile%\Zomboid\console.txt` e procurar `KRjobs`, `krjobs:`, `CharacterProfessionDefinitionScript error`,
   `CharacterTraitDefinitionScript error`, `Unknown key` e `RuntimeException`. **Esperado: nenhuma ocorrência.** (A 42.21 lança exceção para receita ou tradução inexistente.)
2. Novo jogo > Sobrevivência > tela de profissões. **Esperado: 24 profissões novas** além das vanilla, cada uma com nome traduzido e ícone
   (7 ícones próprios: Matador de Aluguel, Arquiteto, Serralheiro, Sobrevivencialista, Preparador de Carros, Carteiro Rural, Boxeador Amador; as demais usam ícones vanilla).
3. Para cada profissão, passar o mouse/selecionar: a descrição mostra a frase, as linhas `+N Habilidade` e o nome do traço de profissão. Conferir o custo (pontos) com a tabela de DECISIONS-KRjobs.md.
4. Na lista de traços escolhidos, passar o mouse no traço de profissão: descrição com receitas/kit e as linhas `+N` do traço.
5. Criar personagem **Cirurgião Especialista**. No jogo: aba Habilidades mostra Primeiros Socorros 6, Lâmina Curta 1, Costura 1.
   Inventário tem **bisturi, pinça e porta-agulha** (uma vez só). Salvar, sair e carregar: **o kit não é dado de novo**.
6. Criar **Engenheiro Químico**: abrir o menu de criação (Crafting) e procurar "Aerosol"/"Bomba de fumaça" e "Mildew"/"Míldio": as receitas aparecem como conhecidas.
7. Criar **Soprador de Vidro**: receitas de garrafa/copo/espelho aparecem como conhecidas; nível de Vidraria 3.
8. Criar **Preparador de Carros**: tem o traço vanilla de mecânica (consertar todas as partes de veículos) + chave inglesa e chave de fenda.
9. Criar **Analista de Sistemas**: tem Coruja Noturna (traço vanilla) + receitas de rádio improvisado.
10. Multiplayer (servidor local com o mod): entrar com Navy SEAL. Conferir que a profissão aparece igual no cliente e que a faca de caça chega uma vez só. Morrer e criar novo personagem: kit dado de novo só para o novo personagem.
11. Repetir o passo 2 com o jogo em **English**: nomes e descrições em inglês, sem chaves cruas tipo `UI_prof_KRjobs_...`.

## Build 41 (41.78)

1. Iniciar com o mod ativo, abrir console.txt e procurar `KRjobs`, `attempted index`, `nil` perto de `KRjobs_Professions.lua`. **Esperado: nada.**
2. Tela de profissões: **20 profissões** (sem Ferrador, Soprador de Vidro, Taxidermista, Arqueólogo de Campo). Cada uma aparece **uma vez só** (o bug de duplicar do v1 foi corrigido).
3. Criar **Boxeador Amador** (antigo "Fighter", que travava no v1): o jogo não trava; Habilidades mostram Condicionamento 2, Força 2, Contundente Curto 1, Corrida 1, Agilidade/Ágil 1.
4. Criar **Serralheiro**: receitas "Fazer chapa de metal" conhecidas; máscara de solda no inventário.
5. Carregar um save antigo com personagem do v1 (Hitman/Architect/blacksmith/Survivalist/Car Modifier/Mailman/Fighter): a profissão continua lá (os tipos do v1 foram mantidos), com os bônus novos para personagens novos.
6. Jogo em Português: textos acentuados corretos (ex.: "Cirurgião Especialista", "Técnico Antibombas"), sem caracteres quebrados.

## O que anotar se algo falhar

Profissão, build, idioma, SP/MP e o trecho do console.txt. Corrigir em `tools/data.js`, rodar `npm run gen` e `npm test`.

## Autoridade e entrega parcial de kits
Em host/dedicado, criar personagem no cliente e conferir que o kit aparece uma única vez em ambos os inventários observados; reconectar e reiniciar. Testar novo personagem após morte. Em instrumentação de teste, falhar um slot de entrega e repetir o evento: somente o item que faltou deve ser criado. Os testes offline usam representações separadas, mas não comprovam o evento e a replicação da engine.
