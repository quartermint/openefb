# Technology Stack

## Languages & Runtime

- **Swift 5.0+** — primary and only language
- **iOS 26.0** deployment target (iPad)
- **Xcode project** — `efb-212.xcodeproj`, single scheme `efb-212`
- **Build setting:** `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — all types are `@MainActor` by default unless explicitly opted out with `nonisolated`

## Frameworks

| Framework | Version | Purpose |
|-----------|---------|---------|
| **SwiftUI** | iOS 26 | Primary UI framework |
| **Combine** | Built-in | Reactive state management, inter-service communication |
| **CoreLocation** | Built-in | GPS position, heading, speed, altitude |
| **UIKit** | Built-in | Battery monitoring (`UIDevice`), MapLibre delegate callbacks |
| **Security** | Built-in | Keychain storage, Secure Enclave key generation |
| **SwiftData** | Built-in | User data persistence (profiles, flights, settings) — CloudKit-ready |

## SPM Dependencies

| Package | Source | Version | Purpose |
|---------|--------|---------|---------|
| **MapLibre Native** | `maplibre/maplibre-gl-native-distribution` | 6.23.0 | Map rendering with raster tile overlays, annotations, vector/polygon layers |
| **GRDB.swift** | `groue/GRDB.swift` | 7.9.0 | SQLite with R-tree spatial indexes, FTS5 full-text search, WAL mode |

## Planned Dependencies (Not Yet Added)

| Package | Purpose | Blocker |
|---------|---------|---------|
| **SFR Packages** (local SPM) | Flight recording: GPS track, audio, transcription, debrief | Package extraction from `~/sovereign-flight-recorder/` not done |
| **SwiftNASR** | FAA airport/navaid data parsing (20K US airports) | Not yet integrated; using seed data |
| **Apple Foundation Models** | On-device AI debrief | Availability TBD |

## Build Configuration

- **Targets:** `efb-212` (app), `efb-212Tests` (unit/integration), `efb-212UITests` (UI tests)
- **Build configurations:** Debug, Release
- **Bundle ID:** `quartermint.efb-212`
- **No CI/CD** pipeline configured
- **No Package.swift** — Xcode project manages SPM dependencies

## Configuration & Environment

- No `.env` files or API keys required — NOAA weather API is free/keyless
- Map tiles from OpenFreeMap (free, no API key): `https://tiles.openfreemap.org/styles/liberty`
- VFR sectional charts from FAA aeronav.faa.gov (free, public domain)
- Chart files stored locally as MBTiles in `Application Support/Charts/`
- Aviation database stored as SQLite in `Application Support/aviation.sqlite`
- Seed data versioning tracked via `UserDefaults` keys (`com.efb212.seedDataLoaded`, `com.efb212.seedDataVersion`)
