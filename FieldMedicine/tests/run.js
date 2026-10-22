// Test runner for Field Medicine '93: static checks (luaparse, layout, scripts, item references, translations)
// + Lua specs in fengari (Lua 5.3 VM; mod code sticks to the Lua 5.1 subset used by Kahlua). Usage: npm test
// Vanilla game folder (for item reference checks): env PZ_DIR or the default Steam path below.
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const luaparse = require('luaparse');
const { lua, lauxlib, lualib, to_luastring } = require('fengari');

const ROOT = path.join(__dirname, '..');
const MOD = path.join(ROOT, 'Contents', 'mods', 'KRFieldMedicine');
const LUA = path.join(MOD, '42', 'media', 'lua');
const TR = path.join(MOD, 'common', 'media', 'lua', 'shared', 'Translate');
const PZ = process.env.PZ_DIR || 'E:/SteamLibrary/steamapps/common/ProjectZomboid';
let failed = 0;
const fail = (m) => { failed++; console.log('FAIL: ' + m); };
const ok = (m) => console.log('ok   ' + m);
const fwd = (p) => p.replace(/\\/g, '/');
function walk(dir, out = []) {
  if (!fs.existsSync(dir)) return out;
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, out); else out.push(p);
  }
  return out;
}
const files = walk(path.join(ROOT, 'Contents'));
const read = (p) => fs.readFileSync(p, 'utf8');

// ---------- 1. translations generated from tools/i18n.js are up to date
try { execFileSync(process.execPath, [path.join(ROOT, 'tools', 'i18n.js'), '--check'], { stdio: 'pipe' }); ok('translations up to date with tools/i18n.js'); } catch (e) { fail('tools/i18n.js --check: ' + e.stdout); }

// ---------- 2. syntax
const luaFiles = files.filter((f) => f.endsWith('.lua'));
for (const f of fs.readdirSync(__dirname)) if (f.endsWith('.lua')) luaFiles.push(path.join(__dirname, f));
let syntaxErrors = 0;
for (const f of luaFiles) {
  try { luaparse.parse(read(f), { luaVersion: '5.1' }); } catch (e) { syntaxErrors++; fail('syntax ' + path.relative(ROOT, f) + ': ' + e.message); }
  if (/[^\x00-\x7F]/.test(read(f)) && f.includes('Contents')) fail('non-ASCII in Lua (hardcoded text?) ' + path.relative(ROOT, f));
}
if (!syntaxErrors) ok(`Lua syntax (5.1): ${luaFiles.length} files, 0 errors`);
const json = {};
for (const f of files.filter((f) => f.endsWith('.json'))) {
  try { json[f] = JSON.parse(read(f)); } catch (e) { fail('json ' + f + ': ' + e.message); }
}
ok(`JSON parse: ${Object.keys(json).length} files`);

// ---------- 3. layout / mod.info / workshop.txt
for (const rel of ['42/mod.info', '42/poster.png', '42/icon.png', '42/media/sandbox-options.txt', '42/media/scripts/KFM_items.txt', '42/media/scripts/KFM_recipes.txt',
  'common/media/lua/shared/Translate/EN/Mod.json', 'common/media/lua/shared/Translate/PTBR/Mod.json']) {
  if (!fs.existsSync(path.join(MOD, rel))) fail('missing ' + rel);
}
if (fs.existsSync(path.join(MOD, 'mod.info')) || fs.existsSync(path.join(MOD, 'media'))) fail('B42-only: no root mod.info / media (B41) expected');
const mi = read(path.join(MOD, '42/mod.info'));
if (!/^id=KRFieldMedicine$/m.test(mi) || !/^versionMin=42\.15$/m.test(mi) || !/^author=Kriger$/m.test(mi)) fail('42/mod.info id/versionMin/author');
if (!/^icon=icon\.png$/m.test(mi) || !/^poster=poster\.png$/m.test(mi)) fail('mod.info icon/poster');
const ws = read(path.join(ROOT, 'workshop.txt'));
if (/^id=/m.test(ws)) fail('workshop.txt must not have an id yet (new item)');
if (!/^title=Field Medicine '93$/m.test(ws)) fail('workshop title');
const png = (p) => { const b = fs.readFileSync(p); return [b.readUInt32BE(16), b.readUInt32BE(20)].join('x'); };
if (png(path.join(MOD, '42/poster.png')) !== '512x512' || png(path.join(MOD, '42/icon.png')) !== '64x64' || png(path.join(ROOT, 'preview.png')) !== '256x256') fail('image sizes (poster 512, icon 64, preview 256)');
for (const f of luaFiles.filter((f) => f.includes('Contents'))) {
  const src = read(f);
  if (/\bgetPlayer\(\)/.test(src) && !/client[\\/]/.test(f)) fail('getPlayer() outside client: ' + path.relative(MOD, f));
  if (/ISHealthPanel\s*=|ISHealthPanel\.new\s*=|ISStitch\s*=|ISDisinfect\s*=/.test(src)) fail('vanilla class overwritten in ' + path.relative(MOD, f));
}
ok('layout (B42 only), mod.info, workshop.txt (no id), image sizes, no vanilla overwrite');

// ---------- 4. Knox guard: no code path reads the zombie infection
const knoxApi = /\b(isInfected|IsInfected|getInfectionLevel|isFakeInfected|IsFakeInfected|getApparentInfectionLevel|getInfectionTime|setInfected|SetInfected|SetFakeInfected|getInfectionMortalityDuration)\s*\(/;
for (const f of luaFiles.filter((f) => f.includes('Contents'))) {
  const src = read(f).replace(/--.*$/mg, '');
  if (knoxApi.test(src)) fail('zombie infection API used in ' + path.relative(MOD, f) + ': ' + src.match(knoxApi)[0]);
}
ok('Knox guard: no zombie-infection API in mod Lua');

// ---------- 5. scripts: items, recipes, references exist in vanilla or mod
const modScripts = read(path.join(MOD, '42/media/scripts/KFM_items.txt')) + '\n' + read(path.join(MOD, '42/media/scripts/KFM_recipes.txt'));
for (const f of files.filter((f) => /[\\/]media[\\/]scripts[\\/].*\.txt$/.test(f))) {
  // Native B42 parser does not treat a leading // generated header as a module prefix.
  if (!/^\s*(?:\/\*[\s\S]*?\*\/\s*)*module\s+\w+\s*\{/.test(read(f))) fail('native module prefix ' + path.relative(MOD, f));
}
for (const [n, s] of [['items', read(path.join(MOD, '42/media/scripts/KFM_items.txt'))], ['recipes', read(path.join(MOD, '42/media/scripts/KFM_recipes.txt'))]]) {
  if ((s.match(/{/g) || []).length !== (s.match(/}/g) || []).length) fail('braces ' + n);
  if (!/^module Base\s*$/m.test(s)) fail('module Base ' + n);
}
const modItems = new Set([...modScripts.matchAll(/^\s*item (\w+)\s*$/mg)].map((m) => 'Base.' + m[1]));
const modRecipes = [...modScripts.matchAll(/craftRecipe (\w+)/g)].map((m) => m[1]);
const vanillaItemsDir = path.join(PZ, 'media', 'scripts', 'generated', 'items');
const vanillaItems = new Set();
if (fs.existsSync(vanillaItemsDir)) {
  for (const f of walk(vanillaItemsDir)) for (const m of read(f).matchAll(/^\s*item (\w+)\s*$/mg)) vanillaItems.add('Base.' + m[1]);
  ok(`vanilla scan: ${vanillaItems.size} items`);
} else console.log('skip vanilla item scan (PZ_DIR not found: ' + PZ + ')');
const known = (ft) => modItems.has(ft) || vanillaItems.size === 0 || vanillaItems.has(ft);
const refs = new Set();
for (const m of modScripts.matchAll(/\[([^\]]+)\]/g)) for (const t of m[1].split(';')) if (/^Base\.\w+$/.test(t.trim())) refs.add(t.trim());
for (const m of modScripts.matchAll(/^\s*item \d+ (Base\.\w+)/mg)) refs.add(m[1]);
for (const f of luaFiles.filter((f) => f.includes('Contents'))) for (const m of read(f).matchAll(/"(Base\.\w+)"/g)) refs.add(m[1]);
for (const r of refs) if (!known(r)) fail('unknown item reference ' + r);
ok(`item references exist (vanilla or mod): ${refs.size}`);
for (const ft of modItems) {
  const name = ft.split('.')[1];
  const block = modScripts.match(new RegExp('item ' + name + '\\s*{([^}]*)}'))[1];
  if (!/ItemType = base:\w+/.test(block) || /DisplayName/.test(block)) fail('B42 item format ' + name);
}

// ---------- 6. translations: parity + coverage
const tr = {};
for (const lang of ['EN', 'PTBR']) {
  tr[lang] = {};
  for (const f of fs.readdirSync(path.join(TR, lang))) tr[lang][f.replace('.json', '')] = json[path.join(TR, lang, f)] || {};
}
const sameKeys = (a, b) => JSON.stringify(Object.keys(a).sort()) === JSON.stringify(Object.keys(b).sort());
if (!sameKeys(tr.EN, tr.PTBR)) fail('EN/PTBR file sets differ');
for (const f of Object.keys(tr.EN)) {
  if (!sameKeys(tr.EN[f], tr.PTBR[f] || {})) fail(`${f}: EN and PTBR key sets differ`);
  for (const [k, v] of Object.entries(tr.PTBR[f] || {})) {
    if (!v || v === k) fail(`PTBR empty ${k}`);
    if (/[A-Za-z\u00c0-\u00ff]\?[A-Za-z\u00c0-\u00ff]|\?\?|\ufffd/.test(v)) fail(`PTBR damaged encoding ${k}`);
    const ph = (s) => (s.match(/%\d/g) || []).sort().join();
    if (ph(v) !== ph(tr.EN[f][k])) fail(`placeholder mismatch ${k}`);
  }
}
const allKeys = Object.assign({}, ...Object.values(tr.EN));
for (const ft of modItems) if (!tr.EN.ItemName[ft]) fail('item name missing ' + ft);
for (const r of modRecipes) if (!tr.EN.Recipes[r]) fail('recipe name missing ' + r);
for (const m of modScripts.matchAll(/Tooltip = (\w+)/g)) if (!tr.EN.Tooltip[m[1]]) fail('item tooltip missing ' + m[1]);
const sb = read(path.join(MOD, '42/media/sandbox-options.txt'));
for (const m of sb.matchAll(/translation = (\w+)/g)) {
  if (!tr.EN.Sandbox['Sandbox_' + m[1]] || !tr.EN.Sandbox['Sandbox_' + m[1] + '_tooltip']) fail('sandbox text ' + m[1]);
}
for (const m of sb.matchAll(/page = (\w+)/g)) if (!tr.EN.Sandbox['Sandbox_' + m[1]]) fail('sandbox page text ' + m[1]);
const sbNames = [...sb.matchAll(/option KFM\.(\w+)/g)].map((m) => m[1]).sort();
const used = new Set();
for (const f of luaFiles.filter((f) => f.includes('Contents'))) {
  const src = read(f);
  for (const m of src.matchAll(/"((?:IGUI|ContextMenu|Tooltip)_KFM_\w+)"/g)) { used.add(m[1]); if (!m[1].endsWith('_') && !allKeys[m[1]]) fail(`key ${m[1]} used in Lua but missing`); }
  for (const m of src.matchAll(/"(IGUI_KFM_Exam_(?:General|Fracture)_)"/g)) used.add(m[1]);
}
// dynamic exam keys (General_*/Fracture_*) are validated in glue_spec through the EN map
ok(`translations: EN == PTBR (${Object.keys(allKeys).length} keys, placeholders), items/recipes/tooltips/sandbox covered`);

// ---------- 7. Lua specs in fengari
function run(L, code) {
  if (lauxlib.luaL_dostring(L, to_luastring(code)) !== lua.LUA_OK) throw new Error(lua.lua_tojsstring(L, -1));
  const v = lua.lua_gettop(L) > 0 ? lua.lua_tonumber(L, -1) : undefined;
  lua.lua_settop(L, 0);
  return v;
}
const luaMap = (obj) => '{' + Object.entries(obj).map(([k, v]) => `[${JSON.stringify(k)}]=${JSON.stringify(v)}`).join(',') + '}';
const luaList = (arr) => '{' + arr.map((x) => JSON.stringify(x)).join(',') + '}';
for (const spec of ['core_spec.lua', 'glue_spec.lua', 'illness_spec.lua', 'phase2_spec.lua', 'symptoms_spec.lua', 'exam_spec.lua', 'effects_spec.lua', 'strain_spec.lua', 'clinical_spec.lua']) {
  const L = lauxlib.luaL_newstate();
  lualib.luaL_openlibs(L);
  try {
    run(L, `package.path = ${JSON.stringify(fwd(LUA) + '/shared/?.lua;' + fwd(LUA) + '/?.lua;')} .. package.path`);
    const n = run(L, `TR=${luaMap(allKeys)}; SANDBOX_NAMES=${luaList(sbNames)}; MODLUA=${JSON.stringify(fwd(LUA))}; return dofile(${JSON.stringify(fwd(path.join(__dirname, spec)))})`);
    if (n !== 0) fail(`${spec}: ${n} failure(s)`); else ok(spec);
  } catch (e) { fail(`${spec} crashed: ${e.message}`); }
}

console.log(failed ? `\n${failed} FAILURE(S)` : '\nALL TESTS PASSED');
process.exit(failed ? 1 : 0);
