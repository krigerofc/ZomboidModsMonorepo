// Single source of truth for Passive Skills v2 content.
// tools/gen.js turns this into: Catalog.lua (B42), item scripts, sandbox options and
// every translation file (B42 JSON). Edit here, then run `npm run gen`.
//
// id     = item name prefix (Base.Magazine<id>_<tier>) AND read-once key prefix. Kept from v1 for save compat.
// perk   = Perks.<perk> (verified against vanilla 42.19.2 Lua).
// en/pt  = skill display name (matches the vanilla IGUI_perks_* wording where vanilla has one).
const SKILLS = [
  // ---- v1 skills (Welding removed: it duplicated MetalWelding, kept only as legacy alias below) ----
  { id: 'Woodwork', perk: 'Woodwork', en: 'Carpentry', pt: 'Carpintaria' },
  { id: 'Cooking', perk: 'Cooking', en: 'Cooking', pt: 'Culinária' },
  { id: 'Agriculture', perk: 'Farming', en: 'Agriculture', pt: 'Agricultura' },
  { id: 'Doctor', perk: 'Doctor', en: 'First Aid', pt: 'Primeiros Socorros' },
  { id: 'Electrical', perk: 'Electricity', en: 'Electrical', pt: 'Elétrica' },
  { id: 'MetalWelding', perk: 'MetalWelding', en: 'Welding', pt: 'Metalurgia' },
  { id: 'Mechanics', perk: 'Mechanics', en: 'Mechanics', pt: 'Mecânica' },
  { id: 'Tailoring', perk: 'Tailoring', en: 'Tailoring', pt: 'Costura' },
  { id: 'Fishing', perk: 'Fishing', en: 'Fishing', pt: 'Pescaria' },
  { id: 'AnimalCare', perk: 'Husbandry', en: 'Animal Care', pt: 'Cuidado com Animais' },
  { id: 'Carving', perk: 'Carving', en: 'Carving', pt: 'Entalhe' },
  { id: 'Knapping', perk: 'FlintKnapping', en: 'Knapping', pt: 'Lascamento' },
  { id: 'Pottery', perk: 'Pottery', en: 'Pottery', pt: 'Cerâmica' },
  { id: 'Tracking', perk: 'Tracking', en: 'Tracking', pt: 'Rastreamento' },
  { id: 'Trapping', perk: 'Trapping', en: 'Trapping', pt: 'Caça' },
  { id: 'Foraging', perk: 'PlantScavenging', en: 'Foraging', pt: 'Coleta' },
  { id: 'Maintenance', perk: 'Maintenance', en: 'Maintenance', pt: 'Manutenção' },
  { id: 'Aiming', perk: 'Aiming', en: 'Aiming', pt: 'Mira' },
  { id: 'Reloading', perk: 'Reloading', en: 'Reloading', pt: 'Recarga' },
  { id: 'Sneaking', perk: 'Sneak', en: 'Sneaking', pt: 'Furtividade' },
  // ---- v2 new skills (Fitness/Strength deliberately excluded) ----
  { id: 'LongBlunt', perk: 'Blunt', en: 'Long Blunt', pt: 'Contundentes Longos' },
  { id: 'Axe', perk: 'Axe', en: 'Axe', pt: 'Machados' },
  { id: 'LongBlade', perk: 'LongBlade', en: 'Long Blade', pt: 'Lâminas Longas' },
  { id: 'ShortBlade', perk: 'SmallBlade', en: 'Short Blade', pt: 'Lâminas Curtas' },
  { id: 'Spear', perk: 'Spear', en: 'Spear', pt: 'Lanças' },
  { id: 'ShortBlunt', perk: 'SmallBlunt', en: 'Short Blunt', pt: 'Contundentes Curtos' },
  { id: 'Masonry', perk: 'Masonry', en: 'Masonry', pt: 'Alvenaria' },
  { id: 'Blacksmith', perk: 'Blacksmith', en: 'Blacksmithing', pt: 'Forja' },
  { id: 'Glassmaking', perk: 'Glassmaking', en: 'Glassmaking', pt: 'Vidraria' },
  { id: 'Butchering', perk: 'Butchering', en: 'Butchering', pt: 'Açougue' },
  { id: 'Nimble', perk: 'Nimble', en: 'Nimble', pt: 'Agilidade' },
  { id: 'Lightfoot', perk: 'Lightfoot', en: 'Lightfooted', pt: 'Discrição' },
  { id: 'Running', perk: 'Sprinting', en: 'Running', pt: 'Corrida' },
];

// v1 items that still exist in old saves. Defined (so they don't vanish) but never spawned;
// reading one counts as reading the target skill's volume (shared read-once key).
const LEGACY = [{ id: 'Welding', aliasOf: 'MetalWelding' }];

const TIERS = ['one', 'two', 'three', 'four', 'five'];
const TIER_XP = [75, 150, 300, 750, 1500]; // = vanilla XP for levels 1..5 -> sum 2775 = exactly level 5
const TIER_WEIGHTS = [40, 25, 18, 11, 6]; // spawn: lower volumes more common (sum 100)
const TIER_PAGES = [10, 15, 20, 25, 30]; // x MinutesPerPage (default 2) -> 20..60 in-game minutes

const UI = {
  EN: {
    modName: 'Passive Skills v2',
    modDesc: "B42 only. 33 skills in five magazine volumes: 2775 fixed XP per skill at defaults; 12% magazine chance. 16 original VHS programs for eight skills play on compatible TVs. Each full tape offers 250 base XP; native XP multipliers and media level cutoff apply. Learn each recorded line once per character. Separate VHS chance (2%) and XP options. PT-BR + EN. Existing v2 magazine read history is preserved. Gameplay and multiplayer validation on 42.21 pending.",
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
    modDesc: "Somente B42. 33 habilidades em cinco volumes de revistas: 2775 XP fixos por habilidade no padrão; chance de revista de 12%. 16 VHS originais para oito habilidades, reproduzidos em TVs compatíveis. Cada fita completa oferece 250 XP base; multiplicadores e limite de nível de mídia do jogo se aplicam. Aprenda cada trecho uma vez por personagem. Opções próprias de chance de VHS (2%) e XP. PT-BR + EN. Histórico de revistas da v2 preservado. Validação no jogo e multiplayer 42.21 pendente.",
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

// Stable original VHS programs. Never rename published IDs or caption keys.
const VHS = [
  ["Woodwork","CRP","SquareStart","The Square Start","O começo no esquadro",[["Set the board on a steady bench and mark its face side before measuring.","Apoie a tábua numa bancada firme e marque a face antes de medir."],["Hook the tape on the same end each time so every mark shares one reference.","Prenda a trena sempre na mesma ponta para usar uma única referência."],["Bring the square against the edge and carry the pencil line across the board.","Encoste o esquadro na borda e prolongue o risco pela largura da tábua."],["Clamp the work securely and keep the saw on the waste side of the line.","Prenda bem a peça e mantenha a serra no lado que será descartado."],["Check both diagonals before fastening a frame; equal lengths help keep it square.","Confira as duas diagonais antes de fixar a moldura; medidas iguais ajudam no esquadro."]]],
  ["Woodwork","CRP","ShelfSunday","Sunday Shelf Workshop","Oficina da prateleira de domingo",[["Plan the shelf around its load and mark the supports before cutting lumber.","Planeje a prateleira conforme a carga e marque os apoios antes de cortar."],["Inspect each board for splits near the ends before choosing a fastening point.","Inspecione rachaduras nas pontas das tábuas antes de escolher onde fixar."],["Drill a pilot hole close to the board end to reduce splitting when driving a screw.","Faça um furo guia perto da ponta para reduzir rachaduras ao colocar o parafuso."],["Use a level while attaching the brackets and verify the fixing surface is sound.","Use o nível ao instalar os suportes e confira se a superfície de fixação é firme."],["Load the finished shelf gradually and watch the brackets for movement.","Coloque a carga aos poucos na prateleira pronta e observe os suportes."]]],
  ["Mechanics","MEC","DrivewayChecks","Driveway Checks with Dale","Revisão na garagem com Dale",[["Park on level ground, stop the engine and let it cool before an inspection.","Estacione em local plano, desligue o motor e deixe esfriar antes da inspeção."],["Read the dipstick after wiping it clean and reinserting it fully.","Limpe a vareta, encaixe até o fim e só então confira o nível do óleo."],["Inspect coolant hoses for cracks and keep the pressure cap closed while hot.","Procure rachaduras nas mangueiras e mantenha a tampa fechada com o sistema quente."],["Compare cold tire pressures with the vehicle specification, including the spare.","Compare a pressão dos pneus frios com a especificação e confira o estepe."],["Record fluid loss or unusual wear so the next inspection can reveal a pattern.","Anote perdas de fluido e desgaste incomum para comparar na próxima revisão."]]],
  ["Mechanics","MEC","WheelRoutine","The Wheel Routine","A rotina das rodas",[["Chock the wheels and identify the correct lifting point before raising the car.","Calce as rodas e identifique o ponto de elevação correto antes de levantar o carro."],["Loosen wheel nuts slightly while the tire still rests on the ground.","Afrouxe um pouco as porcas enquanto o pneu ainda está apoiado no chão."],["Support the vehicle on proper stands; a jack alone is not a working support.","Apoie o veículo em cavaletes adequados; o macaco sozinho não serve de apoio."],["Inspect the removed tire for cuts and uneven wear across the tread.","Examine cortes no pneu retirado e desgaste desigual ao longo da banda."],["Tighten wheel nuts in a crossing pattern to the specified torque, then recheck.","Aperte as porcas em cruz com o torque especificado e faça nova conferência."]]],
  ["Doctor","DOC","FirstMinutes","Community First Aid: First Minutes","Primeiros socorros: primeiros minutos",[["Check that the scene is safe before approaching an injured person.","Confira a segurança do local antes de se aproximar de uma pessoa ferida."],["Call for help and check responsiveness and normal breathing without delay.","Peça ajuda e confira imediatamente a resposta da pessoa e a respiração normal."],["Use clean gloves or a barrier when handling blood or an open wound.","Use luvas limpas ou uma barreira ao lidar com sangue ou feridas abertas."],["Apply firm direct pressure to serious external bleeding with a clean dressing.","Aplique pressão direta firme sobre sangramento externo intenso com um curativo limpo."],["Keep the person warm and watch for changes while waiting for qualified help.","Mantenha a pessoa aquecida e observe mudanças enquanto aguarda ajuda qualificada."]]],
  ["Doctor","DOC","CleanDressings","Community First Aid: Clean Dressings","Primeiros socorros: curativos limpos",[["Wash your hands and prepare clean materials before changing a dressing.","Lave as mãos e prepare materiais limpos antes de trocar um curativo."],["Rinse a minor dirty wound with clean water and avoid rubbing exposed tissue.","Lave uma ferida pequena e suja com água limpa, sem esfregar o tecido exposto."],["Cover the cleaned area with a sterile dressing without touching its wound side.","Cubra a área limpa com curativo estéril sem tocar na face que encosta na ferida."],["Secure the bandage without cutting circulation and check the fingers or toes.","Prenda a faixa sem interromper a circulação e confira os dedos da mão ou do pé."],["Seek medical help for spreading redness, worsening pain, fever or deep wounds.","Procure atendimento para vermelhidão crescente, dor piorando, febre ou feridas profundas."]]],
  ["Electrical","ELC","DeadCircuit","The Dead Circuit Rule","A regra do circuito desligado",[["Identify the circuit and disconnect its supply before opening electrical equipment.","Identifique o circuito e desligue sua alimentação antes de abrir equipamentos elétricos."],["Prevent anyone from restoring power while the work area remains open.","Impeça que outra pessoa religue a energia enquanto a área de trabalho estiver aberta."],["Check the tester on a known source before and after testing for absence of voltage.","Confira o testador numa fonte conhecida antes e depois de verificar a ausência de tensão."],["Replace damaged insulation and use connectors rated for the wire and application.","Troque a isolação danificada e use conectores adequados ao fio e à aplicação."],["Close covers and clear the work area before safely restoring the supply.","Feche as tampas e libere a área de trabalho antes de restabelecer a alimentação."]]],
  ["Electrical","ELC","BenchRadio","Bench Radio: Finding the Fault","Rádio de bancada: encontrando a falha",[["Unplug the radio and follow the service instructions before opening its case.","Desligue o rádio da tomada e siga as instruções de manutenção antes de abrir."],["Sketch the wire connections before removing a part so reassembly has a reference.","Desenhe as conexões dos fios antes de remover peças para orientar a montagem."],["Look for loose connections, scorched components and cracked solder joints.","Procure conexões soltas, componentes queimados e juntas de solda rachadas."],["Use the schematic to trace one section at a time instead of changing random parts.","Use o esquema para examinar uma seção por vez, sem trocar peças ao acaso."],["Check component values and polarity before fitting an approved replacement.","Confira os valores e a polaridade do componente antes de instalar a reposição correta."]]],
  ["MetalWelding","MTL","WeldPrep","Weld Shop: Preparation Pays","Oficina de solda: preparar compensa",[["Clear flammable materials and provide ventilation before setting up the welding area.","Afaste materiais inflamáveis e garanta ventilação antes de preparar a área de solda."],["Wear suitable eye, face and skin protection before striking an arc.","Use proteção adequada para olhos, rosto e pele antes de abrir o arco."],["Clean rust, paint and contamination from the joint using a suitable preparation method.","Remova ferrugem, tinta e contaminação da junta com um método de preparação adequado."],["Fit the parts closely and clamp them so the joint cannot shift while tacking.","Ajuste as peças e prenda com grampos para impedir movimento durante o ponteamento."],["Practice the machine settings on matching scrap before welding the actual assembly.","Pratique os ajustes da máquina numa sobra equivalente antes de soldar a peça final."]]],
  ["MetalWelding","MTL","SteadyBead","Weld Shop: A Steady Bead","Oficina de solda: cordão constante",[["Check the lead connections and select consumables suited to the metal and process.","Confira as conexões e escolha consumíveis adequados ao metal e ao processo."],["Support your working arm so the torch angle stays consistent along the joint.","Apoie o braço para manter constante o ângulo da tocha ao longo da junta."],["Watch the molten pool and maintain a steady travel speed rather than chasing the sparks.","Observe a poça de fusão e mantenha a velocidade, sem acompanhar as faíscas."],["Let the work cool safely before cleaning and inspecting the finished bead.","Deixe a peça esfriar com segurança antes de limpar e inspecionar o cordão."],["Look for cracks, undercut and poor fusion; structural work needs qualified inspection.","Procure trincas, mordeduras e falta de fusão; estruturas exigem inspeção qualificada."]]],
  ["Blacksmith","BLA","ForgeMorning","Morning at the Forge","Manhã na forja",[["Organize the forge, water and clear walking space before heating the first stock.","Organize a forja, a água e a passagem livre antes de aquecer a primeira barra."],["Choose tongs that grip the stock firmly and check the hammer handle for damage.","Escolha uma tenaz que segure a barra e confira se o cabo do martelo está íntegro."],["Heat the working section evenly and keep watching its condition at the fire.","Aqueça a seção de trabalho por igual e acompanhe sua condição no fogo."],["Stand square to the anvil and use controlled blows rather than an oversized hammer.","Posicione-se diante da bigorna e use golpes controlados em vez de um martelo pesado demais."],["Treat every piece near the forge as hot until its temperature is safely confirmed.","Considere quente qualquer peça perto da forja até confirmar sua temperatura com segurança."]]],
  ["Blacksmith","BLA","HookAndEye","Forge Practice: Hook and Eye","Prática de forja: gancho e olhal",[["Mark the length needed for the hook and allow extra stock for the bend.","Marque o comprimento do gancho e reserve material adicional para a curva."],["Draw out the end with overlapping blows and rotate the stock to keep its section even.","Estire a ponta com golpes sobrepostos e gire a barra para manter a seção uniforme."],["Work the bend around the anvil horn in small steps rather than forcing one sharp fold.","Faça a curva no chifre da bigorna aos poucos, sem forçar uma dobra brusca."],["Reheat before the stock becomes too cold to shape without cracking.","Reaqueça antes que a barra esfrie demais para ser moldada sem rachar."],["Check the cooled hook against the pattern and remove sharp burrs from its edges.","Compare o gancho frio ao modelo e remova rebarbas cortantes das bordas."]]],
  ["Masonry","MAS","FirstCourse","Masonry Corner: The First Course","Canto da alvenaria: primeira fiada",[["Start with a sound level base and mark the wall position before mixing mortar.","Comece com uma base firme e nivelada e marque a parede antes de misturar a argamassa."],["Dry lay the first course to plan joints and avoid an awkward final cut.","Disponha a primeira fiada a seco para planejar juntas e evitar um corte final ruim."],["Mix only the mortar you can use within its working time and follow its proportions.","Misture apenas a argamassa que usará no prazo de trabalho e respeite as proporções."],["Set corner units carefully and stretch a line to guide the face of the course.","Assente os blocos dos cantos com cuidado e estique uma linha para guiar a face da fiada."],["Check each unit for level and alignment while the mortar can still be adjusted.","Confira o nível e o alinhamento de cada bloco enquanto a argamassa permite ajustes."]]],
  ["Masonry","MAS","BrickRhythm","Masonry Corner: The Brick Rhythm","Canto da alvenaria: ritmo dos tijolos",[["Keep joint thickness consistent so each course reaches the planned height.","Mantenha as juntas uniformes para que cada fiada alcance a altura planejada."],["Stagger vertical joints according to the chosen bond rather than stacking seams.","Desencontre as juntas verticais conforme a amarração escolhida, sem alinhar as emendas."],["Spread an even mortar bed and butter the end before placing the next brick.","Espalhe uma camada uniforme de argamassa e cubra a ponta antes de assentar o tijolo."],["Use the line as a guide without pushing it outward with the brick face.","Use a linha como guia sem empurrá-la para fora com a face do tijolo."],["Protect fresh work from drying too quickly, heavy rain and freezing conditions.","Proteja o trabalho novo contra secagem rápida, chuva forte e congelamento."]]],
  ["Tailoring","TAI","MendBasket","The Mending Basket","O cesto de consertos",[["Wash the fabric and inspect the damaged area before choosing thread and a patch.","Lave o tecido e examine o dano antes de escolher a linha e o remendo."],["Trim loose threads without enlarging the tear and support thin fabric from beneath.","Corte fios soltos sem aumentar o rasgo e apoie por baixo o tecido fino."],["Choose a patch larger than the weak area so the stitches anchor in sound cloth.","Escolha um remendo maior que a área fraca para prender os pontos em tecido firme."],["Keep small stitches evenly spaced and avoid pulling the fabric into puckers.","Mantenha pontos pequenos e regulares, sem puxar o tecido a ponto de franzir."],["Finish the thread securely on the inside and check that the repair can flex.","Arremate a linha pelo lado interno e confira se o conserto permite flexibilidade."]]],
  ["Tailoring","TAI","WorkingHem","A Working Hem","Uma barra bem feita",[["Try the garment on and mark the hem while it hangs naturally.","Experimente a roupa e marque a barra enquanto o tecido cai naturalmente."],["Measure the allowance consistently and press the fold before stitching.","Meça a margem por igual e passe a dobra antes de costurar."],["Baste the folded edge first so slippery fabric cannot creep during the final seam.","Alinhave a borda dobrada para impedir que tecidos lisos deslizem na costura final."],["Choose needle and thread to suit the fabric weight and test on a spare scrap.","Escolha agulha e linha conforme o peso do tecido e teste numa sobra."],["Use light tension for a hidden hem and inspect the outside for visible pulls.","Use tensão leve numa barra invisível e examine o lado de fora para ver repuxos."]]]
].map(([skill, code, id, en, pt, lessons]) => ({
  skill, code, id: 'PassiveSkillsVHS_' + id, en, pt, lessons
}));
module.exports.VHS = VHS;

Object.assign(UI.EN, {
  vhsSpawn: 'Skill VHS chance (%)',
  vhsSpawnTip: 'Independent chance of one original skill VHS in an eligible magazine container. 0 disables new VHS spawns; existing tapes remain playable. Default 2%. Vanilla tapes are unchanged.',
  vhsXp: 'Skill VHS base XP (%)',
  vhsXpTip: '100 = 250 base XP per complete tape (five teaching lines). Normal game XP multipliers and media level cutoff apply. Native cooldown/history rules apply. 0 disables learning without consuming unseen lines. Magazine XP is separate.',
});
Object.assign(UI.PTBR, {
  vhsSpawn: 'Chance de VHS de habilidade (%)',
  vhsSpawnTip: 'Chance independente de um VHS original em contêiner elegível de revistas. 0 desativa novas fitas; fitas existentes continuam reproduzíveis. Padrão 2%. Fitas do jogo permanecem iguais.',
  vhsXp: 'XP base de VHS de habilidade (%)',
  vhsXpTip: '100 = 250 XP base por fita completa (cinco trechos). Multiplicadores e limite de nível de mídia do jogo se aplicam. Regras nativas de intervalo e histórico se aplicam. 0 desativa aprendizado sem consumir trechos inéditos. XP das revistas é separado.',
});
