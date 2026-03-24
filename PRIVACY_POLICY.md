# Privacy Policy — There Yet

**Last updated:** 2026-03-24

Welcome to There Yet for Android!

This is an open-source app developed by BW20, published under the EUPL 1.2 licence. The source code is available on GitHub.

As an Android user myself, I take privacy very seriously. I know how frustrating it is when apps collect your data without your knowledge. There Yet was built with one principle: your data belongs on your device, nowhere else.

I hereby state, to the best of my knowledge and belief, that I have not programmed this app to collect any personally identifiable information. All data created by you (the user) is stored locally on your device only, and can be erased by clearing the app's data or uninstalling it. No analytics or tracking software is present in the app.

## Data stored on your device

- **Alarms** — name, coordinates, radius, and settings are stored in a local SQLite database.
- **Location data** — GPS coordinates are processed in real-time to check alarm proximity. They are never stored persistently or transmitted to the developer or any third party.
- **Preferences** — theme, units, and other settings are stored locally via SharedPreferences.
- **Map tile cache** — downloaded map tiles are cached on-device for up to 30 days to reduce network usage.

## Network requests

The app makes a small number of network requests. No personal data or device identifiers are included in any of them.

### Map tiles

When you open the map, tile images are loaded from **OpenStreetMap France** (`tile.openstreetmap.fr`). Only tile coordinates and a User-Agent header (`nl.bw20.there_yet`) are sent. Tiles are cached locally, so repeat views do not require network access.

### Location search (user-initiated)

When you search for a place by name, the query is sent to the **Photon** geocoding service (`photon.komoot.io`), an open-source project by Komoot. The search text and an approximate location (for result ranking) are sent. This only happens when you explicitly type a search query.

### Reverse geocoding (user-initiated)

When you save or edit an alarm, the coordinates are sent to **Photon** (`photon.komoot.io`) to resolve a human-readable place name. This only happens at the moment you save.

No other network requests are made. The core alarm functionality works fully offline.

## Explanation of permissions requested in the app

The list of permissions required by the app can be found in the [`AndroidManifest.xml`](android/app/src/main/AndroidManifest.xml) file:

| Permission | Why it is required |
| :---: | --- |
| `android.permission.ACCESS_FINE_LOCATION` | Required to show your position on the map and to check your proximity to alarm zones. Has to be granted by the user manually; can be revoked at any time from Settings. |
| `android.permission.ACCESS_COARSE_LOCATION` | Used alongside fine location. Provides an approximate position when fine location is not yet available. Has to be granted by the user manually; can be revoked at any time. |
| `android.permission.ACCESS_BACKGROUND_LOCATION` | Required to continue monitoring alarm zones when the app is not in the foreground. Without this permission, alarms will not trigger while the screen is off or another app is open. Has to be granted by the user manually; can be revoked at any time. |
| `android.permission.POST_NOTIFICATIONS` | Required to alert you when you enter an alarm zone. Has to be granted by the user manually (Android 13+); can be revoked at any time. It is highly recommended that you allow this permission so the app can show the alarm notification when triggered. |
| `android.permission.FOREGROUND_SERVICE` and `android.permission.FOREGROUND_SERVICE_LOCATION` | Required to run a foreground service that monitors your proximity to alarm zones. The service shows a persistent notification while active. Automatically granted by the system; cannot be revoked by the user. |
| `android.permission.USE_FULL_SCREEN_INTENT` | Required to show the alarm dismissal screen over the lock screen when an alarm triggers. Automatically granted by the system; cannot be revoked by the user. |
| `android.permission.VIBRATE` | Required to vibrate the device when an alarm is ringing. Automatically granted by the system; cannot be revoked by the user. |
| `android.permission.WAKE_LOCK` | Required to keep the device awake while showing the alarm dismissal screen. Automatically granted by the system; cannot be revoked by the user. |
| `android.permission.RECEIVE_BOOT_COMPLETED` | When your device restarts, all proximity alerts registered with the system are lost. This permission enables the app to receive a message from the system once it has rebooted, so that it can re-register all active alarms. Automatically granted by the system; cannot be revoked by the user. |
| `android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | Allows the app to ask you to exempt it from battery optimisation. This prevents the OS from killing the alarm monitoring service. The actual exemption is granted by you and can be revoked at any time from Settings. |
| `android.permission.INTERNET` | Required to download map tiles from OpenStreetMap and to perform geocoding searches via Photon (see above). Automatically granted by the system; cannot be revoked by the user. |

All user-facing permissions are requested at the point they are needed, with an explanation of why.

## Third-party services

| Service | Operator | Purpose | Privacy policy |
| :---: | --- | --- | --- |
| OpenStreetMap France tile server | OSM France | Map tiles | [openstreetmap.fr](https://www.openstreetmap.fr) |
| Photon geocoding | Komoot | Location search and reverse geocoding | [photon.komoot.io](https://photon.komoot.io) |

No other third-party services, SDKs, or libraries that transmit data off-device are used.

## What the app does NOT do

- No analytics or telemetry
- No crash reporting services
- No advertising
- No user accounts or cloud sync
- No tracking of any kind
- No Google Play Services dependency

## Children's privacy

The app does not knowingly collect any data from anyone, including children under 13. Since no personal data is collected at all, no age-specific provisions are necessary.

## Data sharing

There Yet does not share any data with third parties. There is no data to share — nothing is collected.

## Data retention

All data is stored locally on your device. Uninstalling the app removes all associated data. There is no server-side data to delete.

## Changes to this policy

Updates to this policy will be reflected in the "Last updated" date above and committed to the source repository. Since the app collects no data, material changes are unlikely.

---

If you find any security vulnerability that has been inadvertently caused by me, or have any questions regarding how the app protects your privacy, please open an issue on GitHub and I will do my best to address it.
