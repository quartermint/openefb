---
phase: 01-foundation-navigation-core
plan: 05
subsystem: ui
tags: [swiftui, instrument-strip, nearest-airport, hud, gps, navigation, rtree]

# Dependency graph
requires:
  - phase: 01-foundation-navigation-core/01
    provides: "AppState with ownship properties (groundSpeed, altitude, verticalSpeed, track, gpsAvailable, activeFlightPlan, distanceToNext, estimatedTimeEnroute, directToAirport)"
  - phase: 01-foundation-navigation-core/02
    provides: "AviationDatabase with nearestAirports R-tree spatial query"
  - phase: 01-foundation-navigation-core/03
    provides: "MapContainerView composition structure, MapViewModel with databaseService"
provides:
  - "InstrumentStripView with GS/ALT/VS/TRK/DTG/ETE cells"
  - "NearestAirportHUD persistent capsule badge"
  - "NearestAirportViewModel with R-tree nearest airport queries"
  - "NearestAirportView sorted list with direct-to navigation"
  - "InstrumentCell reusable component for aviation readouts"
  - "NearestAirportEntry model for distance/bearing computation"
affects: [flight-planning, recording, map-integration]

# Tech tracking
tech-stack:
  added: []
  patterns: ["Aviation-standard rounding (ALT to 10ft, GS to 1kt)", "0.5 NM skip threshold for spatial query debounce", "Conditional instrument cells (DTG/ETE) based on AppState flight plan state"]

key-files:
  created:
    - efb-212/Views/Map/InstrumentStripView.swift
    - efb-212/Views/Map/NearestAirportHUD.swift
    - efb-212/Views/Map/NearestAirportView.swift
    - efb-212/ViewModels/NearestAirportViewModel.swift
  modified: []

key-decisions:
  - "Direct-to sets activeFlightPlan=true and computes DTG/ETE from ownship position and ground speed"
  - "NearestAirportViewModel skips DB query when ownship moves <0.5 NM to avoid excessive R-tree queries"
  - "Vertical speed displays with +/- prefix for immediate pilot readability"

patterns-established:
  - "InstrumentCell: Reusable VStack with label/value/unit for monospaced aviation readouts"
  - "NearestAirportEntry: Lightweight struct with precomputed distance/bearing for sorted display"
  - "Position-based query debounce: skip spatial queries when position change below threshold"

requirements-completed: [NAV-03, NAV-06, DATA-03]

# Metrics
duration: 4min
completed: 2026-03-21
---

# Phase 01 Plan 05: Instrument Strip + Nearest Airport Summary

**Instrument strip with GS/ALT/VS/TRK readouts, GPS fallback dashes, conditional DTG/ETE, and nearest airport HUD with R-tree spatial queries and direct-to navigation**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-21T02:28:38Z
- **Completed:** 2026-03-21T02:32:34Z
- **Tasks:** 1
- **Files modified:** 4

## Accomplishments
- InstrumentStripView with full-width bottom bar showing GS/ALT/VS/TRK instrument cells using monospaced typography per UI-SPEC
- Aviation-standard rounding: altitude to nearest 10 ft, ground speed to nearest 1 kt, track with 3-digit leading zeros
- GPS unavailable graceful degradation with "---" dashes and "No GPS" capsule indicator
- DTG and ETE cells conditionally visible only when activeFlightPlan or directToAirport is set
- NearestAirportHUD persistent capsule badge showing closest airport ICAO, distance (NM), and bearing
- NearestAirportViewModel with R-tree spatial query (10 nearest), 0.5 NM movement threshold to avoid excessive DB queries
- NearestAirportView sorted list with runway info, distance/bearing, and direct-to button
- Direct-to navigation sets AppState flight plan state with computed DTG and ETE

## Task Commits

Each task was committed atomically:

1. **Task 1: InstrumentStripView and NearestAirportHUD with view models** - `4725f45` (feat)

**Plan metadata:** (pending final commit)

## Files Created/Modified
- `efb-212/Views/Map/InstrumentStripView.swift` - Full-width bottom bar with GS/ALT/VS/TRK/DTG/ETE instrument cells, InstrumentCell reusable component
- `efb-212/Views/Map/NearestAirportHUD.swift` - Persistent capsule badge showing nearest airport with distance and bearing
- `efb-212/Views/Map/NearestAirportView.swift` - Full sorted list of nearest airports with runway info and direct-to button
- `efb-212/ViewModels/NearestAirportViewModel.swift` - R-tree nearest airport computation, 0.5 NM debounce, direct-to navigation

## Decisions Made
- Direct-to sets activeFlightPlan=true and computes DTG/ETE from ownship position and ground speed (>10 kt threshold to avoid divide-by-zero)
- NearestAirportViewModel skips DB query when ownship moves <0.5 NM to prevent excessive R-tree queries during minor GPS jitter
- Vertical speed displays with explicit +/- prefix for immediate pilot readability (aviation convention)
- ETE formatting uses hours+minutes when >60 min, minutes-only when <60 min

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed LightingType enum case in Preview**
- **Found during:** Task 1 (NearestAirportView)
- **Issue:** Plan specified `.mediumIntensity` for LightingType but actual enum has `.fullTime`, `.partTime`, `.none`
- **Fix:** Changed preview runway to use `.fullTime` lighting type
- **Files modified:** efb-212/Views/Map/NearestAirportView.swift
- **Verification:** Build succeeded
- **Committed in:** 4725f45 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Preview-only fix. No behavioral change.

## Issues Encountered
None beyond the enum case name mismatch in the preview code.

## User Setup Required
None - no external service configuration required.

## Known Stubs
None - all views are wired to real AppState properties and DatabaseServiceProtocol.

## Next Phase Readiness
- Instrument strip and nearest airport HUD are ready for integration into MapContainerView
- Views read directly from AppState @Observable properties -- will update live when LocationService feeds GPS data
- NearestAirportViewModel.setDirectTo() sets AppState properties that trigger DTG/ETE display in instrument strip
- Integration with MapContainerView can be done when both plan 04 and 05 views are ready

## Self-Check: PASSED

All 4 created files verified on disk. Commit 4725f45 verified in git log.

---
*Phase: 01-foundation-navigation-core*
*Completed: 2026-03-21*
