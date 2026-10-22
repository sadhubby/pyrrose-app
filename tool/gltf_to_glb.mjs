// Converts a Goxel-exported .gltf into a .glb whose colours live in the
// COLOR_0 vertex attribute.
//
// Why this exists: goxel exports voxel models with a palette texture, but its
// UVs address a 16x16 cell grid while the palette PNG is written as a
// ceil(sqrt(palette_size))x... grid of 4px blocks
// (src/volume_to_vertices.c vs src/formats/gltf.c in goxel). The two grids
// disagree, so every viewer samples the wrong texel and the model comes out
// the wrong colours. Here we recover the intended palette index from the UV
// itself, read the colour straight out of the palette PNG, convert sRGB to
// linear (glTF COLOR_0 is linear) and bake it per vertex. The texture and
// its sampler are then dropped, which also means no mip levels to wash the
// colours out when the flower is drawn small.
//
// Usage:
//   node tool/gltf_to_glb.mjs <input.gltf> <output.glb> [--validate]
//   node tool/gltf_to_glb.mjs --inspect <input.gltf>
//
// Setup: npm install (in this directory).

import { readFile, writeFile } from 'node:fs/promises';
import { basename, resolve } from 'node:path';
import { NodeIO, Accessor } from '@gltf-transform/core';
import { prune } from '@gltf-transform/functions';
import { PNG } from 'pngjs';

// goxel writes the UVs on a grid of max(next_pow2(ceil(log2(palette_size))), 16)
// cells, which is 16 for every palette size that fits in a texture.
const GOXEL_UV_GRID = 16;
// goxel draws every palette entry as a block of this many pixels.
const PALETTE_PIXEL = 4;

function srgbToLinear(channel) {
  const s = channel / 255;
  return s <= 0.04045 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4);
}

// goxel's palette index for a UV, i.e. texcoord = (c % grid + 0.5) / grid.
function paletteIndex(u, v) {
  const column = Math.round(u * GOXEL_UV_GRID - 0.5);
  const row = Math.round(v * GOXEL_UV_GRID - 0.5);
  if (Math.abs(u * GOXEL_UV_GRID - 0.5 - column) > 1e-4) {
    throw new Error(`UV ${u} is not a goxel palette coordinate`);
  }
  return GOXEL_UV_GRID * row + column;
}

// The colour of a palette entry, read from the palette texture.
function paletteColor(png, index, grid) {
  const cellX = index % grid;
  const cellY = Math.floor(index / grid);
  if (cellY >= grid) {
    throw new Error(`palette index ${index} is outside the ${grid}x${grid} palette`);
  }
  const offset = (png.width * (cellY * PALETTE_PIXEL) + cellX * PALETTE_PIXEL) * 4;
  return [png.data[offset], png.data[offset + 1], png.data[offset + 2]];
}

// A .gltf may spread its data over several buffers, but a .glb may only hold
// one, so the buffers are concatenated here and the buffer views are rebased.
function mergeBuffers(json) {
  const buffers = json.buffers ?? [];
  if (buffers.length <= 1) return;
  const parts = [];
  const bases = [];
  let base = 0;
  for (const buffer of buffers) {
    if (!buffer.uri?.startsWith('data:')) {
      throw new Error(`external buffer files are not supported: ${buffer.uri}`);
    }
    const part = Buffer.from(buffer.uri.slice(buffer.uri.indexOf(',') + 1), 'base64');
    parts.push(part);
    bases.push(base);
    base += part.length;
  }
  const merged = Buffer.concat(parts);
  for (const view of json.bufferViews ?? []) {
    view.byteOffset = (view.byteOffset ?? 0) + bases[view.buffer];
    view.buffer = 0;
  }
  json.buffers = [{
    uri: `data:application/octet-stream;base64,${merged.toString('base64')}`,
    byteLength: merged.length,
  }];
}

function primitivesOf(doc) {
  const primitives = [];
  for (const mesh of doc.getRoot().listMeshes()) {
    for (const primitive of mesh.listPrimitives()) primitives.push(primitive);
  }
  return primitives;
}

// Bakes the palette texture into COLOR_0. Models that already carry COLOR_0
// (goxel's "Vertex Color" export) are left alone: those values are linear.
function bakePalette(doc) {
  const root = doc.getRoot();
  const primitives = primitivesOf(doc);
  const textured = primitives.filter((p) => p.getAttribute('TEXCOORD_0'));
  if (textured.length === 0) return { baked: 0 };

  const texture = root.listTextures()[0];
  if (!texture) {
    throw new Error('model has TEXCOORD_0 but no texture to read the palette from');
  }
  const png = PNG.sync.read(Buffer.from(texture.getImage()));
  const grid = png.width / PALETTE_PIXEL;
  if (grid !== png.height / PALETTE_PIXEL) {
    throw new Error(`palette texture ${png.width}x${png.height} is not a square cell grid`);
  }

  let baked = 0;
  for (const primitive of primitives) {
    const uv = primitive.getAttribute('TEXCOORD_0');
    if (!uv) continue;
    if (primitive.getAttribute('COLOR_0')) continue;
    const uvs = uv.getArray();
    const colors = new Float32Array(uv.getCount() * 4);
    for (let i = 0; i < uv.getCount(); i++) {
      const index = paletteIndex(uvs[i * 2], uvs[i * 2 + 1]);
      const [r, g, b] = paletteColor(png, index, grid);
      colors[i * 4 + 0] = srgbToLinear(r);
      colors[i * 4 + 1] = srgbToLinear(g);
      colors[i * 4 + 2] = srgbToLinear(b);
      colors[i * 4 + 3] = 1;
    }
    primitive.setAttribute(
      'COLOR_0',
      doc.createAccessor('COLOR_0')
        .setArray(colors)
        .setType(Accessor.Type.VEC4)
        .setBuffer(root.listBuffers()[0]),
    );
    primitive.setAttribute('TEXCOORD_0', null);
    baked += uv.getCount();
  }

  for (const material of root.listMaterials()) material.setBaseColorTexture(null);
  for (const item of root.listTextures()) item.dispose();
  return { baked, grid };
}

// Column-major 4x4 multiply, enough to follow the node transforms.
function multiplyMatrices(a, b) {
  const out = new Array(16).fill(0);
  for (let column = 0; column < 4; column++) {
    for (let row = 0; row < 4; row++) {
      let sum = 0;
      for (let k = 0; k < 4; k++) sum += a[k * 4 + row] * b[column * 4 + k];
      out[column * 4 + row] = sum;
    }
  }
  return out;
}

// The world matrix of every node, found by walking the node tree from the
// scene roots. A model may have several scenes and several roots, so the
// walk starts from the roots rather than from the flat node list.
function worldMatrices(doc) {
  const root = doc.getRoot();
  const identity = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];
  const matrices = new Map();
  const visited = new Set();
  const visit = (node, parent) => {
    if (visited.has(node)) return;
    visited.add(node);
    const local = node.getMatrix() ?? identity;
    const world = multiplyMatrices(parent, local);
    matrices.set(node, world);
    for (const child of node.listChildren()) visit(child, world);
  };
  for (const scene of root.listScenes()) {
    for (const node of scene.listChildren()) visit(node, identity);
  }
  // A node that belongs to no scene is its own root.
  for (const node of root.listNodes()) visit(node, identity);
  return matrices;
}

// The world matrix of the node a mesh hangs from.
function meshMatrices(doc) {
  const identity = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];
  const matrices = worldMatrices(doc);
  const result = new Map();
  for (const node of doc.getRoot().listNodes()) {
    const mesh = node.getMesh();
    if (mesh && !result.has(mesh)) result.set(mesh, matrices.get(node) ?? identity);
  }
  return result;
}

function describe(doc) {
  const root = doc.getRoot();
  const matrices = meshMatrices(doc);
  const identity = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];
  const min = [Infinity, Infinity, Infinity];
  const max = [-Infinity, -Infinity, -Infinity];
  const colors = new Set();
  let vertices = 0;
  let triangles = 0;
  const semantics = new Set();

  for (const mesh of root.listMeshes()) {
    const matrix = matrices.get(mesh) ?? identity;
    for (const primitive of mesh.listPrimitives()) {
      const position = primitive.getAttribute('POSITION');
      if (!position) continue;
      vertices += position.getCount();
      triangles += (primitive.getIndices()?.getCount() ?? position.getCount()) / 3;
      for (const semantic of primitive.listSemantics()) semantics.add(semantic);
      const positions = position.getArray();
      for (let i = 0; i < positions.length; i += 3) {
        const x = positions[i], y = positions[i + 1], z = positions[i + 2];
        const world = [
          matrix[0] * x + matrix[4] * y + matrix[8] * z + matrix[12],
          matrix[1] * x + matrix[5] * y + matrix[9] * z + matrix[13],
          matrix[2] * x + matrix[6] * y + matrix[10] * z + matrix[14],
        ];
        for (let axis = 0; axis < 3; axis++) {
          min[axis] = Math.min(min[axis], world[axis]);
          max[axis] = Math.max(max[axis], world[axis]);
        }
      }
      const color = primitive.getAttribute('COLOR_0');
      if (color) {
        const values = color.getArray();
        for (let i = 0; i < values.length; i += 4) {
          colors.add(`${values[i].toFixed(4)},${values[i + 1].toFixed(4)},${values[i + 2].toFixed(4)}`);
        }
      }
    }
  }

  return { vertices, triangles, semantics, colors, min, max };
}

function report(stats) {
  const format = (n) => n.toFixed(3);
  console.log(`  attributes    ${[...stats.semantics].join(', ')}`);
  console.log(`  geometry      ${stats.vertices} vertices, ${stats.triangles} triangles`);
  console.log(`  colors        ${stats.colors.size} distinct`);
  console.log(
    `  bbox (world)  x[${format(stats.min[0])}, ${format(stats.max[0])}] ` +
    `y[${format(stats.min[1])}, ${format(stats.max[1])}] ` +
    `z[${format(stats.min[2])}, ${format(stats.max[2])}]`,
  );
}

async function validate(bytes) {
  const { default: validator } = await import('gltf-validator');
  const result = await validator.validateBytes(new Uint8Array(bytes));
  const { numErrors, numWarnings, numInfos, numHints } = result.issues;
  console.log(`  validator     ${numErrors} errors, ${numWarnings} warnings, ${numInfos} infos, ${numHints} hints`);
  for (const message of result.issues.messages) {
    console.log(`    - ${message.severity} ${message.code} ${message.pointer}: ${message.message}`);
  }
  if (numErrors > 0) process.exitCode = 1;
}

async function main() {
  const args = process.argv.slice(2);
  const inspect = args.includes('--inspect');
  const shouldValidate = args.includes('--validate');
  const positional = args.filter((a) => !a.startsWith('--'));
  const [input, output] = positional;

  if (!input) {
    console.error('usage: node tool/gltf_to_glb.mjs <input.gltf> <output.glb> [--validate]');
    console.error('       node tool/gltf_to_glb.mjs --inspect <input.gltf>');
    process.exitCode = 1;
    return;
  }

  const json = JSON.parse(await readFile(resolve(input), 'utf8'));
  mergeBuffers(json);
  const io = new NodeIO();
  const doc = await io.readJSON({ json });

  if (inspect) {
    console.log(`${input}`);
    report(describe(doc));
    return;
  }
  if (!output) {
    console.error('missing output path');
    process.exitCode = 1;
    return;
  }

  const baked = bakePalette(doc);
  if (baked.baked > 0) {
    console.log(`  baked         ${baked.baked} vertices from a ${baked.grid}x${baked.grid} palette`);
  }
  await doc.transform(prune());

  const bytes = await io.writeBinary(doc);
  await writeFile(resolve(output), bytes);

  console.log(`${input} -> ${output}`);
  console.log(`  size          ${bytes.length} bytes`);
  report(describe(await io.readBinary(bytes)));
  if (shouldValidate) await validate(bytes);
  console.log(`  wrote         ${basename(output)}`);
}

main().catch((error) => {
  console.error(`[pyrrose] ${error.message}`);
  process.exitCode = 1;
});
