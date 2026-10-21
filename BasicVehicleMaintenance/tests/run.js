// Test runner for Basic Vehicle Maintenance v2: static checks (luaparse, layout, sandbox,
// translations) + Lua specs in fengari (Lua 5.3 VM; mod code sticks to the Kahlua/Lua 5.1 subset).
// Usage: npm test
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const luaparse = require('luaparse');
const { lua, lauxlib, lualib, to_luastring } = require('fengari');

const ROOT = path.join(__dirname, '..');
const MOD = path.join(ROOT, 'Contents', 'mods', 'MoreVehiclesRepairs');
const LUA = path.join(MOD, '42', 'media', 'lua');
const TR = path.join(MOD, 'common', 'media', 'lua', 'shared', 'Translate');
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

// ---------- 1. syntax ----------
const luaFiles = files.filter((f) => f.endsWith('.lua'));
for (const f of fs.readdirSync(__dirname)) if (f.endsWith('.lua')) luaFiles.push(path.join(__dirname, f));
let syntaxErrors = 0;
for (const f of luaFiles) {
  try { luaparse.parse(fs.readFileSync(f, 'utf8'), { luaVersion: '5.1' }); } catch (e) { syntaxErrors++; fail('syntax ' + path.relative(ROOT, f) + ': ' + e.message); }
  if (f.includes('Contents') && /\bgoto\b|\/\/|getSpecificPlayer\(0\)|getPlayer\(\)/.test(fs.readFileSync(f, 'utf8'))) fail('forbidden construct (goto, //, getSpecificPlayer(0), getPlayer()) in ' + path.relative(ROOT, f));
}
if (!syntaxErrors) ok(`Lua syntax (5.1): ${luaFiles.length} files, 0 errors`);

// ---------- 2. layout ----------
for (const rel of ['mod.info', 'poster.png', 'icon.png', '42/mod.info', '42/poster.png', '42/icon.png', '42/media/sandbox-options.txt',
  '42/media/lua/shared/MVR/Core.lua', '42/media/lua/shared/MVR/Config.lua', '42/media/lua/shared/MVR/Game.lua',
  '42/media/lua/shared/TimedActions/MVR_RepairAction.lua', '42/media/lua/client/MVR/Menu.lua']) {
  if (!fs.existsSync(path.join(MOD, rel))) fail('missing ' + rel);
}
for (const mi of ['mod.info', '42/mod.info']) {
  const t = fs.readFileSync(path.join(MOD, mi), 'utf8');
  if (!/^id=MoreVehiclesRepairs$/m.test(t)) fail(mi + ' id');
  if (!/^name=Basic Vehicle Maintenance$/m.test(t)) fail(mi + ' name');
  if (!/^icon=icon\.png$/m.test(t) || !/^poster=poster\.png$/m.test(t)) fail(mi + ' icon/poster');
  if ((t.match(/^description=/mg) || []).length !== 1) fail(mi + ' must have exactly one description line');
}
if (!/^versionMin=42\.15$/m.test(fs.readFileSync(path.join(MOD, '42/mod.info'), 'utf8'))) fail('42/mod.info versionMin');
if (fs.existsSync(path.join(MOD, 'media'))) fail('root media/ must not exist (B42-only mod)');
const ws = fs.readFileSync(path.join(ROOT, 'workshop.txt'), 'utf8');
if (!/^id=3643006111$/m.test(ws) || !/^title=Basic Vehicle Maintenance$/m.test(ws)) fail('workshop.txt id/title');
const png = (p) => { const b = fs.readFileSync(p); return [b.readUInt32BE(16), b.readUInt32BE(20)].join('x'); };
for (const d of ['', '42']) {
  if (png(path.join(MOD, d, 'poster.png')) !== '512x512' || png(path.join(MOD, d, 'icon.png')) !== '64x64') fail('image sizes in ' + (d || 'root'));
}
if (png(path.join(ROOT, 'preview.png')) !== '256x256') fail('preview.png 256x256');
for (const f of files) {
  if (/\.(lua|txt|json)$/.test(f) && /MVR_RepairConfig|MVR_CasualRepairAction|SetScratchedWindow|setBurned\(|Unhappyness|PipeWrench/.test(fs.readFileSync(f, 'utf8'))) fail('v1 leftover / non-existent API in ' + path.relative(MOD, f));
}
ok('layout, mod.info, workshop.txt, image sizes, no v1 leftovers / invented APIs');

// ---------- 3. translations ----------
try { execFileSync(process.execPath, [path.join(ROOT, 'tools', 'translations.js'), '--check'], { stdio: 'pipe' }); ok('translation JSON up to date with tools/translations.js'); } catch (e) { fail('translations stale: ' + e.stdout); }
const sets = { EN: {}, PTBR: {} };
const all = { EN: {}, PTBR: {} };
for (const lang of ['EN', 'PTBR']) {
  for (const f of ['ContextMenu', 'Tooltip', 'IG_UI', 'Sandbox']) {
    const p = path.join(TR, lang, f + '.json');
    try { sets[lang][f] = JSON.parse(fs.readFileSync(p, 'utf8')); Object.assign(all[lang], sets[lang][f]); } catch (e) { fail('json ' + p + ': ' + e.message); sets[lang][f] = {}; }
    const prefix = { ContextMenu: 'ContextMenu_', Tooltip: 'Tooltip_', IG_UI: 'IGUI_', Sandbox: 'Sandbox_' }[f];
    for (const k of Object.keys(sets[lang][f])) if (!k.startsWith(prefix + 'MVR')) fail(`${lang}/${f}.json key ${k} must start with ${prefix}MVR`);
  }
}
for (const f of Object.keys(sets.EN)) {
  const a = Object.keys(sets.EN[f]).sort(); const b = Object.keys(sets.PTBR[f]).sort();
  if (JSON.stringify(a) !== JSON.stringify(b)) fail(`${f}: EN and PTBR key sets differ`);
  for (const [k, v] of Object.entries(sets.PTBR[f])) {
    if (!v || v === k) fail('PTBR empty ' + k);
    const pe = (sets.EN[f][k] || '').match(/%\d/g) || []; const pp = v.match(/%\d/g) || [];
    if (pe.sort().join() !== pp.sort().join()) fail('placeholder mismatch ' + k);
  }
}
if (!/ção|ã|é/.test(JSON.stringify(sets.PTBR))) fail('PTBR accents (UTF-8) missing');
// sandbox options <-> translations <-> Core.SandboxSpec
const sb = fs.readFileSync(path.join(MOD, '42/media/sandbox-options.txt'), 'utf8');
const sbNames = [...sb.matchAll(/^option MVR\.(\w+)/gm)].map((m) => m[1]);
for (const m of sb.matchAll(/translation = (\w+)/g)) {
  for (const lang of ['EN', 'PTBR']) if (!all[lang]['Sandbox_' + m[1]] || !all[lang]['Sandbox_' + m[1] + '_tooltip']) fail(`${lang} sandbox text ${m[1]}`);
}
for (const m of sb.matchAll(/page = (\w+)/g)) if (!all.EN['Sandbox_' + m[1]]) fail('sandbox page text ' + m[1]);
const core = fs.readFileSync(path.join(LUA, 'shared/MVR/Core.lua'), 'utf8');
const specNames = [...core.matchAll(/^\s{4}(\w+) = \{ [^}]*\},$/gm)].map((m) => m[1]);
if (JSON.stringify(sbNames.slice().sort()) !== JSON.stringify(specNames.slice().sort())) fail('sandbox-options.txt options != Core.SandboxSpec: ' + sbNames + ' / ' + specNames);
// literal getText keys in Lua exist
for (const f of luaFiles.filter((x) => x.includes('Contents'))) {
  for (const m of fs.readFileSync(f, 'utf8').matchAll(/getText\("(\w+)"\s*[,)]/g)) {
    if (!/^IGUI_Vehicle(Part|Name)$/.test(m[1]) && !all.EN[m[1]]) fail(`getText key ${m[1]} missing (${path.basename(f)})`);
  }
}
// dynamic keys: statuses, tiers, tools, risks, requirements, outcomes
const dyn = [];
for (const s of ['disabled', 'not_repairable', 'not_installed', 'undamaged', 'above_cap', 'skill', 'missing_tools', 'missing_materials']) dyn.push('Tooltip_MVR_Status_' + s, 'IGUI_MVR_Fail_' + s);
for (const t of ['patch', 'repair', 'overhaul']) dyn.push('ContextMenu_MVR_Tier_' + t);
for (const t of ['WRENCH', 'SCREWDRIVER', 'SEWING_NEEDLE']) dyn.push('Tooltip_MVR_Tool_' + t);
for (const t of ['low', 'medium', 'high']) dyn.push('Tooltip_MVR_Risk_' + t);
for (const t of ['Mechanics', 'MetalWelding', 'Electricity', 'ShelterOrJack']) dyn.push('Tooltip_MVR_Req_' + t);
for (const t of ['success', 'crit', 'light', 'severe']) for (const n of [1, 2, 3]) dyn.push(`IGUI_MVR_Say_${t}_${n}`);
for (const t of ['Injury', 'Burn', 'ToolWear', 'Frustration', 'Waste']) dyn.push('IGUI_MVR_Event_' + t);
for (const k of dyn) if (!all.EN[k]) fail('dynamic translation key missing: ' + k);
ok(`translations: ${Object.keys(all.EN).length} keys, EN == PTBR key sets + placeholders, sandbox + getText + dynamic keys present`);

// ---------- 4. Lua specs in fengari ----------
const fixture = JSON.parse(fs.readFileSync(path.join(__dirname, 'fixtures', 'vanilla.json'), 'utf8'));
function run(L, code) {
  if (lauxlib.luaL_dostring(L, to_luastring(code)) !== lua.LUA_OK) throw new Error(lua.lua_tojsstring(L, -1));
  const v = lua.lua_gettop(L) > 0 ? lua.lua_tonumber(L, -1) : undefined;
  lua.lua_settop(L, 0);
  return v;
}
const luaStr = (s) => JSON.stringify(s);
const luaSet = (arr) => '{' + arr.map((x) => `[${luaStr(x)}]=true`).join(',') + '}';
const luaArr = (arr) => '{' + arr.map(luaStr).join(',') + '}';
const luaMap = (obj) => '{' + Object.entries(obj).map(([k, v]) => `[${luaStr(k)}]=${luaStr(v)}`).join(',') + '}';
const prelude = `PARTIDS=${luaArr(fixture.partIds)}; ITEMS=${luaSet(fixture.items)}; TR=${luaMap(all.EN)};
  ACTIONFILE=${luaStr(fwd(path.join(LUA, 'shared/TimedActions/MVR_RepairAction.lua')))}; MENUFILE=${luaStr(fwd(path.join(LUA, 'client/MVR/Menu.lua')))};`;
for (const spec of ['core_spec.lua', 'game_spec.lua']) {
  const L = lauxlib.luaL_newstate();
  lualib.luaL_openlibs(L);
  try {
    run(L, `package.path = ${luaStr(fwd(LUA) + '/shared/?.lua;')} .. package.path`);
    const n = run(L, prelude + ` return dofile(${luaStr(fwd(path.join(__dirname, spec)))})`);
    if (n !== 0) fail(`${spec}: ${n} failure(s)`); else ok(spec);
  } catch (e) { fail(`${spec} crashed: ${e.message}`); }
}

console.log(failed ? `\n${failed} FAILURE(S)` : '\nALL TESTS PASSED');
process.exit(failed ? 1 : 0);
