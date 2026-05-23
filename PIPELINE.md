# PIPELINE.md — Skills do Workspace PZ Mods

> Fluxo completo das 10 skills em `.claude/skills/zomboid-*/SKILL.md`.
> Cada skill produz UM artefato com nome fixo, consumido pela próxima.

## Visão geral

```mermaid
flowchart TD
    A([guia.md ausente?]):::dec
    B[/zomboid-guia-bootstrapper/]:::skill --> G[(guia.md)]:::art
    A -->|sim| B
    A -->|não| C{Mod B41 existente?}:::dec

    C -->|sim| MIG[/zomboid-mod-migrator/]:::skill --> MIGD[(MIGRATION.md)]:::art
    MIGD --> P
    C -->|não| P{Novo mod ou feature?}:::dec

    P -->|sim| PL[/zomboid-mod-planner/]:::skill
    PL --> PLD[(PLAN.md)]:::art
    PLD --> DEV[/zomboid-mod-developer/]:::skill
    DEV --> DEVD[(IMPLEMENTATION.md)]:::art

    DEV -.invoca.-> CR[Skill code-review]:::native

    DEVD --> REV[/zomboid-mod-reviewer/]:::skill
    REV -.invoca.-> CR
    REV -.invoca.-> SR[Skill security-review]:::native
    REV --> REVD[(REVIEW.md)]:::art

    REVD -->|REPROVADO| DEV
    REVD -->|aprovado| BAL{Há números pra auditar?}:::dec
    BAL -->|sim| BA[/zomboid-mod-balance-auditor/]:::skill --> BAD[(BALANCE.md)]:::art --> REV
    BAL -->|não| IT[/zomboid-mod-ingame-tester/]:::skill

    IT --> ITD[(TEST_PLAN.md)]:::art
    ITD --> USER([Usuário roda no jogo]):::user

    USER -->|tudo ok| WS[/zomboid-mod-workshop/]:::skill --> WSD[(WORKSHOP.md)]:::art --> PUB([Upload manual via in-game uploader]):::user
    USER -->|crash/erro| DBG[/zomboid-mod-debugger/]:::skill
    DBG --> DBGD[(BUGS.md)]:::art --> DEV

    O[/zomboid-mod-orchestrator/]:::skill -.triagem.-> A

    classDef skill fill:#1e3a8a,stroke:#3b82f6,color:#fff
    classDef art fill:#0f766e,stroke:#14b8a6,color:#fff
    classDef native fill:#7c2d12,stroke:#ea580c,color:#fff
    classDef dec fill:#4c1d95,stroke:#8b5cf6,color:#fff
    classDef user fill:#374151,stroke:#9ca3af,color:#fff
```

## Tabela de hand-off

| Skill | Lê | Produz | Encadeia para |
|---|---|---|---|
| `zomboid-guia-bootstrapper` | `research-findings.md` | `guia.md` | planner ou migrator |
| `zomboid-mod-planner` | `guia.md` + briefing do user | `PLAN.md` | developer |
| `zomboid-mod-developer` | `PLAN.md` + `guia.md` | `IMPLEMENTATION.md` + código | reviewer |
| `zomboid-mod-reviewer` | `PLAN.md`, `IMPLEMENTATION.md`, código | `REVIEW.md` | ingame-tester (aprovado) ou developer (reprovado) |
| `zomboid-mod-migrator` | mod B41 + `guia.md` (breaking changes) | `MIGRATION.md` | planner (replano) ou developer (fixes triviais) |
| `zomboid-mod-ingame-tester` | `IMPLEMENTATION.md`, `PLAN.md` | `TEST_PLAN.md` | usuário roda; depois workshop ou debugger |
| `zomboid-mod-debugger` | `console.txt` + código do mod | `BUGS.md` | developer |
| `zomboid-mod-workshop` | `REVIEW.md` APROVADO + mod | `WORKSHOP.md` | usuário sobe via in-game uploader |
| `zomboid-mod-balance-auditor` | `PLAN.md` + scripts/lua | `BALANCE.md` | reviewer (integra) ou planner (replano) |
| `zomboid-mod-orchestrator` | todos os artefatos | recomendação | a skill apropriada |

## Skills nativas invocadas (Skill tool)
| Native | Quando | Skill que invoca |
|---|---|---|
| `code-review` | Após cada arquivo significativo | developer |
| `code-review` | Análise final do mod inteiro | reviewer |
| `security-review` | Mod tem MP, network, ou input do usuário | reviewer |

## Princípios honrados em todas as skills
1. **Gate de versão.** Toda skill (exceto bootstrapper) começa lendo `guia.md` e abortando se ausente/divergente.
2. **Pesquisa primeiro, escrita depois.** Planner não cita API sem confirmar.
3. **Artefatos com nomes fixos.** Sem ambiguidade entre runs.
4. **Encadeamento explícito.** Cada skill termina com `## Próxima etapa`.
5. **Sem retrabalho.** A próxima lê o artefato; não refaz a análise.
6. **PT-BR ao usuário, inglês no código.**
7. **`[VERIFICAR]` é bloqueador.** Planner marca; developer para.
8. **Sem invenção de API.** Tudo cita fonte (URL ou seção do `guia.md`).

## Como começar (caminho golden)
1. **Workspace novo** → `/zomboid-guia-bootstrapper` (gera `guia.md`).
2. **Mod B41 a migrar** → `/zomboid-mod-migrator`.
3. **Mod novo** → `/zomboid-mod-planner` → confirma briefing → produz `PLAN.md`.
4. **Implementar** → `/zomboid-mod-developer` → produz `IMPLEMENTATION.md`.
5. **Revisar** → `/zomboid-mod-reviewer` → veredito.
6. **(opcional) Auditar números** → `/zomboid-mod-balance-auditor`.
7. **Roteiro de teste** → `/zomboid-mod-ingame-tester` → você roda no jogo.
8. **Se crashou** → `/zomboid-mod-debugger` apontando `console.txt`.
9. **Publicar** → `/zomboid-mod-workshop`.

## Roteador
Em dúvida sobre qual rodar → `/zomboid-mod-orchestrator` te diz pelo estado dos artefatos.

## Sugestão de hook (não aplicada)
Para validar sintaxe Lua localmente após cada Edit/Write, adicione em `~/.claude/settings.json` (precisa de `luac` instalado):
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "if": "Edit(*.lua)",
            "command": "luac -p \"${tool_input.file_path}\""
          },
          {
            "type": "command",
            "if": "Write(*.lua)",
            "command": "luac -p \"${tool_input.file_path}\""
          }
        ]
      }
    ]
  }
}
```
Esse hook NÃO foi aplicado — apenas sugerido. Verifique se você tem `luac` (do Lua 5.1 ou 5.3, qual a versão de PZ usa internamente) instalado no PATH antes de habilitar.

## Localização das skills
- **Workspace project-level**: `.claude/skills/zomboid-*/SKILL.md` (versionado no monorepo `ZomboidModsMonorepo`).
- Quem clonar o repo recebe o pipeline pronto.
- Os planos individuais (`PLAN.md`, etc.) ficam **fora do git** se você quiser — adicione ao `.gitignore`. Os artefatos por mod podem ser commitados ou não conforme preferência.
