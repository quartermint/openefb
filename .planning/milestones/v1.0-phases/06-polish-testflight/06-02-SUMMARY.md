---
phase: 06-polish-testflight
plan: 02
subsystem: ui
tags: [swiftui, settings, beta-banner, weather-staleness, testflight]

# Dependency graph
requires:
  - phase: 01-foundation
    provides: "MapViewModel, LayerControlsView, WeatherBadge, ContentView with TabView shell"
provides:
  - "SettingsView with version, feedback link, chart info, legal section"
  - "BetaBanner dismissable beta disclaimer with @AppStorage persistence"
  - "Weather data age badge in LayerControlsView"
  - "MapViewModel.oldestWeatherObservationTime tracked property"
affects: [06-03-testflight-submission]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "@AppStorage for persistent user preference flags"
    - "VStack wrapping TabView for non-tab overlay content (BetaBanner)"

key-files:
  created:
    - efb-212/Views/Settings/SettingsView.swift
    - efb-212/Views/Components/BetaBanner.swift
  modified:
    - efb-212/ContentView.swift
    - efb-212/Views/Map/LayerControlsView.swift
    - efb-212/ViewModels/MapViewModel.swift

key-decisions:
  - "@AppStorage for beta banner dismissal instead of SwiftData UserSettings -- simpler for single boolean flag"
  - "Weather age badge positioned under Weather toggle in LayerControlsView with 52pt left indent -- map dots are GeoJSON circles and cannot host SwiftUI badges"

patterns-established:
  - "VStack(spacing: 0) wrapping TabView for overlay content that spans all tabs"
  - "Tracked computed property pattern (oldestWeatherObservationTime / _oldestWeatherObservationTime) for @Observable weather age"

requirements-completed: [INFRA-05]

# Metrics
duration: 3min
completed: 2026-03-21
---

# Phase 06 Plan 02: Settings + Beta Banner + Weather Age Summary

**Settings tab with version/feedback/legal, dismissable beta banner with @AppStorage persistence, weather data age badge in LayerControlsView**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-21T20:16:15Z
- **Completed:** 2026-03-21T20:19:15Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- SettingsView replacing placeholder with real content: app version, build number, Send Feedback mailto link, chart info section, MPL-2.0 license and GitHub source link
- BetaBanner with @AppStorage("hasDismissedBetaBanner") for one-time dismissable beta disclaimer wired into ContentView
- Weather data age badge below Weather toggle in LayerControlsView showing oldest observation time via WeatherBadge component
- MapViewModel tracks oldestWeatherObservationTime from weather fetch results

## Task Commits

Each task was committed atomically:

1. **Task 1: Create SettingsView and BetaBanner components** - `8c39ade` (feat)
2. **Task 2: Wire SettingsView + BetaBanner into ContentView, add weather age to LayerControlsView** - `7ed746d` (feat)

## Files Created/Modified
- `efb-212/Views/Settings/SettingsView.swift` - Real Settings tab with version, feedback, charts, and legal sections
- `efb-212/Views/Components/BetaBanner.swift` - Dismissable beta disclaimer banner with @AppStorage persistence
- `efb-212/ContentView.swift` - Replaced Settings placeholder with SettingsView, added BetaBanner overlay via VStack wrapper
- `efb-212/Views/Map/LayerControlsView.swift` - Added weather data age badge below Weather toggle
- `efb-212/ViewModels/MapViewModel.swift` - Added oldestWeatherObservationTime tracked property updated on weather fetch

## Decisions Made
- Used @AppStorage("hasDismissedBetaBanner") instead of SwiftData UserSettings model -- single boolean flag doesn't warrant schema change, and @AppStorage is already declared in PrivacyInfo.xcprivacy UserDefaults reason CA92.1
- Weather age badge placed under Weather toggle in LayerControlsView with 52pt leading indent -- map weather dots are GeoJSON circles rendered by MapService and cannot host SwiftUI views, so LayerControlsView is the map surface's weather readout for staleness
- Wrapped TabView in VStack(spacing: 0) to position BetaBanner above all tabs -- banner renders conditionally (only when not dismissed) so zero visual impact after first dismissal

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Settings tab, beta banner, and weather age indicator are complete
- Ready for Plan 03: TestFlight submission, onboarding flow
- PrivacyInfo.xcprivacy (Plan 01) must declare @AppStorage usage (UserDefaults CA92.1 reason) to cover BetaBanner's @AppStorage

## Self-Check: PASSED

- [x] efb-212/Views/Settings/SettingsView.swift exists
- [x] efb-212/Views/Components/BetaBanner.swift exists
- [x] 06-02-SUMMARY.md exists
- [x] Commit 8c39ade found
- [x] Commit 7ed746d found

---
*Phase: 06-polish-testflight*
*Completed: 2026-03-21*
