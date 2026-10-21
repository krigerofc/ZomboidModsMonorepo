// Rebuilds tests/fixtures/*.json from a local vanilla install (B42) and the official B41 translation files.
// Dev only. Usage:
//   node tools/build-fixtures.js <PZ_B42_media_dir> <Recipes_EN.txt 41.78> <ItemName_EN.txt 41.78>
// B41 files: github.com/TheIndieStone/ProjectZomboidTranslations (master = 41.78.x) EN/Recipes_EN.txt, EN/ItemName_EN.txt
const fs = require('fs');
const path = require('path');
const [media, rec41, items41] = process.argv.slice(2);
if (!media || !rec41 || !items41) { console.error('usage: node tools/build-fixtures.js <media> <Recipes_EN.txt> <ItemName_EN.txt>'); process.exit(1); }
const OUT = path.join(__dirname, '..', 'tests', 'fixtures');
const write = (f, o) => fs.writeFileSync(path.join(OUT, f), JSON.stringify(o, null, 1) + '\n');
function walk(d, o = []) { for (const e of fs.readdirSync(d, { withFileTypes: true })) { const p = path.join(d, e.name); e.isDirectory() ? walk(p, o) : p.endsWith('.txt') && o.push(p); } return o; }
const scripts = walk(path.join(media, 'scripts'));

// ---- B42 recipes (craftRecipe names; learnable = needTobeLearn = true) ----
const all = new Set(); const learnable = new Set();
for (const f of scripts) {
  const s = fs.readFileSync(f, 'utf8');
  for (const part of s.split(/^\s*craftRecipe\s+/m).slice(1)) {
    const name = part.match(/^(\S+)/)[1];
    all.add(name);
    const body = part.split(/^\s*craftRecipe\s+/m)[0].slice(0, 3000);
    if (/needTobeLearn\s*=\s*true/i.test(body)) learnable.add(name);
  }
}
write('recipes_b42.json', { _source: 'craftRecipe blocks in vanilla 42.19.2 media/scripts; learnable = needTobeLearn = true', learnable: [...learnable].sort(), all: [...all].sort() });

// ---- B42 items ----
const items = new Set();
for (const f of scripts) {
  let mod = 'Base';
  for (const line of fs.readFileSync(f, 'utf8').split(/\r?\n/)) {
    const mm = line.match(/^\s*module\s+(\w+)/); if (mm) mod = mm[1];
    const m = line.match(/^\s*item\s+([\w.]+)\s*$/); if (m) items.add(mod + '.' + m[1]);
  }
}
write('items_b42.json', { _source: 'item blocks in vanilla 42.19.2 media/scripts', items: [...items].sort() });

// ---- B42 vanilla professions / traits ----
const CH = path.join(media, 'scripts', 'generated', 'characters');
function parse(file, kw) {
  const s = fs.readFileSync(path.join(CH, file), 'utf8'); const out = {};
  for (const b of s.split(kw).slice(1)) {
    const id = b.match(/^\s*(\S+)/)[1];
    const g = (k) => { const m = b.match(new RegExp('\\n\\s*' + k + ' = ([^\\r\\n]*),')); return m ? m[1] : ''; };
    const xp = {}; for (const p of g('XPBoosts').split(';').filter(Boolean)) { const [k, v] = p.split('='); xp[k] = +v; }
    out[id] = { cost: +g('Cost'), xp, traits: g('GrantedTraits').split(';').filter(Boolean), recipes: g('GrantedRecipes').split(';').filter(Boolean).length,
      icon: g('IconPathName'), isProfessionTrait: g('IsProfessionTrait') === 'true' };
  }
  return out;
}
const profs = parse('character_professions.txt', 'character_profession_definition');
const traits = parse('character_traits.txt', 'character_trait_definition');
write('vanilla_b42.json', { _source: 'vanilla 42.19.2 scripts/generated/characters', professions: profs,
  traits: Object.fromEntries(Object.entries(traits).map(([k, t]) => [k, { cost: t.cost, xp: t.xp, recipes: t.recipes, isProfessionTrait: t.isProfessionTrait }])),
  icons: [...new Set(Object.values(profs).map((p) => p.icon).filter(Boolean))].sort() });

// ---- B41 recipes / items from the 41.78 translation tables ----
const keys = (file, prefix) => [...fs.readFileSync(file, 'utf8').matchAll(new RegExp('^\\s*' + prefix + '([^\\s=]+)\\s*=', 'gm'))].map((m) => m[1]);
write('recipes_b41.json', { _source: 'Recipe_* keys of 41.78 EN/Recipes_EN.txt (key = recipe name with spaces as _), plus vanilla B41 free-recipe names without translation keys',
  recipes: [...new Set(keys(rec41, 'Recipe_').map((k) => k.replace(/_/g, ' ')).concat(['Basic Mechanics', 'Intermediate Mechanics', 'Advanced Mechanics', 'Generator', 'Herbalist']))].sort() });
write('items_b41.json', { _source: 'ItemName_* keys of 41.78 EN/ItemName_EN.txt', items: [...new Set(keys(items41, 'ItemName_'))].sort() });
console.log('fixtures written:', learnable.size, 'learnable /', all.size, 'recipes;', items.size, 'items;', Object.keys(profs).length, 'professions');
