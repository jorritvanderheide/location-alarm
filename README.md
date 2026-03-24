# There Yet - Location Alarm

[![Donate](https://liberapay.com/assets/widgets/donate.svg)](https://liberapay.com/BW20)

Get alerted when you arrive. Place a pin on the map, set a radius, and the app wakes you up when you enter the area. No accounts, no tracking, no Google Play Services.

## Features

- **Proximity alarms** — set a location and radius, get alerted when you arrive
- **Works in the background** — dual trigger: GPS polling + Android ProximityAlert for reliability even when the app is closed
- **Adaptive monitoring** — polling frequency adjusts based on your speed and distance to the alarm
- **Offline-capable** — map tiles are cached locally for offline use after first viewing
- **Location search** — find places by name with autocomplete (Photon geocoding)
- **Material 3** — dynamic colors, dark mode, AMOLED true black

## Privacy

There Yet is designed to minimize data leaving your device. See [PRIVACY.md](PRIVACY.md) for full details.

- All alarm data stays on your device (SQLite + local files)
- No accounts, no analytics, no telemetry, no ads
- No Google Play Services — uses Android's LocationManager directly
- Works on privacy-focused ROMs (GrapheneOS, CalyxOS, LineageOS)
- Permissions requested at point of use with rationale, never upfront

**Network calls (only when you use the map):**
- Map tiles from OSM France (`tile.openstreetmap.fr`)
- Search queries and reverse geocoding via Photon (`photon.komoot.io`)

## Limitations

- **Android only** — no iOS or web
- **GPS accuracy degrades with screen off** — Android LocationManager limitation without Play Services (100–200m)
- **Aggressive OEMs may kill the service** — battery optimization exemption helps but doesn't guarantee survival on all devices
- **Minimum practical radius ~100m** — GPS hardware constraint
- **High-speed transit** — at 140 km/h in Doze mode, trigger reliability is ~35% without Play Services

## Tech stack

- Flutter + Dart
- Riverpod for state management
- Drift (SQLite) for persistence
- flutter_map with OpenStreetMap tiles
- Photon (Nominatim) for geocoding
- Kotlin for Android-native alarm service, notifications, and proximity alerts

## License

[EUPL 1.2](LICENSE) (European Union Public Licence) — open source, copyleft.

Map data: [OpenStreetMap contributors](https://www.openstreetmap.org/copyright) (ODbL).
Geocoding: [Photon](https://photon.komoot.io/) by Komoot.
