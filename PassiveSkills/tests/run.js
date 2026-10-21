// Test runner for Passive Skills v2: static checks (luaparse, layout, scripts, translations) + Lua specs
// executed in fengari (Lua 5.3 VM; mod code sticks to the Lua 5.1 subset used by Kahlua). Usage: npm test
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const luaparse = require('luaparse');
const { lua, lauxlib, lualib, to_luastring } = require('fengari');

const ROOT = path.join(__dirname, '..');
const MOD = path.join(ROOT, 'Contents', 'mods', 'PassiveSkills');
const BUILDS = {
  42: { lua: path.join(MOD, '42', 'media', 'lua'), media: path.join(MOD, '42', 'media'), hook: 'shared/PassiveSkills_ReadHook.lua' },

};
const TR42 = path.join(MOD, 'common', 'media', 'lua', 'shared', 'Translate');
let failed = 0;
const fail = (m) => { failed++; console.log('FAIL: ' + m); };
const ok = (m) => console.log('ok   ' + m);
const fwd = (p) => p.replace(/\\/g, '/');

function walk(dir, out = []) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, out); else out.push(p);
  }
  return out;
}
const files = walk(path.join(ROOT, 'Contents'));

// ---------- 1. B42 generated resources ----------
try { execFileSync(process.execPath, [path.join(ROOT, 'tools', 'gen.js'), '--check'], { stdio: 'pipe' }); ok('generated files up to date (Catalog, magazines, VHS, sandbox, B42 JSON)'); } catch (e) { fail('tools/gen.js --check: ' + e.stdout); }

// ---------- 2. syntax ----------
const luaFiles = files.filter((f) => f.endsWith('.lua') || /Translate[\\/][A-Z]+[\\/](IG_UI|Tooltip|Sandbox)_[A-Z]+\.txt$/.test(f));
for (const f of fs.readdirSync(__dirname)) if (f.endsWith('.lua')) luaFiles.push(path.join(__dirname, f));
let syntaxErrors = 0;
for (const f of luaFiles) {
  const src = fs.readFileSync(f, /PTBR/.test(f) && f.endsWith('.txt') ? 'latin1' : 'utf8');
  try { luaparse.parse(src, { luaVersion: '5.1' }); } catch (e) { syntaxErrors++; fail('syntax ' + path.relative(ROOT, f) + ': ' + e.message); }
}
if (!syntaxErrors) ok(`Lua syntax (5.1): ${luaFiles.length} files, 0 errors`);
const json = {};
for (const f of files.filter((f) => f.endsWith('.json'))) {
  try { json[f] = JSON.parse(fs.readFileSync(f, 'utf8')); } catch (e) { fail('json ' + f + ': ' + e.message); }
}
ok(`JSON parse: ${Object.keys(json).length} files`);

if (fs.existsSync(path.join(MOD, 'media')) || fs.existsSync(path.join(MOD, 'mod.info'))) fail('active B41 root payload remains');
// ---------- 3. layout, mod.info, v1 leftovers ----------
for (const rel of [
  '42/mod.info', '42/poster.png', '42/icon.png', '42/media/sandbox-options.txt', '42/media/textures/Item_MagazineSkillsPhoto.png',
  'common/media/lua/shared/Translate/EN/Mod.json', 'common/media/lua/shared/Translate/PTBR/Mod.json']) {
  if (!fs.existsSync(path.join(MOD, rel))) fail('missing ' + rel);
}
for (const mi of ['42/mod.info']) {
  const t = fs.readFileSync(path.join(MOD, mi), 'utf8');
  if (!/^id=Passiveskillskr$/m.test(t)) fail(mi + ' id');
  if (!/^icon=icon\.png$/m.test(t) || !/^poster=poster\.png$/m.test(t)) fail(mi + ' icon/poster');
  if (/world\.s\b/.test(t)) fail(mi + ' typo world.s');
  if ((t.match(/^description=/mg) || []).length !== 1) fail(mi + ' must have exactly one description line');
}
if (!/^versionMin=42\.15$/m.test(fs.readFileSync(path.join(MOD, '42/mod.info'), 'utf8'))) fail('42/mod.info versionMin=42.15');
if (!/^id=3477846890$/m.test(fs.readFileSync(path.join(ROOT, 'workshop.txt'), 'utf8'))) fail('workshop.txt id');
const png = (p) => { const b = fs.readFileSync(p); return [b.readUInt32BE(16), b.readUInt32BE(20)].join('x'); };
if (png(path.join(MOD, '42', 'poster.png')) !== '512x512' || png(path.join(MOD, '42', 'icon.png')) !== '64x64' || png(path.join(ROOT, 'preview.png')) !== '256x256') fail('image sizes (poster 512, icon 64, preview 256)');
for (const f of files) {
  if (/defines\.lua$/i.test(f)) fail('defines.lua must be deleted: ' + f);
  if (/\.(lua|txt|json)$/.test(f) && /GydeTraitMags|ZomboidGlobals|getPlayer\(\)|ProceduralDistributions|OnPreDistributionMerge/.test(fs.readFileSync(f, 'utf8'))) fail('v1 leftover / forbidden API in ' + path.relative(MOD, f));
}
ok('layout, mod.info (id, icon, versionMin, typo), workshop id, image sizes, no v1 leftovers');

// ---------- 4. item scripts ----------
const TIERS = ['one', 'two', 'three', 'four', 'five'];
const PAGES = [10, 15, 20, 25, 30];
const scriptItems = {};
for (const b of ['42']) {
  const src = fs.readFileSync(path.join(BUILDS[b].media, 'scripts', 'PassiveSkills_Magazines.txt'), 'utf8');
  const opens = (src.match(/{/g) || []).length; const closes = (src.match(/}/g) || []).length;
  if (opens !== closes) fail(`B${b} script braces ${opens}/${closes}`);
  const items = {};
  const re = /item (\w+)\s*{([^}]*)}/g; let m;
  while ((m = re.exec(src))) {
    const props = Object.fromEntries(m[2].split(',').map((l) => l.trim()).filter(Boolean).map((l) => l.split('=').map((x) => x.trim())));
    items['Base.' + m[1]] = props;
    const tier = TIERS.indexOf(m[1].split('_').pop());
    if (tier < 0) fail('bad tier suffix ' + m[1]);
    if (+props.NumberOfPages !== PAGES[tier]) fail(`${m[1]} pages ${props.NumberOfPages}`);
    if (props.Tooltip !== 'Tooltip_PassiveSkills_Magazine') fail(m[1] + ' tooltip');
    if (b === '42') {
      if (props.ItemType !== 'base:literature' || props.Type || props.DisplayName || props.Tags !== 'base:magazine') fail('B42 item format ' + m[1]);
    }
  }
  scriptItems[b] = items;
  ok(`B${b} script: ${Object.keys(items).length} items, format + page counts OK`);
}

// ---------- 5. translations ----------
const sets = {};
for (const lang of ['EN', 'PTBR']) {
  sets['42' + lang] = {};
  for (const f of ['ItemName', 'IG_UI', 'Tooltip', 'Sandbox', 'Mod', 'Recorded_Media']) sets['42' + lang][f] = json[path.join(TR42, lang, f + '.json')] || {};
}
const sameKeys = (a, b) => JSON.stringify(Object.keys(a).sort()) === JSON.stringify(Object.keys(b).sort());
for (const b of ['42']) {
  for (const f of Object.keys(sets[b + 'EN'])) {
    if (!sameKeys(sets[b + 'EN'][f], sets[b + 'PTBR'][f])) fail(`B${b} ${f}: EN and PTBR key sets differ`);
    for (const [k, v] of Object.entries(sets[b + 'PTBR'][f])) if (!v || v === k) fail(`B${b} PTBR empty ${k}`);
  }
  const names = sets[b + 'EN'].ItemName;
  const prefix = '';
  const want = Object.keys(scriptItems[b]).map((k) => prefix + k).sort();
  if (JSON.stringify(Object.keys(names).sort()) !== JSON.stringify(want)) fail(`B${b} ItemName keys != script items`);
}

if (sets['42PTBR'].ItemName['Base.MagazineWoodwork_one'] !== 'Revista de Carpintaria Vol. 1') fail('PTBR item name sample');

// sandbox options <-> Sandbox translations
for (const b of ['42']) {
  const sb = fs.readFileSync(path.join(BUILDS[b].media, 'sandbox-options.txt'), 'utf8');
  for (const m of sb.matchAll(/translation = (\w+)/g)) {
    for (const lang of ['EN', 'PTBR']) {
      const t = sets[b + lang].Sandbox;
      if (!t['Sandbox_' + m[1]] || !t['Sandbox_' + m[1] + '_tooltip']) fail(`B${b} ${lang} sandbox text ${m[1]}`);
    }
  }
  for (const m of sb.matchAll(/page = (\w+)/g)) if (!sets[b + 'EN'].Sandbox['Sandbox_' + m[1]]) fail('sandbox page text ' + m[1]);
}
// literal getText keys used in Lua exist (dynamic skill keys are checked in glue_spec)
for (const f of luaFiles.filter((f) => f.includes('Contents') && f.endsWith('.lua'))) {
  for (const m of fs.readFileSync(f, 'utf8').matchAll(/getText\("(\w+)"\s*[,)]/g)) {
    for (const b of ['42']) if (!sets[b + 'EN'].IG_UI[m[1]] && !sets[b + 'PTBR'].IG_UI[m[1]]) fail(`getText key ${m[1]} missing (B${b})`);
  }
}
ok('translations: EN == PTBR key sets (B42 JSON, including80 original captions), item names cover scripts, sandbox + getText keys present');

// ---------- 6. Lua specs in fengari ----------
function newLua() {
  const L = lauxlib.luaL_newstate();
  lualib.luaL_openlibs(L);
  return L;
}
function run(L, code) {
  if (lauxlib.luaL_dostring(L, to_luastring(code)) !== lua.LUA_OK) throw new Error(lua.lua_tojsstring(L, -1));
  const v = lua.lua_gettop(L) > 0 ? lua.lua_tonumber(L, -1) : undefined;
  lua.lua_settop(L, 0);
  return v;
}
const luaSet = (arr) => '{' + arr.map((x) => `[${JSON.stringify(x)}]=true`).join(',') + '}';
const luaMap = (obj) => '{' + Object.entries(obj).map(([k, v]) => `[${JSON.stringify(k)}]=${JSON.stringify(v)}`).join(',') + '}';
for (const b of ['42']) {
  const perks = JSON.parse(fs.readFileSync(path.join(__dirname, 'fixtures', `perks_b${b}.json`), 'utf8')).perks;
  const tr = Object.assign({}, sets[b + 'EN'].IG_UI);
  const native = process.env.PZ_MEDIA || 'E:/SteamLibrary/steamapps/common/ProjectZomboid/media';
  const vanilla = path.join(native, 'lua/shared/RadioCom/ISRadioInteractions.lua');
  if (fs.existsSync(vanilla)) ok('real native ISRadioInteractions.lua SHA256=' + require('crypto').createHash('sha256').update(fs.readFileSync(vanilla)).digest('hex'));
  else console.log('SKIP real native integration: set PZ_MEDIA to a game media directory');
  const prelude = `BUILD=${b}; PERKS=${luaSet(perks)}; ITEMS=${luaSet(Object.keys(scriptItems[b]))}; TR=${luaMap(tr)};
    MEDIA_TEXT=${luaMap(sets[b + 'EN'].Recorded_Media)}; VANILLA_RADIO=${fs.existsSync(vanilla) ? JSON.stringify(fwd(vanilla)) : 'nil'}; MODROOT=${JSON.stringify(fwd(BUILDS[b].lua))}; HOOKFILE=${JSON.stringify(fwd(path.join(BUILDS[b].lua, BUILDS[b].hook)))};`;
  for (const spec of ['core_spec.lua', 'glue_spec.lua', 'vhs_spec.lua']) {
    const L = newLua();
    try {
      run(L, `package.path = ${JSON.stringify(fwd(BUILDS[b].lua) + '/shared/?.lua;')} .. package.path`);
      const n = run(L, prelude + ` return dofile(${JSON.stringify(fwd(path.join(__dirname, spec)))})`);
      if (n !== 0) fail(`B${b} ${spec}: ${n} failure(s)`); else ok(`B${b} ${spec}`);
    } catch (e) { fail(`B${b} ${spec} crashed: ${e.message}`); }
  }
}

console.log(failed ? `\n${failed} FAILURE(S)` : '\nALL TESTS PASSED');
process.exit(failed ? 1 : 0);
