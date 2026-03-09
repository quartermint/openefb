# Concerns & Technical Debt

## Blockers for Phase 2

### 1. SFR Package Extraction (High Priority)
- **What:** Flight recording functionality (GPS track, cockpit audio, transcription, AI debrief) depends on extracting code from `~/sovereign-flight-recorder/` into reusable SPM packages
- **Impact:** Entire Phase 2 recording feature is blocked
- **Scope:** 7,000+ LOC in SFR needs `public` access modifiers, package boundaries, and SPM manifest creation
- **Workaround:** `EFBRecordingCoordinator.swift` is a no-op stub that provides published state for compile-time compatibility
- **Files:** `efb-212/Services/EFBRecordingCoordinator.swift` (44 lines, all stubs)

### 2. Apple Foundation Models Availability (Medium Priority)
- **What:** On-device AI flight debrief depends on Apple Foundation Models API, which is not yet publicly available
- **Impact:** Debrief feature of Phase 2 is blocked
- **Risk:** API surface may change before release

## Stub Services (Known Incomplete)

### TFR Service — Hardcoded Data
- **File:** `efb-212/Services/TFRService.swift`
- **Issue:** Returns 6 hardcoded Bay Area TFRs instead of live FAA data
- **Risk:** Low for development, but cannot be shipped — users need real TFR data for safety
- **Note:** FAA TFR API (tfr.faa.gov) has unreliable/hard-to-parse formats; real integration requires careful parsing

### NASR Data Import — Seed Data Only
- **File:** `efb-212/Data/DatabaseManager.swift` (`importNASRData` method)
- **Issue:** `importNASRData()` just calls `loadSeedData()` — no actual SwiftNASR integration
- **Impact:** Limited to ~3,700 seeded airports instead of full FAA 20K+ airport database
- **Planned:** SwiftNASR SPM package integration for full NASR parsing

### FAA Lookup Service — HTML Scraping
- **File:** `efb-212/Services/FAALookupService.swift`
- **Issue:** Scrapes FAA registry HTML with regex — fragile if FAA changes page structure
- **Risk:** Medium — could break silently if HTML format changes

## Architecture Concerns

### @unchecked Sendable Usage
- **Files:** `AviationDatabase`, `DatabaseManager`, `PlaceholderDatabaseManager`, `PlaceholderWeatherService`, `PlaceholderTFRService`, `MockDatabaseManager`
- **Issue:** Multiple types use `@unchecked Sendable` to satisfy Sendable requirements without compiler verification
- **Risk:** GRDB's `DatabasePool` handles its own thread safety, so this is safe in practice, but it bypasses compiler checks
- **Mitigation:** All GRDB operations go through `DatabasePool.read/write` which handles concurrency

### MapService Not Protocol-Abstracted
- **File:** `efb-212/Services/MapService.swift`
- **Issue:** `MapService` is a concrete class without a protocol — cannot be mocked in tests
- **Impact:** `MapViewModel` tests cannot fully mock map interactions
- **Reason:** MLNMapView requires UIKit delegate patterns (NSObject conformance), making protocol extraction complex

### WeatherService.cachedWeather() Returns Nil
- **File:** `efb-212/Services/WeatherService.swift` (line 267-272)
- **Issue:** The `nonisolated func cachedWeather(for:) -> WeatherCache?` always returns `nil` because it cannot safely access actor-isolated state synchronously
- **Impact:** Protocol requires this method but it is non-functional on the actor implementation
- **Workaround:** Callers use `fetchMETAR()` instead, which checks both caches

### AppState as Global Coordinator
- **File:** `efb-212/Core/AppState.swift`
- **Issue:** AppState holds navigation, map, location, recording, flight plan, and system state — growing responsibility
- **Risk:** As Phase 2 adds recording state and Phase 3+ adds debrief/replay, this class will become unwieldy
- **Recommendation:** Consider extracting sub-states (MapState, RecordingState) into separate ObservableObjects

## Data Concerns

### Seed Data Scale
- **Files:** `efb-212/Data/SeedData/*.swift` (10 regional files)
- **Issue:** ~3,700 airports hardcoded as Swift code — large compile-time cost, increases binary size
- **Alternative:** Bundle as JSON/SQLite file instead of Swift literals
- **Current mitigation:** Seed data versioning (`currentSeedVersion = 3`) prevents re-insertion

### No Database Backup/Recovery
- **Issue:** If `aviation.sqlite` becomes corrupted, there is no recovery mechanism beyond re-seeding
- **Impact:** User would lose any custom data stored alongside aviation data
- **Note:** `EFBError.databaseCorrupted` exists but no automated recovery path

## Performance Considerations

### Map Region Change Triggers Full Reload
- **File:** `efb-212/ViewModels/MapViewModel.swift`
- **Issue:** Every map pan/zoom triggers `loadAirportsForRegion()` which runs R-tree query + weather fetch + TFR fetch + airspace fetch
- **Mitigation:** Some debouncing via MapLibre's `regionDidChangeAnimated`, radius clamped to 100 NM
- **Risk:** At low zoom levels with many visible airports, could cause UI lag on older iPads

### Annotation-Based Map Rendering
- **File:** `efb-212/Services/MapService.swift`
- **Issue:** Airports, weather dots, and navaids use individual `MLNPointAnnotation` objects rather than GeoJSON cluster sources
- **Impact:** Performance degrades with hundreds of annotations visible simultaneously
- **Recommendation:** Migrate to GeoJSON source + symbol layer for airports/weather at higher airport counts

## Missing Features (Phase 1 Gaps)

| Feature | Status | Impact |
|---------|--------|--------|
| Offline map tiles | Charts download but no offline base map | Map requires network for base layer |
| Network reachability monitoring | `NetworkManagerProtocol` defined but not implemented | `appState.networkAvailable` never updates |
| Background location | Info.plist key check exists but may not be configured | Recording may not work in background |
| Chart tile conversion | FAA distributes GeoTIFF, app expects MBTiles | Download pipeline incomplete — needs gdal2tiles + mb-util |

## Security Notes

- **No API keys in code** — all APIs used are free/keyless
- **Keychain storage** implemented but not yet used for any secrets
- **Secure Enclave** key generation works on device, falls back to software key on simulator
- **No sensitive data in seed files** — all aviation data is public domain
