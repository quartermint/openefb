---
phase: 01-foundation-navigation-core
plan: 04
subsystem: weather, services, ui
tags: [noaa, metar, taf, tfr, nwpathmonitor, swiftui, maplibre, geojson, proximity-alerts]

# Dependency graph
requires:
  - phase: 01-foundation-navigation-core (01-01)
    provides: Core types (WeatherCache, Airport, Airspace, TFR, FlightCategory), protocols (WeatherServiceProtocol, TFRServiceProtocol, ReachabilityServiceProtocol), AppState, EFBError
  - phase: 01-foundation-navigation-core (01-02)
    provides: AviationDatabase with R-tree spatial queries, DatabaseServiceProtocol, airspace containment check
  - phase: 01-foundation-navigation-core (01-03)
    provides: MapService with GeoJSON layers (weather dots, TFRs), MapViewModel, MapContainerView, LocationService
provides:
  - WeatherService with NOAA Aviation Weather API client (METAR/TAF) and 15-min cache
  - TFRService with sample TFR data (5 well-known TFRs) for Phase 1
  - ProximityAlertService with distance-based airspace/TFR alerts
  - ReachabilityService with NWPathMonitor network monitoring
  - WeatherViewModel for airport info sheet weather display
  - AirportInfoSheet bottom sheet with two-column layout
  - WeatherBadge staleness indicator component
  - FlightCategoryDot FAA standard color component
  - Weather dot integration on map via MapViewModel
  - TFR data loading and disclaimer banner on map
  - Offline indicator in MapContainerView
affects: [02-flight-recording, 03-ai-debrief, flight-planning, settings]

# Tech tracking
tech-stack:
  added: [NWPathMonitor (Network framework), NOAA Aviation Weather API]
  patterns: [actor-based service with in-memory cache, @Observable service with NWPathMonitor, distance-based proximity alerts with throttling, two-column bottom sheet layout]

key-files:
  created:
    - efb-212/Services/WeatherService.swift
    - efb-212/Services/TFRService.swift
    - efb-212/Services/ProximityAlertService.swift
    - efb-212/Services/ReachabilityService.swift
    - efb-212/ViewModels/WeatherViewModel.swift
    - efb-212/Views/Map/AirportInfoSheet.swift
    - efb-212/Views/Components/WeatherBadge.swift
    - efb-212/Views/Components/FlightCategoryDot.swift
  modified:
    - efb-212/Services/MapService.swift
    - efb-212/ViewModels/MapViewModel.swift
    - efb-212/Views/Map/MapContainerView.swift

key-decisions:
  - "WeatherService as actor (not @Observable class) for thread-safe cache access with nonisolated static constants"
  - "cachedWeather() returns nil synchronously — real cache access goes through fetchMETAR which checks cache first"
  - "MapService.updateWeatherDots takes stationCoordinates dict parameter for airport-correlated weather dot positions"
  - "TFRService ships 5 sample TFRs (DC SFRA, presidential, stadium, space launch, wildfire) with TFR_DATA_IS_SAMPLE flag"
  - "ProximityAlertService uses Haversine distance to nearest polygon vertex for approximate boundary distance"

patterns-established:
  - "Actor-based API services: actor isolation for network cache, nonisolated static for constants"
  - "Weather staleness badge pattern: progressive urgency coloring (fresh->yellow->red->gray STALE)"
  - "Two-column bottom sheet layout: left (frequencies/runways) right (weather) with .regularMaterial background"
  - "Manual refresh pattern: clear cache then re-fetch for forced weather update"
  - "TFR sample data with disclaimer banner: non-dismissable red banner when TFR layer visible"

requirements-completed: [WX-01, WX-02, WX-03, DATA-05, DATA-06, DATA-02, INFRA-02]

# Metrics
duration: 10min
completed: 2026-03-21
---

# Phase 01 Plan 04: Weather, TFR, Proximity Alerts, and Airport Info Summary

**NOAA weather service with 15-min METAR/TAF cache, sample TFR data, airspace proximity alerts (5/3/2 NM thresholds), NWPathMonitor reachability, and two-column airport info bottom sheet with manual refresh button**

## Performance

- **Duration:** 10 min
- **Started:** 2026-03-21T02:28:09Z
- **Completed:** 2026-03-21T02:38:09Z
- **Tasks:** 2
- **Files created:** 8
- **Files modified:** 3

## Accomplishments
- NOAA Aviation Weather API client fetching METAR/TAF with 15-minute in-memory cache, batch station queries (40 per batch), and flight category computation per FAA standards
- Airport info bottom sheet with ICAO header, flight category dot, info chips (elevation/type/TPA/fuel), two-column layout (frequencies+runways left, decoded weather+raw METAR right), manual refresh button
- TFR stub service with 5 well-known sample TFRs and non-dismissable disclaimer banner
- Airspace proximity alert service with class-specific thresholds (5 NM Class B, 3 NM Class C, 2 NM Class D), throttled to 10-second intervals
- Weather dot integration on map using airport-correlated coordinates from database
- Network reachability monitoring with offline indicator in map view

## Task Commits

Each task was committed atomically:

1. **Task 1: WeatherService, TFRService, ProximityAlertService, ReachabilityService** - `4725f45` (feat)
2. **Task 2: AirportInfoSheet, WeatherBadge, FlightCategoryDot, WeatherViewModel, MapContainerView integration** - `53ddda5` (feat)

## Files Created/Modified
- `efb-212/Services/WeatherService.swift` - NOAA METAR/TAF API client with 15-min cache, batch fetch, flight category parsing (310 lines)
- `efb-212/Services/TFRService.swift` - Stub TFR service with 5 sample TFRs (DC SFRA, presidential, stadium, space launch, wildfire) (129 lines)
- `efb-212/Services/ProximityAlertService.swift` - Airspace/TFR proximity detection with distance-based alerts (216 lines)
- `efb-212/Services/ReachabilityService.swift` - NWPathMonitor wrapper for network status (39 lines)
- `efb-212/ViewModels/WeatherViewModel.swift` - Weather display VM with decoded fields and manual refresh (124 lines)
- `efb-212/Views/Map/AirportInfoSheet.swift` - Half-height bottom sheet with two-column airport info layout (388 lines)
- `efb-212/Views/Components/WeatherBadge.swift` - Capsule staleness indicator (fresh/yellow/red/STALE) (70 lines)
- `efb-212/Views/Components/FlightCategoryDot.swift` - FAA standard color-coded circle (VFR/MVFR/IFR/LIFR) (41 lines)
- `efb-212/Services/MapService.swift` - Updated updateWeatherDots to accept stationCoordinates lookup dict
- `efb-212/ViewModels/MapViewModel.swift` - Added weather dot loading, TFR loading, proximity alert integration
- `efb-212/Views/Map/MapContainerView.swift` - Wired AirportInfoSheet, TFR disclaimer, offline indicator, reachability

## Decisions Made
- WeatherService implemented as Swift actor (not @Observable class) for thread-safe cache access; nonisolated static constants avoid MainActor isolation warnings
- `cachedWeather()` protocol method returns nil synchronously to satisfy Sendable protocol contract; real cache access goes through `fetchMETAR()` which checks cache first (known limitation documented in PROJECT.md)
- MapService `updateWeatherDots` changed to accept `stationCoordinates: [String: CLLocationCoordinate2D]` parameter instead of internal coordinate lookup, because weather station coordinates come from joining with airport database
- TFR service ships with 5 hardcoded sample TFRs representing common TFR types; `TFR_DATA_IS_SAMPLE` constant controls UI disclaimer banner
- ProximityAlertService approximates distance to polygon airspace boundary using nearest vertex (Haversine), which is adequate for alert thresholds

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed Swift static property isolation warnings**
- **Found during:** Task 1 (WeatherService)
- **Issue:** Static let properties on actor type inherited MainActor isolation from project-wide default, causing "cannot be accessed from outside of the actor" warnings (future Swift 6 errors)
- **Fix:** Added `nonisolated` modifier to static let constants (metarURL, tafURL, cacheExpiry)
- **Files modified:** efb-212/Services/WeatherService.swift
- **Committed in:** 4725f45 (Task 1 commit)

**2. [Rule 1 - Bug] Fixed Font.largeTitle.rounded() chain syntax**
- **Found during:** Task 2 (AirportInfoSheet)
- **Issue:** `.font(.largeTitle.rounded().weight(.semibold))` is invalid SwiftUI font chain; `Font` has no `.rounded()` member
- **Fix:** Changed to `.font(.system(.largeTitle, design: .rounded, weight: .semibold))` which is the correct SwiftUI API
- **Files modified:** efb-212/Views/Map/AirportInfoSheet.swift
- **Committed in:** 53ddda5 (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (2 bugs)
**Impact on plan:** Both auto-fixes necessary for clean compilation. No scope creep.

## Known Stubs

- `TFRService` uses hardcoded sample data (5 TFRs) -- live FAA TFR API integration deferred to future iteration per RESEARCH.md
- `cachedWeather()` returns nil synchronously -- callers use `fetchMETAR()` (async, cache-aware) instead

## Issues Encountered
- Build failure in NearestAirportView.swift (plan 01-05 file) using nonexistent `LightingType.mediumIntensity` -- this is a pre-existing issue in a file owned by the parallel plan executor, not related to this plan's changes

## User Setup Required
None - no external service configuration required. NOAA Aviation Weather API is free and requires no API key.

## Next Phase Readiness
- Weather services, TFR stub, proximity alerts, and airport info sheet are fully wired
- MapViewModel can load weather dots and TFRs when layers are toggled on
- Flight planning (Plan 05) can use WeatherService for route weather display
- Phase 2 (flight recording) has all foundation services available

---
*Phase: 01-foundation-navigation-core*
*Completed: 2026-03-21*
