// Pyrrose viewer entry point.
// Visual preview only: renders the first flower in the catalog with orbit
// controls. Tap-picking, info cards, and bouquet deep-links arrive in Phase 4.
import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';

const titleEl = document.getElementById('bouquet-title');
const canvas = document.getElementById('scene');

async function loadCatalog() {
  const res = await fetch('data/flowers.json');
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return res.json();
}

function buildFlower(flower) {
  const group = new THREE.Group();
  for (const part of flower.parts) {
    if (part.kind !== 'box') continue;
    const geometry = new THREE.BoxGeometry(...part.size);
    const material = new THREE.MeshStandardMaterial({ color: part.color });
    const mesh = new THREE.Mesh(geometry, material);
    mesh.position.fromArray(part.at);
    mesh.rotation.set(
      THREE.MathUtils.degToRad(part.rot[0]),
      THREE.MathUtils.degToRad(part.rot[1]),
      THREE.MathUtils.degToRad(part.rot[2]),
    );
    group.add(mesh);
  }
  return group;
}

async function main() {
  let catalog;
  try {
    catalog = await loadCatalog();
  } catch (err) {
    console.error('[pyrrose] failed to load catalog:', err);
    return;
  }

  const flower = catalog.flowers && catalog.flowers[0];
  if (!flower) {
    console.error('[pyrrose] catalog contains no flowers');
    return;
  }

  titleEl.textContent = flower.name;

  const scene = new THREE.Scene();
  scene.background = new THREE.Color(0xfaf7f5);

  const renderer = new THREE.WebGLRenderer({ canvas, antialias: true });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));

  const camera = new THREE.PerspectiveCamera(45, 1, 0.01, 100);

  const flowerGroup = buildFlower(flower);
  scene.add(flowerGroup);

  const bounds = new THREE.Box3().setFromObject(flowerGroup);
  const center = bounds.getCenter(new THREE.Vector3());
  const size = bounds.getSize(new THREE.Vector3());
  const radius = Math.max(size.x, size.y, size.z);
  const distance = (radius / Math.tan(THREE.MathUtils.degToRad(camera.fov / 2))) * 1.6;

  camera.position.set(
    center.x + distance * 0.6,
    center.y + distance * 0.4,
    center.z + distance * 0.7,
  );
  camera.lookAt(center);

  const controls = new OrbitControls(camera, renderer.domElement);
  controls.target.copy(center);
  controls.enableDamping = true;

  scene.add(new THREE.AmbientLight(0xffffff, 0.7));
  const sun = new THREE.DirectionalLight(0xffffff, 1.5);
  sun.position.set(2, 4, 3);
  scene.add(sun);

  function resize() {
    const w = canvas.clientWidth;
    const h = canvas.clientHeight;
    if (w === 0 || h === 0) return;
    renderer.setSize(w, h, false);
    camera.aspect = w / h;
    camera.updateProjectionMatrix();
  }
  new ResizeObserver(resize).observe(canvas);
  resize();

  renderer.setAnimationLoop(() => {
    controls.update();
    renderer.render(scene, camera);
  });

  console.info('[pyrrose] showing', flower.name);
}

main();
