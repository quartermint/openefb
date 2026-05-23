# Phase 3: Flight Recording Engine - Context

**Gathered:** 2026-03-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver the complete flight recording pipeline: simultaneous GPS track + cockpit audio capture, real-time speech-to-text with aviation vocabulary processing, automatic flight phase detection, auto-start on speed threshold, and robust interruption handling. A pilot can start recording with one tap (or automatically) and get a clean capture of their entire flight.

</domain>

<decisions>
## Implementation Decisions

### Recording Controls & UX
- Record button is a prominent floating button on the map view (top-left), always accessible, one-tap start/stop, red color when recording
- Recording status shows a red dot + elapsed time in the top bar with pulse animation while recording — unmistakable, matches camera/recorder conventions
- Auto-start triggers when ground speed exceeds threshold (default 15 kts) with a 3-second countdown + cancel option — prevents accidental recording while taxiing slowly
- Manual stop shows confirmation dialog ("End flight recording?"); auto-stop triggers after 5 minutes below speed threshold — prevents accidental mid-flight stop

### Audio Engine & Transcription
- Two audio quality profiles: "Standard" (32kbps AAC, ~14MB/hr) and "High" (64kbps AAC, ~28MB/hr), default Standard — balances quality with 6-hour flight storage
- Live transcription shown in a scrolling, collapsible panel displaying last 3-5 segments — useful for reviewing ATC calls without filling the screen
- Aviation vocabulary post-processor corrects common Speech framework misrecognitions: "november" → "N", "niner" → "9", runway number formats, altitude callouts, frequency formats — leverages SFR's proven patterns
- Auto-resume recording after phone call / Siri / headphone disconnect interruption with gap marker in transcript — pilot should never need to manually restart

### Flight Phase Detection
- Speed + altitude state machine with hysteresis (SFR-proven approach): preflight (<5kts), taxi (5-15kts), takeoff (>15kts + climbing), cruise (level flight >500ft AGL), approach (descending), landing (<15kts after descent), postflight (<5kts sustained)
- Phase transitions shown as subtle label update in recording status bar ("Taxi" → "Takeoff" → "Cruise") — informational, not distracting to the pilot
- 30-second minimum hysteresis in each phase before transition allowed — prevents rapid toggling from turbulence or go-arounds
- Phase markers stored in GRDB with timestamp and GPS coordinates — enables per-phase analysis in AI debrief (Phase 4)

### Claude's Discretion
- Exact AVAudioEngine configuration and buffer sizes
- GPS track sampling rate optimization (1Hz vs adaptive)
- Speech framework locale and recognition task configuration
- Recording file naming convention and storage directory structure
- Background mode entitlement configuration details
- Memory management strategy for long recordings

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `EFBRecordingCoordinator.swift` — Existing recording coordinator (reference for state machine pattern)
- `FlightRecord.swift` — SwiftData @Model for flight data (reference for data model)
- SFR design patterns: TrackLogRecorder (adaptive GPS sampling), CockpitAudioEngine (quality profiles), AviationVocabularyProcessor (regex patterns for N-numbers, altitudes, frequencies, runways)

### Established Patterns
- Actor-based service pattern (WeatherService, ChartManager) — RecordingCoordinator should follow
- Combine publishers for state changes (recording state → UI updates)
- Background location already configured in LocationManager
- GRDB write-through for persistent data alongside in-memory state

### Integration Points
- LocationManager (Phase 1) provides CLLocationUpdate AsyncSequence for GPS track
- AppState.RecordingState sub-state for recording status across the app
- Phase 2 profiles: aircraft and pilot association with flight records
- GRDB aviation database for departure/arrival airport reverse lookup (nearest airport at start/end)
- Phase 4 depends on: GPS track points + finalized transcript segments in GRDB

</code_context>

<specifics>
## Specific Ideas

- SFR is the design spec, not importable code — algorithms and thresholds transfer as design knowledge
- AVAudioEngine with simultaneous file write + Speech framework buffer tap (SFR proven pattern)
- Only isFinal == true transcript segments stored to GRDB (discard volatile/partial)
- .airborne CLLocationUpdate configuration for in-flight accuracy
- Background audio session category must coexist with background location

</specifics>

<deferred>
## Deferred Ideas

- Radio coach AI training mode (future milestone)
- ADS-B integration for traffic awareness during recording (requires hardware)
- Video recording overlay (significant scope increase)

</deferred>

---
*Phase: 03-flight-recording-engine*
*Context gathered: 2026-03-20 via Smart Discuss (autonomous)*
