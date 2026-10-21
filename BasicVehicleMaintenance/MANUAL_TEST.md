# Teste manual - Basic Vehicle Maintenance v2 (More Vehicles Repairs)

Testes automáticos (`npm install` + `npm test`) cobrem a lógica pura (fórmulas, limites, aliases de TODAS as peças vanilla, materiais em bolsas aninhadas, histórico, XP anti-farm, efeitos) e a integração com mocks (TimedAction, menu, feedback, paridade EN/PT-BR). Este roteiro cobre o que só dá para ver no jogo.
Referência: vanilla B42.19.2 (alvo 42.21). Mod id `MoreVehiclesRepairs`, Workshop 3643006111. **Só Build 42.**

## 1. Preparação

1. Não deixe outra cópia ativa: a pasta antiga `C:\Users\pedro\Zomboid\mods\VehicleMod` foi removida; se estiver inscrito no item 3643006111 do Workshop, desinscreva (ou garanta que só esta cópia em `Zomboid\Workshop\BasicVehicleMaintenance` está carregando).
2. Steam > PZ > Propriedades > Opções de inicialização: `-debug -debugtranslation`.
3. Menu Mods: ative **Basic Vehicle Maintenance** (pôster e ícone novos).
4. Novo jogo > Sandbox personalizado > página **Manutenção Básica de Veículos**: 13 opções, todas com nome e tooltip em PT-BR. Com `-debugtranslation` nenhuma chave crua (`Sandbox_MVR_...`) aparece.
5. Troque o idioma para English e confira a mesma página em EN. Volte para PT-BR.

Kit de teste (Debug > Items List, ou console `getPlayer():getInventory():AddItem("Base.X")`): `Wrench`, `Screwdriver`, `Needle`, `ScrapMetal` ×10, `SheetMetal` ×3, `SmallSheetMetal` ×4, `Screws` ×10, `DuctTape` ×3, `Glue` ×2, `RippedSheets` ×6, `Wire`, `ElectronicsScrap` ×4, `ElectricWire` ×4, `LeatherStrips` ×3, `Thread`, `Jack`, `BlowTorch`, `Bag_Schoolbag`.
Use Debug (botão direito na peça > DBG cheat / "Set condition") para deixar peças em ~20%.

## 2. Menu e tooltip (SP)

| Passo | Esperado |
|---|---|
| Abrir Mecânica de um carro, botão direito em **Freio** (condição 20) | Opção "Reparo improvisado" com submenu Remendo / Reparo / Revisão + "Inspecionar veículo (manutenção)". Opções vanilla continuam lá. |
| Passar o mouse em **Remendo** | Tooltip colorido (verde = tem, vermelho = falta), linhas separadas (sem `\n` cru): materiais com "tem/precisa", ferramentas, ganho +15 (teto 55), "Risco de falha: médio" (Mecânica < 4), tempo, aviso de falha grave. |
| Personagem com Mecânica 4+ | Mostra "Chance de falha: X%". |
| Colocar **todos** os materiais e ferramentas dentro da mochila | Continuam contando como presentes. Ao clicar, o personagem primeiro tira os itens da mochila, anda até a roda e faz a ação. |
| Chave de fenda/inglesa quebrada (condição 0) | Não conta; opção fica indisponível com a ferramenta em vermelho. Qualquer chave inglesa (ex.: Pipe Wrench) serve. |
| Peça em 100% | Opção indisponível: "Esta peça não está danificada." |
| Peça acima do teto (ex.: freio em 60) | Indisponível: "Já está no limite ou acima..." |
| **Farol** (Headlight) | "Reparo improvisado" aparece desabilitado com dica "Lâmpada não tem remendo: substitua a peça". Nenhum erro no console (bug v1 do servidor). |
| Peça desinstalada | Sem opção do mod (o vanilla mostra "Instalar"). |
| Dentro do carro | Menu de peça vanilla não abre para não-admin; nada do mod aparece. |
| Jogo pausado + botão direito | Nenhum menu e nenhum erro. |
| Peça com reparo vanilla (ex.: porta com chapa + maçarico no inventário) | Tooltip avisa "Dá para fazer o reparo padrão... (menu Reparar)". |

## 3. Resultado do reparo (SP)

| Passo | Esperado |
|---|---|
| Remendo no freio 20%, Mecânica 0 | Barra de progresso, animação de trabalho na roda. Sucesso: fala ("Remendei." / variações) + texto flutuante verde "Condição 20 -> 35". Materiais somem (inclusive da mochila); fita perde 1 uso (não o rolo inteiro). |
| XP | +3 XP de Mecânica (sucesso), +5 (crítico), +1 (falha). Repetir na mesma peça no mesmo dia de jogo: 0 XP. No dia seguinte: XP de novo. |
| Repetir remendos na mesma peça | Tooltip mostra "Já remendada N vez(es)" e o teto cai 3 por remendo (mín. 30). Desinstalar e instalar outra peça: histórico zera. |
| Sandbox "Multiplicador da chance de falha" = 3 | Falhas frequentes: falha leve = -5 e material perdido; falha grave = -20 (nunca vai a 0 de uma vez a partir de 30+). |
| Sandbox "Falhas graves" desligado | Só falhas leves. |
| Motor | Abre o capô antes, fecha depois (como "Reparar motor" vanilla). |
| Sem luvas, muitas tentativas | Às vezes arranhão/corte na mão (painel de saúde mostra), queimadura só em motor/escapamento/tanque. Com luvas, bem mais raro. Ferramenta perde 1-3 de condição às vezes. |
| Sandbox "Efeitos colaterais" desligado | Nenhum ferimento, desgaste ou frustração. |
| Carro dentro de garagem | Tooltip "Local coberto: menor chance de falha" (chance exata cai 3 pontos com Mecânica 4+). |
| À noite, sem luz | Tooltip "Escuro demais: maior chance de falha"; "Inspecionar veículo" desabilitado. Com lanterna ligada / luz: normal. |
| Macaco no inventário, pneu/freio/suspensão | Tooltip "Macaco: trabalho mais rápido" (15% mais rápido). |

## 4. Faixas de qualidade

| Passo | Esperado |
|---|---|
| Mecânica 0 | Reparo e Revisão indisponíveis, requisitos em vermelho com "(você: 0)". |
| Mecânica 3, freio, fora da garagem sem macaco | Reparo indisponível ("Local coberto (garagem) ou um macaco"). Com macaco: disponível, materiais ×1,5, teto +10. |
| Mecânica 3, motor | Reparo pede também Metalurgia 2. |
| Mecânica 6, motor | Revisão pede Metalurgia 4 e maçarico (3 usos, consumidos). Bateria/rádio pedem Elétrica 3. Teto nunca passa de 80. |
| Sandbox "Faixas de qualidade" desligado | Só "Reparo improvisado" (Remendo), sem submenu. |

## 5. Inspeção

"Inspecionar veículo" (com luz): ~300 ticks, depois janela com todas as peças, condição em cores, "remendada Nx", risco do próximo remendo, "substituir" para luzes, "reparo padrão possível" e a linha de peças críticas (< 25%).

## 6. Multiplayer - host local (Host no menu principal)

1. Menu principal > Host > configure o servidor com o mod ativo (aba Mods) e a página de sandbox do mod. Inicie e entre.
2. Repita os passos 3.1, 3.2 e um teste com materiais na mochila.
3. Esperado: inventário atualiza sem precisar reabrir (itens somem na hora, sem "itens fantasmas"), fala/texto flutuante aparecem, condição da peça atualiza na janela de Mecânica, XP aparece.
4. Saia e entre de novo: condição e histórico de remendos persistem; inventário bate com o que sobrou.
5. Segundo cliente (outra conta Steam/PC ou `-nosteam` em servidor dedicado): o segundo jogador vê a nova condição da peça do mesmo carro; o inventário do primeiro não muda no segundo.
6. Tentativa de exploit: abrir o menu com materiais, largar os materiais no chão durante a ação -> ao terminar: "Estou sem os materiais.", nada muda.

## 7. Servidor dedicado local (opcional, recomendado antes de publicar)

`ProjectZomboidServer.bat` com `Mods=MoreVehiclesRepairs` e `WorkshopItems=` vazio (cópia local) ou `3643006111`. Repetir a seção 6 com 2 clientes.

## 8. Log

Depois de cada sessão:

```
grep -iE "error|exception|stack trace|MVR" "%UserProfile%\Zomboid\console.txt"
```

Esperado: nenhuma linha de erro do mod. Se aparecer `[MVR] context menu error`, anote a mensagem inteira. Conferir também, se possível em debug:
- escala de infelicidade (+5 deve dar um aumento pequeno, não moodle máximo);
- `syncPlayerStats` e `syncBodyPart` sem warnings no console do servidor.

## 9. Remoção

Desativar o mod num save existente: carros carregam normalmente (o mod só grava `part:getModData().MVR`).
