# META-PROMPT — Reescrever o pipeline de skills do Claude Code para mods de Project Zomboid

> **Como usar:** abra o Claude Code na **pasta do seu workspace de mods de PZ** (não nesta pasta). Cole este arquivo inteiro como prompt. O Claude que receber este prompt vai pesquisar, projetar e escrever todas as skills. Garanta que `WebSearch` e `WebFetch` estejam aprovados nessa sessão — sem isso a pesquisa não roda.

---

## 0. Contexto e objetivo

Eu já tenho 3 skills funcionais mas vagas para modding de Project Zomboid:

- `zomboid-mod-planner`
- `zomboid-mod-developer`
- `zomboid-mod-reviewer`

Elas estão acopladas a um arquivo `guia.md` na raiz do workspace de mods, que serve como fonte canônica de docs/URLs e versão alvo do jogo (atualmente **Build 42**).

**Problemas atuais que quero resolver:**

1. As skills são genéricas demais — não capturam armadilhas reais de PZ B42 (crafting novo, ModData sync, OnTick performance, breaking changes B41→B42).
2. Não validam APIs contra a versão alvo antes de planejar/escrever — risco alto de retrabalho.
3. Não cobrem etapas críticas do ciclo de vida do mod: **migração B41→B42, debugging de logs in-game, teste manual roteirizado, publicação no Workshop, balanceamento**.
4. Não encadeiam claramente — cada uma deveria entregar artefatos consumidos pela próxima.
5. Não aproveitam as skills oficiais da Anthropic disponíveis no Claude Code (`code-review`, `verify`, `review`, `security-review`, `skill-creator`).

**O que você vai entregar:** um conjunto coerente de skills user-invocable em `~/.claude/skills/` (ou em `.claude/skills/` da pasta do mod, se você decidir que esse é o melhor escopo — explique sua decisão) que cobre todo o ciclo, do briefing à publicação. Veja seção 5 para a lista final.

---

## 1. Diretivas absolutas (valem pra você, Claude, durante este trabalho)

1. **Não invente APIs de PZ.** Toda chamada de classe/método/evento que aparecer em qualquer skill que você escrever DEVE estar verificada contra fonte primária (pzwiki, decompiled Java do jogo, ou docs oficiais da Indie Stone). Se não conseguir verificar, marque `[VERIFICAR]` e explique o que precisa ser confirmado.
2. **Pesquisa primeiro, escrita depois.** A Fase 2 (pesquisa) é obrigatória. Documente o que encontrou em `research-findings.md` antes de tocar nas skills. Esse arquivo é parte do entregável.
3. **Cada skill deve EXIGIR confirmação de versão do jogo** no início do fluxo, lendo de `guia.md`. Se não houver `guia.md` ou se a versão não estiver explícita, a skill deve PARAR e pedir.
4. **Skills devem encadear.** Cada uma produz artefatos nomeados (`PLAN.md`, `IMPLEMENTATION.md`, `REVIEW.md`, `TEST_PLAN.md`, `BUGS.md`, `WORKSHOP.md`) e referencia a próxima skill no relatório final.
5. **PT-BR para tudo que o usuário lê.** Código (variáveis, funções, comentários em código) em inglês.
6. **Sem retrabalho.** Se uma skill já produziu um artefato, a próxima lê o artefato, não refaz a análise.
7. **Aproveite as skills nativas** (`anthropic-skills:skill-creator` para o formato; `code-review`, `verify`, `security-review` para invocar via `Skill` tool quando apropriado). NÃO duplique o que essas já fazem — chame-as.
8. **Output das skills é cirúrgico**, não verborrágico. Cada skill tem regras absolutas, fluxo numerado, formato de relatório fixo, e seção "o que NÃO fazer". Sem floreio.
9. **Sandbox de testes:** nenhuma skill executa o jogo. O `ingame-tester` gera um roteiro pra o usuário rodar manualmente, e o `debugger` lê os logs depois.

---

## 2. Fase 1 — Reconhecimento (rode antes de pesquisar)

Execute, em paralelo quando possível:

1. **Liste o workspace atual:**
   - `Glob` em `**/mod.info`, `**/*.lua`, `**/scripts/*.txt`, `**/Translate/**`, para entender o que já existe.
   - `Read` em `guia.md` se existir na raiz. Anote: versão alvo, URLs da doc, qualquer convenção do usuário.
   - `Read` nas 3 skills atuais (caminhos prováveis: `~/.claude/skills/zomboid-mod-planner.md`, `.../zomboid-mod-developer.md`, `.../zomboid-mod-reviewer.md`). Se não estiverem nesses caminhos, use `Glob` `**/zomboid-mod-*.md` em `~/.claude/` e `.claude/`.
2. **Mapeie skills disponíveis no Claude Code** lendo o que aparece em `<system-reminder>` no início da sessão (lista de skills do harness).
3. **Cheque hooks existentes** em `.claude/settings.json` ou `~/.claude/settings.json` (não modifique ainda — só leia).
4. **Resuma o que achou** em uma resposta curta ao usuário antes de seguir pra Fase 2. O usuário precisa confirmar versão alvo e workspace antes de você gastar tokens em pesquisa.

---

## 3. Fase 2 — Pesquisa obrigatória (com WebSearch/WebFetch)

> Se WebSearch/WebFetch não estiverem disponíveis, **PARE** e peça ao usuário pra liberar. Não invente substituto baseado em memória de treino.

Dispare estes blocos de pesquisa **em paralelo** sempre que possível (multi tool-call no mesmo turn). Documente CADA resultado em `research-findings.md` com URL, data de acesso, e citação literal do trecho relevante.

### 3.1 Documentação canônica de PZ B42

Fontes alvo (verifique e expanda):

- `pzwiki.net/wiki/Modding` — índice principal
- `pzwiki.net/wiki/Lua_Events` — lista de eventos
- `pzwiki.net/wiki/Modding:Lua_API` (ou equivalente atual)
- `pzwiki.net/wiki/B42` (changelog/diffs B41→B42)
- `theindiestone.com/community/forum/` — busque "B42 modding changes"
- `projectzomboid.com/modding/` — docs oficiais
- Lua/Java reference: `zomboid-javadoc` no GitHub, ou similar
- Subreddit: `reddit.com/r/projectzomboidmodders`

**Para cada evento que você for citar em qualquer skill**, registre em `research-findings.md`:
- Nome exato (`Events.OnTick`, `Events.OnPlayerUpdate`, `Events.OnEquipPrimary`, `Events.EveryTenMinutes`, `Events.OnGameStart`, `Events.OnPlayerMove`, etc.)
- Assinatura do handler (parâmetros que recebe)
- Frequência/quando dispara
- Custo de performance se aplicável (OnTick é caro)
- Diferenças B41 vs B42 se houver

### 3.2 Mods de referência (estrutura e padrões)

Procure no GitHub e Steam Workshop **3 a 5 mods bem mantidos compatíveis com B42**. Sugestões pra começar (verifique se ainda existem e são B42-compatible):

- ORGM (Real Guns Mod)
- Brita's (Weapons / Armor)
- More Builds / More Traits
- Mods top do "Most Subscribed" do Workshop categoria B42

Para cada um, registre em `research-findings.md`:
- URL do repo
- Estrutura de pastas exata
- Convenção de nomes
- Como organizam translations (`media/lua/shared/Translate/`)
- Como tratam compat com outros mods
- Padrões interessantes que você vai replicar nas skills

### 3.3 Pitfalls comuns (fóruns, reddit, discord públicos)

Busque por (queries sugeridas):
- "Project Zomboid mod common mistakes B42"
- "Project Zomboid Lua ModData sync multiplayer"
- "Project Zomboid OnTick performance"
- "Project Zomboid B42 breaking changes B41"
- "Project Zomboid Lua nil check getSpecificPlayer"
- "Project Zomboid B42 crafting recipes script format"

Para cada pitfall encontrado, registre em `research-findings.md`:
- Descrição do problema
- Sintoma observável (crash, log error, comportamento errado)
- Causa raiz
- Como evitar / como detectar em review

### 3.4 Ecossistema Claude Code (para encadear com nativas)

Verifique e cite literalmente:

- `docs.claude.com/en/docs/claude-code/skills` — formato oficial de skills, frontmatter, descrição que dispara
- `docs.claude.com/en/docs/claude-code/sub-agents` — padrões de subagents
- `docs.claude.com/en/docs/claude-code/hooks` — hooks (PreToolUse, PostToolUse, etc.)
- `github.com/obra/superpowers` — Claude Superpowers do Jesse Vincent. Liste skills relevantes, copie convenções de design (regras absolutas, fluxo numerado, "absolute rules" / "what NOT to do" sections).
- Built-in skills mencionadas neste prompt: `code-review`, `verify`, `review`, `security-review`, `skill-creator`. Leia se houver documentação pública.

### 3.5 Critério de "pesquisa suficiente"

Antes de avançar pra Fase 3, `research-findings.md` deve ter no mínimo:
- 15 eventos PZ documentados com assinatura
- 20 pitfalls catalogados
- 3 mods de referência analisados
- 5 breaking changes B41→B42 confirmados
- Estrutura de skills do Superpowers documentada (pelo menos 3 exemplos)

Se faltar, expanda a pesquisa antes de continuar.

---

## 4. Fase 3 — Princípios de qualidade que TODAS as skills devem honrar

Toda skill que você escrever DEVE incorporar:

### 4.1 Frontmatter completo

```yaml
---
name: zomboid-mod-<role>
description: <uma frase ativa que descreve quando esta skill é invocada — escreva pra que o roteador do Claude consiga matchar gatilhos reais do usuário, não jargão interno>
user_invocable: true
---
```

A `description` deve listar **gatilhos de invocação** (verbos/substantivos que o usuário usaria) — siga o padrão das skills `anthropic-skills:*` na lista do harness.

### 4.2 Estrutura interna (ordem obrigatória)

1. `# <nome-da-skill>` — título
2. **Identidade e papel** — 1 parágrafo
3. **Personalidade** — 2-3 linhas (rigorosa, disciplinada, paranóica, etc.)
4. **Regras absolutas** — numeradas, executáveis (não filosóficas)
5. **Critérios de qualidade / checklist** — quando aplicável
6. **Fluxo de trabalho** — passos numerados, cada passo com tool específico (`Read`, `Glob`, `WebFetch`, `Edit`)
7. **Formato do relatório final** — template literal que a skill preenche
8. **O que NÃO fazer** — bullets
9. **Encadeamento** — última linha do relatório aponta a próxima skill recomendada
10. **Ferramentas que usa** — lista enxuta (`Read`, `Edit`, `Grep`, `Glob`, `WebFetch`, `Skill`)

### 4.3 Confirmação de versão (gate obrigatório no início)

Todo fluxo começa com:

```
1. Read guia.md
2. Confirme versão alvo (ex: Build 42)
3. Se guia.md não existir OU versão ambígua → PARE e chame zomboid-guia-bootstrapper
4. Se versão != versão de trabalho do usuário → PARE e confirme
```

### 4.4 Artefatos de hand-off (nomes fixos, na raiz da pasta do mod)

| Artefato | Produzido por | Consumido por |
|---|---|---|
| `guia.md` | guia-bootstrapper | TODAS |
| `PLAN.md` | planner | developer, reviewer, ingame-tester |
| `IMPLEMENTATION.md` | developer | reviewer, ingame-tester |
| `REVIEW.md` | reviewer | developer (loop), workshop |
| `TEST_PLAN.md` | ingame-tester | usuário (executa) |
| `BUGS.md` | debugger | developer, reviewer |
| `WORKSHOP.md` | workshop publisher | usuário (publica) |
| `MIGRATION.md` | migrator | planner |
| `BALANCE.md` | balance-auditor | reviewer |
| `research-findings.md` | (este meta-prompt) | guia-bootstrapper |

### 4.5 Encadeamento explícito

Toda skill termina com:

```
## Próxima etapa
Recomendado: rode `/<nome-da-próxima-skill>` para <razão>.
```

### 4.6 Invocação de skills nativas

- `Skill code-review` após `developer` escrever código — captura cheiros de código genéricos.
- `Skill verify` quando o usuário pede confirmação que algo funciona — embora o jogo precise ser rodado manualmente, a skill pode invocar `verify` pra coisas como sintaxe Lua via `luac`.
- `Skill security-review` no `reviewer` quando o mod manipula entrada de rede / ModData sync.

---

## 5. Skills a produzir (lista final)

Você vai produzir **10 skills** no total. Justifique no `research-findings.md` se decidir mesclar/dividir.

### 5.1 `zomboid-guia-bootstrapper` (NOVA)

**Objetivo:** gerar ou atualizar o `guia.md` raiz do workspace de mods. Esse arquivo é a fonte de verdade pra versão alvo e URLs de doc.

**Inputs:** versão do jogo (perguntar ao usuário), conteúdo do `research-findings.md`.

**Outputs:** `guia.md` com:
- Versão alvo (B41/B42/etc) e build exato
- URLs canônicas (pzwiki, javadoc, fórum)
- Eventos mais usados com assinatura
- Caminhos típicos do jogo (`media/lua/`, `media/scripts/`)
- Convenções de nomes/pastas do workspace do usuário
- Lista de "pitfalls a evitar" extraída da pesquisa
- Tabela de "APIs proibidas em B42" (removidas/renomeadas)

**Quando invocar:** primeira vez no workspace, ou quando o usuário mudar versão alvo.

### 5.2 `zomboid-mod-planner` (REESCRITA)

Mantenha a estrutura atual mas reforce:

- **Gate de versão obrigatório** no início.
- **Pesquisa via WebFetch** nos URLs do `guia.md` ANTES de produzir o plano — não só "consulte se necessário".
- **Tabela de Dependências de API expandida**: cada API listada precisa ter status `Confirmado / [VERIFICAR] / Inexistente`. Linhas `Inexistente` bloqueiam o plano até resolver.
- **Seção nova "Premissa e balanceamento"**: pergunte ao usuário objetivo do mod, público-alvo, e valores numéricos (XP, raridade, dano) com referência a valores base do jogo. Sem isso, plano fica incompleto.
- **Seção nova "Compatibilidade"**: identifique mods populares que tocam nas mesmas APIs/items, e proponha estratégia (override vs hook vs config).
- **Seção nova "Multiplayer"**: client/server/shared? Precisa de `SendCommandToServer`? ModData sync? Se sim, detalhe.
- **Hand-off**: produz `PLAN.md` na raiz da pasta do mod.

### 5.3 `zomboid-mod-developer` (REESCRITA)

Mantenha a disciplina executora mas reforce:

- **Lê `PLAN.md` + `guia.md` antes de qualquer coisa.** Sem `PLAN.md` → PARE e mande rodar planner.
- **Itens `[VERIFICAR]` do plano são bloqueadores** — PARA e pede confirmação, não chuta.
- **Padrões de código obrigatórios** (mantenha os atuais e adicione):
  - Cache de chamadas repetidas em loops
  - Use `EveryOneMinute`/`EveryTenMinutes` em vez de `OnTick` quando possível
  - Helpers de namespace via tabela local + `return NS` no fim do arquivo
  - Translations sempre em `media/lua/shared/Translate/EN/<MyMod>_EN.txt` (e PT/etc)
  - Sempre `local` em tudo
  - Comentários só onde o "porquê" não é óbvio (regra anti-comentário, alinhada com o sistema)
- **Após escrever cada arquivo, invoque `Skill code-review` com escopo no diff** — antes de produzir o relatório final.
- **Hand-off**: produz `IMPLEMENTATION.md` listando arquivos criados/modificados, decisões tomadas, pontos a testar.

### 5.4 `zomboid-mod-reviewer` (REESCRITA)

Mantenha a estrutura atual e adicione:

- **Lê `PLAN.md` + `IMPLEMENTATION.md` + `guia.md`** antes de tudo.
- **Checklist B42-specific** com itens da pesquisa (ex: "não usa `getInventoryItemRecurse` que foi removido em B42" — confirmar via pesquisa).
- **Análise estática real**: grep por antipatterns conhecidos (`Events.OnTick` com >5 linhas, globals sem `local`, concatenação `..` dentro de loops, métodos chamados sem nil check).
- **Verificação cruzada com `Skill code-review` e `Skill security-review`** — chame essas skills, integre os achados.
- **Score numérico**: 0-100 com critérios pesados (corretude 40%, performance 25%, fidelidade 20%, padrões 15%).
- **Hand-off**: produz `REVIEW.md` com veredito + issues. Se REPROVADO, aponta de volta pro developer.

### 5.5 `zomboid-mod-migrator` (NOVA)

**Objetivo:** migrar mods B41 → B42 (ou identificar incompatibilidades).

**Fluxo:**
1. Lê `guia.md` (deve ter tabela de breaking changes B41→B42).
2. `Glob` todos os `.lua` e `.txt` (scripts) do mod.
3. Pra cada arquivo, busca por APIs/padrões listados como removidos/renomeados em B42.
4. Produz `MIGRATION.md` com lista de pontos que precisam mudar, exemplo before/after, e ordem sugerida.
5. Encadeia pra `planner` (replano da migração) ou `developer` (aplicar correções triviais).

**Conteúdo do `MIGRATION.md`:** tabela `Arquivo:Linha | API antiga | API nova | Tipo de mudança | Esforço`.

### 5.6 `zomboid-mod-ingame-tester` (NOVA)

**Objetivo:** gerar roteiro de teste manual que o usuário roda dentro do jogo.

**Inputs:** `PLAN.md`, `IMPLEMENTATION.md`.

**Outputs:** `TEST_PLAN.md` com:
- Sandbox vars necessárias (ex: "comece num save com loot abundance Insane")
- Cenários golden path: 5-10 cenários numerados com passos exatos, resultado esperado
- Cenários de borda: save/load, multiplayer host+client, fast-forward de tempo, morte do player
- Comandos de admin/debug úteis (`Tab` console, `additem`, `gimme`, debug menu)
- Como capturar logs: caminho `%USERPROFILE%\Zomboid\Logs\` no Windows
- Checklist final pra rodar `/zomboid-mod-debugger` se algo der errado

### 5.7 `zomboid-mod-debugger` (NOVA)

**Objetivo:** ler logs do jogo, mapear erros pra arquivos/linhas do mod, propor fix.

**Fluxo:**
1. Pergunta ao usuário o caminho do log (`%USERPROFILE%\Zomboid\Logs\console.txt` por default no Windows, ou `~/Zomboid/Logs/` em Linux).
2. `Read` no `console.txt` (com `offset/limit` se grande).
3. Grep por `ERROR`, `WARN`, stack traces Lua (`stack traceback:`, `attempt to index nil`).
4. Pra cada stack trace, mapeia pro arquivo do mod via `Glob`.
5. Produz `BUGS.md`:
   - Erro literal
   - Arquivo:linha provável
   - Causa raiz hipotética
   - Fix proposto
   - Repro steps (extraídos do TEST_PLAN.md se existir)
6. Encadeia pra `developer` (aplicar fix) ou `planner` (replanejar se for design).

### 5.8 `zomboid-mod-workshop` (NOVA)

**Objetivo:** preparar mod pra Steam Workshop.

**Fluxo:**
1. Valida `mod.info` (campos obrigatórios B42: `name`, `id`, `description`, `poster`, `icon`, `require`, `pack`, `tiledef`).
2. Verifica que `REVIEW.md` está com veredito APROVADO ou APROVADO_COM_RESSALVAS (não publica REPROVADO).
3. Gera descrição de Workshop em PT-BR e EN-US (texto com BBCode pro Steam: `[h1]`, `[list]`, `[img]`).
4. Checklist de upload: preview.png 256x256, workshop_preview.png 512x512, peso máximo, tags sugeridas.
5. Produz `WORKSHOP.md` com tudo acima + comandos do PZ Workshop Uploader (se aplicável).

### 5.9 `zomboid-mod-balance-auditor` (NOVA)

**Objetivo:** verificar que valores numéricos do mod (XP, dano, raridade, pesos, tempos) estão balanceados em relação ao jogo base.

**Fluxo:**
1. Lê `PLAN.md` (seção "Premissa e balanceamento").
2. Extrai todos os valores numéricos de scripts do mod (`Glob` em `**/scripts/**/*.txt`, `**/sandbox-options.lua` se houver).
3. Cruza com valores base do jogo (vai precisar de tabelas de referência — produzir uma vez via pesquisa e salvar em `guia.md`).
4. Produz `BALANCE.md`:
   - Tabela `Item/skill | Valor do mod | Valor base equivalente | Razão | Recomendação`
   - Flags vermelhos: outliers >3x, raridade ≤1 (overpowered), XP gain >10x base
5. Encadeia pro `reviewer` integrar no relatório final.

### 5.10 `zomboid-mod-orchestrator` (NOVA — opcional, decida se vale)

**Objetivo:** roteador. Quando o usuário diz "quero fazer um mod que X", esta skill faz triagem e chama a próxima.

**Lógica:**
- Existe `guia.md`? Não → `guia-bootstrapper`.
- Existe `PLAN.md`? Não → `planner`.
- Existe `IMPLEMENTATION.md` mais novo que `PLAN.md`? Não → `developer`.
- Existe `REVIEW.md` aprovado? Não → `reviewer`.
- Logs com erro? → `debugger`.
- Quer publicar? → `workshop`.

Avalie se essa skill agrega ou se a documentação clara de encadeamento nas outras skills já basta. Justifique no `research-findings.md`.

---

## 6. Fase 4 — Entregáveis finais (na raiz da pasta do mod)

Quando você terminar, eu espero ver:

1. `research-findings.md` — pesquisa documentada, com URLs e citações
2. `~/.claude/skills/zomboid-*.md` (10 arquivos, ou justifique se forem menos)
3. `PIPELINE.md` na raiz da pasta do mod — explica a ordem, com diagrama mermaid do fluxo
4. `guia.md` — versão inicial do guia (rodando o bootstrapper você mesmo, se ainda não existir)
5. Sugestão de `.claude/settings.json` ou hook útil (ex: PostToolUse rodando `luac -p` em `.lua` após Edit), se fizer sentido — sem aplicar, apenas sugerir

---

## 7. O que NÃO fazer (você, Claude, executando este prompt)

- **NÃO escreva nenhuma skill antes de completar a Fase 2.** Pesquisa primeiro.
- **NÃO use memória de treino para preencher APIs/eventos.** Toda referência técnica vem de fonte verificada na pesquisa.
- **NÃO crie skills que duplicam o que `code-review`/`verify`/`security-review` já fazem.** Encadeie.
- **NÃO infle as skills com regras filosóficas** ("seja consciente", "pense profundamente"). Regras são executáveis ou não existem.
- **NÃO produza arquivos sem frontmatter** no formato exato da seção 4.1.
- **NÃO mexa em código de mod existente.** Você está construindo o pipeline, não usando-o.

---

## 8. Critério de pronto

Considere o trabalho concluído quando:

- [ ] `research-findings.md` tem cobertura mínima da seção 3.5
- [ ] 10 skills criadas com frontmatter completo e estrutura da seção 4.2
- [ ] Cada skill tem gate de versão (seção 4.3)
- [ ] Cada skill tem hand-off explícito pra próxima (seção 4.5)
- [ ] `PIPELINE.md` produzido na pasta do mod
- [ ] `guia.md` produzido (rodando o bootstrapper que você acabou de criar)
- [ ] Você invocou `Skill code-review` na sua própria produção e integrou achados
- [ ] Relatório final ao usuário em PT-BR, sob 300 palavras, listando o que foi entregue e como começar

---

## 9. Comece agora

Sua primeira ação deve ser **Fase 1 — Reconhecimento** (seção 2). Reporte ao usuário o que achou e confirme versão alvo antes de gastar tokens em pesquisa.

Boa sorte. Seja paranóico com APIs — modders perdem horas por causa de funções que mudaram de nome entre builds.