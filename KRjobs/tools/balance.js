// KRjobs balance formula (shared by tests and docs). Calibrated on the 25 vanilla B42 professions
// (tests/fixtures/vanilla_professions_b42.json, 42.19.2): mean absolute error ~1.5 points.
//
//   value V  = sum(skill weight * levels)                     profession + trait XPBoosts
//            + recipeValue(#granted recipes)                    0 / 1 (1-5 recipes) / 2 (6+)
//            + 1 per starting kit (Lua, 1-3 tools/clothes)
//            + value of granted vanilla profession traits (VANILLA_TRAIT_VALUE)
//   expected Cost = 8 - V          (unemployed = +8 with nothing)
//
// Weights: 2 = combat / physical skills and the "gated tech" skills that unlock whole systems
// (Electricity, MetalWelding, Mechanics, Blacksmith); 1.5 = Maintenance; 1 = every other craft/survival skill.
// Rules enforced for KRjobs professions (both builds):
//   |Cost - expected| <= 2, Cost in [-8, +2], total levels in [3, 9], no skill above 6,
//   at most 7 levels in weight-2 skills, at least one own profession trait.

const W2 = ['Fitness', 'Strength', 'Sprinting', 'Nimble', 'Lightfoot', 'Sneak', 'Aiming', 'Reloading', 'Axe', 'Blunt', 'SmallBlunt',
  'LongBlade', 'SmallBlade', 'Spear', 'Electricity', 'MetalWelding', 'Mechanics', 'Blacksmith'];
const weight = (perk) => (W2.includes(perk) ? 2 : perk === 'Maintenance' ? 1.5 : 1);
const recipeValue = (n) => (n === 0 ? 0 : n <= 5 ? 1 : 2);
const VANILLA_TRAIT_VALUE = {
  'base:desensitized': 6, 'base:burglar': 3, 'base:marksman': 3, 'base:nutritionist2': 2, 'base:axeman': 2, 'base:mechanics2': 2,
  'base:inventive_prof': 2, 'base:blacksmith2': 2, 'base:cook2': 1, 'base:nightowl': 1, 'base:herbalist_prof': 1,
  Mechanics2: 2, NightOwl: 1,
};
const LIMITS = { tolerance: 2, minCost: -8, maxCost: 2, minLevels: 3, maxLevels: 9, maxSkill: 6, maxW2Levels: 7, vanillaMAE: 2 };

const xpValue = (xp) => Object.entries(xp || {}).reduce((a, [k, v]) => a + weight(k) * v, 0);

// prof: { xp, recipes:[], vtraits:[] }, traits: [{ xp, recipes:[], kit:[] }]
function evaluate(prof, traits) {
  let V = xpValue(prof.xp) + recipeValue((prof.recipes || []).length);
  const levels = {};
  const add = (xp) => { for (const [k, v] of Object.entries(xp || {})) levels[k] = (levels[k] || 0) + v; };
  add(prof.xp);
  for (const t of traits) {
    V += xpValue(t.xp) + recipeValue((t.recipes || []).length) + ((t.kit || []).length ? 1 : 0);
    add(t.xp);
  }
  for (const vt of prof.vtraits || []) V += VANILLA_TRAIT_VALUE[vt] || 0;
  const total = Object.values(levels).reduce((a, b) => a + b, 0);
  const w2 = Object.entries(levels).filter(([k]) => weight(k) === 2).reduce((a, [, v]) => a + v, 0);
  const maxSkill = Math.max(0, ...Object.values(levels));
  return { value: V, expected: 8 - V, total, w2, maxSkill, levels };
}

function check(prof, traits, cost) {
  const e = evaluate(prof, traits);
  const errs = [];
  if (Math.abs(cost - e.expected) > LIMITS.tolerance) errs.push(`cost ${cost} vs expected ${e.expected}`);
  if (cost < LIMITS.minCost || cost > LIMITS.maxCost) errs.push(`cost ${cost} out of [${LIMITS.minCost},${LIMITS.maxCost}]`);
  if (e.total < LIMITS.minLevels || e.total > LIMITS.maxLevels) errs.push(`total levels ${e.total}`);
  if (e.maxSkill > LIMITS.maxSkill) errs.push(`skill above ${LIMITS.maxSkill}`);
  if (e.w2 > LIMITS.maxW2Levels) errs.push(`${e.w2} levels in weight-2 skills`);
  return { ...e, errs };
}

module.exports = { weight, recipeValue, VANILLA_TRAIT_VALUE, LIMITS, evaluate, check, xpValue };
