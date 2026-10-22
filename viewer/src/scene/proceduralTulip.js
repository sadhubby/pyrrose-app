import * as THREE from 'three';

function createCurvedLeaf() {
  const leafGroup = new THREE.Group();

  const leafMaterial = new THREE.MeshStandardMaterial({
    color: 0x4caf50,
    roughness: 0.6,
    side: THREE.DoubleSide,
  });

  // Create a curved leaf using Shape
  const shape = new THREE.Shape();
  shape.moveTo(0, 0);
  shape.quadraticCurveTo(0.5, 0.3, 1.2, 0.2);
  shape.quadraticCurveTo(0.5, -0.05, 0, 0);

  const geometry = new THREE.ShapeGeometry(shape);
  const leaf = new THREE.Mesh(geometry, leafMaterial);
  leaf.scale.set(0.8, 0.8, 1);
  leaf.rotation.y = Math.PI / 2;
  leaf.rotation.z = Math.PI / 2;

  leafGroup.add(leaf);
  return leafGroup;
}

function createPetalLatheProfile() {
  // Profile for a tulip petal cup - creates the bulbous shape
  const points = [];
  for (let i = 0; i <= 6; i++) {
    const t = i / 6;
    const x = Math.sin(t * Math.PI) * (0.05 + t * 0.35);
    const y = t * 2.2;
    points.push(new THREE.Vector2(x, y));
  }
  return points;
}

function createTulipPetals(customColor = 0xff5252) {
  const petalsGroup = new THREE.Group();

  const petalMaterial = new THREE.MeshStandardMaterial({
    color: customColor,
    roughness: 0.3,
    side: THREE.DoubleSide,
  });

  const innerMaterial = new THREE.MeshStandardMaterial({
    color: 0xff6f61,
    roughness: 0.3,
    side: THREE.DoubleSide,
  });

  const profile = createPetalLatheProfile();

  // Outer petals
  const outerSegments = 6;
  for (let i = 0; i < outerSegments; i++) {
    const angle = (i / outerSegments) * Math.PI * 2;
    const latheGeo = new THREE.LatheGeometry(profile, 12);
    const petal = new THREE.Mesh(latheGeo, petalMaterial);
    petal.scale.set(1.4, 1.0, 1.4);
    petal.rotation.y = angle;
    petal.rotation.x = 0.25;
    petal.rotation.z = Math.sin(angle) * 0.15;
    petal.position.y = 1.2;
    petalsGroup.add(petal);
  }

  // Inner petals (layered, tucked in)
  const innerSegments = 6;
  for (let i = 0; i < innerSegments; i++) {
    const angle = (i / innerSegments) * Math.PI * 2 + Math.PI / 6;
    const latheGeo = new THREE.LatheGeometry(profile, 10);
    const petal = new THREE.Mesh(latheGeo, innerMaterial);
    petal.scale.set(1.0, 0.9, 1.0);
    petal.rotation.y = angle;
    petal.rotation.x = 0.15;
    petal.rotation.z = Math.sin(angle) * 0.1;
    petal.position.y = 1.1;
    petalsGroup.add(petal);
  }

  return petalsGroup;
}

export function createProceduralTulip(customColor = 0xff5252) {
  const tulipGroup = new THREE.Group();

  // Stem
  const stemGeometry = new THREE.CylinderGeometry(0.12, 0.16, 3.2, 8);
  const stemMaterial = new THREE.MeshStandardMaterial({
    color: 0x388e3c,
    roughness: 0.8,
  });
  const stem = new THREE.Mesh(stemGeometry, stemMaterial);
  stem.position.y = 1.6;
  tulipGroup.add(stem);

  // Leaves
  for (let i = 0; i < 2; i++) {
    const leaf = createCurvedLeaf();
    leaf.position.set(i === 0 ? -0.35 : 0.35, 1.2, 0);
    leaf.rotation.y = i === 0 ? -0.4 : 0.4;
    leaf.rotation.z = i === 0 ? -0.6 : 0.6;
    tulipGroup.add(leaf);
  }

  // Petals
  const petals = createTulipPetals(customColor);
  tulipGroup.add(petals);

  return tulipGroup;
}
