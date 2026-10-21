// Single source of all EN / PT-BR texts. `npm run i18n` writes common/media/lua/shared/Translate/{EN,PTBR}/*.json.
// `node tools/i18n.js --check` fails if the JSON files are out of date (used by npm test).
const fs = require('fs');
const path = require('path');

const T = {
  Mod: {
    name: ["Field Medicine '93", "Medicina de Campo '93"],
    description: ["1993 field medicine that complements vanilla health: clinical exams, wound irrigation, tourniquets, cauterization, fracture reduction and debridement. First Aid requirements, costs and risks, with sandbox options. Never identifies the Knox infection. Build 42 only; PT-BR + EN.","Medicina de campo de 1993 que complementa a saúde vanilla: exame clínico, irrigação de feridas, torniquete, cauterização, redução de fratura e debridamento. Requisitos de Primeiros Socorros, custos e riscos, com opções de sandbox. Nunca identifica a infecção Knox. Só Build 42; PT-BR + EN."],
  },
  ContextMenu: {
    ContextMenu_KFM_Root: ["Field Medicine", "Medicina de Campo"],
    ContextMenu_KFM_Exam: ["Clinical exam", "Exame clínico"],
    ContextMenu_KFM_ExamSelf: ["Examine yourself", "Examinar a si mesmo"],
    ContextMenu_KFM_Irrigate: ["Irrigate wound", "Irrigar ferida"],
    ContextMenu_KFM_Tourniquet: ["Apply tourniquet", "Aplicar torniquete"],
    ContextMenu_KFM_TourniquetRemove: ["Remove tourniquet", "Remover torniquete"],
    ContextMenu_KFM_Cauterize: ["Cauterize wound", "Cauterizar ferida"],
    ContextMenu_KFM_ReduceFracture: ["Reduce fracture", "Reduzir fratura"],
    ContextMenu_KFM_Debride: ["Debride wound", "Debridar ferida"],
  },
  Tooltip: {
    Tooltip_KFM_Exam: [
      "Check the patient's general state, temperature, pulse, hydration and healing. What you notice depends on First Aid level. A stethoscope counts as +1 level; a tongue depressor (used up) lets anyone check hydration and throat.",
      "Avalia estado geral, temperatura, pulso, hidratação e recuperação do paciente. O que você percebe depende do nível de Primeiros Socorros. Estetoscópio conta como +1 nível; abaixador de língua (consumido) permite a qualquer um checar hidratação e garganta.",
    ],
    Tooltip_KFM_Irrigate: [
      "Flush an open, unbandaged wound with 0.25 L of water. Clean water lowers wound infection; tainted water makes it worse. Weaker than disinfectant, and it stings.",
      "Lava uma ferida aberta e sem curativo com 0,25 L de água. Água limpa reduz a infecção da ferida; água contaminada piora. Mais fraco que desinfetante, e arde.",
    ],
    Tooltip_KFM_Tourniquet: [
      "Arms and legs only. Stops the bleeding of this part and everything below it while applied. Buys time to stitch or bandage; it is not a treatment. After a few hours the limb starts to suffer.",
      "Só braços e pernas. Para o sangramento desta parte e de tudo abaixo dela enquanto estiver aplicado. Ganha tempo para suturar ou enfaixar; não é tratamento. Depois de algumas horas o membro começa a sofrer.",
    ],
    Tooltip_KFM_TourniquetRemove: [
      "Removes the tourniquet and gives it back. Untreated wounds below it start bleeding again.",
      "Remove o torniquete e o devolve. Feridas não tratadas abaixo dele voltam a sangrar.",
    ],
    Tooltip_KFM_Cauterize: [
      "Close a deep wound with a heated blade (uses a lighter or matches). Leaves a burn that needs cleaning. Worse than stitches, better than bleeding out. Does not work on bites.",
      "Fecha uma ferida profunda com uma lâmina aquecida (gasta isqueiro ou fósforo). Deixa uma queimadura que precisa ser limpa. Pior que sutura, melhor que sangrar até morrer. Não funciona em mordidas.",
    ],
    Tooltip_KFM_ReduceFracture: [
      "Set the broken bone back in place: much faster healing, extremely painful. Once per fracture. The patient must be sitting or lying down. Painkillers taken before halve the pain.",
      "Recoloca o osso quebrado no lugar: consolidação bem mais rápida, extremamente doloroso. Uma vez por fratura. O paciente precisa estar sentado ou deitado. Analgésico tomado antes reduz a dor pela metade.",
    ],
    Tooltip_KFM_Debride: [
      "Cut away badly infected tissue with a scalpel. Clears the wound infection but the wound bleeds again: bandage it afterwards. Never affects any other infection.",
      "Remove com bisturi o tecido muito infectado. Elimina a infecção da ferida, mas ela volta a sangrar: faça um curativo depois. Nunca afeta outras infecções.",
    ],
    Tooltip_KFM_ImprovisedTourniquet: [
      "Cloth strips and a stick used as a windlass. Use it from the health panel on an arm or leg.",
      "Tiras de pano e um graveto usado como torniquete. Use pelo painel de saúde em um braço ou perna.",
    ],
  },
  ItemName: {
    'Base.KFM_ImprovisedTourniquet': ['Improvised Tourniquet', 'Torniquete Improvisado'],
  },
  Recipes: {
    KFM_MakeImprovisedTourniquet: ['Make Improvised Tourniquet', 'Fazer Torniquete Improvisado'],
  },
  IG_UI: {
    IGUI_KFM_Exam_Title: ['Clinical exam: %1', 'Exame clínico: %1'],
    IGUI_KFM_Exam_TitleSelf: ['Clinical exam (yourself)', 'Exame clínico (você mesmo)'],
    IGUI_KFM_Exam_General_Good: ['General state: good.', 'Estado geral: bom.'],
    IGUI_KFM_Exam_General_Stable: ['General state: stable.', 'Estado geral: estável.'],
    IGUI_KFM_Exam_General_Serious: ['General state: serious.', 'Estado geral: grave.'],
    IGUI_KFM_Exam_General_Critical: ['General state: critical.', 'Estado geral: crítico.'],
    IGUI_KFM_Exam_HighFever: ['High fever. Many things can cause it.', 'Febre alta. Muitas coisas podem causar isso.'],
    IGUI_KFM_Exam_Fever: ['Feverish. Many things can cause it.', 'Febril. Muitas coisas podem causar isso.'],
    IGUI_KFM_Exam_Cold: ['Body is cold to the touch.', 'Corpo frio ao toque.'],
    IGUI_KFM_Exam_TempNormal: ['Temperature seems normal.', 'Temperatura parece normal.'],
    IGUI_KFM_Exam_PulseWeak: ['Pulse weak and thready.', 'Pulso fraco e fino.'],
    IGUI_KFM_Exam_PulseFast: ['Pulse racing.', 'Pulso acelerado.'],
    IGUI_KFM_Exam_PulseCalm: ['Pulse steady.', 'Pulso regular.'],
    IGUI_KFM_Exam_BreathFast: ['Breathing fast and shallow.', 'Respiração rápida e curta.'],
    IGUI_KFM_Exam_BreathNormal: ['Breathing normal.', 'Respiração normal.'],
    IGUI_KFM_Exam_DehydratedSevere: ['Severely dehydrated.', 'Muito desidratado.'],
    IGUI_KFM_Exam_Dehydrated: ['Somewhat dehydrated.', 'Um pouco desidratado.'],
    IGUI_KFM_Exam_Hydrated: ['Well hydrated.', 'Bem hidratado.'],
    IGUI_KFM_Exam_Malnourished: ['Malnourished.', 'Desnutrido.'],
    IGUI_KFM_Exam_Underfed: ['Underfed.', 'Mal alimentado.'],
    IGUI_KFM_Exam_ThroatSore: ['Throat red and irritated.', 'Garganta vermelha e irritada.'],
    IGUI_KFM_Exam_ThroatOk: ['Throat looks fine.', 'Garganta parece normal.'],
    IGUI_KFM_Exam_Fracture_VeryLong: ['%1: fracture, many weeks to heal.', '%1: fratura, muitas semanas para consolidar.'],
    IGUI_KFM_Exam_Fracture_Long: ['%1: fracture, long way to heal.', '%1: fratura, ainda falta muito para consolidar.'],
    IGUI_KFM_Exam_Fracture_Medium: ['%1: fracture, healing.', '%1: fratura, consolidando.'],
    IGUI_KFM_Exam_Fracture_Short: ['%1: fracture, nearly healed.', '%1: fratura, quase consolidada.'],
    IGUI_KFM_Exam_Fracture_AlmostHealed: ['%1: fracture, almost healed.', '%1: fratura, praticamente consolidada.'],
    IGUI_KFM_Exam_WoundInflamed: ['%1: the wound looks inflamed, it may be getting infected.', '%1: a ferida parece inflamada, pode estar infeccionando.'],
    IGUI_KFM_Exam_UnexplainedWeakness: [
      'Weaker than the visible wounds explain (blood loss, illness, hunger, exhaustion...).',
      'Mais fraco do que as feridas visíveis explicam (perda de sangue, doença, fome, exaustão...).',
    ],
    IGUI_KFM_Exam_MoreSkill: ['With more First Aid skill you would notice more.', 'Com mais Primeiros Socorros você perceberia mais.'],
    IGUI_KFM_Exam_Disclaimer: ['A field exam, not a lab: some things cannot be known.', 'Um exame de campo, não um laboratório: algumas coisas não dá para saber.'],
    IGUI_KFM_RequiresLevel: ['Requires First Aid level %1.', 'Requer Primeiros Socorros nível %1.'],
    IGUI_KFM_FailChance: ['Chance of failure: %1%', 'Chance de falha: %1%'],
    IGUI_KFM_HelperHint: ['A helper next to the patient lowers the requirement by %1.', 'Um ajudante ao lado do paciente reduz o requisito em %1.'],
    IGUI_KFM_MustRest: ['The patient must be sitting or lying down.', 'O paciente precisa estar sentado ou deitado.'],
    IGUI_KFM_Result_IrrigateOk: ['Wound flushed clean.', 'Ferida lavada.'],
    IGUI_KFM_Result_IrrigateDirty: ['That water was not clean...', 'Essa água não estava limpa...'],
    IGUI_KFM_Result_TourniquetOk: ['Tourniquet tight. Bleeding stopped for now.', 'Torniquete apertado. Sangramento contido por enquanto.'],
    IGUI_KFM_Result_TourniquetFail: ['Could not get the tourniquet tight enough.', 'Não consegui apertar o torniquete o suficiente.'],
    IGUI_KFM_Result_TourniquetRemoved: ['Tourniquet removed.', 'Torniquete removido.'],
    IGUI_KFM_Result_CauterizeOk: ['Wound sealed. That will leave a mark.', 'Ferida selada. Isso vai deixar marca.'],
    IGUI_KFM_Result_CauterizeFail: ['Only burned it, the wound is still open.', 'Só queimei, a ferida continua aberta.'],
    IGUI_KFM_Result_ReduceOk: ['The bone is back in place.', 'O osso voltou para o lugar.'],
    IGUI_KFM_Result_ReduceFail: ['It did not go back in place. Made it worse.', 'Não encaixou. Piorou.'],
    IGUI_KFM_Result_DebrideOk: ['Infected tissue removed. Needs a bandage now.', 'Tecido infectado removido. Agora precisa de curativo.'],
    IGUI_KFM_Result_DebrideFail: ['Could not remove all of it.', 'Não consegui remover tudo.'],
  },
  Sandbox: {
    Sandbox_KFM: ["Field Medicine '93", "Medicina de Campo '93"],
    Sandbox_KFM_Enabled: ['Enable Field Medicine', 'Ativar Medicina de Campo'],
    Sandbox_KFM_Enabled_tooltip: ['Turns every procedure of this mod on or off. Tourniquets already applied keep working until removed.', 'Liga ou desliga todos os procedimentos deste mod. Torniquetes já aplicados continuam funcionando até serem removidos.'],
    Sandbox_KFM_ExamEnabled: ['Enable clinical exam', 'Ativar exame clínico'],
    Sandbox_KFM_ExamEnabled_tooltip: ['Allows the clinical exam from the health panel and from a stethoscope / tongue depressor.', 'Permite o exame clínico pelo painel de saúde e pelo estetoscópio / abaixador de língua.'],
    Sandbox_KFM_ShowFeverInExam: ['Exam shows fever', 'Exame mostra febre'],
    Sandbox_KFM_ShowFeverInExam_tooltip: ['The exam reports fever without its cause (any fever looks the same). Hardcore servers can hide it.', 'O exame informa febre sem a causa (qualquer febre parece igual). Servidores hardcore podem esconder.'],
    Sandbox_KFM_SkillRequirementOffset: ['First Aid requirement offset', 'Ajuste do requisito de Primeiros Socorros'],
    Sandbox_KFM_SkillRequirementOffset_tooltip: ['Added to the level needed by tourniquet, cauterization, fracture reduction and debridement (exam and irrigation always level 0). Default 0.', 'Somado ao nível exigido por torniquete, cauterização, redução de fratura e debridamento (exame e irrigação sempre nível 0). Padrão 0.'],
    Sandbox_KFM_FailChanceMultiplier: ['Failure chance multiplier', 'Multiplicador da chance de falha'],
    Sandbox_KFM_FailChanceMultiplier_tooltip: ['0 = procedures never fail. Default 1.', '0 = procedimentos nunca falham. Padrão 1.'],
    Sandbox_KFM_ProcedurePainMultiplier: ['Procedure pain multiplier', 'Multiplicador da dor dos procedimentos'],
    Sandbox_KFM_ProcedurePainMultiplier_tooltip: ['Pain added by the procedures. Default 1.', 'Dor causada pelos procedimentos. Padrão 1.'],
    Sandbox_KFM_IrrigationStrength: ['Irrigation strength', 'Força da irrigação'],
    Sandbox_KFM_IrrigationStrength_tooltip: ['How much wound infection one irrigation removes. Default 1.', 'Quanto de infecção da ferida uma irrigação remove. Padrão 1.'],
    Sandbox_KFM_TourniquetSafeHours: ['Tourniquet safe hours', 'Horas seguras do torniquete'],
    Sandbox_KFM_TourniquetSafeHours_tooltip: ['In-game hours before the limb starts losing health and hurting. Lasting damage after 3x this time. Default 2.', 'Horas de jogo antes de o membro começar a perder saúde e doer. Dano duradouro depois de 3x esse tempo. Padrão 2.'],
    Sandbox_KFM_FractureReductionMax: ['Max fracture time reduction', 'Redução máxima do tempo de fratura'],
    Sandbox_KFM_FractureReductionMax_tooltip: ['Cap of the healing time removed by a successful fracture reduction (0.40 = 40%). Default 0.40.', 'Limite do tempo de consolidação removido por uma redução de fratura bem-sucedida (0,40 = 40%). Padrão 0,40.'],
    Sandbox_KFM_XPMultiplier: ['First Aid XP multiplier', 'Multiplicador de XP de Primeiros Socorros'],
    Sandbox_KFM_XPMultiplier_tooltip: ['XP given by the procedures (only on real injuries, with a cooldown per patient). Default 1.', 'XP dado pelos procedimentos (só em lesões reais, com intervalo por paciente). Padrão 1.'],
  },
};

const ROOT = path.join(__dirname, '..', 'Contents', 'mods', 'KRFieldMedicine', 'common', 'media', 'lua', 'shared', 'Translate');
const check = process.argv.includes('--check');
let stale = 0;
for (const [li, lang] of ['EN', 'PTBR'].entries()) {
  for (const [file, entries] of Object.entries(T)) {
    const obj = {};
    for (const [k, v] of Object.entries(entries)) obj[k] = v[li];
    const out = JSON.stringify(obj, null, 4) + '\n';
    const p = path.join(ROOT, lang, file + '.json');
    if (check) {
      if (!fs.existsSync(p) || fs.readFileSync(p, 'utf8') !== out) { stale++; console.log('stale: ' + p); }
    } else {
      fs.mkdirSync(path.dirname(p), { recursive: true });
      fs.writeFileSync(p, out);
    }
  }
}
if (check && stale) process.exit(1);
module.exports = T;
