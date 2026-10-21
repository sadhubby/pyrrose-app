# Phase 2b — Goxel rose → asset pipeline (converter + viewer + app)

## Research findings (all verified this session, in-memory prototypes)

1. **Goxel's glTF exporter has a real bug** — the vertex UVs address a **16×16** grid
   (`volume_to_vertices.c:313`: `s = max(next_pow2(ceil(log2(palette->size))), 16)`), but the palette
   texture is written into a **32×32** grid of 4px cells (`gltf.c:409`: `x = (k % (s/pix_size)) * pix_size`).
   So *every* viewer samples the wrong texel → wrong colours. Not our bug to fix in the viewer:
   we must recover the true palette index from the UV.
2. **True index is recoverable** from the UV alone (verified: 155 distinct cells, stem 100 % green,
   bloom 95 % warm):
   `cm = u*16 - 0.5`, `cq = v*16 - 0.5`, `c = 16*cq + cm` → palette entry `c` →
   4px block at `(c % 32, floor(c/32))` → sRGB bytes → **sRGB→linear**.
3. **Goxel also has a "Vertex Color" export option** (`gltf.c:502` checkbox) that writes `COLOR_0`
   directly, already **linear** (`srgba8_to_rgba` → `srgb8_to_rgb`). If the user's goxel has it,
   re-exporting is simpler and exact; the converter supports both paths.
4. **flutter_scene supports `COLOR_0`** (`primitive_packer.dart:172` → `_readOptionalColor`, VEC4
   float, used as-is, no sRGB conversion → linear required ✓). It also decomposes node matrices
   (`bounds_baker.dart:495`) so goxel's Z-up→Y-up root matrix is honoured → the flower stands upright.
5. **Pipeline validated end-to-end** with `@gltf-transform/core` 4.5.1 + `pngjs` 7.0.0:
   3 data-URI buffers → 1 merged buffer → palette baked to COLOR_0 → texture removed → `prune()` →
   GLB = **120 KB** (down from 167 KB .gltf) → **Khronos glTF-Validator: 0 errors, 0 warnings**
   (1 info: unused accessor, removed by `prune`).
6. Model facts: 2578 verts / 1360 tris / 155 palette cells; glTF-space bbox X∈[-1,8], Y∈[0,16],
   Z∈[-3,7]; stem core at x∈[1,2] (axis 1.5), stem depth y∈[-2,0] (glTF Z centre 1), base at Y=0.

## Step 1 — `tool/package.json` + `tool/gltf_to_glb.mjs`  (new)

`tool/package.json` (new, private, `type: module`):
deps `@gltf-transform/core ^4.5.1`, `pngjs ^7.0.0`; devDep `gltf-validator` (optional, `--validate`).

`tool/gltf_to_glb.mjs` — CLI: `node tool/gltf_to_glb.mjs <in.gltf> <out.glb> [--validate]`
1. Read `.gltf` JSON; merge N data-URI buffers → 1 (adjust `bufferView.byteOffset` by each buffer's
   base offset). `io.readJSON({ json })` → Document with exactly 1 buffer (GLB requires 0–1).
2. If the primitive has `TEXCOORD_0` + a `baseColorTexture`:
   decode the palette PNG (pngjs) → per-vertex true index → 4px block colour → sRGB→linear →
   write `COLOR_0` VEC4 accessor → drop `TEXCOORD_0`.
   If the source already has `COLOR_0`, use it as-is (already linear).
3. `material.setBaseColorTexture(null)`, dispose textures, `doc.transform(prune())`.
4. `io.writeBinary(doc)` → write file.
5. Self-check: re-read the GLB, print verts/tris/distinct colours/bbox/attributes/size; `--validate`
   runs the Khronos validator.

Also support a `--inspect` mode (stats only, no write) so it doubles as a model-inspection tool.

## Step 2 — asset placement

- Move `~/Documents/rose.gltf` → `app/assets/models/source/rose.gltf` (keep the authored file).
- Generate `app/assets/models/rose.glb` with the converter (flutter_scene's build hook discovers
  `.glb` under `app/assets/` → `app/hook/build.dart` is already wired).

## Step 3 — catalog entry (`app/assets/catalog/flowers.json`)

Add, alongside the existing `parts`-based entries:

```json
{
  "id": "rose-voxel",
  "name": "Rose (voxel)",
  "scientificName": "Rosa",
  "meaning": "Love and devotion",
  "accent": "#c2185b",
  "model": { "file": "rose.glb", "scale": 0.0625, "offset": [-0.09375, 0, -0.0625] },
  "parts": []
}
```

- `model.file` is a bare file name; each consumer resolves it (`app` → `assets/models/<file>`,
  `viewer` → `data/<file>`) so one catalog serves both.
- Convention: `world = offset + scale * gltfPosition`. `scale = 1/16` → 1 unit tall; `offset.x`
  puts the stem axis (x = 1.5) on X = 0; `offset.z` centres the stem depth (Z centre 1) on Z = 0;
  `offset.y = 0` keeps the base on the ground plane.

## Step 4 — `tool/sync_catalog.dart`

Extend to also copy `app/assets/models/*.glb` → `viewer/data/` (keeps viewer and app on the same
asset; viewer needs it because `data/` is the only static dir served).

## Step 5 — `viewer/src/main.js`

- Import `GLTFLoader` from `three/addons/loaders/GLTFLoader.js` (the importmap at
  `viewer/index.html:8-15` already maps `three/addons/` → jsDelivr examples/jsm — no install).
- `buildModelFlower(flower)`: load `data/<file>`, apply `scale`/`offset` to the loaded scene root
  (`scale.setScalar(...)`, `position.set(...)`), return the group.
- Branch in `main()`: `flower.model` → model path, else the existing `procedural`/box paths.
- `?flower=<id>` query param to select the entry (defaults to today's `tulip`).
- Lighting: bump ambient a little for the darker voxel palette (verify visually).

## Step 6 — docs

- `README.md`: add `- [ ] Phase 2b — 3D model assets: glTF → .glb pipeline, model-backed flowers`
  after Phase 2; reword Phase 6's "Blender GLTF" → "Blender authoring"; fix line 27
  ("One geometry format … is rendered twice") — there are now two geometry kinds
  (box-part specs + glTF models).
- `TODO.txt`: add a Phase 2b section; keep line 29 (app must load `flowers.json`) open.

## Verification

1. `node tool/gltf_to_glb.mjs app/assets/models/source/rose.gltf app/assets/models/rose.glb --validate`
   → stats + Khronos 0 errors; colour sanity: stem green, bloom red.
2. `cd app && flutter build web` → `app/flutter_scene_generated/manifest.json` contains
   `assets/models/rose`; then `flutter run -d chrome` shows the rose upright and correctly coloured.
3. `cd viewer && npm run dev` → `http://localhost:4173/?flower=rose-voxel` shows an upright,
   1-unit-tall red/pink rose (not green, not lying on its side).
4. `cd app && flutter analyze` clean.

## Open question for the user

Does their goxel GLTF export dialog have a **"Vertex Color"** checkbox? If yes, re-exporting with it
gives `COLOR_0` directly (already linear, no palette decode). Either way the converter works; the
palette path is the one needed for the file we have and is already validated.
