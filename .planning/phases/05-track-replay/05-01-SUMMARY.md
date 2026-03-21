---
phase: 05-track-replay
plan: 01
subsystem: replay
tags: [avfoundation, maplibre, grdb, interpolation, playback, geojson]

# Dependency graph
requires:
  - phase: 03-flight-recording
    provides: RecordingDatabase with TrackPointRecord, TranscriptSegmentRecord, PhaseMarkerRecord
  - phase: 01-foundation-navigation-core
    provides: MapService with GeoJSON source/layer pattern, MapLibre integration
provides:
  - ReplayEngine @Observable @MainActor playback coordinator with time model
  - GPS interpolation between track points at configurable speeds (1x/2x/4x/8x)
  - Transcript segment matching by time range for synchronized highlighting
  - Phase marker fraction computation for scrub bar overlay
  - MapService replay track polyline (orange) and position marker layers
  - fitMapToTrack and centerOnCoordinate for replay view camera
affects: [05-track-replay plan 02 (ReplayView UI), flights tab]

# Tech tracking
tech-stack:
  added: [AVAudioPlayer rate control, PhaseMarkerFraction struct]
  patterns: [on-demand layer lifecycle (add/remove vs always-present), testTick for deterministic timer testing, binary search interpolation]

key-files:
  created:
    - efb-212/Services/Replay/ReplayEngine.swift
    - efb-212Tests/ServiceTests/ReplayEngineTests.swift
  modified:
    - efb-212/Services/MapService.swift
    - efb-212/Data/RecordingDatabase.swift

key-decisions:
  - "PhaseMarkerFraction struct instead of tuple array for @Observable compatibility"
  - "testTick() bypasses isPlaying guard for deterministic unit testing"
  - "Replay layers added on-demand via addReplayLayers, not in onStyleLoaded"
  - "Fixed GRDB UUID BLOB/TEXT mismatch in RecordingDatabase queries (pre-existing bug)"

patterns-established:
  - "On-demand MapService layer lifecycle: addReplayLayers/removeReplayLayers (not in onStyleLoaded)"
  - "testTick pattern: expose tick internals without isPlaying guard for deterministic testing"
  - "Binary search + linear interpolation for GPS position between track points"

requirements-completed: [REPLAY-01, REPLAY-02]

# Metrics
duration: 68min
completed: 2026-03-21
---

# Phase 5 Plan 1: ReplayEngine + MapService Replay Layers Summary

**ReplayEngine playback coordinator with 4-speed time model, GPS interpolation, transcript sync, and MapService orange track polyline + position marker layers (20 tests passing)**

## Performance

- **Duration:** 68 min
- **Started:** 2026-03-21T16:48:08Z
- **Completed:** 2026-03-21T17:56:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- ReplayEngine: @Observable @MainActor playback coordinator with single-source-of-truth time model driving synchronized map, audio, and transcript state
- GPS interpolation via binary search + linear interpolation between track points for smooth 20Hz animation
- MapService replay infrastructure: orange track polyline, heading-rotated position marker, fit-to-track camera, on-demand layer lifecycle
- 20 unit tests covering load, duration, interpolation (start/mid/end), tick at all 4 speeds, seek with clamping, transcript matching, phase marker fractions, play/pause, audio muting
- Fixed pre-existing GRDB UUID BLOB/TEXT mismatch bug in RecordingDatabase queries

## Task Commits

Each task was committed atomically:

1. **Task 1: ReplayEngine coordinator + unit tests** - `f56a6e9` (feat)
2. **Task 2: MapService replay track and marker layers** - `82b0fea` (feat)

## Files Created/Modified
- `efb-212/Services/Replay/ReplayEngine.swift` - @Observable playback coordinator: time model, interpolation, AVAudioPlayer sync, speed control, transcript matching (305 lines)
- `efb-212Tests/ServiceTests/ReplayEngineTests.swift` - 20 unit tests with temp GRDB database helper (447 lines)
- `efb-212/Services/MapService.swift` - Replay track polyline source, position marker source, fit-to-track, center-on-coordinate, on-demand layer add/remove (+150 lines)
- `efb-212/Data/RecordingDatabase.swift` - Fixed UUID BLOB/TEXT mismatch in all query filters

## Decisions Made
- **PhaseMarkerFraction struct over tuple array:** Swift's @Observable macro had issues tracking changes to `[(String, Double)]` tuple arrays. Created a dedicated `PhaseMarkerFraction` struct for reliable observation.
- **testTick() bypasses isPlaying guard:** Production `tick()` requires `isPlaying == true` (set by `play()`). Unit tests need deterministic tick control without Timer scheduling, so `testTick()` directly advances position.
- **On-demand replay layers:** Replay layers are NOT added in `onStyleLoaded` -- they are added via `addReplayLayers(to:)` when entering replay mode and removed via `removeReplayLayers()` when exiting. This avoids replay artifacts during normal navigation.
- **Fixed GRDB UUID BLOB/TEXT mismatch:** GRDB 7.x `PersistableRecord` stores UUID via `DatabaseValueConvertible` (BLOB), but queries used `flightID.uuidString` (TEXT). Changed all queries to use `flightID` directly for consistent BLOB comparison. This was a pre-existing bug affecting track point, transcript, and phase marker retrieval.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed GRDB UUID BLOB/TEXT mismatch in RecordingDatabase**
- **Found during:** Task 1 (ReplayEngine unit tests)
- **Issue:** GRDB 7.x stores UUID properties as 16-byte BLOBs via DatabaseValueConvertible, but all query filters compared with `flightID.uuidString` (TEXT string). SQLite BLOB != TEXT, so all track point, transcript, and phase marker queries returned 0 rows.
- **Fix:** Changed all `Column("flightID") == flightID.uuidString` to `Column("flightID") == flightID` in RecordingDatabase. Also fixed raw SQL arguments in updatePhaseMarkerEnd, deleteFlightData, insertDebrief, and deleteDebrief.
- **Files modified:** efb-212/Data/RecordingDatabase.swift
- **Verification:** All 20 ReplayEngine tests pass, data loads correctly from test database
- **Committed in:** f56a6e9 (Task 1 commit)

**2. [Rule 3 - Blocking] Added CoreLocation import to test file**
- **Found during:** Task 1 (initial test compilation)
- **Issue:** CLLocationCoordinate2D.latitude/longitude properties required `import CoreLocation` in test file
- **Fix:** Added `import CoreLocation` to ReplayEngineTests.swift
- **Files modified:** efb-212Tests/ServiceTests/ReplayEngineTests.swift
- **Verification:** Tests compile and run
- **Committed in:** f56a6e9 (Task 1 commit)

**3. [Rule 1 - Bug] PhaseMarkerFraction struct for @Observable compatibility**
- **Found during:** Task 1 (phase marker fraction test crash)
- **Issue:** `@Observable` macro didn't properly track changes to tuple array `[(phase: String, fraction: Double)]`, resulting in empty array after loadFlight
- **Fix:** Created `PhaseMarkerFraction` struct to replace the tuple type
- **Files modified:** efb-212/Services/Replay/ReplayEngine.swift
- **Verification:** phaseMarkerFractions test passes with correct values
- **Committed in:** f56a6e9 (Task 1 commit)

---

**Total deviations:** 3 auto-fixed (2 bugs, 1 blocking)
**Impact on plan:** All auto-fixes necessary for correctness. The UUID BLOB/TEXT fix resolves a pre-existing bug that would have affected production recording playback. No scope creep.

## Issues Encountered
- Simulator contention during parallel agent execution caused initial test runs to crash with "server died" errors. Resolved by using a different simulator (iPad Pro 11-inch) and disabling parallel testing.

## Known Stubs
None - all data sources are wired to RecordingDatabase, all MapService methods are functional.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- ReplayEngine provides the complete time model that Plan 02's UI will drive
- MapService has all layer infrastructure needed for the replay view
- Plan 02 can build ReplayView, ReplayViewModel, scrub bar, transcript panel, and speed controls on top of this foundation

## Self-Check: PASSED

- ReplayEngine.swift: FOUND (305 lines)
- ReplayEngineTests.swift: FOUND (447 lines, 20 @Test methods)
- 05-01-SUMMARY.md: FOUND
- Commit f56a6e9 (Task 1): FOUND
- Commit 82b0fea (Task 2): FOUND
- All 20 unit tests: PASSED

---
*Phase: 05-track-replay*
*Completed: 2026-03-21*
