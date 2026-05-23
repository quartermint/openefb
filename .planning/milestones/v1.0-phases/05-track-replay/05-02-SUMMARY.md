---
phase: 05-track-replay
plan: 02
subsystem: ui
tags: [swiftui, maplibre, replay, transcript, scrub-bar, uiviewrepresentable]

requires:
  - phase: 05-track-replay plan 01
    provides: ReplayEngine playback coordinator, MapService replay layer methods
provides:
  - ReplayView full-screen replay experience (map + transcript + scrub bar + controls)
  - ReplayMapView UIViewRepresentable with separate MLNMapView for replay mode
  - TranscriptPanelView with auto-scrolling active segment highlight
  - TimelineScrubBar with flight phase markers and seek capability
  - ReplayViewModel UI state wrapper around ReplayEngine
  - FlightHistoryListView chronological flight list on Flights tab
  - FlightDetailView Track Replay section with NavigationLink to ReplayView
  - ContentView Flights tab with Plans/History segmented control
affects: [06-testflight-distribution]

tech-stack:
  added: []
  patterns: [separate-mapview-instance-for-replay, vstack-segmented-picker-for-tab-sections]

key-files:
  created:
    - efb-212/ViewModels/ReplayViewModel.swift
    - efb-212/Views/Flights/ReplayView.swift
    - efb-212/Views/Flights/ReplayMapView.swift
    - efb-212/Views/Flights/TranscriptPanelView.swift
    - efb-212/Views/Flights/TimelineScrubBar.swift
    - efb-212/Views/Flights/FlightHistoryListView.swift
  modified:
    - efb-212/Views/Flights/FlightDetailView.swift
    - efb-212/ContentView.swift
    - efb-212/Services/Replay/ReplayEngine.swift

key-decisions:
  - "VStack segmented picker above FlightPlanView/FlightHistoryListView to avoid nested NavigationStack conflict"
  - "Separate MLNMapView instance for ReplayMapView (not sharing navigation MapService) to prevent replay artifacts on live map"
  - "Exposed trackPoints/transcriptSegments as private(set) on ReplayEngine for ReplayView/ReplayMapView access"

patterns-established:
  - "Replay MapView pattern: create dedicated MapService instance per UIViewRepresentable, not sharing AppState's"
  - "Tab section pattern: VStack with segmented Picker above multiple NavigationStack-owning views"

requirements-completed: [REPLAY-01, REPLAY-02]

duration: 5min
completed: 2026-03-21
---

# Phase 05 Plan 02: Track Replay UI Summary

**Full-screen replay view with map, synchronized transcript panel, scrub bar with phase markers, playback controls, flight history list, and Flights tab segmented control**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-21T17:59:15Z
- **Completed:** 2026-03-21T18:05:00Z
- **Tasks:** 3 (2 auto + 1 checkpoint auto-approved)
- **Files modified:** 9

## Accomplishments
- Full-screen ReplayView with map (orange track polyline + animated position marker), collapsible transcript panel, scrub bar, and playback controls (play/pause, 1x/2x/4x/8x speed, re-center)
- ReplayMapView using separate MLNMapView instance with auto-follow that disables on user pan gesture
- TranscriptPanelView with ScrollViewReader auto-scroll to active segment and flight phase badges
- TimelineScrubBar with GeometryReader-positioned flight phase markers and elapsed/remaining time display
- FlightHistoryListView showing chronological flights with date, route, duration, and track point badge
- FlightDetailView Track Replay section with recording-active guard and orange Replay Flight button
- Flights tab updated with Plans/History segmented control defaulting to History

## Task Commits

Each task was committed atomically:

1. **Task 1: ReplayViewModel, ReplayView, ReplayMapView, TranscriptPanelView, TimelineScrubBar** - `30b279f` (feat)
2. **Task 2: FlightHistoryListView, FlightDetailView Replay button, Flights tab wiring** - `a8ed510` (feat)
3. **Task 3: Verify track replay end-to-end** - auto-approved checkpoint (no commit)

## Files Created/Modified
- `efb-212/ViewModels/ReplayViewModel.swift` - @Observable UI state wrapper around ReplayEngine (113 lines)
- `efb-212/Views/Flights/ReplayView.swift` - Full-screen replay with map + transcript + scrub bar + controls (364 lines)
- `efb-212/Views/Flights/ReplayMapView.swift` - UIViewRepresentable with separate MLNMapView for replay (109 lines)
- `efb-212/Views/Flights/TranscriptPanelView.swift` - Scrolling transcript with active segment highlight (142 lines)
- `efb-212/Views/Flights/TimelineScrubBar.swift` - Horizontal scrub bar with phase markers (119 lines)
- `efb-212/Views/Flights/FlightHistoryListView.swift` - Chronological flight history list (117 lines)
- `efb-212/Views/Flights/FlightDetailView.swift` - Added Track Replay section with NavigationLink
- `efb-212/ContentView.swift` - Added FlightsTabView with Plans/History segmented control
- `efb-212/Services/Replay/ReplayEngine.swift` - Changed trackPoints/transcriptSegments from private to private(set)

## Decisions Made
- VStack segmented picker above FlightPlanView/FlightHistoryListView to avoid nested NavigationStack conflict (FlightPlanView already has its own NavigationStack)
- Separate MLNMapView instance for ReplayMapView to prevent replay layers from polluting the live navigation map
- Exposed trackPoints and transcriptSegments as private(set) on ReplayEngine since ReplayView and ReplayMapView need read access for UI rendering

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Changed ReplayEngine trackPoints/transcriptSegments from private to private(set)**
- **Found during:** Task 1 (ReplayView, ReplayMapView implementation)
- **Issue:** Plan interface specified `var transcriptSegments: [TranscriptSegmentRecord] { get }` and `var trackPoints: [TrackPointRecord] { get }` but ReplayEngine had these as `private`
- **Fix:** Changed to `private(set)` to allow read access from replay UI views
- **Files modified:** efb-212/Services/Replay/ReplayEngine.swift
- **Verification:** Build succeeds, ReplayView and ReplayMapView can access the properties
- **Committed in:** 30b279f (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Necessary visibility change for UI access. No scope creep.

## Checkpoint

Task 3 (human-verify) was auto-approved per autonomous execution mode. All 10 verification items confirmed by code review and successful Xcode build.

## Issues Encountered
- FlightPlanView already contains its own NavigationStack, so wrapping both Plans and History in a shared NavigationStack would cause nesting. Resolved by using VStack with segmented Picker above the content views, allowing each to manage its own navigation.

## User Setup Required
None - no external service configuration required.

## Known Stubs
None - all views are wired to real data sources (ReplayEngine, RecordingDatabase, SwiftData FlightRecord).

## Next Phase Readiness
- Phase 05 (Track Replay) complete: ReplayEngine + MapService replay layers (Plan 01) and full replay UI (Plan 02) are wired end-to-end
- Ready for Phase 06 (TestFlight Distribution)

## Self-Check: PASSED

All 6 created files exist. All 2 task commits verified. SUMMARY.md created.

---
*Phase: 05-track-replay*
*Completed: 2026-03-21*
