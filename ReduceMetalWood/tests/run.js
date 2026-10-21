// Test runner: static Lua syntax check (luaparse, Lua 5.1 grammar ~ Kahlua) + real Lua
// execution of the mod modules in fengari. Usage: npm test
const fs = require('fs');
const path = require('path');
const luaparse = require('luaparse');
const { lua, lauxlib, lualib, to_luastring } = require('fengari');

const ROOT = path.join(__dirname, '..');
const MOD = path.join(ROOT, 'Contents', 'mods', 'ReduceMetalWood');
const B42_SHARED = path.join(MOD, '42', 'media', 'lua', 'shared');
const B41_SHARED = path.join(MOD, 'media', 'lua', 'shared');
let failed = 0;
const fail = (m) => { failed++; console.log('FAIL: ' + m); };
const ok = (m) => console.log('ok   ' + m);

function walk(dir, out = []) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, out); else out.push(p);
  }
  return out;
}

// ---------- 1. static syntax check ----------
const files = walk(path.join(ROOT, 'Contents'));
const luaFiles = files.filter((f) => f.endsWith('.lua') || /Translate[\\/][A-Z]+[\\/]Sandbox_[A-Z]+\.txt$/.test(f));
luaFiles.push(path.join(__dirname, 'core_spec.lua'));
let syntaxErrors = 0;
for (const f of luaFiles) {
  const src = fs.readFileSync(f, f.includes('PTBR') && f.endsWith('.txt') ? 'latin1' : 'utf8');
  try { luaparse.parse(src, { luaVersion: '5.1' }); } catch (e) { syntaxErrors++; fail('syntax ' + path.relative(ROOT, f) + ': ' + e.message); }
}
if (!syntaxErrors) ok(`Lua syntax: ${luaFiles.length} files, 0 errors`);
for (const f of files.filter((f) => f.endsWith('.json'))) {
  try { JSON.parse(fs.readFileSync(f, 'utf8')); } catch (e) { fail('json ' + f + ': ' + e.message); }
}
ok('JSON translations parse');

// B41 and B42 copies of the Lua must be identical (same code, adaptive API access)
for (const rel of ['ReduceMetalWood/Classifier.lua', 'ReduceMetalWood/Core.lua', 'ReduceMetalWood_Init.lua']) {
  const a = fs.readFileSync(path.join(B42_SHARED, rel), 'utf8');
  const b = fs.readFileSync(path.join(B41_SHARED, rel), 'utf8');
  if (a !== b) fail('B41/B42 copy differs: ' + rel); else ok('B41 == B42 copy: ' + rel);
}
// required layout files
for (const rel of ['mod.info', 'poster.png', 'icon.png', 'media/sandbox-options.txt',
  'media/lua/shared/Translate/EN/Sandbox_EN.txt', 'media/lua/shared/Translate/PTBR/Sandbox_PTBR.txt',
  '42/mod.info', '42/poster.png', '42/icon.png', '42/media/sandbox-options.txt',
  'common/media/lua/shared/Translate/EN/Sandbox.json', 'common/media/lua/shared/Translate/EN/Mod.json',
  'common/media/lua/shared/Translate/PTBR/Sandbox.json', 'common/media/lua/shared/Translate/PTBR/Mod.json']) {
  if (!fs.existsSync(path.join(MOD, rel))) fail('missing ' + rel);
}
for (const mi of ['mod.info', '42/mod.info']) {
  if (!/^id=ReduceMetal&Wood50x$/m.test(fs.readFileSync(path.join(MOD, mi), 'utf8'))) fail(mi + ' id');
}
ok('layout + mod ids');

// ---------- 2. run Lua in fengari ----------
function newLua(sharedDir) {
  const L = lauxlib.luaL_newstate();
  lualib.luaL_openlibs(L);
  const p = sharedDir.replace(/\\/g, '/');
  run(L, `package.path = "${p}/?.lua;" .. package.path`);
  return L;
}
function run(L, code) {
  if (lauxlib.luaL_dostring(L, to_luastring(code)) !== lua.LUA_OK) {
    throw new Error(lua.lua_tojsstring(L, -1));
  }
  const top = lua.lua_gettop(L);
  const v = top > 0 ? (lua.lua_isnumber(L, -1) ? lua.lua_tonumber(L, -1) : lua.lua_tojsstring(L, -1)) : undefined;
  lua.lua_settop(L, 0);
  return v;
}
const luaStr = (s) => JSON.stringify(String(s));
function luaItems(items, module = 'Base') {
  return '{' + items.map((i) => `{module=${luaStr(module)},name=${luaStr(i.name)},displayCategory=${i.dc == null ? 'nil' : luaStr(i.dc)},metalValue=${+i.mv || 0},w=${+i.w || 0},tags={${(i.tags || []).map(luaStr).join(',')}}}`).join(',\n') + '}';
}
function classifyAll(sharedDir, items) {
  const L = newLua(sharedDir);
  const out = run(L, `
    local C = require "ReduceMetalWood/Classifier"
    local items = ${luaItems(items)}
    local lines = {}
    for i = 1, #items do
      local m, inc, why = C.classify(items[i])
      lines[#lines + 1] = items[i].name .. "|" .. tostring(m) .. "|" .. tostring(inc) .. "|" .. why .. "|" .. C.computeWeight(items[i].w, 50)
    end
    return table.concat(lines, "\\n")`);
  return out.split('\n').map((l) => { const [name, m, inc, why, w50] = l.split('|'); return { name, mat: m === 'nil' ? null : m, inc: inc === 'true', why, w50: +w50 }; });
}

// 2a. B42 vanilla catalogue vs golden list
const items42 = JSON.parse(fs.readFileSync(path.join(__dirname, 'fixtures', 'items_b42_vanilla.json'), 'utf8'));
const golden = JSON.parse(fs.readFileSync(path.join(__dirname, 'fixtures', 'expected_b42_vanilla.json'), 'utf8'));
const res42 = classifyAll(B42_SHARED, items42);
const got = { wood: res42.filter((r) => r.inc && r.mat === 'wood').map((r) => r.name).sort(), metal: res42.filter((r) => r.inc && r.mat === 'metal').map((r) => r.name).sort() };
for (const mat of ['wood', 'metal']) {
  const exp = new Set(golden[mat]); const g = new Set(got[mat]);
  const missing = golden[mat].filter((n) => !g.has(n)); const extra = got[mat].filter((n) => !exp.has(n));
  if (missing.length || extra.length) fail(`B42 ${mat}: missing [${missing}] extra [${extra}]`);
  else ok(`B42 vanilla ${mat}: ${got[mat].length} items match golden list`);
}
const byName = Object.fromEntries(res42.map((r) => [r.name, r]));
const mustInclude = ['Plank', 'Log', 'TreeBranch2', 'Nails', 'SheetMetal', 'IronIngot', 'SteelBar', 'ScrapMetal', 'SwordBlade', 'WoodAxeHead', 'Katana_Shard', 'IronBloom'];
const mustExclude = ['PropaneTank', 'IronOre', 'CopperOre', 'Hematite', 'HematiteLarge', 'Malachite', 'MalachiteLarge', 'Charcoal', 'Coke',
  'IronIngotMold', 'BlacksmithAnvilUntreated', 'CeramicCrucible_Iron', 'BucketConcreteFull', 'Hammer', 'Axe', 'Door', 'Pot', 'Katana', 'Sledgehammer'];
for (const n of mustInclude) if (!byName[n] || !byName[n].inc) fail('must include ' + n + (byName[n] ? ' (' + byName[n].why + ')' : ' (not in fixture)'));
for (const n of mustExclude) if (byName[n] && byName[n].inc) fail('must exclude ' + n + ' (' + byName[n].why + ')');
ok(`B42 asserts: ${mustInclude.length} must-include, ${mustExclude.length} must-exclude checked`);
if (byName.Plank.w50 !== 1.5) fail('Plank 50% weight ' + byName.Plank.w50);
const finished = items42.filter((i) => /^(Clothing|ProtectiveGear|Furniture|Weapon|Tool|ToolWeapon|Cooking|CookingWeapon|Container|Bag)$/.test(i.dc)).map((i) => byName[i.name]).filter((r) => r.inc);
if (finished.length) fail('finished-product DC included: ' + finished.map((r) => r.name)); else ok('no finished-product DisplayCategory item included');
console.log(`     counts B42 vanilla: scanned=${res42.length} wood=${got.wood.length} metal=${got.metal.length} total=${got.wood.length + got.metal.length}`);

// 2b. B41 sample, run through the root media (B41) copy
const s41 = JSON.parse(fs.readFileSync(path.join(__dirname, 'fixtures', 'items_b41_sample.json'), 'utf8')).items;
const res41 = classifyAll(B41_SHARED, s41);
let bad41 = 0;
res41.forEach((r, i) => { const e = s41[i].expect; if ((r.inc ? r.mat : null) !== e) { bad41++; fail(`B41 ${r.name}: expected ${e} got ${r.inc ? r.mat : null} (${r.why})`); } });
if (!bad41) ok(`B41 sample: ${s41.length} items as expected (wood=${res41.filter((r) => r.inc && r.mat === 'wood').length} metal=${res41.filter((r) => r.inc && r.mat === 'metal').length})`);

// 2c. Core + Init runtime spec with mocks (both copies)
for (const [label, dir] of [['B42', B42_SHARED], ['B41', B41_SHARED]]) {
  const L = newLua(dir);
  run(L, `package.path = "${__dirname.replace(/\\/g, '/')}/?.lua;" .. package.path`);
  const n = run(L, 'return dofile("' + path.join(__dirname, 'core_spec.lua').replace(/\\/g, '/') + '")');
  if (n !== 0) fail(`${label} core_spec: ${n} failures`); else ok(`${label} runtime spec (Core + Init with mocks)`);
}

console.log(failed ? `\n${failed} FAILURE(S)` : '\nALL TESTS PASSED');
process.exit(failed ? 1 : 0);
