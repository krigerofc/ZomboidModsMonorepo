// Generates all translation files from one source of truth.
// B42 (>= 42.15): UTF-8 JSON in common/media/lua/shared/Translate/<LANG>/.
// B41: Sandbox_<LANG>.txt Lua tables; EN is UTF-8, PTBR must be Cp1252 (latin1 suffices for pt-BR).
const fs = require('fs');
const path = require('path');
const MOD = path.join(__dirname, '..', 'Contents', 'mods', 'ReduceMetalWood');
const T = {
  EN: {
    name: 'Build & Haul - Lightweight Materials',
    description: "Reduces eligible wood, metal, ores and mineral construction materials by 50% by default (0-99% sandbox). Includes bricks, clay, stone, sand, gravel, concrete and plaster. Filled construction containers reduce contents only; empty containers, tools, fuel and finished products keep their weight. B41 + B42; EN + PT-BR.",
    page: 'Build & Haul',
    opt: 'Weight reduction (%)',
    tip: 'Reduction for eligible wood, metal, ores and mineral construction stock. 50 = half material weight; 0 = disabled. Filled construction containers retain their empty-container weight and reduce contents only. Tools, fuel and finished products are excluded.',
  },
  PTBR: {
    name: 'Build & Haul - Materiais Leves',
    description: "Reduz em 50% o peso de madeira, metal, minérios e insumos minerais de construção (0-99% no sandbox). Inclui tijolos, argila, pedra, areia, cascalho, concreto e gesso. Recipientes de construção reduzem apenas o conteúdo; recipientes vazios, ferramentas, combustíveis e produtos acabados mantêm o peso. B41 + B42; EN + PT-BR.",
    page: 'Build & Haul',
    opt: 'Redução de peso (%)',
    tip: 'Redução para madeira, metal, minérios e insumos minerais de construção elegíveis. 50 = metade do peso do material; 0 = desativado. Recipientes de construção mantêm o peso vazio e reduzem só o conteúdo. Ferramentas, combustíveis e produtos acabados ficam de fora.',
  },
};
const keys = (t) => ({
  Sandbox_ReduceMetalWood: t.page,
  Sandbox_ReduceMetalWood_WeightReductionPercent: t.opt,
  Sandbox_ReduceMetalWood_WeightReductionPercent_tooltip: t.tip,
});
const check = process.argv.includes('--check');
let stale = 0;
function emit(file, data, encoding) {
  const bytes = Buffer.isBuffer(data) ? data : Buffer.from(data, encoding || 'utf8');
  if (check) {
    if (!fs.existsSync(file) || !fs.readFileSync(file).equals(bytes)) { console.error('stale: ' + path.relative(MOD, file)); stale++; }
  } else { fs.mkdirSync(path.dirname(file), { recursive: true }); fs.writeFileSync(file, bytes); }
}
const luaStr = (s) => JSON.stringify(s); // ASCII-safe quoting; PZ strings here have no escapes beyond \"
for (const [lang, t] of Object.entries(T)) {
  const b42 = path.join(MOD, 'common', 'media', 'lua', 'shared', 'Translate', lang);
  emit(path.join(b42, 'Sandbox.json'), JSON.stringify(keys(t), null, 4) + '\n', 'utf8');
  emit(path.join(b42, 'Mod.json'), JSON.stringify({ name: t.name, description: t.description }, null, 4) + '\n', 'utf8');
  const b41 = path.join(MOD, 'media', 'lua', 'shared', 'Translate', lang);
  const body = 'Sandbox_' + lang + ' = {\n' +
    Object.entries(keys(t)).map(([k, v]) => '    ' + k + ' = ' + luaStr(v) + ',').join('\n') + '\n}\n';
  emit(path.join(b41, 'Sandbox_' + lang + '.txt'), Buffer.from(body, lang === 'EN' ? 'utf8' : 'latin1'));
}
for (const build of ['', '42/']) {
  const info = 'name=' + T.EN.name + '\nid=ReduceMetal&Wood50x\nauthor=pedro\ndescription=' + T.EN.description + '\nposter=poster.png\nicon=icon.png\n' + (build ? 'versionMin=42.15\n' : '');
  emit(path.join(MOD, build, 'mod.info'), info);
}
const workshop = ['version=1','id=3140965857','title=' + T.EN.name,'description=[b]EN[/b] ' + T.EN.description,'description=','description=[b]PT-BR[/b] ' + T.PTBR.description,'description=','description=Development build: automated checks only. In-game validation on B41/42.21, hosted multiplayer and dedicated servers is pending. / Versão em desenvolvimento: verificações automatizadas; validação no jogo B41/42.21 e em multiplayer ainda pendente.','tags=Build 41;Build 42;Balance;Items','visibility=public',''].join('\n');
emit(path.join(MOD, '..', '..', '..', 'workshop.txt'), workshop);
if (stale) process.exitCode = 1;
else console.log(check ? 'generated resources current' : 'translations and metadata written');
