# Teste manual - Passive Skills v2

Testes automáticos (`npm test`) cobrem lógica pura e a integração com mocks. Este roteiro cobre o que só dá para ver no jogo.
Referência: vanilla B42.19.2 (alvo 42.21). Mod id `Passiveskillskr`, Workshop 3477846890.

## 1. Preparação

1. Garanta que **não** há outra cópia do mod ativa: a pasta antiga `C:\Users\pedro\Zomboid\mods\PassiveSkills` foi removida; desinscreva o item do Workshop se estiver inscrito (ou deixe só esta cópia em `Zomboid\Workshop\PassiveSkills`).
2. Steam > PZ > Propriedades > Opções de inicialização: `-debug -debugtranslation`.
3. Menu Mods: ative **Passive Skills v2**. Confira nome/descrição em PT-BR (B42 lê `Mod.json`).
4. Novo jogo > Sandbox personalizado > página **Passive Skills**:
   - "Chance de revista de habilidade (%)" = 12 (padrão) e tooltip em PT-BR.
   - "XP por revista (%)" = 100 (padrão) e tooltip em PT-BR.
   - Com `-debugtranslation`, nenhuma chave crua (`Sandbox_PassiveSkills_...`) deve aparecer.

## 2. Itens e nomes

1. Debug > Items List: busque `Magazine`. B42: 33 habilidades × 5 volumes (+5 legados `MagazineWelding_*`); B41: 24 × 5 (+5 legados).
2. Nome em PT-BR, ex.: `Base.MagazineWoodwork_one` = "Revista de Carpintaria Vol. 1"; em EN "Carpentry Magazine Vol. 1" (B41 EN: Metalurgia = "Metalworking").
3. Tooltip do item: "Revista de habilidade (5 volumes por habilidade)...". Categoria: Livro de habilidade.
4. Não deve existir nenhuma revista de Fitness/Força. No B41 não devem existir Cuidado com Animais, Entalhe, Lascamento, Cerâmica, Rastreamento, Alvenaria, Forja, Vidraria, Açougue.

## 3. Leitura (SP)

Personagem novo (ex.: Desempregado), sem nível em Carpintaria.

| Passo | Esperado |
|---|---|
| Spawnar `Base.MagazineWoodwork_one` e ler | Leitura ~20 min de jogo (10 páginas × 2 min). No fim: balão "Li isso e aprendi algo sobre Carpintaria." + texto flutuante verde "+ Carpintaria". XP de Carpintaria +75 (painel de habilidades / Debug > Player Stats). |
| Ler a mesma revista de novo | A ação **não começa** (não trava a fila); balão "Já li essa revista. Nada de novo aqui." XP não muda. |
| Spawnar outra cópia da mesma revista e tentar ler | Mesmo resultado (registro é por personagem, não por item). |
| Ler Vol. 2..5 de Carpintaria | +150, +300, +750, +1500. Total 2775 = **nível 5** exato. |
| Repetir com um profissional (ex.: Carpinteiro, que começa com nível) | Ganha os mesmos 75/150/300/750/1500 (sem multiplicador de profissão); termina **acima** do nível 5. |
| Testar 3 habilidades novas (ex.: `MagazineSpear_five`, `MagazineRunning_one`, B42 `MagazineBlacksmith_three`) | XP vai para Lanças / Corrida / Forja. |
| Interromper a leitura no meio (andar) | Sem XP; ler de novo continua de onde parou; ao terminar ganha XP normalmente. |
| Ler um item legado `Base.MagazineWelding_two` depois de `MagazineMetalWelding_two` | "Já li essa revista" (mesma chave de leitura). |
| Morrer e criar novo personagem | O novo personagem pode ler tudo de novo (registro fica no modData do personagem). |
| Sandbox "XP por revista (%)" = 50 | Vol. 5 dá +750. |

## 4. Spawn

1. Sandbox "Chance de revista" = **100**, novo jogo. Abra estantes de sala, expositores de revista, escrivaninhas, caixas de correio, biblioteca/livraria: **exatamente uma** revista de habilidade em cada contêiner elegível recém-gerado.
2. Geladeira, guarda-roupa, prateleiras de mercado: **nenhuma** revista do mod.
3. Chance = **0**: nenhuma revista em lugar nenhum (não há entradas nas tabelas vanilla).
4. Chance = 12 (padrão): andar por ~50 contêineres elegíveis deve dar por volta de 6 revistas; volumes 1-2 bem mais comuns que 4-5.

## 5. Multiplayer (B42)

Servidor dedicado local (ou host) + 2 clientes, mod ativo nos dois lados.

1. Cliente A lê `MagazineCooking_one`: balão e texto flutuante aparecem no cliente A; XP +75 aparece no A e é a mesma no servidor (relogar e conferir).
2. Cliente A tenta reler: "Já li..." sem XP. Cliente B lê a mesma revista: ganha XP (registro por personagem).
3. Cliente A sai e volta (e reinicie o servidor): tentar reler deve continuar bloqueado (o cliente pede a lista ao servidor ao entrar). **Se depois de reiniciar o servidor a leitura voltar a dar XP, o modData do jogador não persiste no servidor: reportar.**

## 6. Log

Depois de jogar:

```
grep -iE "error|exception|stack trace|PassiveSkills" "C:\Users\pedro\Zomboid\console.txt"
```

Esperado: linhas `[PassiveSkills] build 42: 33 skills, 170 magazine types` (B41: `build 41: 24 skills, 125 magazine types`) e `[PassiveSkills] read Base.Magazine... -> <Perk> +<XP> XP`. Nenhuma linha `[PassiveSkills] error ...`, `perk not found`, nem erro de script de item `PassiveSkills_Magazines.txt`. Com `-debugtranslation`, nenhuma chave `IGUI_PassiveSkills_*`/`Tooltip_PassiveSkills_*` faltando.
