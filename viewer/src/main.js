// Pyrrose viewer entry point.
// Phase 4: fetch bouquet + catalog, build Three.js scene, orbit + raycast picking.

const status = document.getElementById('bouquet-title');
if (status) {
  status.textContent = 'Viewer scaffold — bouquet rendering arrives in Phase 4';
}

console.info('[pyrrose] viewer scaffold ready');
