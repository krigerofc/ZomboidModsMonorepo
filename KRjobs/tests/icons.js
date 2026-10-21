// Icon resolution test: every profession's IconPathName (B42 scripts) and ProfessionFactory icon (B41 Lua)
// must resolve to a texture the game can load in that build:
//   - our own file media/textures/<name>.png (B42: 42/media/textures, B41: media/textures), or
//   - a vanilla profession icon (fixtures vanilla_b42/b41.json, built from the vanilla profession definitions).
// If a local PZ install is found (PZ_DIR or the default Steam path), B42 vanilla names are also checked
// against media/texturepacks/UI2.pack. Usage: node tests/icons.js (run by npm test)
const fs = require('fs');
const path = require('path');
const D = require('../tools/data');

const ROOT = path.join(__dirname, '..');
const MOD = path.join(ROOT, 'Contents', 'mods', 'KRjobs');
const TEX = { 42: path.join(MOD, '42', 'media', 'textures'), 41: path.join(MOD, 'media', 'textures') };
const FX = (f) => JSON.parse(fs.readFileSync(path.join(__dirname, 'fixtures', f), 'utf8'));
const VAN = { 42: new Set(FX('vanilla_b42.json').icons), 41: new Set(FX('vanilla_b41.json').icons) };
let failed = 0;
const fail = (m) => { failed++; console.log('FAIL: ' + m); };
const ok = (m) => console.log('ok   ' + m);

const PZ = process.env.PZ_DIR || 'E:/SteamLibrary/steamapps/common/ProjectZomboid';
const packPath = path.join(PZ, 'media', 'texturepacks', 'UI2.pack');
const pack = fs.existsSync(packPath) ? fs.readFileSync(packPath).toString('latin1') : null;

function resolves(build, name) {
  if (!name) return 'empty icon';
  if (name.startsWith('profession_krjobs_')) return fs.existsSync(path.join(TEX[build], name + '.png')) ? null : `missing ${path.relative(ROOT, path.join(TEX[build], name + '.png'))}`;
  if (!VAN[build].has(name)) return `not a vanilla B${build} profession icon`;
  if (build === 42 && pack && !pack.includes(name)) return 'not found in B42 UI2.pack';
  return null;
}

// 1. source of truth: every profession has an icon for each build it ships in
const used = { 42: new Set(), 41: new Set() };
for (const p of D.PROFESSIONS) {
  const builds = p.b42only ? [42] : [42, 41];
  for (const b of builds) {
    const icon = p['icon' + b];
    const err = resolves(b, icon);
    if (err) fail(`B${b} ${p.id}: icon ${icon}: ${err}`);
    used[b].add(icon);
  }
}

// 2. shipped files: what the game actually reads
const script42 = fs.readFileSync(path.join(MOD, '42', 'media', 'scripts', 'KRjobs_professions.txt'), 'utf8');
const icons42 = [...script42.matchAll(/IconPathName\s*=\s*([^,\s]+)/g)].map((m) => m[1]);
if (icons42.length !== D.PROFESSIONS.length) fail(`B42 script: ${icons42.length} IconPathName lines, expected ${D.PROFESSIONS.length}`);
for (const i of icons42) { const err = resolves(42, i); if (err) fail(`B42 script icon ${i}: ${err}`); }

const lua41 = fs.readFileSync(path.join(MOD, 'media', 'lua', 'shared', 'NPCs', 'KRjobs_Professions.lua'), 'utf8');
const icons41 = [...lua41.matchAll(/icon\s*=\s*"([^"]*)"/g)].map((m) => m[1]);
const n41 = D.PROFESSIONS.filter((p) => !p.b42only).length;
if (icons41.length !== n41) fail(`B41 Lua: ${icons41.length} icons, expected ${n41}`);
for (const i of icons41) { const err = resolves(41, i); if (err) fail(`B41 Lua icon ${i}: ${err}`); }

// 3. no orphan mod textures (every shipped profession_krjobs_*.png is used)
for (const b of [42, 41]) {
  for (const f of fs.readdirSync(TEX[b]).filter((f) => f.endsWith('.png'))) {
    if (!used[b].has(f.replace(/\.png$/, ''))) fail(`B${b} texture ${f} not used by any profession`);
  }
}

if (failed) { console.log(`\n${failed} icon check(s) failed`); process.exit(1); }
ok(`icons: ${icons42.length} B42 + ${icons41.length} B41 profession icons resolve (${pack ? 'UI2.pack checked' : 'no local PZ install, fixtures only'})`);
