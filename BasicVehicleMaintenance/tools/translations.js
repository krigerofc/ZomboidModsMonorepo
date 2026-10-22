// Single source for all EN + PT-BR texts. `node tools/translations.js` writes the B42 JSON files
// (common/media/lua/shared/Translate/<LANG>/<File>.json). `--check` fails if they are stale.
const fs = require('fs');
const path = require('path');

const T = {
  Mod: {
    name: ["Basic Vehicle Maintenance","Manutenção Básica de Veículos"],
    description: ["Improvised vehicle repairs using scrap, tape and tools. Includes engine repairs, condition caps, failure risks, Mechanics XP, inspection, patch history and three quality tiers. Materials inside bags count. Sandbox options. Build 42 only; PT-BR + EN.","Reparos improvisados de veículos com sucata, fita e ferramentas. Inclui reparo do motor, limites de condição, risco de falha, XP de Mecânica, inspeção, histórico de remendos e três faixas de qualidade. Materiais nas bolsas contam. Opções de sandbox. Só Build 42; PT-BR + EN."],
  },
  ContextMenu: {
    ContextMenu_MVR_Repair: ['Improvised repair', 'Reparo improvisado'],
    ContextMenu_MVR_Tier_patch: ['Patch', 'Remendo'],
    ContextMenu_MVR_Tier_repair: ['Proper repair', 'Reparo'],
    ContextMenu_MVR_Tier_overhaul: ['Overhaul', 'Revisão'],
    ContextMenu_MVR_Inspect: ['Inspect vehicle (maintenance)', 'Inspecionar veículo (manutenção)'],
  },
  Tooltip: {
    Tooltip_MVR_Title: ['Improvised repair: %1', 'Reparo improvisado: %1'],
    Tooltip_MVR_Condition: ['Condition: %1 (this repair reaches up to %2)', 'Condição: %1 (este reparo chega até %2)'],
    Tooltip_MVR_Requirements: ['Requirements:', 'Requisitos:'],
    Tooltip_MVR_Materials: ['Materials (bags count):', 'Materiais (bolsas contam):'],
    Tooltip_MVR_Tools: ['Tools:', 'Ferramentas:'],
    Tooltip_MVR_Or: ['or', 'ou'],
    Tooltip_MVR_Gain: ['Condition gain: +%1 (cap %2)', 'Ganho de condição: +%1 (teto %2)'],
    Tooltip_MVR_FailExact: ['Failure chance: %1%', 'Chance de falha: %1%'],
    Tooltip_MVR_FailBand: ['Failure risk: %1 (Mechanics 4 shows the exact chance)', 'Risco de falha: %1 (Mecânica 4 mostra a chance exata)'],
    Tooltip_MVR_Risk_low: ['low', 'baixo'],
    Tooltip_MVR_Risk_medium: ['medium', 'médio'],
    Tooltip_MVR_Risk_high: ['high', 'alto'],
    Tooltip_MVR_Severe: ['A bad failure costs 20 condition; a minor one costs 5 and the materials.', 'Falha grave tira 20 de condição; falha leve tira 5 e gasta os materiais.'],
    Tooltip_MVR_Time: ['Work time: %1', 'Tempo de trabalho: %1'],
    Tooltip_MVR_Time_short: ['short', 'curto'],
    Tooltip_MVR_Time_medium: ['medium', 'médio'],
    Tooltip_MVR_Time_long: ['long', 'longo'],
    Tooltip_MVR_Patches: ['Already patched %1 time(s): each patch lowers the cap by 3. Replace the part to reset.', 'Já remendada %1 vez(es): cada remendo baixa o teto em 3. Troque a peça para zerar.'],
    Tooltip_MVR_Indoors: ['Sheltered workplace: lower failure chance.', 'Local coberto: menor chance de falha.'],
    Tooltip_MVR_Dark: ['Too dark: higher failure chance.', 'Escuro demais: maior chance de falha.'],
    Tooltip_MVR_Jack: ['Jack: faster work.', 'Macaco: trabalho mais rápido.'],
    Tooltip_MVR_VanillaAvailable: ['A standard repair is possible with what you carry (Repair menu). It is usually better.', 'Dá para fazer o reparo padrão com o que você carrega (menu Reparar). Normalmente é melhor.'],
    Tooltip_MVR_VanillaExists: ['This part also has a standard repair (Repair menu).', 'Esta peça também tem reparo padrão (menu Reparar).'],
    Tooltip_MVR_Status_disabled: ['Disabled in sandbox options.', 'Desativado nas opções de sandbox.'],
    Tooltip_MVR_Status_not_repairable: ['Bulbs cannot be patched: replace the part.', 'Lâmpada não tem remendo: substitua a peça.'],
    Tooltip_MVR_Status_not_installed: ['The part is not installed.', 'A peça não está instalada.'],
    Tooltip_MVR_Status_undamaged: ['This part is not damaged.', 'Esta peça não está danificada.'],
    Tooltip_MVR_Status_above_cap: ['Already at or above what this repair can reach (%1).', 'Já está no limite ou acima do que este reparo alcança (%1).'],
    Tooltip_MVR_Status_skill: ['Requirements not met.', 'Requisitos não atendidos.'],
    Tooltip_MVR_Status_missing_tools: ['Missing tools.', 'Faltam ferramentas.'],
    Tooltip_MVR_Status_missing_materials: ['Missing materials.', 'Faltam materiais.'],
    Tooltip_MVR_Req_Mechanics: ['Mechanics %1 (you: %2)', 'Mecânica %1 (você: %2)'],
    Tooltip_MVR_Req_MetalWelding: ['Metalworking %1 (you: %2)', 'Metalurgia %1 (você: %2)'],
    Tooltip_MVR_Req_Electricity: ['Electrical %1 (you: %2)', 'Elétrica %1 (você: %2)'],
    Tooltip_MVR_Req_ShelterOrJack: ['Indoors (garage) or a jack in the inventory', 'Local coberto (garagem) ou um macaco no inventário'],
    Tooltip_MVR_Tool_WRENCH: ['Wrench (any, not broken)', 'Chave inglesa (qualquer, não quebrada)'],
    Tooltip_MVR_Tool_SCREWDRIVER: ['Screwdriver (any, not broken)', 'Chave de fenda (qualquer, não quebrada)'],
    Tooltip_MVR_Tool_SEWING_NEEDLE: ['Sewing needle', 'Agulha de costura'],
    Tooltip_MVR_Inspect: ['Check every part: condition, earlier patches, risk of the next patch and standard repairs you can do. Needs light.', 'Confere cada peça: condição, remendos anteriores, risco do próximo remendo e reparos padrão possíveis. Precisa de luz.'],
    Tooltip_MVR_InspectDark: ['Too dark to inspect. Get a light.', 'Escuro demais para inspecionar. Arrume uma luz.'],
  },
  IG_UI: {
    IGUI_MVR_Job: ['Improvised repair', 'Reparo improvisado'],
    IGUI_MVR_Say_success_1: ['Patched it up.', 'Remendei.'],
    IGUI_MVR_Say_success_2: ['That should hold for a while.', 'Isso deve aguentar um tempo.'],
    IGUI_MVR_Say_success_3: ['Not pretty, but it works.', 'Não ficou bonito, mas funciona.'],
    IGUI_MVR_Say_crit_1: ['Nailed it!', 'Ficou perfeito!'],
    IGUI_MVR_Say_crit_2: ['Better than I expected!', 'Melhor do que eu esperava!'],
    IGUI_MVR_Say_crit_3: ['Now that is a clean job.', 'Isso sim é serviço bem feito.'],
    IGUI_MVR_Say_light_1: ['It did not hold... wasted material.', 'Não segurou... perdi o material.'],
    IGUI_MVR_Say_light_2: ['Damn, that made it a bit worse.', 'Droga, piorei um pouco.'],
    IGUI_MVR_Say_light_3: ['That did not go as planned.', 'Não saiu como eu queria.'],
    IGUI_MVR_Say_severe_1: ['No! I broke it even more!', 'Não! Quebrei mais ainda!'],
    IGUI_MVR_Say_severe_2: ['That was a disaster.', 'Isso foi um desastre.'],
    IGUI_MVR_Say_severe_3: ['I really messed that up.', 'Fiz besteira das grandes.'],
    IGUI_MVR_Halo_Condition: ['Condition %1 -> %2', 'Condição %1 -> %2'],
    IGUI_MVR_Event_Injury: ['Hurt my hand!', 'Machuquei a mão!'],
    IGUI_MVR_Event_Burn: ['Burned my hand!', 'Queimei a mão!'],
    IGUI_MVR_Event_ToolWear: ['The tool wore down', 'A ferramenta desgastou'],
    IGUI_MVR_Event_Frustration: ['This is frustrating...', 'Que frustrante...'],
    IGUI_MVR_Event_Waste: ['Wasted some material', 'Desperdicei material'],
    IGUI_MVR_Fail_disabled: ['Improvised repairs are disabled here.', 'Reparos improvisados estão desativados aqui.'],
    IGUI_MVR_Fail_not_repairable: ['A bulb has to be replaced, not patched.', 'Lâmpada se troca, não se remenda.'],
    IGUI_MVR_Fail_not_installed: ['The part is not there anymore.', 'A peça não está mais lá.'],
    IGUI_MVR_Fail_undamaged: ['It is not damaged.', 'Não está danificada.'],
    IGUI_MVR_Fail_above_cap: ['I cannot improve it any further this way.', 'Não consigo melhorar mais desse jeito.'],
    IGUI_MVR_Fail_skill: ['I do not know enough for this yet.', 'Ainda não sei o suficiente para isso.'],
    IGUI_MVR_Fail_missing_tools: ['I do not have the tools anymore.', 'Estou sem as ferramentas.'],
    IGUI_MVR_Fail_missing_materials: ['I do not have the materials anymore.', 'Estou sem os materiais.'],
    IGUI_MVR_Inspect_Title: ['Maintenance inspection: %1', 'Inspeção de manutenção: %1'],
    IGUI_MVR_Inspect_Line: ['%1: %2%', '%1: %2%'],
    IGUI_MVR_Inspect_Patches: ['patched %1x', 'remendada %1x'],
    IGUI_MVR_Inspect_Risk: ['next patch risk %1', 'risco do próximo remendo %1'],
    IGUI_MVR_Inspect_Vanilla: ['standard repair possible', 'reparo padrão possível'],
    IGUI_MVR_Inspect_Replace: ['replace (cannot be patched)', 'substituir (sem remendo)'],
    IGUI_MVR_Inspect_Critical: ['Critical (below 25%): %1', 'Críticas (abaixo de 25%): %1'],
    IGUI_MVR_Inspect_NoCritical: ['No critical parts.', 'Nenhuma peça crítica.'],
  },
  Sandbox: {
    Sandbox_MVR: ['Basic Vehicle Maintenance', 'Manutenção Básica de Veículos'],
    Sandbox_MVR_Enabled: ['Enable improvised repairs', 'Ativar reparos improvisados'],
    Sandbox_MVR_Enabled_tooltip: ['Turns the whole mod on or off.', 'Liga ou desliga o mod inteiro.'],
    Sandbox_MVR_MaterialCostMultiplier: ['Material cost multiplier', 'Multiplicador de custo de materiais'],
    Sandbox_MVR_MaterialCostMultiplier_tooltip: ['Scales every material quantity (minimum 1). Default 1.', 'Multiplica todas as quantidades de material (mínimo 1). Padrão 1.'],
    Sandbox_MVR_ConditionGainMultiplier: ['Condition gain multiplier', 'Multiplicador de ganho de condição'],
    Sandbox_MVR_ConditionGainMultiplier_tooltip: ['Scales how much condition a successful repair restores. Default 1.', 'Multiplica quanto de condição um reparo bem-sucedido recupera. Padrão 1.'],
    Sandbox_MVR_CapOffset: ['Condition cap offset', 'Ajuste do teto de condição'],
    Sandbox_MVR_CapOffset_tooltip: ['Added to every repair cap. Improvised repairs never go above 75/78/80 (patch/repair/overhaul) nor below 30. Default 0.', 'Somado a todo teto de reparo. Reparo improvisado nunca passa de 75/78/80 (remendo/reparo/revisão) nem fica abaixo de 30. Padrão 0.'],
    Sandbox_MVR_FailChanceMultiplier: ['Failure chance multiplier', 'Multiplicador da chance de falha'],
    Sandbox_MVR_FailChanceMultiplier_tooltip: ['0 = repairs never fail. Default 1.', '0 = reparos nunca falham. Padrão 1.'],
    Sandbox_MVR_SevereFailEnabled: ['Severe failures', 'Falhas graves'],
    Sandbox_MVR_SevereFailEnabled_tooltip: ['When on, 40% of failures cost 20 condition instead of 5.', 'Ligado: 40% das falhas tiram 20 de condição em vez de 5.'],
    Sandbox_MVR_SideEffectsEnabled: ['Side effects', 'Efeitos colaterais'],
    Sandbox_MVR_SideEffectsEnabled_tooltip: ['Hand cuts/burns, tool wear, wasted material and frustration.', 'Cortes/queimaduras na mão, desgaste de ferramenta, desperdício de material e frustração.'],
    Sandbox_MVR_InjuryChanceMultiplier: ['Injury chance multiplier', 'Multiplicador da chance de ferimento'],
    Sandbox_MVR_InjuryChanceMultiplier_tooltip: ['Scales cut and burn chances. Gloves already reduce them. Default 1.', 'Multiplica as chances de corte e queimadura. Luvas já reduzem. Padrão 1.'],
    Sandbox_MVR_XPMultiplier: ['Mechanics XP multiplier', 'Multiplicador de XP de Mecânica'],
    Sandbox_MVR_XPMultiplier_tooltip: ['Base XP: 3 success, 5 great success, 1 failure, once per part per vehicle per game day. Default 1.', 'XP base: 3 sucesso, 5 sucesso crítico, 1 falha, uma vez por peça por veículo por dia de jogo. Padrão 1.'],
    Sandbox_MVR_TimeMultiplier: ['Work time multiplier', 'Multiplicador do tempo de trabalho'],
    Sandbox_MVR_TimeMultiplier_tooltip: ['Scales how long repairs take. Default 1.', 'Multiplica quanto tempo os reparos levam. Padrão 1.'],
    Sandbox_MVR_PatchHistoryEnabled: ['Patch history', 'Histórico de remendos'],
    Sandbox_MVR_PatchHistoryEnabled_tooltip: ['Emergency patches lower the cap by 3 (minimum 30). Proper repairs preserve history; overhauls remove one patch penalty.', 'Remendos baixam o teto em 3 (mínimo 30). Reparos preservam o histórico; revisões removem uma penalidade de remendo.'],
    Sandbox_MVR_WorkshopBonusEnabled: ['Workshop modifiers', 'Modificadores de oficina'],
    Sandbox_MVR_WorkshopBonusEnabled_tooltip: ['Vehicle indoors: -3 points of failure chance. Darkness: +5. Jack: tires, brakes and suspension 15% faster.', 'Veículo em local coberto: -3 pontos na chance de falha. Escuro: +5. Macaco: pneus, freios e suspensão 15% mais rápidos.'],
    Sandbox_MVR_QualityTiersEnabled: ['Quality tiers', 'Faixas de qualidade'],
    Sandbox_MVR_QualityTiersEnabled_tooltip: ['Adds Repair (Mechanics 3) and Overhaul (Mechanics 6) with higher caps, more materials and time. Off = Patch only.', 'Adiciona Reparo (Mecânica 3) e Revisão (Mecânica 6) com tetos maiores, mais material e tempo. Desligado = só Remendo.'],
  },
};

T.IG_UI.IGUI_MVR_Fail_work_area = ["Work beside the part on the same floor, with the vehicle stopped and engine off.", "Trabalhe junto da peça no mesmo piso, com o veículo parado e motor desligado."];


Object.assign(T.ContextMenu, {
 ContextMenu_MVR_Workshop: ["Vehicle workshop", "Oficina do veículo"],
 ContextMenu_MVR_Upgrade1: ["Upgrade I", "Melhoria I"],
 ContextMenu_MVR_Upgrade2: ["Upgrade II (sheltered workshop)", "Melhoria II (oficina coberta)"],
 ContextMenu_MVR_Restore: ["Remove upgrade", "Remover melhoria"],
 ContextMenu_MVR_Unsupported: ["Upgrade unavailable for this part", "Melhoria indisponível nesta peça"],
 ContextMenu_MVR_Paint: ["Paint vehicle", "Pintar veículo"],
 ContextMenu_MVR_Rust: ["Remove some rust", "Remover parte da ferrugem"],
 ContextMenu_MVR_Wash: ["Wash blood (standard action)", "Lavar sangue (ação padrão)"],
});
for (const [id, en, pt] of [["red","Red","Vermelho"],["blue","Blue","Azul"],["green","Green","Verde"],["yellow","Yellow","Amarelo"],["orange","Orange","Laranja"],["purple","Purple","Roxo"],["brown","Brown","Marrom"],["black","Black","Preto"],["white","White","Branco"],["grey","Grey","Cinza"]]) T.ContextMenu["ContextMenu_MVR_Color_"+id] = [en,pt];
Object.assign(T.Tooltip, {
 Tooltip_MVR_Workshop: ["Vehicle workshop: %1", "Oficina do veículo: %1"],
 Tooltip_MVR_WorkshopBenefit: ["Original %1 -> selected %2 (at full condition; native damage penalties still apply).", "Original %1 -> selecionado %2 (em condição plena; penalidades de dano do jogo continuam)."],
 Tooltip_MVR_WorkshopCost: ["Requirements and costs are checked again when work finishes.", "Requisitos e custos são conferidos novamente ao concluir."],
 Tooltip_MVR_WorkshopRisk: ["No random failure. This work grants no XP.", "Sem falha aleatória. Este trabalho não concede XP."],
 Tooltip_MVR_WorkshopTime: ["Work time: %1 action units (before character speed modifiers).", "Tempo: %1 unidades de ação (antes dos modificadores do personagem)."],
 Tooltip_MVR_WorkshopPower: ["Power only: +5% / +10%. Quality and noise are preserved.", "Somente potência: +5% / +10%. Qualidade e ruído são preservados."],
 Tooltip_MVR_WorkshopCargo: ["Cargo: +10% / +20%, at most +40 capacity. Follows the physical part.", "Carga: +10% / +20%, no máximo +40 de capacidade. Acompanha a peça física."],
 Tooltip_MVR_WorkshopGlove: ["Glove box: +25% / +50%, at most +5 capacity. Follows the physical part.", "Porta-luvas: +25% / +50%, no máximo +5 de capacidade. Acompanha a peça física."],
 Tooltip_MVR_CosmeticOnly: ["Appearance only: paint and rust removal do not repair parts or add protection.", "Somente aparência: pintura e remoção de ferrugem não reparam peças nem adicionam proteção."],
 Tooltip_MVR_RustStep: ["Removes up to 20 percentage points of rust per application.", "Remove até 20 pontos percentuais de ferrugem por aplicação."],
 Tooltip_MVR_Wash: ["Uses the game's normal water-consuming vehicle washing action. Carry at least 1 unit of water and find blood to wash.", "Usa a lavagem normal do jogo, consumindo água. Leve ao menos 1 unidade de água e encontre sangue para lavar."],
});
const workshopStatuses = {
 ok: ["Ready. Work beside the selected part, on the same floor, with engine off and vehicle stopped.", "Pronto. Trabalhe junto à peça selecionada, no mesmo piso, com motor desligado e veículo parado."],
 disabled: ["This operation is disabled by the server.", "Esta operação está desativada pelo servidor."],
 not_installed: ["The selected part must be installed.", "A peça selecionada precisa estar instalada."],
 unsupported: ["Only the game's generic engine, trunk and glove-box parts have supported upgrades. Special systems are excluded.", "Somente motor, porta-malas e porta-luvas genéricos do jogo recebem melhorias. Sistemas especiais ficam de fora."],
 unpaintable: ["This model does not enable native vehicle tinting.", "Este modelo não permite a coloração nativa de veículos."],
 access: ["Unlock access using the vehicle key or the game's normal door/window access.", "Libere o acesso com a chave do veículo ou pelo acesso normal de portas e janelas do jogo."],
 already: ["The selected result is already installed, or there is nothing left to remove.", "O resultado selecionado já está aplicado ou não resta nada para remover."],
 overloaded: ["Unload cargo first. A downgrade cannot reduce capacity below the contents; damaged parts may require more unloading.", "Retire a carga primeiro. A redução não pode deixar a capacidade menor que o conteúdo; peças danificadas podem exigir retirar mais carga."],
 conflict: ["Another system changed this part's base statistics. This upgrade is suspended to preserve that change.", "Outro sistema alterou os atributos de base desta peça. A melhoria está suspensa para preservar essa alteração."],
 workshop: ["Tier II needs a sheltered vehicle and Mechanics 6.", "O nível II exige veículo em local coberto e Mecânica 6."],
 skill: ["Your Mechanics level is too low.", "Seu nível de Mecânica é insuficiente."],
 missing_tools: ["A required tool is missing or broken.", "Falta uma ferramenta obrigatória ou ela está quebrada."],
 missing_materials: ["Required materials are missing.", "Faltam materiais obrigatórios."],
 stale: ["The vehicle or installed part changed while you were working. Start again.", "O veículo ou a peça instalada mudou durante o trabalho. Inicie novamente."],
 work_area: ["Work beside the part, on the same floor, with the vehicle stopped and engine off.", "Trabalhe junto à peça, no mesmo piso, com o veículo parado e motor desligado."],
};
for (const [status, pair] of Object.entries(workshopStatuses)) {
 T.Tooltip["Tooltip_MVR_WorkshopStatus_"+status] = pair;
 if (!T.IG_UI["IGUI_MVR_Fail_"+status]) T.IG_UI["IGUI_MVR_Fail_"+status] = pair;
}
Object.assign(T.IG_UI, {
 IGUI_MVR_WorkshopJob: ["Vehicle workshop", "Oficina de veículo"],
 IGUI_MVR_WorkshopDone: ["Workshop work finished.", "Trabalho de oficina concluído."],
});
Object.assign(T.Sandbox, {
 Sandbox_MVR_UpgradesEnabled: ["Capacity and engine upgrades", "Melhorias de carga e motor"],
 Sandbox_MVR_UpgradesEnabled_tooltip: ["Enables bounded cargo/glove-box capacity and engine power upgrades. Disabling restores original values when cargo permits; no items are discarded.", "Ativa melhorias limitadas de carga/porta-luvas e potência. Ao desligar, restaura valores originais quando a carga permitir; nenhum item é descartado."],
 Sandbox_MVR_CustomizationEnabled: ["Vehicle painting and rust removal", "Pintura e remoção de ferrugem"],
 Sandbox_MVR_CustomizationEnabled_tooltip: ["Enables resource-consuming cosmetic work. Washing still uses the game's normal action.", "Ativa trabalhos cosméticos com consumo de recursos. A lavagem continua usando a ação normal do jogo."],
});
T.Mod.description = ["Emergency patches, durable repairs and overhauls, vehicle inspection, bounded trunk/glove-box and engine power upgrades, painting and gradual rust removal. Uses standard vehicle washing. Generic vanilla parts also work on modded vehicle models. B42 only; English and Brazilian Portuguese.", "Remendos emergenciais, reparos duráveis e revisões, inspeção, melhorias limitadas de porta-malas/porta-luvas e potência, pintura e remoção gradual de ferrugem. Usa a lavagem padrão. Peças genéricas do jogo também funcionam em modelos de veículos de mods. Somente B42; português brasileiro e inglês."];

T.Tooltip.Tooltip_MVR_Status_access = T.Tooltip.Tooltip_MVR_WorkshopStatus_access;
T.Tooltip.Tooltip_MVR_Status_destroyed = ["A destroyed window must be replaced.", "Uma janela destruída precisa ser substituída."];
T.IG_UI.IGUI_MVR_Fail_destroyed = T.Tooltip.Tooltip_MVR_Status_destroyed;
T.Tooltip.Tooltip_MVR_HistoryRestoration = ["History restoration only: removes one patch penalty on success while preserving current condition.", "Somente restauração do histórico: remove uma penalidade de remendo no sucesso, preservando a condição atual."];
T.Tooltip.Tooltip_MVR_Req_WorkshopShelter = ["Sheltered workshop: %2/%1", "Oficina coberta: %2/%1"];
const ROOT = path.join(__dirname, '..', 'Contents', 'mods', 'MoreVehiclesRepairs', 'common', 'media', 'lua', 'shared', 'Translate');
const LANGS = ['EN', 'PTBR'];
const check = process.argv.includes('--check');
let stale = 0;
for (const [file, keys] of Object.entries(T)) {
  LANGS.forEach((lang, li) => {
    const obj = {};
    for (const [k, v] of Object.entries(keys)) obj[k] = v[li];
    const text = JSON.stringify(obj, null, 4) + '\n';
    const p = path.join(ROOT, lang, file + '.json');
    if (check) {
      if (!fs.existsSync(p) || fs.readFileSync(p, 'utf8') !== text) { stale++; console.log('stale ' + p); }
    } else {
      fs.mkdirSync(path.dirname(p), { recursive: true });
      fs.writeFileSync(p, text);
    }
  });
}
if (check && stale) process.exit(1);
module.exports = T;
