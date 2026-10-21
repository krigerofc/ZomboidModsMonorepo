// Regenerates tests/fixtures/vanilla.json from a local Project Zomboid install (dev only).
// Usage: node tools/gen-fixtures.js [path-to-ProjectZomboid]
// Collects: every concrete vehicle part id declared in vanilla vehicle scripts, and every item
// type of module Base (so tests can check that Config.lua only references items that exist).
const fs = require('fs');
const path = require('path');

const GAME = process.argv[2] || 'E:/SteamLibrary/steamapps/common/ProjectZomboid';
const GEN = path.join(GAME, 'media', 'scripts', 'generated');

function walk(dir, out = []) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, out); else if (p.endsWith('.txt')) out.push(p);
  }
  return out;
}

const partIds = new Set();
for (const f of walk(path.join(GEN, 'vehicles'))) {
  for (const m of fs.readFileSync(f, 'utf8').matchAll(/^\s*part\s+([A-Za-z0-9_]+)\s*$/gm)) partIds.add(m[1]);
}
const items = new Set();
for (const f of walk(path.join(GEN, 'items'))) {
  for (const m of fs.readFileSync(f, 'utf8').matchAll(/^\s*item\s+([A-Za-z0-9_]+)\s*$/gm)) items.add('Base.' + m[1]);
}
const out = {
  source: 'Project Zomboid ' + (fs.existsSync(path.join(GAME, 'ProjectZomboid64.json')) ? 'local install' : GAME) + ' (42.19.2 when generated)',
  partIds: [...partIds].sort(),
  items: [...items].sort(),
};
fs.writeFileSync(path.join(__dirname, '..', 'tests', 'fixtures', 'vanilla.json'), JSON.stringify(out, null, 1) + '\n');
console.log(`partIds=${out.partIds.length} items=${out.items.length}`);
