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

for (const [file, entries] of Object.entries({"Sandbox":{"Sandbox_KFM_IllnessEnabled":["Common illness and injury episodes","Episódios de doenças e lesões"],"Sandbox_KFM_IllnessEnabled_tooltip":["Common illness and injury episodes. Server authoritative; progression pauses offline. Severe complications give warnings before gradual damage.","Episódios de doenças e lesões. Controle pelo servidor; evolução pausa offline. Complicações graves avisam antes do dano gradual."],"Sandbox_KFM_ContactTransmissionEnabled":["Viral contact spread","Contágio viral por contato"],"Sandbox_KFM_ContactTransmissionEnabled_tooltip":["Viral contact spread. Server authoritative; progression pauses offline. Severe complications give warnings before gradual damage.","Contágio viral por contato. Controle pelo servidor; evolução pausa offline. Complicações graves avisam antes do dano gradual."],"Sandbox_KFM_NewDiseaseMortalityEnabled":["Neglected severe complications can kill","Complicações graves negligenciadas podem matar"],"Sandbox_KFM_NewDiseaseMortalityEnabled_tooltip":["Neglected severe complications can kill. Server authoritative; progression pauses offline. Severe complications give warnings before gradual damage.","Complicações graves negligenciadas podem matar. Controle pelo servidor; evolução pausa offline. Complicações graves avisam antes do dano gradual."],"Sandbox_KFM_DiseaseFrequency":["Exposure risk multiplier","Multiplicador do risco por exposição"],"Sandbox_KFM_DiseaseFrequency_tooltip":["Exposure risk multiplier. Server authoritative; progression pauses offline. Severe complications give warnings before gradual damage.","Multiplicador do risco por exposição. Controle pelo servidor; evolução pausa offline. Complicações graves avisam antes do dano gradual."],"Sandbox_KFM_DiseaseSeverity":["Symptom severity multiplier","Multiplicador da gravidade dos sintomas"],"Sandbox_KFM_DiseaseSeverity_tooltip":["Symptom severity multiplier. Server authoritative; progression pauses offline. Severe complications give warnings before gradual damage.","Multiplicador da gravidade dos sintomas. Controle pelo servidor; evolução pausa offline. Complicações graves avisam antes do dano gradual."]}})) Object.assign(T[file], entries);

for (const [file, entries] of Object.entries({"IG_UI":{"IGUI_KFM_SevereWarning":["Severe complication suspected. Seek care now; neglected illness may cause gradual health loss.","Suspeita de complicação grave. Procure atendimento; doença negligenciada pode causar perda gradual de saúde."],"IGUI_KFM_ConsentPrompt":["%1 requests permission for Field Medicine care for one game hour. You can revoke it from your health menu.","%1 solicita permissão para cuidados por uma hora de jogo. Você pode revogar pelo menu de saúde."],"IGUI_KFM_Recovery":["Recovery estimate: %1 simulated hours. Follow up after treatment; not a Knox diagnosis.","Estimativa de recuperação: %1 horas simuladas. Reavalie após o cuidado; não identifica Knox."]},"ContextMenu":{"ContextMenu_KFM_Consent":["Request permission for care","Solicitar permissão para cuidados"],"ContextMenu_KFM_Revoke":["Revoke care permission","Revogar permissão para cuidados"],"ContextMenu_KFM_Care":["Episode care","Cuidar do quadro"]},"ItemName":{"Base.KFM_SupportSachet":["Support sachet","Sachê de suporte"],"Base.KFM_SkinOintment":["Skin care ointment","Pomada de cuidado da pele"],"Base.KFM_BurnDressing":["Burn care dressing","Curativo para queimadura"],"Base.KFM_RehabWrap":["Rehabilitation wrap","Faixa de reabilitação"]},"Tooltip":{}})) Object.assign(T[file], entries);

for (const [file, entries] of Object.entries({"IG_UI":{"IGUI_KFM_CareRequirements":["Needs First Aid level %1 and the shown supply. Other patients must consent; rest for splinting, drying and rehabilitation.","Exige Primeiros Socorros nível %1 e o material indicado. Outros pacientes precisam consentir; repouso para imobilização, secagem e reabilitação."],"IGUI_KFM_CareInterval":["Minimum interval: %1 game hours. Supplies are consumed only after a useful, valid treatment.","Intervalo mínimo: %1 horas de jogo. Material só é consumido após cuidado útil e válido."],"IGUI_KFM_Condition_flu":["Suspected flu-like illness","Suspeita de quadro gripal"],"IGUI_KFM_Condition_viral":["Suspected viral gastroenteritis","Suspeita de gastroenterite viral"],"IGUI_KFM_Condition_foodborne":["Foodborne illness signs","Sinais de intoxicação alimentar"],"IGUI_KFM_Condition_wound":["Wound infection signs","Sinais de infecção de ferida"],"IGUI_KFM_Condition_deep":["Deep skin infection signs","Sinais de infecção cutânea profunda"],"IGUI_KFM_Condition_systemic":["Severe systemic complication suspected","Suspeita de complicação sistêmica grave"],"IGUI_KFM_Condition_respiratory":["Severe respiratory complication suspected","Suspeita de complicação respiratória grave"],"IGUI_KFM_Condition_conjunctivitis":["Eye irritation / conjunctivitis signs","Irritação ocular / sinais de conjuntivite"],"IGUI_KFM_Condition_dermatitis":["Contact dermatitis signs","Sinais de dermatite de contato"],"IGUI_KFM_Condition_fungal":["Fungal skin condition suspected","Suspeita de micose cutânea"],"IGUI_KFM_Condition_burn":["Burn follow-up","Acompanhamento de queimadura"],"IGUI_KFM_Condition_fracture":["Fracture follow-up","Acompanhamento de fratura"],"IGUI_KFM_Condition_muscle":["Muscle strain signs","Sinais de distensão muscular"],"IGUI_KFM_Condition_nerve":["Regional nerve injury suspected","Suspeita de lesão nervosa regional"],"IGUI_KFM_Phase_latent":["Early signs / observation","Sinais iniciais / observação"],"IGUI_KFM_Phase_symptomatic":["Symptoms active","Sintomas ativos"],"IGUI_KFM_Phase_recovering":["Recovering / continue follow-up","Recuperando / mantenha acompanhamento"],"IGUI_KFM_Phase_complication":["Complication / seek care","Complicação / procure atendimento"],"IGUI_KFM_Phase_resolved":["Resolved","Resolvido"]},"ContextMenu":{"ContextMenu_KFM_Care_support":["Support sachet and hydration","Sachê de suporte e hidratação"],"ContextMenu_KFM_Care_hygiene":["Clean water hygiene","Higiene com água limpa"],"ContextMenu_KFM_Care_antibacterial":["Antibiotics for bacterial complication","Antibiótico para complicação bacteriana"],"ContextMenu_KFM_Care_topical":["Skin ointment","Pomada para a pele"],"ContextMenu_KFM_Care_dry":["Rest and dry skin care","Repouso e secagem da pele"],"ContextMenu_KFM_Care_burnCare":["Burn dressing care","Cuidado com curativo de queimadura"],"ContextMenu_KFM_Care_stabilize":["Stabilize with splint","Estabilizar com tala"],"ContextMenu_KFM_Care_rehab":["Guided rehabilitation with wrap","Reabilitação orientada com faixa"]}})) Object.assign(T[file], entries);

Object.assign(T.IG_UI, require("./exam-text"));

for (const [file, entries] of Object.entries({"Sandbox":{"Sandbox_KFM_SeasonalIllnessEnabled":["Seasonal cold and wet-heat illness","Doenças sazonais por frio e calor úmido"],"Sandbox_KFM_SeasonalIllnessEnabled_tooltip":["Seasonal cold and wet-heat illness. Server controlled; no offline catch-up or native trait-point changes.","Doenças sazonais por frio e calor úmido. Controle pelo servidor; sem avanço offline ou alteração de pontos de traços nativos."],"Sandbox_KFM_MosquitoIllnessEnabled":["Summer mosquito-associated illness","Quadros associados a mosquitos no verão"],"Sandbox_KFM_MosquitoIllnessEnabled_tooltip":["Summer mosquito-associated illness. Server controlled; no offline catch-up or native trait-point changes.","Quadros associados a mosquitos no verão. Controle pelo servidor; sem avanço offline ou alteração de pontos de traços nativos."],"Sandbox_KFM_ColdInjuryEnabled":["Cold injury in hands and fingers","Lesões por frio nas mãos e dedos"],"Sandbox_KFM_ColdInjuryEnabled_tooltip":["Cold injury in hands and fingers. Server controlled; no offline catch-up or native trait-point changes.","Lesões por frio nas mãos e dedos. Controle pelo servidor; sem avanço offline ou alteração de pontos de traços nativos."],"Sandbox_KFM_MaskProtectionEnabled":["Appropriate face-mask protection","Proteção por máscara facial adequada"],"Sandbox_KFM_MaskProtectionEnabled_tooltip":["Appropriate face-mask protection. Server controlled; no offline catch-up or native trait-point changes.","Proteção por máscara facial adequada. Controle pelo servidor; sem avanço offline ou alteração de pontos de traços nativos."],"Sandbox_KFM_DynamicCardiorespiratoryEnabled":["Reversible cardiorespiratory states","Estados cardiorrespiratórios reversíveis"],"Sandbox_KFM_DynamicCardiorespiratoryEnabled_tooltip":["Reversible cardiorespiratory states. Server controlled; no offline catch-up or native trait-point changes.","Estados cardiorrespiratórios reversíveis. Controle pelo servidor; sem avanço offline ou alteração de pontos de traços nativos."],"Sandbox_KFM_PsychologicalConditionsEnabled":["Reversible psychological states","Estados psicológicos reversíveis"],"Sandbox_KFM_PsychologicalConditionsEnabled_tooltip":["Reversible psychological states. Server controlled; no offline catch-up or native trait-point changes.","Estados psicológicos reversíveis. Controle pelo servidor; sem avanço offline ou alteração de pontos de traços nativos."],"Sandbox_KFM_PsychologicalEffectsEnabled":["Local psychological perceptions","Percepções psicológicas locais"],"Sandbox_KFM_PsychologicalEffectsEnabled_tooltip":["Local psychological perceptions. Server controlled; no offline catch-up or native trait-point changes.","Percepções psicológicas locais. Controle pelo servidor; sem avanço offline ou alteração de pontos de traços nativos."],"Sandbox_KFM_SymptomEffectsEnabled":["Cough and visual symptom effects","Efeitos de tosse e sintomas visuais"],"Sandbox_KFM_SymptomEffectsEnabled_tooltip":["Cough and visual symptom effects. Server controlled; no offline catch-up or native trait-point changes.","Efeitos de tosse e sintomas visuais. Controle pelo servidor; sem avanço offline ou alteração de pontos de traços nativos."],"Sandbox_KFM_FaintingEnabled":["Short severe-illness blackouts","Desmaios breves em quadros graves"],"Sandbox_KFM_FaintingEnabled_tooltip":["Short severe-illness blackouts. Server controlled; no offline catch-up or native trait-point changes.","Desmaios breves em quadros graves. Controle pelo servidor; sem avanço offline ou alteração de pontos de traços nativos."]},"IG_UI":{"IGUI_KFM_ColdHandsWarning":["Hands/fingers remain cold and numb. Warm and dry them; pain impairs native aiming and melee. Seek protective care.","Mãos/dedos continuam frios e dormentes. Aqueça e seque; a dor prejudica mira e combate nativos. Procure cuidado protetor."]},"ItemName":{},"ContextMenu":{}})) Object.assign(T[file], entries);

for (const [file, entries] of Object.entries(require("./health-text"))) Object.assign(T[file] = T[file] || {}, entries);

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
