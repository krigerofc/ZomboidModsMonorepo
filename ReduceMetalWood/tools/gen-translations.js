// Generates all translation files from one source of truth.
// B42 (>= 42.15): UTF-8 JSON in common/media/lua/shared/Translate/<LANG>/.
// B41: Sandbox_<LANG>.txt Lua tables; EN is UTF-8, PTBR must be Cp1252 (latin1 suffices for pt-BR).
const fs = require('fs');
const path = require('path');
const MOD = path.join(__dirname, '..', 'Contents', 'mods', 'ReduceMetalWood');
const T = {
  EN: {
    name: 'Reduce Metal&Wood v2',
    description: "Reduces the weight of eligible wood and metal crafting materials, including forged parts and welding rods, by 50% by default. Adjustable from 0% to 99% in sandbox options. Finished products stay unchanged. Supports B41 and B42; PT-BR + EN.",
    page: 'Reduce Metal&Wood',
    opt: 'Weight reduction (%)',
    tip: 'How much lighter wood and metal crafting materials become (planks, logs, nails, sheets, bars, ingots, scrap, forged blades and heads). 50 = half weight. 0 = disabled. Finished products are not affected.',
  },
  PTBR: {
    name: 'Reduce Metal&Wood v2',
    description: "Reduz em 50%, por padrão, o peso dos materiais elegíveis de madeira e metal, incluindo peças forjadas e varetas de solda. Ajustável de 0% a 99% no sandbox. Produtos acabados mantêm o peso. B41 e B42; PT-BR + EN.",
    page: 'Reduce Metal&Wood',
    opt: 'Redução de peso (%)',
    tip: 'Quanto mais leves ficam os materiais de madeira e metal (tábuas, toras, pregos, chapas, barras, lingotes, sucata, lâminas e cabeças forjadas). 50 = metade do peso. 0 = desativado. Produtos acabados não são afetados.',
  },
};
const keys = (t) => ({
  Sandbox_ReduceMetalWood: t.page,
  Sandbox_ReduceMetalWood_WeightReductionPercent: t.opt,
  Sandbox_ReduceMetalWood_WeightReductionPercent_tooltip: t.tip,
});
const luaStr = (s) => JSON.stringify(s); // ASCII-safe quoting; PZ strings here have no escapes beyond \"
for (const [lang, t] of Object.entries(T)) {
  const b42 = path.join(MOD, 'common', 'media', 'lua', 'shared', 'Translate', lang);
  fs.mkdirSync(b42, { recursive: true });
  fs.writeFileSync(path.join(b42, 'Sandbox.json'), JSON.stringify(keys(t), null, 4) + '\n', 'utf8');
  fs.writeFileSync(path.join(b42, 'Mod.json'), JSON.stringify({ name: t.name, description: t.description }, null, 4) + '\n', 'utf8');
  const b41 = path.join(MOD, 'media', 'lua', 'shared', 'Translate', lang);
  fs.mkdirSync(b41, { recursive: true });
  const body = 'Sandbox_' + lang + ' = {\n' +
    Object.entries(keys(t)).map(([k, v]) => '    ' + k + ' = ' + luaStr(v) + ',').join('\n') + '\n}\n';
  fs.writeFileSync(path.join(b41, 'Sandbox_' + lang + '.txt'), Buffer.from(body, lang === 'EN' ? 'utf8' : 'latin1'));
}
console.log('translations written');
