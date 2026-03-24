# Privacy Policy

There Yet is designed to be privacy-respecting and works fully offline for its core functionality.

## Data that stays on your device

- **Alarm definitions** — stored locally in SQLite
- **GPS/location data** — processed in real-time for alarm checking, never stored or transmitted
- **Alarm service logs** — stored locally for debugging (debug builds only)
- **User preferences** — stored locally via SharedPreferences
- **Map thumbnails** — captured screenshots stored locally

## Data that leaves your device

### Map tiles
When viewing the map, tile images are requested from OpenStreetMap's tile servers.

- **Server:** `tile.openstreetmap.fr` (OSM France)
- **Data sent:** tile coordinates (zoom/x/y), User-Agent header (`nl.bw20.there_yet`)
- **When:** only while the map is visible; tiles are cached locally for 30 days
- **No personal data** is included in tile requests

### Location search (optional)
When you search for a location by name, the query is sent to the Photon geocoding service.

- **Server:** `photon.komoot.io` (open-source project by Komoot)
- **Data sent:** search query text, approximate location (for result ranking)
- **When:** only when you explicitly type a search query
- **User-Agent:** `ThereYet/<version> (Android)`

### Reverse geocoding (optional)
When saving an alarm, the location is reverse-geocoded to show a place name on the alarm card.

- **Server:** `photon.komoot.io`
- **Data sent:** alarm coordinates (latitude, longitude)
- **When:** only when saving a new alarm or editing an alarm's location
- **User-Agent:** `ThereYet/<version> (Android)`

## What we do NOT do

- No analytics or telemetry
- No crash reporting services
- No advertising
- No user accounts or cloud sync
- No tracking of any kind
- No API keys or proprietary services required
- No Google Play Services dependency

## Permissions

All permissions are requested at the point they are needed, with an explanation of why:

| Permission | Purpose |
|---|---|
| Location (foreground) | Show your position on the map |
| Location (background) | Monitor alarm zones while the app is closed |
| Notifications | Alert you when entering an alarm zone |
| Battery optimization exemption | Prevent the OS from killing the alarm service |

## Open source

There Yet is open source under the EUPL 1.2 (European Union Public Licence).
