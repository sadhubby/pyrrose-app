# Pyrrose

Compose bouquets of stylized, boxy 3D flowers on your phone — share them as
links. The recipient opens the link in a browser, orbits the bouquet, and taps
each flower to see its name, scientific name, and meaning.

## Repository layout

```
pyrrose-app/
├── app/                           # Flutter client (Android first, iOS later)
│   ├── assets/catalog/flowers.json# canonical flower geometry + meanings
│   └── lib/
│       ├── core/                  # config, theme, routing
│       ├── features/              # builder, catalog, sharing logic
│       ├── state/                 # Riverpod providers/controllers
│       └── views/                 # screens (home, builder canvas, share)
├── viewer/                        # static Three.js page recipients open
│   ├── index.html
│   ├── src/                       # scene, flower spec parser, styles
│   └── data/                      # synced catalog (see tool/sync_catalog.dart)
├── backend/                       # Supabase schema (no server code)
│   └── supabase/migrations/
└── tool/                          # dev scripts
```

One geometry format (`flowers.json` box-part specs) is rendered twice: by
`flutter_scene` in the app and by Three.js in the viewer.

## Development

```sh
cd app && flutter run -d chrome        # app on Chrome (or -d <android-device>)
cd viewer && npm run dev               # viewer at http://localhost:4173
dart run tool/sync_catalog.dart        # re-sync catalog into viewer after edits
flutter analyze                        # from app/
```

Android builds need Flutter GPU, already enabled in the manifest; for CLI runs
use `flutter run --enable-flutter-gpu`.

## Roadmap

- [x] Phase 1 — repository layout & scaffolding
- [ ] Phase 2 — flower catalog + flutter_scene renderer + tap-picking
- [ ] Phase 3 — builder UI (slot ring, customizer, local save, share)
- [ ] Phase 4 — Three.js viewer (orbit, tap → info card, sample data)
- [ ] Phase 5 — Supabase go-live + GitHub Pages hosting
- [ ] Phase 6 — voice/video/Spotify attachments, auth, Blender GLTF, iOS
