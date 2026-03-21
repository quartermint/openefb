# Roadmap: OpenEFB v1.0 — Public TestFlight

## Overview

Six phases from a fresh Xcode project to public TestFlight beta. Phases follow the dependency cascade in the architecture: the data layer and navigation core must be right before anything else is built on top (lesson from the Feb 2026 prototype). Profiles and planning precede recording so flight records can be associated with aircraft and pilot. Recording fully precedes AI debrief — there is no useful transcript without a real flight. Track replay completes the post-flight experience and is built on the recording + debrief storage from Phases 3–4. Polish and TestFlight submission close the milestone.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Foundation + Navigation Core** - New Xcode project, @Observable architecture, GRDB aviation database, MapLibre moving map with VFR sectional overlay, weather, airspace, TFRs, offline capability
- [ ] **Phase 2: Profiles + Flight Planning** - Aircraft and pilot profiles (SwiftData), currency tracking, A→B flight planning with ETE/fuel calculations
- [ ] **Phase 3: Flight Recording Engine** - GPS track + cockpit audio recording, real-time speech-to-text, flight phase detection, background location + audio lifecycle
- [ ] **Phase 4: AI Debrief + Logbook** - On-device Foundation Models debrief, FlightSummaryBuilder token compression, digital logbook auto-populated from recording, currency warnings
- [ ] **Phase 5: Track Replay** - GPS track playback with synchronized audio and scrolling transcript, flight history list
- [ ] **Phase 6: Polish + TestFlight** - Privacy manifest, performance validation, chart expiration warnings, weather staleness badges, public TestFlight distribution

## Phase Details

### Phase 1: Foundation + Navigation Core
**Goal**: A pilot can open the app, see their GPS position on a moving map with VFR sectional overlay, find airport information, check weather, and navigate with the instrument strip — all working offline
**Depends on**: Nothing (first phase). Chart CDN infrastructure (Cloudflare R2 + MBTiles pipeline) must be operational before phase verification.
**Requirements**: NAV-01, NAV-02, NAV-03, NAV-04, NAV-05, NAV-06, NAV-07, DATA-01, DATA-02, DATA-03, DATA-04, DATA-05, DATA-06, WX-01, WX-02, WX-03, INFRA-01, INFRA-02, INFRA-03
**Success Criteria** (what must be TRUE):
  1. Pilot opens the app and sees their live GPS position on the map as a heading indicator; position updates in real time; background location keeps tracking when screen locks
  2. VFR sectional chart tiles render on the map with working opacity slider; chart expiration status is visible; app functions normally with no network connection using pre-downloaded tiles and bundled airport database
  3. Pilot taps any airport on the map and sees runways (length/width/surface), radio frequencies, field elevation, current METAR with flight category color, and TAF; weather dot color coding is visible on the map; all weather data shows a staleness badge
  4. Pilot can toggle airspace boundaries (Class B/C/D with floor/ceiling labels), TFR polygons, weather dots, navaids, and airports on and off; proximity alerts fire when approaching Class B/C/D or an active TFR
  5. Pilot taps nearest airport to get a sorted list with distance, bearing, runways, and one-tap direct-to; instrument strip shows GS/ALT/VSI/TRK/DTG/ETE updating from GPS
**Plans**: 6 plans

Plans:
- [x] 01-01-PLAN.md — @Observable AppState, shared types, domain models, service protocols, SwiftData V1 schema, app entry point
- [ ] 01-02-PLAN.md — Aviation database: bundled SQLite with NASR airports, GRDB R-tree spatial index, FTS5 search, NASR importer tool
- [ ] 01-03-PLAN.md — Map layer: MapLibre UIViewRepresentable, GeoJSON sources, ownship GPS, VFR sectional overlay, layer toggles, LocationService
- [ ] 01-04-PLAN.md — Weather + airspace: NOAA METAR/TAF service, TFR service, proximity alerts, reachability, airport info sheet
- [ ] 01-05-PLAN.md — Navigation: instrument strip, nearest airport HUD, nearest airport list
- [ ] 01-06-PLAN.md — Final assembly: airport search, MapContainerView wiring with all services

### Phase 2: Profiles + Flight Planning
**Goal**: A pilot can enter their aircraft specs and certificate information, create a basic A→B flight plan with fuel and time calculations, and check their currency status before flying
**Depends on**: Phase 1 (AppState sub-states, SwiftData container, aviation database for airport search in flight planning)
**Requirements**: PLAN-01, PLAN-02, PLAN-03, PLAN-04
**Success Criteria** (what must be TRUE):
  1. Pilot can create and save an aircraft profile (N-number, type, fuel capacity, burn rate, cruise speed, V-speeds) that persists across app launches
  2. Pilot can create and save a pilot profile (name, certificate number, medical class/expiry, flight review date) that persists across app launches
  3. Pilot can enter departure and destination airports (with search), see the route drawn on the map, and read estimated distance (nm), time, and fuel burn using their saved aircraft profile
  4. Pilot's profile screen shows green/yellow/red currency status for medical expiry, flight review date, and 61.57 night passenger-carrying requirements
**Plans**: TBD

Plans:
- [ ] 02-01: SwiftData models — AircraftProfile, PilotProfile with VersionedSchema V1; CRUD views for each profile
- [ ] 02-02: Flight planning — departure/destination airport search, route rendering on map, distance/ETE/fuel calculation from aircraft profile; FlightPlanState integration
- [ ] 02-03: Currency tracking — computation from PilotProfile dates and logbook entries; currency status badges in profile view

### Phase 3: Flight Recording Engine
**Goal**: A pilot can start recording with one tap (or it auto-starts on takeoff), capturing GPS track and cockpit audio simultaneously with real-time transcription and automatic flight phase detection, and stop cleanly including after interruptions
**Depends on**: Phase 2 (aircraft and pilot profiles exist for associating recordings; SwiftData models stable)
**Requirements**: REC-01, REC-02, REC-03, REC-04, REC-05
**Success Criteria** (what must be TRUE):
  1. Pilot taps the record button; GPS track starts capturing at 1-second intervals and cockpit audio begins recording simultaneously; a one-tap stop ends both cleanly
  2. When ground speed crosses the configurable threshold (default 15 kts), recording starts automatically without any pilot action
  3. Cockpit audio records continuously for a 6+ hour flight at configurable quality without crashing or stopping; a simulated phone call interruption mid-flight resumes recording automatically
  4. Real-time transcript appears during flight with N-numbers, altitudes, headings, frequencies, and runway identifiers recognized correctly; only finalized (non-volatile) segments are stored
  5. Flight phase label (preflight / taxi / takeoff / departure / cruise / approach / landing / postflight) updates automatically based on GPS speed and altitude patterns during the flight
**Plans**: TBD

Plans:
- [ ] 03-01: RecordingCoordinator actor — GPS track capture (CLLocationUpdate AsyncSequence, .airborne config), flight phase detection state machine, auto-start threshold logic, background location + audio session configuration
- [ ] 03-02: Audio engine — AVAudioEngine with simultaneous file write + Speech framework buffer tap, 6-hour recording at configurable quality profiles, AVAudioSession interruption handling, headphone disconnect recovery
- [ ] 03-03: SpeechAnalyzer integration — real-time transcription with volatile/final distinction (only isFinal == true to GRDB), aviation vocabulary post-processor (N-numbers, ATC phrases, altitudes, frequencies), GRDB transcript storage

### Phase 4: AI Debrief + Logbook
**Goal**: After landing, a pilot can view an AI-generated post-flight debrief (narrative, per-phase observations, improvements, rating) on-device, confirm an auto-populated logbook entry, and see currency warnings if anything is approaching expiry
**Depends on**: Phase 3 (complete recording with GPS track + finalized transcript in GRDB), Phase 2 (pilot/aircraft profiles for logbook association)
**Requirements**: DEBRIEF-01, DEBRIEF-02, DEBRIEF-03, LOG-01, LOG-02, LOG-03, LOG-04
**Success Criteria** (what must be TRUE):
  1. After a recorded flight ends, pilot taps "Debrief" and sees a structured AI debrief streaming on-screen: narrative summary, observations grouped by flight phase, improvement suggestions, and an overall rating — all generated on-device
  2. On a device without Apple Intelligence enabled, the debrief screen shows a clear, non-alarming message explaining why debrief is unavailable with options for what the pilot can still do
  3. A digital logbook entry is auto-created from the recording with correct date, departure airport, arrival airport, route, block time, and aircraft; pilot can edit any field before confirming
  4. Pilot profile screen shows active warnings (yellow/red badges) when medical certificate, flight review, or 61.57 night currency is within 30 days of expiry or already expired
**Plans**: TBD

Plans:
- [ ] 04-01: FlightSummaryBuilder — token budget strategy (per-phase chunking to stay under 3,000 tokens from 4,096 limit), flight data compression from GRDB GPS track + transcript, phase-by-phase summarization pipeline
- [ ] 04-02: DebriefEngine — LanguageModelSession lifecycle (prewarm on FlightDetailView appear, discard on dismiss), @Generable FlightDebrief schema, streaming output to FlightDetailView, graceful degradation for unavailable Foundation Models
- [ ] 04-03: Logbook — LogbookEntry SwiftData model, auto-population from RecordingCoordinator output (departure/arrival from R-tree reverse lookup, duration, aircraft), pilot review + edit view, logbook list view
- [ ] 04-04: Currency warnings — computation layer wired to PilotProfile + LogbookEntry, warning display in profile and logbook views (30-day lookahead, 90-day 61.57 window)

### Phase 5: Track Replay
**Goal**: A pilot can select any past flight, watch their route replay on the map with synchronized cockpit audio and scrolling transcript, and browse their full flight history
**Depends on**: Phase 4 (flight records, logbook entries, and debrief content stored in GRDB + SwiftData from Phase 3/4)
**Requirements**: REPLAY-01, REPLAY-02
**Success Criteria** (what must be TRUE):
  1. Pilot opens a past flight and taps Play; a position marker follows the recorded GPS track on the map in real time at controllable playback speed
  2. As the position marker moves, cockpit audio plays in sync and the transcript scrolls to the matching segment; scrubbing the audio timeline moves both the map position and transcript position
**Plans**: TBD

Plans:
- [ ] 05-01: Track replay engine — AVAudioPlayer playback, GPS track animation synchronized to audio position, playback speed control, timeline scrub synchronization
- [ ] 05-02: Flight history UI — flight list view sorted by date, flight detail view with map replay + transcript + debrief summary, integration with logbook

### Phase 6: Polish + TestFlight
**Goal**: The app passes Apple privacy review, performs well on real iPad hardware, and is live on public TestFlight for VFR pilots to install and test
**Depends on**: Phase 5 (all features complete)
**Requirements**: INFRA-04, INFRA-05
**Success Criteria** (what must be TRUE):
  1. App includes a complete PrivacyInfo.xcprivacy declaring location continuous use (in-flight navigation), microphone (cockpit recording), and speech recognition; no App Store privacy rejections
  2. Map renders 20K airports without frame drops on an iPad Pro M2 or later; background recording shows expected battery impact in Instruments; no memory leaks in recording lifecycle
  3. When chart tiles are within 7 days of their 56-day FAA expiration cycle, a visible warning badge appears on the map layer; tiles past expiry show a distinct expired indicator
  4. A public TestFlight link is live and any VFR pilot with an iPad running iOS 26 can install and use the app with no account required
**Plans**: TBD

Plans:
- [ ] 06-01: Privacy manifest + App Store compliance — PrivacyInfo.xcprivacy (location, microphone, speech recognition), entitlements audit, background mode declarations, open-source repo hygiene (no credentials in history)
- [ ] 06-02: Performance + hardening — Instruments profiling (map rendering at 20K airports, recording battery impact), chart expiration warning UI (7-day badge, expired state), weather staleness badge on all weather displays, real-device recording lifecycle testing (phone call, Siri, headphone disconnect)
- [ ] 06-03: TestFlight submission — internal test build, external review submission, public TestFlight link, basic onboarding for first-time users

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation + Navigation Core | 0/6 | Planned | - |
| 2. Profiles + Flight Planning | 0/3 | Not started | - |
| 3. Flight Recording Engine | 0/3 | Not started | - |
| 4. AI Debrief + Logbook | 0/4 | Not started | - |
| 5. Track Replay | 0/2 | Not started | - |
| 6. Polish + TestFlight | 0/3 | Not started | - |

---
*Roadmap created: 2026-03-20*
*Coverage: 39/39 v1 requirements mapped*
