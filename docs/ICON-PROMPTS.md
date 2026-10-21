# ICON-PROMPTS — KRjobs profession icons + Field Medicine '93 cover

Image-generation prompts (English) for the art still missing. Source of the list: `DECISIONS-KRjobs.md` § Ícones (13 professions marked `*`, currently on a vanilla placeholder icon).

## 1. KRjobs profession icons (13)

**Format:** PNG, **64×64**, RGBA with **transparent background**. Generate at 512×512 or 1024×1024 and downscale (nearest/box filter, then check readability at 64 px).

**Target paths** (repo `C:\Users\pedro\Zomboid\Workshop\KRjobs\`):
- B42: `Contents\mods\KRjobs\42\media\textures\profession_krjobs_<id>.png`
- B41: `Contents\mods\KRjobs\media\textures\profession_krjobs_<id>.png` (skip for the B42-only ones: glassblower, taxidermist, archaeologist)
- Then set `icon42` (and `icon41` when the profession exists in B41) to `profession_krjobs_<id>` in `tools\data.js`, run `npm run gen` and `npm test`.

**Shared style suffix (append to every prompt):**
> Project Zomboid vanilla profession icon style, single centered object or bust, small flat game icon, clean dark outline, simple cel shading with 2-3 tones, muted desaturated 1990s palette, bold readable silhouette at 64x64 pixels, transparent background, no text, no letters, no logos, no border, no drop shadow.

| # | Profession (EN / PT) | `<id>` | Prompt (subject) |
|---|---|---|---|
| 1 | Navy Rescue Diver / Mergulhador de Resgate | `diver` | A diving mask with snorkel resting over a coiled orange rescue rope, small yellow air tank behind it. |
| 2 | Navy SEAL | `navyseal` | A dark green military diving mask and a black combat knife crossed with a coiled swimmer fin, olive drab and black tones. |
| 3 | Fighter Pilot / Piloto de Caça | `fighterpilot` | A 1990s jet fighter pilot helmet with dark visor down and oxygen mask hanging, olive and grey tones. |
| 4 | Firearms Instructor / Instrutor de Tiro | `rangeinstructor` | Yellow shooting glasses on top of red ear-muff hearing protectors, a paper bullseye target behind them. |
| 5 | Systems Analyst / Analista de Sistemas | `sysanalyst` | A beige 1990s CRT computer monitor with green text glow on the screen, a floppy disk leaning against it. |
| 6 | Chemical Engineer / Engenheiro Químico | `chemengineer` | A glass Erlenmeyer flask with green liquid and a small test tube, white lab goggles beside it. |
| 7 | Robotics Engineer / Engenheiro de Robótica | `roboticsengineer` | A small mechanical robotic arm with exposed servo and wires, holding a screwdriver, grey and copper tones. |
| 8 | Bomb Disposal Technician / Técnico Antibombas | `bombtech` | A heavy olive bomb-disposal helmet with thick visor, a pair of wire cutters and one red and one blue wire in front. |
| 9 | Glassblower / Soprador de Vidro | `glassblower` | A long glassblowing pipe with a glowing orange molten glass bubble at the tip. |
| 10 | Oil Rig Roughneck / Peão de Plataforma | `roughneck` | A dirty white hard hat on top of a large red pipe wrench, oil stains, rugged industrial look. |
| 11 | Taxidermist / Taxidermista | `taxidermist` | A mounted deer head trophy on a small wooden plaque, a scalpel lying below it. |
| 12 | Locksmith / Chaveiro | `locksmith` | A brass padlock with a ring of old keys hanging from it, one key half inserted. |
| 13 | Field Archaeologist / Arqueólogo de Campo | `archaeologist` | A worn wide-brim field hat over a small trowel and a knapped flint arrowhead, earthy brown tones. |

Checks before committing: silhouette recognizable at 64 px, consistent outline weight with the 7 existing `profession_krjobs_*.png` (hitman, architect, ironworker, survivalist, hotrodder, mailcarrier, boxer), fully transparent corners.

## 2. Field Medicine '93 — cover

**Prompt:**
> A tired survivor medic kneeling beside a wounded survivor on the floor of an abandoned rural Kentucky house, tightening an improvised cloth tourniquet with a wooden stick on the patient's thigh, a stethoscope around the medic's neck, an open first-aid kit with bandages, a scalpel and a bottle of water on the floorboards, a kerosene lamp and boarded-up window behind, faint zombie silhouettes outside the window. Project Zomboid style, isometric 3/4 view, Kentucky 1993, muted desaturated palette, overcast light, gritty painterly texture, subtle film grain, square 1:1, bold readable silhouette, no text, no logos.

**Target paths / sizes** (repo `C:\Users\pedro\Zomboid\Workshop\FieldMedicine\`; generate at 1024×1024, then downscale):
| File | Size | Use |
|---|---|---|
| `preview.png` (repo root) | 256×256 | Steam Workshop preview (keep < 1 MB) |
| `Contents\mods\KRFieldMedicine\42\poster.png` | 512×512 | In-game mod list poster |
| `Contents\mods\KRFieldMedicine\42\icon.png` | 64×64 | In-game mod icon (crop to the tourniquet + hands, or the stethoscope, so it reads at 64 px) |

No B41 root files (mod is B42-only). Keep the originals next to the other covers in `C:\Users\pedro\Documents\Codex\2026-10-17\estilo-base-colar-no-fim-de-2\outputs\zomboid-game-style-v2\field-medicine\`.

## Ícones

Placeholders já estão no lugar; substituir pela arte gerada destes prompts depois (mesmos nomes de arquivo e tamanhos).
- KRjobs (13 sem ícone próprio): usam ícones vanilla por `IconPathName` (B42 e B41), ou um dos 7 do v1. Mergulhador `profession_fisher2`, Navy SEAL e Piloto de Caça `profession_veteran2`, Instrutor de Tiro `profession_krjobs_hitman` (revólver), Analista de Sistemas `profession_electrician`, Eng. Químico e Técnico Antibombas `profession_engineer`, Eng. de Robótica `profession_mechanic`, Soprador de Vidro `profession_smither` (só B42), Peão de Plataforma `profession_constructionworker2`, Taxidermista `profession_rancher` (só B42), Chaveiro `profession_burglar2`, Arqueólogo `profession_parkranger2` (só B42). `tests/icons.js` (no `npm test`) garante que todos resolvem. Ao trocar pela arte própria: salvar `profession_krjobs_<id>.png` 64×64 em `src/textures`, `42/media/textures` e `media/textures`, e mudar `icon42`/`icon41` em `tools/data.js` + `npm run gen`.
- Field Medicine: poster/icon/preview provisórios desenhados via PowerShell System.Drawing (maleta de primeiros socorros oliva/cáqui com cruz vermelha e granulado).
