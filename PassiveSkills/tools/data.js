// Single source of truth for Passive Skills v2 content.
// tools/gen.js turns this into: Catalog.lua (B41 + B42 copies), item scripts, sandbox options and
// every translation file (B42 JSON + B41 TXT). Edit here, then run `npm run gen`.
//
// id     = item name prefix (Base.Magazine<id>_<tier>) AND read-once key prefix. Kept from v1 for save compat.
// perk   = Perks.<perk> (verified against vanilla 42.19.2 Lua; B41 list in tests/fixtures/perks_b41.json).
// b41    = also shipped in the Build 41 build (perk exists in B41).
// en/pt  = skill display name (matches the vanilla IGUI_perks_* wording where vanilla has one).
// en41   = optional B41-only English name (vanilla B41 calls MetalWelding "Metalworking").
const SKILLS = [
  // ---- v1 skills (Welding removed: it duplicated MetalWelding, kept only as legacy alias below) ----
  { id: 'Woodwork', perk: 'Woodwork', b41: true, en: 'Carpentry', pt: 'Carpintaria' },
  { id: 'Cooking', perk: 'Cooking', b41: true, en: 'Cooking', pt: 'Culinária' },
  { id: 'Agriculture', perk: 'Farming', b41: true, en: 'Agriculture', pt: 'Agricultura' },
  { id: 'Doctor', perk: 'Doctor', b41: true, en: 'First Aid', pt: 'Primeiros Socorros' },
  { id: 'Electrical', perk: 'Electricity', b41: true, en: 'Electrical', pt: 'Elétrica' },
  { id: 'MetalWelding', perk: 'MetalWelding', b41: true, en: 'Welding', en41: 'Metalworking', pt: 'Metalurgia' },
  { id: 'Mechanics', perk: 'Mechanics', b41: true, en: 'Mechanics', pt: 'Mecânica' },
  { id: 'Tailoring', perk: 'Tailoring', b41: true, en: 'Tailoring', pt: 'Costura' },
  { id: 'Fishing', perk: 'Fishing', b41: true, en: 'Fishing', pt: 'Pescaria' },
  { id: 'AnimalCare', perk: 'Husbandry', b41: false, en: 'Animal Care', pt: 'Cuidado com Animais' },
  { id: 'Carving', perk: 'Carving', b41: false, en: 'Carving', pt: 'Entalhe' },
  { id: 'Knapping', perk: 'FlintKnapping', b41: false, en: 'Knapping', pt: 'Lascamento' },
  { id: 'Pottery', perk: 'Pottery', b41: false, en: 'Pottery', pt: 'Cerâmica' },
  { id: 'Tracking', perk: 'Tracking', b41: false, en: 'Tracking', pt: 'Rastreamento' },
  { id: 'Trapping', perk: 'Trapping', b41: true, en: 'Trapping', pt: 'Caça' },
  { id: 'Foraging', perk: 'PlantScavenging', b41: true, en: 'Foraging', pt: 'Coleta' },
  { id: 'Maintenance', perk: 'Maintenance', b41: true, en: 'Maintenance', pt: 'Manutenção' },
  { id: 'Aiming', perk: 'Aiming', b41: true, en: 'Aiming', pt: 'Mira' },
  { id: 'Reloading', perk: 'Reloading', b41: true, en: 'Reloading', pt: 'Recarga' },
  { id: 'Sneaking', perk: 'Sneak', b41: true, en: 'Sneaking', pt: 'Furtividade' },
  // ---- v2 new skills (Fitness/Strength deliberately excluded) ----
  { id: 'LongBlunt', perk: 'Blunt', b41: true, en: 'Long Blunt', pt: 'Contundentes Longos' },
  { id: 'Axe', perk: 'Axe', b41: true, en: 'Axe', pt: 'Machados' },
  { id: 'LongBlade', perk: 'LongBlade', b41: true, en: 'Long Blade', pt: 'Lâminas Longas' },
  { id: 'ShortBlade', perk: 'SmallBlade', b41: true, en: 'Short Blade', pt: 'Lâminas Curtas' },
  { id: 'Spear', perk: 'Spear', b41: true, en: 'Spear', pt: 'Lanças' },
  { id: 'ShortBlunt', perk: 'SmallBlunt', b41: true, en: 'Short Blunt', pt: 'Contundentes Curtos' },
  { id: 'Masonry', perk: 'Masonry', b41: false, en: 'Masonry', pt: 'Alvenaria' },
  { id: 'Blacksmith', perk: 'Blacksmith', b41: false, en: 'Blacksmithing', pt: 'Forja' },
  { id: 'Glassmaking', perk: 'Glassmaking', b41: false, en: 'Glassmaking', pt: 'Vidraria' },
  { id: 'Butchering', perk: 'Butchering', b41: false, en: 'Butchering', pt: 'Açougue' },
  { id: 'Nimble', perk: 'Nimble', b41: true, en: 'Nimble', pt: 'Agilidade' },
  { id: 'Lightfoot', perk: 'Lightfoot', b41: true, en: 'Lightfooted', pt: 'Discrição' },
  { id: 'Running', perk: 'Sprinting', b41: true, en: 'Running', pt: 'Corrida' },
];

// v1 items that still exist in old saves. Defined (so they don't vanish) but never spawned;
// reading one counts as reading the target skill's volume (shared read-once key).
const LEGACY = [{ id: 'Welding', aliasOf: 'MetalWelding', b41: true }];

const TIERS = ['one', 'two', 'three', 'four', 'five'];
const TIER_XP = [75, 150, 300, 750, 1500]; // = vanilla XP for levels 1..5 -> sum 2775 = exactly level 5
const TIER_WEIGHTS = [40, 25, 18, 11, 6]; // spawn: lower volumes more common (sum 100)
const TIER_PAGES = [10, 15, 20, 25, 30]; // x MinutesPerPage (default 2) -> 20..60 in-game minutes

const UI = {
  EN: {
    modName: 'Passive Skills v2',
    modDesc: "Skill magazines in five volumes. Each character learns once per volume and comments on the reading. All five grant 2775 XP at default settings. Eligible containers have a 12% chance of receiving a magazine. XP and spawn chance are configurable. 33 skills on B42 and 24 on B41; PT-BR + EN.",
    item: (skill, n) => `${skill} Magazine Vol. ${n}`,
    learned: 'I read this and learned something about %1.',
    already: "I've already read this one. Nothing new here.",
    halo: '+ %1',
    tooltip: 'Skill magazine (5 volumes per skill). Each character learns from each volume only once.',
    page: 'Passive Skills',
    spawn: 'Skill magazine chance (%)',
    spawnTip: 'Chance that an eligible container (bookshelves, magazine racks, desks, postboxes, libraries, bookstores...) gets one skill magazine when its loot is generated. Lower volumes are more common. 0 = magazines never spawn. Default 12.',
    xp: 'XP per magazine (%)',
    xpTip: '100 = reading the 5 volumes of a skill gives exactly the XP of level 5 (75/150/300/750/1500). Profession, trait and skill-book XP multipliers are ignored, so every character gains the same.',
  },
  PTBR: {
    modName: 'Passive Skills v2',
    modDesc: "Revistas de habilidade em cinco volumes. Cada personagem aprende uma vez por volume e comenta a leitura. Os cinco concedem 2775 XP nas opções padrão. Contêineres elegíveis têm 12% de chance de receber uma revista. XP e chance são configuráveis. 33 habilidades na B42 e 24 na B41; PT-BR + EN.",
    item: (skill, n) => `Revista de ${skill} Vol. ${n}`,
    learned: 'Li isso e aprendi algo sobre %1.',
    already: 'Já li essa revista. Nada de novo aqui.',
    halo: '+ %1',
    tooltip: 'Revista de habilidade (5 volumes por habilidade). Cada personagem aprende com cada volume só uma vez.',
    page: 'Passive Skills',
    spawn: 'Chance de revista de habilidade (%)',
    spawnTip: 'Chance de um contêiner elegível (estantes de livros, expositores de revistas, escrivaninhas, caixas de correio, bibliotecas, livrarias...) receber uma revista de habilidade quando o loot é gerado. Volumes baixos são mais comuns. 0 = revistas nunca aparecem. Padrão 12.',
    xp: 'XP por revista (%)',
    xpTip: '100 = ler os 5 volumes de uma habilidade dá exatamente o XP do nível 5 (75/150/300/750/1500). Multiplicadores de profissão, traços e livros de habilidade são ignorados, então todo personagem ganha o mesmo.',
  },
};

module.exports = { SKILLS, LEGACY, TIERS, TIER_XP, TIER_WEIGHTS, TIER_PAGES, UI };
