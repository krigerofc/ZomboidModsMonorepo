// Test runner for KRjobs v2: static checks (luaparse, layout, scripts, recipes, perks, translations, balance)
// + Lua specs executed in fengari (Lua 5.3 VM; mod code sticks to the Lua 5.1 subset used by Kahlua). Usage: npm test
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const luaparse = require('luaparse');
const { lua, lauxlib, lualib, to_luastring } = require('fengari');
const D = require('../tools/data');
const B = require('../tools/balance');
const G = require('../tools/gen');

const ROOT = path.join(__dirname, '..');
const MOD = path.join(ROOT, 'Contents', 'mods', 'KRjobs');
const MEDIA = { 42: path.join(MOD, '42', 'media'), 41: path.join(MOD, 'media') };
const TR42 = path.join(MOD, 'common', 'media', 'lua', 'shared', 'Translate');
const FX = (f) => JSON.parse(fs.readFileSync(path.join(__dirname, 'fixtures', f), 'utf8'));
const PERKS = FX('perks.json');
const RECIPES42 = FX('recipes_b42.json');
const RECIPES41 = new Set(FX('recipes_b41.json').recipes.map((r) => r.toLowerCase()));
const ITEMS = { 42: new Set(FX('items_b42.json').items), 41: new Set(FX('items_b41.json').items.filter((k) => k.startsWith('Base.'))) };
const V42 = FX('vanilla_b42.json');
const V41 = FX('vanilla_b41.json');
let failed = 0;
const fail = (m) => { failed++; console.log('FAIL: ' + m); };
const ok = (m) => console.log('ok   ' + m);
const fwd = (p) => p.replace(/\\/g, '/');
function walk(dir, out = []) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) { const p = path.join(dir, e.name); e.isDirectory() ? walk(p, out) : out.push(p); }
  return out;
}
const files = walk(path.join(ROOT, 'Contents'));

// ---------- 1. generated files up to date ----------
try { execFileSync(process.execPath, [path.join(ROOT, 'tools', 'gen.js'), '--check'], { stdio: 'pipe' }); ok('generated files up to date (scripts, registries, B41 Lua, kits, translations, mirrors)'); } catch (e) { fail('tools/gen.js --check: ' + e.stdout); }

// ---------- 2. syntax ----------
const luaFiles = files.filter((f) => f.endsWith('.lua') || /Translate[\\/][A-Z]+[\\/]UI_[A-Z]+\.txt$/.test(f))
  .concat(walk(path.join(ROOT, 'src')).filter((f) => f.endsWith('.lua')), fs.readdirSync(__dirname).filter((f) => f.endsWith('.lua')).map((f) => path.join(__dirname, f)));
let syntaxErrors = 0;
for (const f of luaFiles) {
  const src = fs.readFileSync(f, /PTBR/.test(f) && f.endsWith('.txt') ? 'latin1' : 'utf8');
  try { luaparse.parse(src, { luaVersion: '5.1' }); } catch (e) { syntaxErrors++; fail('syntax ' + path.relative(ROOT, f) + ': ' + e.message); }
}
if (!syntaxErrors) ok(`Lua syntax (5.1): ${luaFiles.length} files, 0 errors`);
const json = {};
for (const f of files.filter((f) => f.endsWith('.json'))) { try { json[f] = JSON.parse(fs.readFileSync(f, 'utf8')); } catch (e) { fail('json ' + f + ': ' + e.message); } }
ok(`JSON parse: ${Object.keys(json).length} files`);

// ---------- 3. layout, mod.info, workshop, images, v1 leftovers ----------
for (const rel of ['mod.info', 'poster.png', 'icon.png', '42/mod.info', '42/poster.png', '42/icon.png', '42/media/registries.lua',
  'common/media/lua/shared/Translate/EN/UI.json', 'common/media/lua/shared/Translate/PTBR/UI.json',
  'media/lua/shared/Translate/EN/UI_EN.txt', 'media/lua/shared/Translate/PTBR/UI_PTBR.txt']) {
  if (!fs.existsSync(path.join(MOD, rel))) fail('missing ' + rel);
}
for (const mi of ['mod.info', '42/mod.info']) {
  const t = fs.readFileSync(path.join(MOD, mi), 'utf8');
  if (!/^id=Krjobs$/m.test(t)) fail(mi + ' id must stay Krjobs');
  if (!/^icon=icon\.png$/m.test(t) || !/^poster=poster\.png$/m.test(t)) fail(mi + ' icon/poster');
  if ((t.match(/^description=/mg) || []).length !== 1) fail(mi + ' exactly one description line');
}
if (!/^versionMin=42\.15$/m.test(fs.readFileSync(path.join(MOD, '42/mod.info'), 'utf8'))) fail('42/mod.info versionMin=42.15 (registries API)');
if (!/^id=3149644183$/m.test(fs.readFileSync(path.join(ROOT, 'workshop.txt'), 'utf8'))) fail('workshop.txt id');
const png = (p) => { const b = fs.readFileSync(p); return [b.readUInt32BE(16), b.readUInt32BE(20)].join('x'); };
for (const p of ['poster.png', '42/poster.png']) if (png(path.join(MOD, p)) !== '512x512') fail(p + ' must be 512x512');
for (const p of ['icon.png', '42/icon.png']) if (png(path.join(MOD, p)) !== '64x64') fail(p + ' must be 64x64');
if (png(path.join(ROOT, 'preview.png')) !== '256x256') fail('preview.png must be 256x256');
for (const f of files.filter((f) => /media[\\/]textures[\\/].*\.png$/.test(f))) if (png(f) !== '64x64') fail('profession icon not 64x64: ' + path.relative(MOD, f));
for (const f of files) {
  if (!/\.(lua|txt|json)$/.test(f)) continue;
  const s = fs.readFileSync(f, 'latin1');
  if (/Perks\.(Agility|Lightfooted)|BEFProfessions|krprofissions/.test(s)) fail('v1 leftover in ' + path.relative(MOD, f));
  if (f.includes(path.join('KRjobs', '42')) && /ProfessionFactory|TraitFactory/.test(s)) fail('B42 must not use ProfessionFactory/TraitFactory: ' + path.relative(MOD, f));
}
ok('layout, mod.info (id Krjobs, icon, versionMin 42.15), workshop id, image sizes, no v1 leftovers');

// ---------- 4. translations ----------
const readB41 = (lang) => {
  const txt = fs.readFileSync(path.join(MEDIA[41], 'lua', 'shared', 'Translate', lang, `UI_${lang}.txt`), lang === 'EN' ? 'utf8' : 'latin1');
  const out = {};
  for (const l of txt.split(/\r?\n/)) { const m = l.match(/^\s*([\w.]+)\s*=\s*"(.*)",\s*$/); if (m) out[m[1]] = m[2]; }
  return out;
};
const TR = {
  42: { EN: json[path.join(TR42, 'EN', 'UI.json')] || {}, PTBR: json[path.join(TR42, 'PTBR', 'UI.json')] || {} },
  41: { EN: readB41('EN'), PTBR: readB41('PTBR') },
};
const sameKeys = (a, b) => JSON.stringify(Object.keys(a).sort()) === JSON.stringify(Object.keys(b).sort());
for (const b of ['42', '41']) {
  if (!sameKeys(TR[b].EN, TR[b].PTBR)) fail(`B${b} UI: EN and PTBR key sets differ`);
  for (const lang of ['EN', 'PTBR']) for (const [k, v] of Object.entries(TR[b][lang])) if (!v || v === k) fail(`B${b} ${lang} empty ${k}`);
}
if (!sameKeys(json[path.join(TR42, 'EN', 'Mod.json')], json[path.join(TR42, 'PTBR', 'Mod.json')])) fail('Mod.json EN/PTBR keys differ');
if (TR[41].PTBR.UI_prof_KRjobs_surgeon !== 'Cirurgião Especialista') fail('B41 PTBR encoding (latin1) broken');
if (TR[42].PTBR.UI_prof_KRjobs_chemengineer !== 'Engenheiro Químico') fail('B42 PTBR UTF-8 sample');
const nonLatin1 = Object.values(TR[42].PTBR).concat(Object.values(TR[42].EN)).filter((s) => /[^\x00-\xff]/.test(s));
if (nonLatin1.length) fail('texts must be Latin-1 safe (B41 Cp1252): ' + nonLatin1[0]);
ok(`translations: EN == PTBR key sets (B42 ${Object.keys(TR[42].EN).length} keys + Mod.json, B41 ${Object.keys(TR[41].EN).length} keys), latin1 PTBR, no empty values`);

// ---------- 5. B42 scripts ----------
const PROF_KEYS = ['CharacterProfession', 'Cost', 'UIName', 'UIDescription', 'IconPathName', 'GrantedTraits', 'XPBoosts', 'GrantedRecipes'];
const TRAIT_KEYS = ['CharacterTrait', 'UIName', 'Cost', 'UIDescription', 'IsProfessionTrait', 'DisabledInMultiplayer', 'GrantedRecipes', 'GrantedTraits', 'XPBoosts', 'MutuallyExclusiveTraits', 'Texture'];
// B42.19.2 ScriptParser.stripComments removes only /* ... */; CreateFromToken
// silently ignores the whole module when its trimmed token does not start with module.
// This models that lexical boundary, not the complete native script parser.
const nativeModuleToken = (src) => src.replace(/\/\*[\s\S]*?\*\//g, '').trim().indexOf('module') === 0;
if (nativeModuleToken('// GENERATED\nmodule Base\n{\n}\n')) fail('native module boundary must reject a leading // header');
if (!nativeModuleToken('/* GENERATED */\nmodule Base\n{\n}\n')) fail('native module boundary must accept a leading block comment');
ok('native module boundary controls: // header rejected, block comment accepted');
function parseScript(file, kw) {
  const src = fs.readFileSync(file, 'utf8');
  if (!nativeModuleToken(src)) fail(path.basename(file) + ' is ignored by the native B42 module boundary (only block comments may precede module)');
  if ((src.match(/{/g) || []).length !== (src.match(/}/g) || []).length) fail('braces unbalanced in ' + path.basename(file));
  if (!/^module Base\s*$/m.test(src)) fail(path.basename(file) + ' must use module Base (unqualified recipe names resolve like vanilla)');
  const out = {};
  for (const m of src.matchAll(new RegExp(kw + '\\s+(\\S+)\\s*\\{([^}]*)\\}', 'g'))) {
    const props = {};
    for (const line of m[2].split(/\r?\n/).map((l) => l.trim()).filter(Boolean)) {
      const mm = line.match(/^(\w+)\s*=\s*(.*),$/);
      if (!mm) { fail(`bad line in ${m[1]}: ${line}`); continue; }
      props[mm[1]] = mm[2];
    }
    out[m[1]] = props;
  }
  return out;
}
const reg = fs.readFileSync(path.join(MEDIA[42], 'registries.lua'), 'utf8');
const regTraits = new Set([...reg.matchAll(/CharacterTrait\.register\("([^"]+)"\)/g)].map((m) => m[1]));
const regProfs = new Set([...reg.matchAll(/CharacterProfession\.register\("([^"]+)"\)/g)].map((m) => m[1]));
const sTraits = parseScript(path.join(MEDIA[42], 'scripts', 'KRjobs_traits.txt'), 'character_trait_definition');
const sProfs = parseScript(path.join(MEDIA[42], 'scripts', 'KRjobs_professions.txt'), 'character_profession_definition');
const vanillaProfTraits42 = new Set(Object.entries(V42.traits).filter(([, t]) => t.isProfessionTrait).map(([k]) => k));
const learnable = new Set(RECIPES42.learnable);
const allRecipes = new Set(RECIPES42.all);
const checkXP = (where, str, perks) => {
  for (const pair of (str || '').split(';').filter(Boolean)) {
    const [perk, lvl] = pair.split('=');
    if (PERKS.categories.includes(perk)) fail(`${where}: ${perk} is a perk category, not a skill`);
    else if (!perks.includes(perk)) fail(`${where}: unknown perk ${perk}`);
    if (!/^[1-6]$/.test(lvl)) fail(`${where}: bad level ${pair}`);
  }
};
const keyExists = (k) => TR[42].EN[k] && TR[42].PTBR[k];
let recipeCount42 = 0;
for (const [id, t] of Object.entries(sTraits)) {
  for (const k of Object.keys(t)) if (!TRAIT_KEYS.includes(k)) fail(`trait ${id}: unknown key ${k}`);
  if (!regTraits.has(id)) fail(`trait ${id} not registered in registries.lua`);
  if (t.CharacterTrait !== id) fail(`trait ${id}: CharacterTrait mismatch`);
  if (t.IsProfessionTrait !== 'true' || t.Cost !== '0' || t.DisabledInMultiplayer !== 'false') fail(`trait ${id}: must be a 0-cost MP-enabled profession trait`);
  if (!keyExists(t.UIName) || !keyExists(t.UIDescription)) fail(`trait ${id}: missing translation`);
  checkXP('trait ' + id, t.XPBoosts, PERKS.b42);
  for (const r of (t.GrantedRecipes || '').split(';').filter(Boolean)) {
    recipeCount42++;
    if (!allRecipes.has(r)) fail(`trait ${id}: recipe ${r} does not exist in vanilla 42.19.2`);
    else if (!learnable.has(r)) fail(`trait ${id}: recipe ${r} is not learnable (needTobeLearn), granting it is pointless`);
  }
}
const usedTraits = new Set();
for (const [id, p] of Object.entries(sProfs)) {
  for (const k of Object.keys(p)) if (!PROF_KEYS.includes(k)) fail(`profession ${id}: unknown key ${k}`);
  if (!regProfs.has(id)) fail(`profession ${id} not registered`);
  if (p.CharacterProfession !== id) fail(`profession ${id}: CharacterProfession mismatch`);
  if (!keyExists(p.UIName) || !keyExists(p.UIDescription)) fail(`profession ${id}: missing translation`);
  checkXP('profession ' + id, p.XPBoosts, PERKS.b42);
  const own = [];
  for (const t of (p.GrantedTraits || '').split(';').filter(Boolean)) {
    if (sTraits[t]) { own.push(t); usedTraits.add(t); } else if (!vanillaProfTraits42.has(t)) fail(`profession ${id}: trait ${t} is neither ours (registered) nor a vanilla profession trait`);
  }
  if (own.length < 1 || own.length > 2) fail(`profession ${id}: needs 1-2 own profession traits, has ${own.length}`);
  if (!V42.icons.includes(p.IconPathName) && !fs.existsSync(path.join(MEDIA[42], 'textures', p.IconPathName + '.png'))) fail(`profession ${id}: icon ${p.IconPathName} not found`);
}
for (const t of regTraits) if (!sTraits[t]) fail(`registered trait ${t} has no definition`);
for (const t of Object.keys(sTraits)) if (!usedTraits.has(t)) fail(`trait ${t} is not granted by any profession`);
for (const p of regProfs) if (!sProfs[p]) fail(`registered profession ${p} has no definition`);
if (Object.keys(sProfs).length < 20 || Object.keys(sProfs).length > 25) fail('B42 must have 20-25 professions');
ok(`B42 scripts: ${Object.keys(sProfs).length} professions, ${Object.keys(sTraits).length} traits, all registered; perks valid; ${recipeCount42} granted recipes exist + learnable; icons + translations present`);

// ---------- 6. B41 Lua in fengari with factory mocks ----------
function newLua() { const L = lauxlib.luaL_newstate(); lualib.luaL_openlibs(L); return L; }
function run(L, code) {
  if (lauxlib.luaL_dostring(L, to_luastring(code)) !== lua.LUA_OK) throw new Error(lua.lua_tojsstring(L, -1));
  const n = lua.lua_gettop(L);
  const v = n > 0 ? (lua.lua_isstring(L, -1) ? lua.lua_tojsstring(L, -1) : lua.lua_tonumber(L, -1)) : undefined;
  lua.lua_settop(L, 0);
  return v;
}
const luaSet = (arr) => '{' + arr.map((x) => `[${JSON.stringify(x)}]=true`).join(',') + '}';
const luaMap = (obj) => '{' + Object.entries(obj).map(([k, v]) => `[${JSON.stringify(k)}]=${JSON.stringify(v)}`).join(',') + '}';
const b41Report = (() => {
  const L = newLua();
  const prelude = `
    PERKSET=${luaSet(PERKS.b41)}; TR=${luaMap(TR[41].EN)}; MISSING={}
    Perks = setmetatable({}, { __index = function(_, k) if PERKSET[k] then return 'perk:'..k end MISSING[#MISSING+1]='perk '..tostring(k); return nil end })
    function getText(k) if not TR[k] then MISSING[#MISSING+1]='text '..k end return TR[k] or k end
    local function obj(kind, t) t.boosts={}; t.recipes={}; t.free={}
      function t:addXPBoost(p, n) self.boosts[#self.boosts+1]=p..'='..n end
      function t:getFreeRecipes() local s=self; return { add=function(_, r) s.recipes[#s.recipes+1]=r end } end
      function t:addFreeTrait(x) self.free[#self.free+1]=x end
      return t end
    TRAITS={}; PROFS={}; NT=0; NP=0
    TraitFactory = { getTrait=function(id) return TRAITS[id] end, sortList=function() end,
      addTrait=function(id, name, cost, desc, prof) NT=NT+1; local t=obj('trait',{id=id,name=name,cost=cost,desc=desc,prof=prof}); TRAITS[id]=t; return t end }
    ProfessionFactory = { getProfession=function(id) return PROFS[id] end,
      addProfession=function(id, name, icon, cost, desc) NP=NP+1; local p=obj('prof',{id=id,name=name,icon=icon,cost=cost,desc=desc}); PROFS[id]=p; return p end }
    DESCS=0
    BaseGameCharacterDetails = { SetProfessionDescription=function() DESCS=DESCS+1 end, SetTraitDescription=function() end }
    HANDLERS={}
    Events = { OnGameBoot={ Add=function(f) HANDLERS[#HANDLERS+1]=f end }, OnCreateLivingCharacter={ Add=function(f) HANDLERS[#HANDLERS+1]=f end } }
    package.preload["NPCs/MainCreationMethods"] = function() return true end`;
  run(L, prelude);
  run(L, `dofile(${JSON.stringify(fwd(path.join(MEDIA[41], 'lua', 'shared', 'NPCs', 'KRjobs_Professions.lua')))})`);
  run(L, 'for _, h in ipairs(HANDLERS) do h() end; for _, h in ipairs(HANDLERS) do h() end');
  const out = run(L, `local parts = {}
    local function esc(s) return (tostring(s):gsub('[|;,]', '_')) end
    for id, p in pairs(PROFS) do parts[#parts+1] = 'P|'..id..'|'..p.icon..'|'..p.cost..'|'..table.concat(p.boosts, ';')..'|'..table.concat(p.free, ';') end
    for id, t in pairs(TRAITS) do parts[#parts+1] = 'T|'..id..'|'..tostring(t.prof)..'|'..t.cost..'|'..table.concat(t.boosts, ';')..'|'..table.concat(t.recipes, ';') end
    parts[#parts+1] = 'N|'..NT..'|'..NP..'|'..DESCS..'|'..#HANDLERS
    for _, m in ipairs(MISSING) do parts[#parts+1] = 'M|'..m end
    return table.concat(parts, '\\n')`);
  return out.split('\n').map((l) => l.split('|'));
})();
{
  const profs = b41Report.filter((r) => r[0] === 'P');
  const traits = Object.fromEntries(b41Report.filter((r) => r[0] === 'T').map((r) => [r[1], r]));
  const n = b41Report.find((r) => r[0] === 'N');
  for (const m of b41Report.filter((r) => r[0] === 'M')) fail('B41 missing ' + m[1]);
  const expected = D.PROFESSIONS.filter((p) => !p.b42only).length;
  if (profs.length !== expected || +n[2] !== expected) fail(`B41 professions ${profs.length}/${n[2]} != ${expected} (or duplicates on re-run)`);
  if (+n[3] !== expected) fail('B41 SetProfessionDescription must run exactly once per profession (idempotent register)');
  if (+n[4] !== 2) fail('B41 must hook OnGameBoot + OnCreateLivingCharacter');
  const used = new Set();
  let rc = 0;
  for (const [, id, icon, , boosts, free] of profs) {
    for (const b of boosts.split(';').filter(Boolean)) if (!PERKS.b41.includes(b.split('=')[0].replace('perk:', ''))) fail(`B41 ${id}: perk ${b}`);
    let own = 0;
    for (const t of free.split(';').filter(Boolean)) { if (traits[t]) { own++; used.add(t); } else if (!V41.traits.includes(t)) fail(`B41 ${id}: free trait ${t} unknown`); }
    if (own < 1) fail(`B41 ${id}: no own profession trait`);
    if (!V41.icons.includes(icon) && !fs.existsSync(path.join(MEDIA[41], 'textures', icon + '.png'))) fail(`B41 ${id}: icon ${icon} missing`);
  }
  for (const [id, t] of Object.entries(traits)) {
    if (t[2] !== 'true' || t[3] !== '0') fail(`B41 trait ${id} must be a 0-cost profession trait`);
    if (!used.has(id)) fail(`B41 trait ${id} unused`);
    for (const r of t[5].split(';').filter(Boolean)) { rc++; if (!RECIPES41.has(r.toLowerCase())) fail(`B41 trait ${id}: recipe "${r}" not in 41.78 recipe list`); }
  }
  const v1 = ['Hitman', 'Architect', 'blacksmith', 'Survivalist', 'Car Modifier', 'Mailman', 'Fighter'];
  for (const t of v1) if (!profs.some((p) => p[1] === t)) fail('B41 must keep v1 profession type ' + t + ' (save compat)');
  ok(`B41 Lua (fengari mocks): ${profs.length} professions, ${Object.keys(traits).length} traits, idempotent on re-run, no unknown perk/text, ${rc} recipes exist in 41.78, v1 types kept`);
}

// ---------- 7. balance formula ----------
{
  let mae = 0; let n = 0;
  for (const [, p] of Object.entries(V42.professions)) {
    const traits = p.traits.map((t) => ({ xp: (V42.traits[t] || {}).xp, recipes: new Array((V42.traits[t] || {}).recipes || 0).fill('r') }));
    const e = B.evaluate({ xp: p.xp, recipes: new Array(p.recipes).fill('r'), vtraits: p.traits }, traits);
    mae += Math.abs(p.cost - e.expected); n++;
  }
  mae /= n;
  if (mae > B.LIMITS.vanillaMAE) fail(`balance formula calibration: vanilla MAE ${mae.toFixed(2)} > ${B.LIMITS.vanillaMAE}`);
  const lines = [];
  for (const b of ['42', '41']) {
    const v = G.view(b);
    const tById = Object.fromEntries(v.traits.map((t) => [t.type, t]));
    let worst = 0;
    for (const p of v.profs) {
      const r = B.check({ xp: p.xp, vtraits: p.vtraits }, p.traits.map((t) => tById[t]), p.cost);
      worst = Math.max(worst, Math.abs(p.cost - r.expected));
      for (const e of r.errs) fail(`balance B${b} ${p.id}: ${e}`);
    }
    lines.push(`B${b} ${v.profs.length} profs, worst |cost-expected| ${worst}`);
  }
  ok(`balance: formula vanilla MAE ${mae.toFixed(2)} (<= ${B.LIMITS.vanillaMAE}); ${lines.join('; ')} (tolerance ${B.LIMITS.tolerance})`);
}

// ---------- 8. kits: items exist + Lua spec per build ----------
for (const b of ['42', '41']) {
  const v = G.view(b);
  const expected = {};
  for (const t of v.traits) {
    if (!t.kit.length) continue;
    expected[t.type] = t.kit.length;
    for (const it of t.kit) if (!ITEMS[b].has(it)) fail(`B${b} kit ${t.id}: item ${it} does not exist in vanilla`);
  }
  const L = newLua();
  try {
    const shared = fwd(path.join(MEDIA[b], 'lua', 'shared'));
    run(L, `package.path = ${JSON.stringify(shared + '/?.lua;')} .. package.path`);
    const r = run(L, `BUILD=${b}; KITS_EXPECTED=${luaMap(expected)}; MAIN_FILE=${JSON.stringify(shared + '/KRjobs_Main.lua')}; return dofile(${JSON.stringify(fwd(path.join(__dirname, 'kits_spec.lua')))})`);
    if (+r !== 0) fail(`B${b} kits_spec: ${r} failure(s)`); else ok(`B${b} kits: ${Object.keys(expected).length} kits, items exist in vanilla, given once (kits_spec.lua)`);
  } catch (e) { fail(`B${b} kits_spec crashed: ${e.message}`); }
}

console.log(failed ? `\n${failed} FAILURE(S)` : '\nALL TESTS PASSED');
process.exit(failed ? 1 : 0);
