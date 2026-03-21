---
phase: 01-foundation-navigation-core
plan: 03
subsystem: map, navigation, ui
tags: [maplibre, geojson, cllocationupdate, uiviewrepresentable, gps, mbtiles, chart-expiration]

# Dependency graph
requires:
  - phase: 01-foundation-navigation-core/01
    provides: "AppState, Types, Protocols, AviationModels, SwiftData schema"
  - phase: 01-foundation-navigation-core/02
    provides: "GRDB AviationDatabase with R-tree spatial queries, DatabaseManager"
provides:
  - "LocationService with CLLocationUpdate.liveUpdates() GPS streaming"
  - "MapService managing all GeoJSON sources and MapLibre style layers"
  - "MapViewModel coordinating region-based data loading with debounce"
  - "MapView UIViewRepresentable wrapping MLNMapView"
  - "MapContainerView composing map tab with controls and overlays"
  - "Chart expiration metadata reading from MBTiles (INFRA-03)"
  - "Layer visibility toggles, sectional opacity slider, map style picker"
  - "ChartExpirationBadge with yellow warning and red expired states"
affects: [weather-service, flight-planning, instrument-strip, nearest-airport, airport-info]

# Tech tracking
tech-stack:
  added: [MapLibre MLNMapView, CLLocationUpdate.liveUpdates, CLBackgroundActivitySession, SQLite3 direct access for MBTiles metadata]
  patterns: [UIViewRepresentable with Coordinator delegate, GeoJSON FeatureCollection for bulk map rendering, region-change debounce with 5NM skip threshold, programmatic icon generation via UIGraphicsImageRenderer]

key-files:
  created:
    - efb-212/Services/LocationService.swift
    - efb-212/Services/MapService.swift
    - efb-212/ViewModels/MapViewModel.swift
    - efb-212/Views/Map/MapView.swift
    - efb-212/Views/Map/MapContainerView.swift
    - efb-212/Views/Map/MapControlsView.swift
    - efb-212/Views/Map/LayerControlsView.swift
    - efb-212/Views/Components/OpacitySlider.swift
    - efb-212/Views/Components/ChartExpirationBadge.swift
  modified:
    - efb-212/ContentView.swift

key-decisions:
  - "MapService runs on MainActor (not actor) because MLNMapView is UIKit main-thread-only"
  - "Used SQLite3 C API directly for MBTiles metadata read to avoid GRDB dependency in MapService"
  - "Ownship chevron rendered programmatically via UIGraphicsImageRenderer instead of bundled asset"
  - "Region change debounce: 500ms delay + 5NM skip threshold prevents excessive database queries"
  - "Layer controls presented as overlay panel (not popover) for better iPad landscape ergonomics"

patterns-established:
  - "UIViewRepresentable + nonisolated Coordinator pattern for MapLibre integration"
  - "GeoJSON FeatureCollection bulk update via MLNShapeSource.shape setter"
  - "Aviation unit conversion constants: 1.94384 (m/s to knots), 0.3048 (meters to feet)"
  - "Chart expiration metadata from MBTiles SQLite metadata table"

requirements-completed: [NAV-01, NAV-02, NAV-04, NAV-05, INFRA-03, DATA-04]

# Metrics
duration: 14min
completed: 2026-03-21
---

# Phase 01 Plan 03: Moving Map Summary

**MapLibre moving map with GPS ownship tracking, GeoJSON airport/navaid/airspace layers, VFR sectional overlay, layer controls, opacity slider, and chart expiration warning (INFRA-03)**

## Performance

- **Duration:** 14 min
- **Started:** 2026-03-21T02:10:43Z
- **Completed:** 2026-03-21T02:24:45Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments
- LocationService streams GPS via CLLocationUpdate.liveUpdates(.otherNavigation) AsyncSequence with CLBackgroundActivitySession for background tracking
- MapService manages 7 GeoJSON sources (airports, navaids, airspace, weather dots, TFRs, ownship, sectional) with data-driven styling and chart expiration metadata reading from MBTiles
- MapView wraps MLNMapView via UIViewRepresentable with Coordinator delegate and tap gesture recognizer for GeoJSON airport feature detection
- Complete map control suite: mode toggle (north-up/track-up), zoom +/-, layer toggles with color tints, sectional opacity slider 0-100%, map style picker (VFR/Street/Satellite/Terrain)
- Chart expiration badge (INFRA-03) displays yellow warning within 7 days and red "CHARTS EXPIRED" when past expiration

## Task Commits

Each task was committed atomically:

1. **Task 1: LocationService, MapService, MapViewModel** - `8ef56ec` (feat)
2. **Task 2: MapView, MapContainerView, controls, layer toggles, chart expiration badge** - `72ad807` (feat)

## Files Created/Modified
- `efb-212/Services/LocationService.swift` - CLLocationUpdate.liveUpdates() GPS wrapper with aviation unit conversions
- `efb-212/Services/MapService.swift` - MapLibre GeoJSON source/layer management, ownship chevron, chart expiration metadata
- `efb-212/ViewModels/MapViewModel.swift` - Map coordination with debounced region queries and chart expiration state
- `efb-212/Views/Map/MapView.swift` - UIViewRepresentable wrapping MLNMapView with Coordinator and tap gesture
- `efb-212/Views/Map/MapContainerView.swift` - Main map tab composing map, controls, chart warning overlay
- `efb-212/Views/Map/MapControlsView.swift` - Right-edge floating controls (mode, zoom, layers)
- `efb-212/Views/Map/LayerControlsView.swift` - Layer toggle panel with opacity slider and style picker
- `efb-212/Views/Components/OpacitySlider.swift` - Sectional opacity slider 0-100%
- `efb-212/Views/Components/ChartExpirationBadge.swift` - Chart expiration warning badge
- `efb-212/ContentView.swift` - Map tab now uses MapContainerView instead of placeholder

## Decisions Made
- MapService runs on MainActor (not actor) because MLNMapView is UIKit main-thread-only
- Used SQLite3 C API directly for MBTiles metadata read to avoid GRDB dependency in MapService
- Ownship chevron rendered programmatically (32pt blue triangle with white outline) via UIGraphicsImageRenderer instead of bundled asset
- Region change debounce set to 500ms with 5NM skip threshold to prevent excessive database queries during map panning
- Layer controls presented as overlay panel rather than popover for better iPad landscape ergonomics
- Used `setDirection(0, animated: true)` for north-up reset since MLNMapView.resetNorth() is an IBAction

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added MapLibre import to MapViewModel.swift**
- **Found during:** Task 1
- **Issue:** MapViewModel referenced MLNStyle and MLNMapView without importing MapLibre. SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY requires explicit imports.
- **Fix:** Added `import MapLibre` to MapViewModel.swift
- **Files modified:** efb-212/ViewModels/MapViewModel.swift
- **Verification:** Build succeeded
- **Committed in:** 8ef56ec (Task 1 commit)

**2. [Rule 3 - Blocking] Added SQLite3 import to MapService.swift**
- **Found during:** Task 1
- **Issue:** Chart expiration metadata reading uses sqlite3_* C functions which require SQLite3 module import
- **Fix:** Added `import SQLite3` to MapService.swift
- **Files modified:** efb-212/Services/MapService.swift
- **Verification:** Build succeeded
- **Committed in:** 8ef56ec (Task 1 commit)

**3. [Rule 1 - Bug] Fixed resetNorth API call**
- **Found during:** Task 1
- **Issue:** MLNMapView.resetNorth() is an IBAction with no parameters; plan specified `resetNorth(animated: true)` which doesn't exist
- **Fix:** Used `setDirection(0, animated: true)` instead which achieves the same north-reset with animation
- **Files modified:** efb-212/ViewModels/MapViewModel.swift
- **Verification:** Build succeeded
- **Committed in:** 8ef56ec (Task 1 commit)

**4. [Rule 3 - Blocking] Added MapLibre import to MapControlsView.swift**
- **Found during:** Task 2
- **Issue:** MapControlsView called `setZoomLevel(_:animated:)` on MLNMapView without importing MapLibre
- **Fix:** Added `import MapLibre` to MapControlsView.swift
- **Files modified:** efb-212/Views/Map/MapControlsView.swift
- **Verification:** Build succeeded
- **Committed in:** 72ad807 (Task 2 commit)

---

**Total deviations:** 4 auto-fixed (1 bug, 3 blocking)
**Impact on plan:** All auto-fixes necessary for compilation. No scope creep.

## Issues Encountered
None beyond the auto-fixed deviations above.

## Known Stubs
- `MapContainerView.swift:66` - "Airport Info Placeholder" text in sheet body. **Intentional** - AirportInfoSheet is delivered in Plan 04 per the plan specification.
- `MapService.swift` - `getStationLatitude`/`getStationLongitude` return nil. **Intentional** - Weather dots are populated by Plan 04 which passes coordinates directly from airport database join.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Map rendering foundation complete, ready for weather overlay (Plan 04), instrument strip and nearest airport HUD (Plan 05)
- LocationService active and updating AppState ownship properties for instrument strip consumption
- GeoJSON sources for weather dots and TFRs are pre-wired (empty) awaiting data from Plan 04
- Chart expiration warning will show automatically once MBTiles are downloaded via Chart CDN (Phase 1 blocker)

## Self-Check: PASSED

All 9 created files verified on disk. Both task commits (8ef56ec, 72ad807) verified in git log.

---
*Phase: 01-foundation-navigation-core*
*Completed: 2026-03-21*
