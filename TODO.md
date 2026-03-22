# TODO

## Vector tiles for fully offline maps

**Status:** Blocked — waiting for `vector_map_tiles` stable release with flutter_map 8 support.

**Current situation (March 2026):**
The app uses OSM France raster tiles with flutter_map's built-in disk cache. Users browse online once, tiles are cached, then work offline for those areas. This is functional but not ideal — users must have viewed an area before going offline.

**The goal:**
Ship the app with a small vector tile file (~200MB for Netherlands) that renders maps entirely on-device. No network needed, ever. Users download regional extracts for their country.

**Why vector tiles:**
- ~3x smaller than raster for the same coverage (vectors compress better)
- Render at any zoom level from one file (no per-zoom tile generation)
- Support dynamic styling (dark mode maps, custom colors)
- Protomaps provides free planet-wide vector PMTiles under ODbL

**The plan:**
1. Use `vector_map_tiles` package to render Protomaps vector PMTiles on-device
2. Bundle a low-detail world extract (~5MB) in the APK for instant offline base map
3. Let users download regional extracts (Netherlands ~200MB) for full detail
4. Use `pmtiles extract` CLI to cut regional files from the Protomaps planet build
5. Host regional extracts on static storage (Cloudflare R2 free tier)

**What's blocking:**
- `vector_map_tiles` stable (v8.0.0) only supports flutter_map ^7
- `vector_map_tiles` v10.0.0-beta.2 supports flutter_map ^8.2.1 but requires Flutter GPU (`flutter_gpu`), which is only available on Flutter's `main` (development) channel
- Flutter GPU is experimental and not production-ready

**When to revisit:**
- When `vector_map_tiles` releases a stable version compatible with flutter_map ^8+ without requiring Flutter GPU
- Or when Flutter GPU lands on the stable channel
- Check: https://pub.dev/packages/vector_map_tiles

**Alternative considered:**
`flutter_map_pmtiles` (MIT, compatible with flutter_map ^8) supports raster PMTiles from local files. But generating raster PMTiles requires a render pipeline (tileserver-gl → mbtiles → pmtiles) and self-hosting the output. This was rejected because the user doesn't want to run CI or servers.
