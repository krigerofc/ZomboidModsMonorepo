// Single source of truth for KRjobs v2. tools/gen.js turns this into every shipped file:
//   B42: 42/media/registries.lua, 42/media/scripts/KRjobs_*.txt, 42/media/lua/shared/KRjobs/Kits.lua,
//        common/.../Translate/{EN,PTBR}/{UI,Mod}.json
//   B41: media/lua/shared/NPCs/KRjobs_Professions.lua, media/lua/shared/KRjobs/Kits.lua,
//        media/lua/shared/Translate/{EN,PTBR}/UI_{EN,PTBR}.txt
// Edit here, then `npm run gen`, then `npm test` (balance formula lives in tools/balance.js).
//
// Profession fields
//   id       B42 registry id suffix (krjobs:<id>) and translation key suffix
//   b41      B41 ProfessionFactory type (the 7 v1 professions keep their v1 type for save compat)
//   b42only  not shipped in B41 (needs B42-only skills)
//   icon42 / icon41  texture name: 'profession_krjobs_*' = our file in media/textures, else vanilla icon
//   cost     B42 Cost (cost41 overrides for B41 when the B41 skill set changes the value)
//   xp       B42 XPBoosts (xp41 overrides for B41)
//   traits   our profession traits (ids in TRAITS); vtraits42 / vtraits41 = vanilla profession traits granted
// Trait fields
//   b41      B41 TraitFactory type
//   xp / xp41, recipes42 / recipes41 (must be learnable vanilla recipes), kit / kit41 (starting items, Lua)
//   en/pt: name + desc (desc41 overrides when B41 recipes/kit differ). XP boosts are appended by the game.

const P = (id, o) => Object.assign({ id }, o);

const PROFESSIONS = [
  // ---------------- v1 professions, renamed and rebalanced ----------------
  P('hitman', {
    b41: 'Hitman', icon42: 'profession_krjobs_hitman', icon41: 'profession_krjobs_hitman', cost: -6,
    xp: { Aiming: 2, SmallBlade: 2, Sneak: 1, Lightfoot: 1 }, traits: ['coldblooded'],
    en: { name: 'Hitman', desc: 'A quiet professional of the early 90s underworld. Close and silent work.' },
    pt: { name: 'Matador de Aluguel', desc: 'Um profissional silencioso do submundo dos anos 90. Trabalho de perto e sem barulho.' },
  }),
  P('architect', {
    b41: 'Architect', icon42: 'profession_krjobs_architect', icon41: 'profession_krjobs_architect', cost: -2, cost41: 0,
    xp: { Woodwork: 3, Masonry: 2 }, xp41: { Woodwork: 3, Maintenance: 1 }, traits: ['draftsman'],
    en: { name: 'Architect', desc: 'Designed houses and offices around Louisville. Knows how a building stands up.' },
    pt: { name: 'Arquiteto', desc: 'Projetava casas e escritórios em Louisville. Sabe como um prédio fica de pé.' },
  }),
  P('ironworker', {
    b41: 'blacksmith', icon42: 'profession_krjobs_ironworker', icon41: 'profession_krjobs_ironworker', cost: -2,
    xp: { MetalWelding: 2, Blacksmith: 1, Strength: 1 }, xp41: { MetalWelding: 3, Strength: 1 }, traits: ['forgehand'],
    en: { name: 'Ornamental Ironworker', desc: 'Welded gates, railings and fire escapes. Half welder, half smith.' },
    pt: { name: 'Serralheiro', desc: 'Soldava portões, grades e escadas de incêndio. Meio soldador, meio ferreiro.' },
  }),
  P('survivalist', {
    b41: 'Survivalist', icon42: 'profession_krjobs_survivalist', icon41: 'profession_krjobs_survivalist', cost: -2,
    xp: { PlantScavenging: 2, Trapping: 2, Fishing: 1, FlintKnapping: 1 }, xp41: { PlantScavenging: 2, Trapping: 2, Fishing: 1, Lightfoot: 1 },
    traits: ['bushcraft'],
    en: { name: 'Survivalist', desc: 'Wilderness survival instructor. Spent more nights in the woods than at home.' },
    pt: { name: 'Sobrevivencialista', desc: 'Instrutor de sobrevivência na selva. Passou mais noites no mato do que em casa.' },
  }),
  P('hotrodder', {
    b41: 'Car Modifier', icon42: 'profession_krjobs_hotrodder', icon41: 'profession_krjobs_hotrodder', cost: -4,
    xp: { Mechanics: 3, MetalWelding: 1, Electricity: 1 }, traits: ['gearhead'], vtraits42: ['base:mechanics2'], vtraits41: ['Mechanics2'],
    en: { name: 'Hot Rod Builder', desc: 'Rebuilt muscle cars in a garage full of chrome and grease.' },
    pt: { name: 'Preparador de Carros', desc: 'Reconstruía carros envenenados numa garagem cheia de cromo e graxa.' },
  }),
  P('mailcarrier', {
    b41: 'Mailman', icon42: 'profession_krjobs_mailcarrier', icon41: 'profession_krjobs_mailcarrier', cost: -2,
    xp: { Fitness: 1, Sprinting: 2, Lightfoot: 1 }, traits: ['routeknowledge'],
    en: { name: 'Rural Mail Carrier', desc: 'Walked a long rural route every day, dogs included.' },
    pt: { name: 'Carteiro Rural', desc: 'Percorria a pé uma longa rota rural todos os dias, cachorros inclusos.' },
  }),
  P('boxer', {
    b41: 'Fighter', icon42: 'profession_krjobs_boxer', icon41: 'profession_krjobs_boxer', cost: -6,
    xp: { Fitness: 2, Strength: 2, SmallBlunt: 1 }, traits: ['ringconditioning'],
    en: { name: 'Amateur Boxer', desc: 'Golden Gloves regular. Hits hard and keeps moving.' },
    pt: { name: 'Boxeador Amador', desc: 'Figurinha carimbada do Golden Gloves. Bate forte e não para de se mexer.' },
  }),

  // ---------------- required new professions ----------------
  P('diver', {
    b41: 'KRjobs_Diver', icon42: 'profession_fisher2', icon41: 'profession_fisher2', cost: -2,
    xp: { Fitness: 2, Strength: 1, Doctor: 1, Fishing: 1 }, traits: ['rescueswimmer'],
    en: { name: 'Navy Rescue Diver', desc: 'Pulled sailors and pilots out of cold water for the US Navy.' },
    pt: { name: 'Mergulhador de Resgate', desc: 'Tirava marinheiros e pilotos da água gelada pela Marinha dos EUA.' },
  }),
  P('navyseal', {
    b41: 'KRjobs_NavySEAL', icon42: 'profession_veteran2', icon41: 'profession_veteran2', cost: -8,
    xp: { Aiming: 2, Fitness: 2, Sneak: 1, SmallBlade: 1 }, traits: ['hellweek'],
    en: { name: 'Navy SEAL', desc: 'Special warfare operator, back home on leave when it all started.' },
    pt: { name: 'Navy SEAL', desc: 'Operador de forças especiais, de licença em casa quando tudo começou.' },
  }),
  P('fighterpilot', {
    b41: 'KRjobs_FighterPilot', icon42: 'profession_veteran2', icon41: 'profession_veteran2', cost: -4,
    xp: { Aiming: 1, Mechanics: 1, Electricity: 1, Fitness: 1 }, traits: ['sere'],
    en: { name: 'Fighter Pilot', desc: 'Flew F-16s out of an Air National Guard base. Knows systems and survival.' },
    pt: { name: 'Piloto de Caça', desc: 'Pilotava F-16 numa base da Guarda Aérea Nacional. Entende de sistemas e de sobrevivência.' },
  }),
  P('rangeinstructor', {
    b41: 'KRjobs_RangeInstructor', icon42: 'profession_krjobs_hitman', icon41: 'profession_krjobs_hitman', cost: -4,
    xp: { Aiming: 3, Reloading: 2, Maintenance: 1 }, traits: ['rangemaster'],
    en: { name: 'Firearms Instructor', desc: 'Ran a shooting range and taught concealed carry classes.' },
    pt: { name: 'Instrutor de Tiro', desc: 'Administrava um estande de tiro e dava aulas de porte de arma.' },
  }),
  P('surgeon', {
    b41: 'KRjobs_Surgeon', icon42: 'profession_doctor2', icon41: 'profession_doctor2', cost: -2,
    xp: { Doctor: 6, SmallBlade: 1 }, traits: ['steadyhands'],
    en: { name: 'Specialist Surgeon', desc: 'Trauma surgeon at a Louisville hospital. Precise hands, long shifts.' },
    pt: { name: 'Cirurgião Especialista', desc: 'Cirurgião de trauma num hospital de Louisville. Mãos precisas, plantões longos.' },
  }),
  P('sysanalyst', {
    b41: 'KRjobs_SystemsAnalyst', icon42: 'profession_electrician', icon41: 'profession_electrician', cost: -2,
    xp: { Electricity: 3, Maintenance: 1 }, traits: ['hardwaretinkerer'], vtraits42: ['base:nightowl'], vtraits41: ['NightOwl'],
    en: { name: 'Systems Analyst', desc: 'Kept a mainframe and a room of 486 PCs running, mostly at night.' },
    pt: { name: 'Analista de Sistemas', desc: 'Mantinha um mainframe e uma sala de PCs 486 funcionando, quase sempre de madrugada.' },
  }),
  P('chemengineer', {
    b41: 'KRjobs_ChemicalEngineer', icon42: 'profession_engineer', icon41: 'profession_engineer', cost: -2, cost41: 0,
    xp: { Electricity: 1, Doctor: 1, Farming: 1, Cooking: 1 }, traits: ['appliedchemistry'],
    en: { name: 'Chemical Engineer', desc: 'Process engineer at a chemical plant on the Ohio River.' },
    pt: { name: 'Engenheiro Químico', desc: 'Engenheiro de processos numa indústria química às margens do rio Ohio.' },
  }),
  P('roboticsengineer', {
    b41: 'KRjobs_RoboticsEngineer', icon42: 'profession_mechanic', icon41: 'profession_mechanic', cost: -2,
    xp: { Electricity: 2, Mechanics: 1, MetalWelding: 1 }, traits: ['servotech'],
    en: { name: 'Robotics Engineer', desc: 'Programmed and repaired welding robots on an auto assembly line.' },
    pt: { name: 'Engenheiro de Robótica', desc: 'Programava e consertava robôs de solda numa linha de montagem de carros.' },
  }),

  // ---------------- obscure-but-real 90s professions ----------------
  P('bombtech', {
    b41: 'KRjobs_BombTech', icon42: 'profession_engineer', icon41: 'profession_engineer', cost: -2,
    xp: { Electricity: 2, Nimble: 1, Lightfoot: 1 }, traits: ['eodtraining'],
    en: { name: 'Bomb Disposal Technician', desc: 'State police bomb squad. Slow hands, slower heartbeat.' },
    pt: { name: 'Técnico Antibombas', desc: 'Esquadrão antibombas da polícia estadual. Mãos lentas, coração mais lento ainda.' },
  }),
  P('smokejumper', {
    b41: 'KRjobs_Smokejumper', icon42: 'profession_fireofficer2', icon41: 'profession_fireofficer2', cost: -2,
    xp: { Fitness: 2, Axe: 1, Strength: 1, PlantScavenging: 1 }, traits: ['firelinecrew'],
    en: { name: 'Smokejumper', desc: 'Parachuted into forest fires out West every summer.' },
    pt: { name: 'Bombeiro Paraquedista', desc: 'Saltava de paraquedas em incêndios florestais no Oeste todo verão.' },
  }),
  P('farrier', {
    b42only: true, icon42: 'profession_smither', cost: -2,
    xp: { Blacksmith: 2, Husbandry: 2, Strength: 1 }, traits: ['hoofandanvil'],
    en: { name: 'Farrier', desc: 'Shod horses on the Kentucky horse farms. Anvil in the truck bed.' },
    pt: { name: 'Ferrador', desc: 'Ferrava cavalos nos haras do Kentucky. Bigorna na caçamba da caminhonete.' },
  }),
  P('glassblower', {
    b42only: true, icon42: 'profession_smither', cost: 0,
    xp: { Glassmaking: 3, Pottery: 1, Maintenance: 1 }, traits: ['glassworks'],
    en: { name: 'Glassblower', desc: 'Ran a small art-glass studio selling vases to tourists.' },
    pt: { name: 'Soprador de Vidro', desc: 'Tinha um pequeno ateliê de vidro artístico e vendia vasos para turistas.' },
  }),
  P('roughneck', {
    b41: 'KRjobs_Roughneck', icon42: 'profession_constructionworker2', icon41: 'profession_constructionworker2', cost: -2,
    xp: { Strength: 2, Mechanics: 1, MetalWelding: 1, Maintenance: 1 }, traits: ['righand'],
    en: { name: 'Oil Rig Roughneck', desc: 'Two weeks on a Gulf of Mexico rig, two weeks home.' },
    pt: { name: 'Peão de Plataforma', desc: 'Duas semanas numa plataforma de petróleo no Golfo do México, duas em casa.' },
  }),
  P('taxidermist', {
    b42only: true, icon42: 'profession_rancher', cost: 0,
    xp: { Butchering: 3, Tailoring: 2, Carving: 1 }, traits: ['specimenmounting'],
    en: { name: 'Taxidermist', desc: 'Mounted deer heads and bass for every hunter in the county.' },
    pt: { name: 'Taxidermista', desc: 'Empalhava cabeças de cervo e peixes para todos os caçadores do condado.' },
  }),
  P('lineman', {
    b41: 'KRjobs_Lineman', icon42: 'profession_electrician', icon41: 'profession_electrician', cost: -4,
    xp: { Electricity: 3, Fitness: 1, Strength: 1 }, traits: ['highvoltage'],
    en: { name: 'Power Lineman', desc: 'Climbed poles in ice storms to keep the county lit.' },
    pt: { name: 'Eletricista de Rede', desc: 'Subia em postes durante tempestades de gelo para manter o condado com luz.' },
  }),
  P('locksmith', {
    b41: 'KRjobs_Locksmith', icon42: 'profession_burglar2', icon41: 'profession_burglar2', cost: 0,
    xp: { Nimble: 1, MetalWelding: 1, Maintenance: 1, Woodwork: 1 }, traits: ['keycutter'],
    en: { name: 'Locksmith', desc: 'Cut keys and rekeyed locks from a small shop downtown.' },
    pt: { name: 'Chaveiro', desc: 'Copiava chaves e trocava segredos de fechaduras numa lojinha no centro.' },
  }),
  P('archaeologist', {
    b42only: true, icon42: 'profession_parkranger2', cost: 0,
    xp: { FlintKnapping: 2, Carving: 1, Masonry: 1, PlantScavenging: 1 }, traits: ['experimentalarch'],
    en: { name: 'Field Archaeologist', desc: 'Dug up Native American sites along the Ohio Valley.' },
    pt: { name: 'Arqueólogo de Campo', desc: 'Escavava sítios indígenas ao longo do vale do rio Ohio.' },
  }),
];

const T = (id, o) => Object.assign({ id, xp: {}, recipes42: [], recipes41: [], kit: [] }, o);

const TRAITS = [
  T('coldblooded', {
    b41: 'KRjobs_ColdBlooded', xp: { Reloading: 1 },
    en: { name: 'Cold-Blooded', desc: 'Calm under pressure, reloads without thinking.' },
    pt: { name: 'Sangue-Frio', desc: 'Calmo sob pressão, recarrega sem pensar.' },
  }),
  T('draftsman', {
    b41: 'KRjobs_Draftsman', xp: { Electricity: 1, Carving: 1 }, xp41: { Electricity: 1 }, kit: ['Base.Pencil', 'Base.Notebook'],
    en: { name: 'Draftsman', desc: 'Reads blueprints, wiring diagrams and wood grain.<br>Starts with: pencil, notebook.' },
    pt: { name: 'Desenhista Técnico', desc: 'Lê plantas, diagramas elétricos e veios de madeira.<br>Começa com: lápis, caderno.' },
  }),
  T('forgehand', {
    b41: 'KRjobs_ForgeHand',
    recipes42: ['Forge_Hinge', 'Forge_Buckle', 'Forge_Nails', 'Forge_Lantern', 'Forge_Tongs'],
    recipes41: ['Make Metal Sheet', 'Make Small Metal Sheet'], kit: ['Base.WeldingMask'],
    en: { name: 'Forge Hand', desc: 'Knows how to forge: hinges, buckles, nails, lanterns, tongs.<br>Starts with: welder mask.' },
    pt: { name: 'Mão de Forja', desc: 'Sabe forjar: dobradiças, fivelas, pregos, lanternas, tenazes.<br>Começa com: máscara de solda.' },
    en41: { desc: 'Knows how to make metal sheets and small metal sheets.<br>Starts with: welder mask.' },
    pt41: { desc: 'Sabe fazer chapas de metal e chapas pequenas de metal.<br>Começa com: máscara de solda.' },
  }),
  T('bushcraft', {
    b41: 'KRjobs_Bushcraft', xp: { Tracking: 1, Carving: 1 }, xp41: {},
    recipes42: ['MakeStickTrap', 'MakeSnareTrap', 'MakeTrapBox', 'MakeCageTrap', 'MakeWoodenBoxTrap'],
    recipes41: ['Make Stick Trap', 'Make Snare Trap', 'Make Wooden Cage Trap', 'Make Trap Box', 'Make Cage Trap'],
    en: { name: 'Bushcraft', desc: 'Knows how to build every kind of trap: stick, snare, trap box, cage and wooden box traps.' },
    pt: { name: 'Técnicas de Mato', desc: 'Sabe montar todo tipo de armadilha: de graveto, laço, caixa, gaiola e caixa de madeira.' },
  }),
  T('gearhead', {
    b41: 'KRjobs_Gearhead', kit: ['Base.Wrench', 'Base.Screwdriver'],
    en: { name: 'Gearhead', desc: 'Never leaves home without tools.<br>Starts with: wrench, screwdriver.' },
    pt: { name: 'Fanático por Motores', desc: 'Nunca sai de casa sem ferramentas.<br>Começa com: chave inglesa, chave de fenda.' },
  }),
  T('routeknowledge', {
    b41: 'KRjobs_RouteKnowledge', xp: { PlantScavenging: 1 }, kit: ['Base.Bag_Satchel'],
    en: { name: 'Knows the Route', desc: 'Knows every backyard, shortcut and berry bush on the way.<br>Starts with: satchel.' },
    pt: { name: 'Conhece a Rota', desc: 'Conhece cada quintal, atalho e pé de fruta do caminho.<br>Começa com: bolsa a tiracolo.' },
  }),
  T('ringconditioning', {
    b41: 'KRjobs_RingConditioning', xp: { Sprinting: 1, Nimble: 1 },
    en: { name: 'Ring Conditioning', desc: 'Roadwork every morning and footwork every night.' },
    pt: { name: 'Condicionamento de Ringue', desc: 'Corrida toda manhã e trabalho de pés toda noite.' },
  }),
  T('rescueswimmer', {
    b41: 'KRjobs_RescueSwimmer', xp: { Doctor: 1 }, kit: ['Base.Glasses_SwimmingGoggles', 'Base.Rope'],
    en: { name: 'Rescue Swimmer', desc: 'Trained to stabilize victims in the water.<br>Starts with: swimming goggles, rope.' },
    pt: { name: 'Nadador de Resgate', desc: 'Treinado para estabilizar vítimas dentro da água.<br>Começa com: óculos de natação, corda.' },
  }),
  T('hellweek', {
    b41: 'KRjobs_HellWeek', xp: { Reloading: 1 }, kit: ['Base.HuntingKnife'],
    en: { name: 'Hell Week Graduate', desc: 'Survived the hardest week of BUD/S training.<br>Starts with: hunting knife.' },
    pt: { name: 'Sobrevivente da Semana do Inferno', desc: 'Sobreviveu à semana mais dura do treinamento BUD/S.<br>Começa com: faca de caça.' },
  }),
  T('sere', {
    b41: 'KRjobs_SERE', xp: { PlantScavenging: 1, Trapping: 1 },
    recipes42: ['MakeStickTrap', 'MakeSnareTrap'], recipes41: ['Make Stick Trap', 'Make Snare Trap'],
    en: { name: 'SERE Training', desc: 'Survival, Evasion, Resistance and Escape school.<br>Knows how to make stick traps and snare traps.' },
    pt: { name: 'Treinamento SERE', desc: 'Escola de Sobrevivência, Evasão, Resistência e Fuga.<br>Sabe fazer armadilhas de graveto e de laço.' },
  }),
  T('rangemaster', {
    b41: 'KRjobs_RangeMaster', kit: ['Base.Hat_EarMuff_Protectors', 'Base.Glasses_Shooting'],
    en: { name: 'Range Master', desc: 'Safety first, every single time.<br>Starts with: ear protectors, shooting glasses.' },
    pt: { name: 'Mestre de Estande', desc: 'Segurança em primeiro lugar, sempre.<br>Começa com: protetor auricular, óculos de tiro.' },
  }),
  T('steadyhands', {
    b41: 'KRjobs_SteadyHands', xp: { Tailoring: 1 }, kit: ['Base.Scalpel', 'Base.Tweezers', 'Base.SutureNeedleHolder'],
    en: { name: 'Steady Hands', desc: 'Sutures as neat as embroidery.<br>Starts with: scalpel, tweezers, suture needle holder.' },
    pt: { name: 'Mãos Firmes', desc: 'Suturas caprichadas como bordado.<br>Começa com: bisturi, pinça, porta-agulha.' },
  }),
  T('hardwaretinkerer', {
    b41: 'KRjobs_HardwareTinkerer', kit: ['Base.Screwdriver'],
    recipes42: ['CraftMakeshiftRadio', 'CraftMakeshiftWalkieTalkie', 'CraftMakeshiftHAMRadio', 'MakeImprovisedFlashlight', 'MakeImprovisedLantern'],
    recipes41: ['Craft Makeshift Radio', 'Craft Makeshift Walkie Talkie', 'Craft Makeshift HAM Radio'],
    en: { name: 'Hardware Tinkerer', desc: 'Knows how to make: makeshift radios, walkie-talkies, HAM radios, improvised flashlights and lanterns.<br>Starts with: screwdriver.' },
    pt: { name: 'Fuçador de Hardware', desc: 'Sabe fazer: rádios improvisados, walkie-talkies, rádios amadores, lanternas improvisadas e lampiões.<br>Começa com: chave de fenda.' },
    en41: { desc: 'Knows how to make: makeshift radios, walkie-talkies and HAM radios.<br>Starts with: screwdriver.' },
    pt41: { desc: 'Sabe fazer: rádios improvisados, walkie-talkies e rádios amadores.<br>Começa com: chave de fenda.' },
  }),
  T('appliedchemistry', {
    b41: 'KRjobs_AppliedChemistry', xp: { Glassmaking: 1 }, xp41: {},
    recipes42: ['MakeAerosolBomb', 'MakeFlameBomb', 'MakeSmokeBomb', 'MakeMildewCure', 'MakeAphidsCure', 'MakeFliesCureFromCigarettes',
      'MakeFliesCureFromLooseTobacco', 'MakeFliesCureFromChewingTobacco', 'MakeCraftedGasMaskFilter', 'RechargeFilters'],
    recipes41: ['Make Aerosol bomb', 'Make Flame bomb', 'Make Smoke Bomb', 'Make Mildew Cure', 'Make Flies Cure'],
    en: { name: 'Applied Chemistry', desc: 'Knows how to make: aerosol, flame and smoke bombs, crop sprays (mildew, aphids, flies), gas mask filters.' },
    pt: { name: 'Química Aplicada', desc: 'Sabe fazer: bombas de aerossol, incendiárias e de fumaça, defensivos agrícolas (míldio, pulgões, moscas), filtros de máscara de gás.' },
    en41: { desc: 'Knows how to make: aerosol, flame and smoke bombs, mildew and flies cures.' },
    pt41: { desc: 'Sabe fazer: bombas de aerossol, incendiárias e de fumaça, remédios contra míldio e moscas.' },
  }),
  T('servotech', {
    b41: 'KRjobs_ServoTech', kit: ['Base.Screwdriver'],
    recipes42: ['MakeRemoteControllerV1', 'MakeRemoteControllerV2', 'MakeRemoteControllerV3', 'MakeRemoteTrigger', 'MakeTimer'],
    recipes41: ['Make Remote Controller V1', 'Make Remote Controller V2', 'Make Remote Controller V3', 'Make Remote Trigger', 'Make Timer'],
    en: { name: 'Servo Technician', desc: 'Knows how to make: remote controllers V1 to V3, remote triggers, timers.<br>Starts with: screwdriver.' },
    pt: { name: 'Técnico em Servomecanismos', desc: 'Sabe fazer: controles remotos V1 a V3, gatilhos remotos, temporizadores.<br>Começa com: chave de fenda.' },
  }),
  T('eodtraining', {
    b41: 'KRjobs_EODTraining',
    recipes42: ['MakePipeBomb', 'AddTimerToBomb', 'AddCraftedTriggerToBomb', 'AddMotionSensorV1ToBomb', 'MakeNoiseMaker'],
    recipes41: ['Make Pipe bomb', 'Make Timer', 'Make Remote Trigger'],
    en: { name: 'EOD Training', desc: 'Knows how to make: pipe bombs, noise makers; how to add timers, triggers and motion sensors to bombs.' },
    pt: { name: 'Treinamento EOD', desc: 'Sabe fazer: bombas caseiras, geradores de ruído; e como acoplar temporizadores, gatilhos e sensores de movimento a bombas.' },
    en41: { desc: 'Knows how to make: pipe bombs, timers, remote triggers.' },
    pt41: { desc: 'Sabe fazer: bombas caseiras, temporizadores, gatilhos remotos.' },
  }),
  T('firelinecrew', {
    b41: 'KRjobs_FirelineCrew', kit: ['Base.HandAxe'],
    en: { name: 'Fireline Crew', desc: 'Cut firebreaks for days with little sleep.<br>Starts with: hand axe.' },
    pt: { name: 'Equipe de Aceiro', desc: 'Abria aceiros por dias quase sem dormir.<br>Começa com: machadinha.' },
  }),
  T('hoofandanvil', {
    b41: 'KRjobs_HoofAndAnvil',
    recipes42: ['Forge_Nails', 'Forge_Tongs', 'Forge_File', 'Forge_Smithing_Hammer_Head', 'Forge_Metalworking_Punch'],
    en: { name: 'Hoof and Anvil', desc: 'Knows how to forge: nails, tongs, files, smithing hammer heads, metalworking punches.' },
    pt: { name: 'Casco e Bigorna', desc: 'Sabe forjar: pregos, tenazes, limas, cabeças de martelo de ferreiro, punções.' },
  }),
  T('glassworks', {
    b41: 'KRjobs_Glassworks',
    recipes42: ['MakeGlassBottle', 'MakeDrinkingGlass', 'MakeGlassJar', 'MakeMirror', 'MakeWineGlass', 'MakeLanternGlass', 'MakeChampagneGlass'],
    en: { name: 'Studio Glassworks', desc: 'Knows how to make: glass bottles, drinking glasses, jars, mirrors, wine and champagne glasses, lantern glass.' },
    pt: { name: 'Ateliê de Vidro', desc: 'Sabe fazer: garrafas, copos, potes de vidro, espelhos, taças de vinho e de champanhe, vidro de lampião.' },
  }),
  T('righand', {
    b41: 'KRjobs_RigHand', kit: ['Base.PipeWrench', 'Base.Hat_HardHat'],
    en: { name: 'Rig Hand', desc: 'Used to heavy pipe and long shifts.<br>Starts with: pipe wrench, hard hat.' },
    pt: { name: 'Braço de Sonda', desc: 'Acostumado com cano pesado e turnos longos.<br>Começa com: chave de cano, capacete de obra.' },
  }),
  T('specimenmounting', {
    b41: 'KRjobs_SpecimenMounting', kit: ['Base.Scalpel'],
    recipes42: ['MakeStagHeadTrophy', 'MakeBoneAwl', 'MakeBoneSewingNeedle', 'SewHideWallet', 'SewHideHat'],
    en: { name: 'Specimen Mounting', desc: 'Knows how to make: stag head trophies, bone awls, bone sewing needles, hide wallets and hats.<br>Starts with: scalpel.' },
    pt: { name: 'Montagem de Espécimes', desc: 'Sabe fazer: troféus de cabeça de cervo, furadores e agulhas de osso, carteiras e chapéus de couro cru.<br>Começa com: bisturi.' },
  }),
  T('highvoltage', {
    b41: 'KRjobs_HighVoltage', kit: ['Base.Gloves_LeatherGloves', 'Base.Hat_HardHat'],
    en: { name: 'High-Voltage Safety', desc: 'Never touches a line without gloves.<br>Starts with: leather gloves, hard hat.' },
    pt: { name: 'Segurança em Alta Tensão', desc: 'Nunca encosta numa linha sem luvas.<br>Começa com: luvas de couro, capacete de obra.' },
  }),
  T('keycutter', {
    b41: 'KRjobs_KeyCutter', kit: ['Base.Screwdriver'], recipes42: ['CopyBuildingKey'],
    en: { name: 'Key Cutter', desc: 'Knows how to copy building keys.<br>Starts with: screwdriver.' },
    pt: { name: 'Copiador de Chaves', desc: 'Sabe copiar chaves de imóveis.<br>Começa com: chave de fenda.' },
    en41: { desc: 'Takes doors and locks apart for a living.<br>Starts with: screwdriver.' },
    pt41: { desc: 'Desmonta portas e fechaduras para ganhar a vida.<br>Começa com: chave de fenda.' },
  }),
  T('experimentalarch', {
    b41: 'KRjobs_ExperimentalArch', xp: { Tracking: 1 },
    recipes42: ['MakeStoneBlade', 'MakeStoneChisel', 'MakeStoneBladeSaw', 'MakeLargeStoneAxeHead', 'MakeStoneDrill'],
    en: { name: 'Experimental Archaeology', desc: 'Knows how to make: stone blades, chisels, blade saws, large axe heads and drills.' },
    pt: { name: 'Arqueologia Experimental', desc: 'Sabe fazer: lâminas, cinzéis, serras, cabeças de machado grandes e brocas de pedra.' },
  }),
];

const MOD = {
  id: 'Krjobs', workshopId: '3149644183', version: '2.0.0',
  en: { name: 'KRjobs v2', description: "24 uncommon 1990s professions on B42 and 20 on B41, with skill bonuses, profession traits, vanilla recipes and small starting kits. Includes rescue diver, fighter pilot, specialist surgeon, systems analyst and chemical engineer. PT-BR + EN." },
  pt: { name: 'KRjobs v2', description: "24 profissões incomuns dos anos 90 na B42 e 20 na B41, com bônus de habilidades, traços profissionais, receitas vanilla e pequenos kits iniciais. Inclui mergulhador de resgate, piloto de caça, cirurgião especialista, analista de sistemas e engenheiro químico. PT-BR + EN." },
};

module.exports = { PROFESSIONS, TRAITS, MOD };
