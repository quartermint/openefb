# Project Research Summary

**Project:** OpenEFB — Open-Source iPad VFR Electronic Flight Bag
**Domain:** iOS aviation app — moving-map navigation, flight recording, on-device AI debrief
**Researched:** 2026-03-20
**Confidence:** HIGH (all four research areas verified against official docs, official releases, and first-hand prototype post-mortem)

## Executive Summary

OpenEFB is a VFR EFB for iPad that combines standard moving-map navigation (VFR sectional overlay, airport database, weather, airspace) with a differentiating loop: integrated cockpit audio recording → real-time speech-to-text → automatic flight phase detection → on-device AI debrief. The stack is well-defined: Swift 6.2 + iOS 26 with `@Observable` (not `ObservableObject`/Combine), MapLibre Native iOS for raster tile rendering, GRDB for aviation data (R-tree spatial indexes required), SwiftData for user data, Apple Foundation Models for AI debrief, and `CLLocationUpdate` AsyncSequence for GPS. The technology choices are constrained by hard requirements — MapLibre is the only open-source SDK that supports VFR sectional raster overlays, GRDB is required because SwiftData cannot use R-tree spatial indexes across 20K airports, and Foundation Models is the only path to on-device AI debrief without violating the zero-cloud-dependency constraint.

The market position is unoccupied. No competitor is free, open-source, requires no account, and provides on-device AI narrative debrief from cockpit audio. ForeFlight's debrief product requires an Essential plan ($240/yr) and is GPS-only. CloudAhoy charges $59-$119/yr, requires a separate app and account, and produces scoring without narrative. Zero competitors have on-device LLM debrief. The combination of table-stakes navigation features plus the recording/debrief loop, delivered free with no account, occupies genuine whitespace in the market.

The primary risks are architectural and operational, not competitive. The prototype already hit three of the most dangerous pitfalls (AppState god object with ObservableObject, individual MLNPointAnnotation for 20K airports, Swift literal seed data). The fresh start must address all three on day one. The additional material risks are the Apple Foundation Models 4,096-token context window (requires a chunking/summarization pipeline — a 1-hour transcript is 5,000-15,000 words), audio session interruption handling during long flights, and the 56-day FAA chart update cycle requiring an automated server-side pipeline. These are engineering problems with known solutions, not unknown unknowns.

## Key Findings

### Recommended Stack

The stack is fully determined by the product requirements and cannot be substituted in the areas that matter. Swift 6.2 + iOS 26 with `@Observable` eliminates the Combine boilerplate that undermined the prototype. MapLibre Native iOS (6.24.0) is the only open-source map SDK with raster tile overlay support for VFR sectionals — there is no alternative that is both open-source and technically capable. GRDB 7.10.0 is required for R-tree spatial indexing across 20K airports; SwiftData cannot satisfy this requirement. Apple Foundation Models is the only path to on-device AI debrief; cloud AI violates the v1 constraint. See `STACK.md` for full version compatibility and SPM installation details.

**Core technologies:**
- **Swift 6.2 + iOS 26**: Language and deployment target — `@Observable` replaces all `ObservableObject`/`@Published`/Combine state management; "Approachable Concurrency" (main-actor-by-default) reduces annotation boilerplate
- **MapLibre Native iOS 6.24.0**: Map rendering — only open-source iOS SDK supporting VFR sectional raster tile overlays; GeoJSON sources + symbol layers handle 20K airports at full framerate
- **MapLibre SwiftUI DSL 0.21.1**: SwiftUI integration — official wrapper, prevents `UIViewRepresentable` state loop pitfalls
- **GRDB 7.10.0**: Aviation database — R-tree spatial indexes for nearest-airport queries, FTS5 for identifier/name search, WAL mode; SwiftData cannot replace this
- **SwiftData (iOS 26)**: User data — pilot profiles, aircraft profiles, flight records, logbook entries; CloudKit-ready but disabled until v1.x
- **CLLocationUpdate AsyncSequence**: GPS tracking — Swift 6 native API, `.airborne` config, no delegate pattern required
- **AVAudioEngine**: Cockpit audio — tap-based real-time buffer access required for simultaneous Speech framework input + file write; `AVAudioRecorder` cannot do both
- **Speech Framework (SpeechAnalyzer, iOS 26)**: Real-time transcription — on-device only (`requiresOnDeviceRecognition = true`); volatile/final distinction is critical
- **Apple Foundation Models**: On-device AI debrief — `LanguageModelSession` + `@Generable` + streaming; 4,096-token context limit requires chunking pipeline; check `SystemLanguageModel.default.availability` before use
- **NOAA Aviation Weather API**: METAR/TAF — free, keyless, 100 req/min limit requires bulk batch requests and 15-min cache TTL
- **Cloudflare R2 + PMTiles**: Chart tile CDN — server-side GeoTIFF → MBTiles pipeline required (GDAL); 56-day FAA update cycle must be automated

### Expected Features

The feature landscape is well-mapped against ForeFlight, Garmin Pilot, FltPlan Go, WingX, and CloudAhoy. Every competitor charges for the features that matter most to OpenEFB's differentiation. See `FEATURES.md` for the full dependency graph, prioritization matrix, and competitor analysis.

**Must have (table stakes) — pilot won't install without these:**
- Moving map with GPS ownship and background location
- VFR sectional chart overlay (requires CDN tile pipeline — a build-phase dependency)
- Airport database with 20K+ NASR airports, search (FTS5), and info sheet
- METAR/TAF with flight category colors + weather dots on map
- Airspace boundaries (Class B/C/D) and TFR display with proximity alerts
- Nearest airport emergency feature (R-tree spatial query)
- Basic flight planning with instrument strip (GS/ALT/TRK/VSI)
- Layer controls and map mode selector
- Offline capability for charts and airport database
- Aircraft and pilot profiles

**Should have (differentiators — the reason to build this):**
- Integrated cockpit audio recording + GPS track (auto-start on takeoff detection)
- Real-time speech-to-text with aviation vocabulary post-processing
- Automatic flight phase detection (preflight/taxi/takeoff/cruise/approach/landing)
- On-device AI post-flight debrief: narrative + phase observations + rating
- Digital logbook auto-populated from recording (departure, destination, duration, aircraft)
- Track replay with synchronized audio and transcript
- Currency tracking: medical, flight review, 61.57 passenger-carrying

**Defer to v1.x (add after TestFlight validation):**
- CloudKit sync (foundation is built; activation deferred until data model proven)
- Cloud premium debrief tier (Claude API) for non-Apple-Intelligence devices
- GPX/KMZ export, PIREP display, multi-leg route planning, ForeFlight import

**Defer to v2+ (not in scope):**
- ADS-B traffic (hardware dependency contradicts core value)
- NEXRAD radar (ADS-B hardware required), Weight and balance calculator
- CFI/student dual logging mode, IFR approach plates

### Architecture Approach

The architecture is a 6-tier dependency cascade: Core Types → Data Layer (GRDB + SwiftData) → Core Services (actors) → Map Layer (MapLibre) → Recording Engine (GPS + Audio actors) → Debrief Engine (Foundation Models) → ViewModels + Views. AppState is decomposed into focused sub-states (`NavState`, `MapState`, `RecordingState`, `FlightPlanState`, `SystemState`) — each independently `@Observable` and testable, held by root AppState for single-injection-point convenience. Services are `nonisolated actor` for background work; ViewModels are `@MainActor @Observable`. All airport/navaid/weather rendering goes through `MLNShapeSource` + `MLNSymbolStyleLayer` (never `MLNPointAnnotation`). `DebriefEngine` owns one `LanguageModelSession` per flight lifecycle, prewarms on `FlightDetailView` appear, and handles context overflow by triggering a per-phase chunking strategy. See `ARCHITECTURE.md` for full data flow diagrams and code patterns per component.

**Major components:**
1. **AppState (decomposed sub-states)** — global coordinator; MapState, RecordingState, NavState, FlightPlanState, SystemState
2. **AviationDatabase (GRDB)** — airports, navaids, airspace; R-tree spatial index; FTS5 search; WAL mode; bundled SQLite resource
3. **WeatherService + TFRService (nonisolated actors)** — NOAA METAR/TAF; FAA TFR; batch requests; 15-min cache; 429 backoff
4. **MapService** — MLNMapView wrapper; GeoJSON sources; symbol layers; raster sectional overlay; ownship layer
5. **RecordingCoordinator (nonisolated actor)** — GPS track + AVAudioEngine orchestration; flight phase detection; background-capable
6. **DebriefEngine (@MainActor @Observable)** — LanguageModelSession lifecycle; FlightSummaryBuilder (token budgeting); streaming output
7. **ChartManager (nonisolated actor)** — CDN download; MBTiles lifecycle; 56-day expiration tracking
8. **SwiftData Container** — pilot/aircraft profiles, flight records, logbook; CloudKit-ready (disabled v1)

### Critical Pitfalls

Research confirmed 12 pitfalls across the domain, with 3 already hit in the prototype. All are addressed by the architecture above but require explicit phase-level enforcement. See `PITFALLS.md` for full detail, warning signs, recovery costs, and the "Looks Done But Isn't" checklist.

1. **AppState god object** — Split into domain sub-states on day one; AppState.swift must stay under 100 lines; the prototype already proved the recovery cost is HIGH
2. **MLNPointAnnotation for 20K airports** — Use GeoJSON `MLNShapeSource` + `MLNSymbolStyleLayer` from the first airport dot; annotation API is unusable at this scale
3. **Foundation Models 4,096-token context cliff** — Build `FlightSummaryBuilder` with a per-phase chunking strategy before writing debrief code; a 1-hour transcript is 5-15x over the limit
4. **Foundation Models device availability** — Check `SystemLanguageModel.default.availability` as the first line in the debrief code path; test on a non-Apple-Intelligence device before Phase 2 ships
5. **SwiftData unversioned schema** — Wrap all `@Model` classes in `VersionedSchema` V1 on day one; retrofitting this after TestFlight users exist requires a two-release migration dance
6. **AVAudioSession interruption during recording** — Handle `AVAudioSessionInterruptionNotification` explicitly; configure session at app launch, not on first tap; test with a phone call mid-flight on real device
7. **SpeechAnalyzer volatile/final distinction** — Only persist `isFinal == true` segments; volatile segments are display-only; unversioned storage produces corrupted transcripts
8. **Chart 56-day expiration blind spot** — Embed expiration metadata in CDN response; show 7-day warning badge; automate the tile pipeline; never treat chart tiles as static assets

## Implications for Roadmap

The dependency cascade in the architecture maps directly to a phase structure. Phases 1-3 are table-stakes (no recording/debrief); Phases 4-5 are the differentiating loop; Phase 6 is the retention/engagement layer. This order is not optional — the debrief engine cannot be built without the recording engine, which cannot be built without the data layer, which must be done correctly or the schema migration cost falls on users.

### Phase 1: Foundation + Navigation Core

**Rationale:** All other phases depend on the data layer, AppState sub-states, GRDB schema, and MapLibre rendering being correct. The prototype's three fatal flaws (god object AppState, annotation perf cliff, Swift literal seed data) must all be resolved here before anything else is built on top. The chart CDN pipeline is also a Phase 1 dependency because the tile server must exist before the map layer can be tested end-to-end.

**Delivers:** Functional moving-map EFB — pilots can navigate VFR with sectional overlay, airport database, weather, airspace, and TFRs; instrument strip; nearest airport emergency feature; offline capability

**Addresses:**
- Moving map + GPS ownship + background location
- VFR sectional chart overlay (requires CDN pipeline operational)
- Airport database (20K NASR, FTS5 search, R-tree spatial index, bundled SQLite)
- METAR/TAF with flight category colors and weather map dots
- Airspace boundaries and TFR display with proximity alerts
- Nearest airport emergency feature
- Instrument strip (GPS ALT labeled explicitly — not "ALT MSL")
- Layer controls + map mode selector
- Offline chart tiles + offline airport database

**Avoids (critical pitfalls):**
- AppState god object — decomposed sub-states are the foundation, not a refactor
- GeoJSON source architecture from first airport dot — never MLNPointAnnotation
- Bundled SQLite resource — not Swift literal seed data
- SwiftData VersionedSchema V1 for all @Model classes before anything ships
- Chart expiration metadata in CDN design before pipeline is built
- NOAA bulk batch request pattern — not per-airport requests
- GPS altitude labeled "GPS ALT" throughout

**Research flag:** Phase planning will need to address the server-side GeoTIFF → MBTiles → Cloudflare R2 pipeline, which is outside the Xcode project. This pipeline must be operational before this phase can be fully verified. Standard patterns exist (GDAL, PMTiles) — research-phase is optional but operational setup is a hard dependency.

---

### Phase 2: Aircraft + Pilot Profiles + Flight Planning

**Rationale:** Flight planning (distance, time, fuel) depends on aircraft profiles (speeds, fuel burn). Currency tracking depends on pilot profiles (medical, flight review dates) and logbook entries. Both are prerequisites for the logbook auto-population in Phase 5, and must be built before flight recording to correctly associate recordings with aircraft/pilot. This is the lowest-complexity phase — pure SwiftData CRUD with no external dependencies.

**Delivers:** Complete pre-flight tool — pilots enter aircraft V-speeds and fuel burn, pilot certificate and medical dates; basic A→B→C flight planning with ETE/fuel calculations; currency tracking (medical, flight review, 61.57)

**Addresses:**
- Aircraft profile (type, speeds, fuel burn)
- Pilot profile (name, certificate, medical, flight review dates)
- Basic flight planning: departure, destination, route, ETE, fuel
- Currency tracking (pure computation from SwiftData logbook)

**Avoids:** SwiftData VersionedSchema (profiles must be versioned from day one — pilots will use these records long-term)

**Research flag:** Standard patterns — no research-phase needed. SwiftData CRUD with SwiftUI forms is well-documented.

---

### Phase 3: Flight Recording Engine

**Rationale:** Recording is the prerequisite for transcription, phase detection, AI debrief, logbook auto-population, and track replay. It is the highest-risk phase technically (background location + audio + transcription simultaneously), so it must be isolated and proven before the debrief layer is built on top. The recording engine must handle audio session interruption correctly from day one — not as a polish item.

**Delivers:** Complete flight recording — auto-start on takeoff (speed threshold), GPS track at 1-second intervals, cockpit audio for 6+ hours, real-time SpeechAnalyzer transcription (volatile display / final storage), flight phase detection (preflight/taxi/takeoff/cruise/approach/landing), auto-stop on landing

**Addresses:**
- Flight recording: GPS + cockpit audio + auto-start on takeoff
- Real-time speech-to-text with aviation vocabulary
- Automatic flight phase detection
- Background location + audio session (full iOS lifecycle including interruption)

**Avoids:**
- `RecordingCoordinator` as `nonisolated actor` — not a class with `@unchecked Sendable`
- SpeechAnalyzer volatile/final distinction — only `isFinal == true` to GRDB
- AVAudioSession interruption handling — required, not optional; tested with phone call on real device
- AVAudioEngine (not AVAudioRecorder) — required for simultaneous file write + Speech framework buffer tap

**Research flag:** Needs `/gsd:research-phase` during planning — background audio + location + speech framework interactions are complex and iOS version-specific. Interruption behavior on iOS 26 may differ from documentation.

---

### Phase 4: AI Debrief + Logbook

**Rationale:** Debrief depends on the complete recording from Phase 3 (GPS track + transcript). Logbook auto-population depends on flight recording (duration), airport database (departure/destination lookup from GPS), and pilot/aircraft profiles from Phase 2. This phase completes the core differentiating loop.

**Delivers:** The primary differentiator — AI post-flight debrief (narrative + phase observations + improvements + rating) streaming from on-device Foundation Models; digital logbook auto-populated from recording with pilot review; flight detail view with debrief display

**Addresses:**
- AI post-flight debrief (narrative, phase observations, improvements, rating)
- Digital logbook auto-populated from recording (departure, destination, duration, aircraft)
- DebriefEngine: `LanguageModelSession` lifecycle, `FlightSummaryBuilder` (token budget), streaming output, context overflow handling
- Graceful degradation for non-Apple-Intelligence devices

**Avoids:**
- Foundation Models 4,096-token context cliff — `FlightSummaryBuilder` with per-phase chunking is the first thing built in this phase
- Foundation Models device availability — check as first line of debrief code path; test on unsupported device
- One `LanguageModelSession` per debrief lifecycle (prewarm on view appear, discard on dismiss)
- Full transcript as single prompt — phase-by-phase summarization then final synthesis

**Research flag:** Needs `/gsd:research-phase` during planning — `@Generable` schema design for `FlightDebrief`, prompt engineering for aviation-context debrief, and FlightSummaryBuilder token budget strategy are novel and require validation against real flight transcripts before committing to an architecture.

---

### Phase 5: Track Replay + Export

**Rationale:** Track replay (GPS + synchronized audio + scrolling transcript) completes the debrief experience and is the retention feature that brings pilots back after each flight. It depends on the complete recording pipeline from Phase 3 and flight storage from Phase 4. This phase also adds v1.x features: GPX/KMZ export, PIREP display.

**Delivers:** Track replay with synchronized audio and transcript scrolling; flight history list; GPX export via AirDrop/Files; PIREP display on map from NOAA

**Addresses:**
- Track replay with synchronized audio and transcript
- Flight history browsing
- GPX/KMZ export (post-TestFlight validation feature)
- PIREP display from NOAA (quick add on existing weather API)

**Research flag:** Timeline synchronization between AVAudioPlayer position and GPS track playback is the novel technical challenge here. Standard patterns from video scrubbing exist but aviation-specific sync needs validation.

---

### Phase 6: Polish, Privacy, TestFlight

**Rationale:** TestFlight external beta requires Apple review. Privacy manifest completeness is a submission blocker (12% rejection rate in Q1 2025). This phase ensures the app can be distributed and collects pilot feedback to drive v1.x priorities.

**Delivers:** Public TestFlight distribution; privacy manifest complete; performance validated on real devices; chart expiration warnings working; data staleness badges on all weather displays; public repo preparations

**Addresses:**
- Privacy manifest (`PrivacyInfo.xcprivacy`) — location, microphone, speech recognition, motion
- Performance verification with Instruments (map at 20K airports, battery impact of background recording)
- Chart expiration warning UI (7-day badge before rollover)
- Weather dot staleness badges (grey out after 2 hours)
- Background recording testing on real device (phone call interruption, Siri, headphone disconnect)
- Open-source repo hygiene — no credentials in history, no API keys in code

**Avoids:** Privacy manifest rejection, first-build TestFlight delay (external review takes 24-48 hours)

**Research flag:** No research-phase needed — Apple privacy manifest requirements are well-documented.

---

### Phase Ordering Rationale

- **Phases are dependency-ordered, not effort-ordered.** Phase 1 must come first because every other phase depends on the data layer and AppState being correct. This is the lesson from the prototype — the god object and annotation perf cliff blocked everything downstream.
- **Recording before Debrief.** The debrief engine has no useful test data without a real recording. Building Phase 4 before Phase 3 would require synthetic test data that masks real-world failures (audio session interruptions, volatile transcript artifacts, GPS accuracy variance at altitude).
- **Profiles before Recording.** Logbook auto-population (Phase 4) associates recordings with aircraft/pilot. Those profiles must exist and be stable before Phase 3 data is captured, or the association cannot be made retroactively without a migration.
- **Chart CDN is Phase 1 critical path.** The VFR sectional overlay cannot be tested without the CDN pipeline. This is the only external infrastructure dependency in the roadmap. It must be operational before Phase 1 can be verified complete.
- **CloudKit sync is deliberately deferred.** The SwiftData models ship CloudKit-ready in Phase 1, but sync is not enabled until v1.x after TestFlight validates the data model is stable. Enabling sync prematurely with an unstable schema is a trust-destroying failure for pilot logbook data.

### Research Flags

Phases needing `/gsd:research-phase` during planning:
- **Phase 3 (Recording Engine):** Background audio + location + SpeechAnalyzer interactions on iOS 26 are complex. Interruption handling behavior, SpeechAnalyzer API surface for long-form cockpit audio, and `AVAudioEngine` tap configuration with simultaneous file write all need validation before implementation.
- **Phase 4 (AI Debrief):** `@Generable` schema design for `FlightDebrief`, `FlightSummaryBuilder` token budget strategy, and prompt engineering for aviation-context debrief are novel. The 4,096-token constraint with real flight data needs to be validated before committing to a chunking architecture.

Phases with standard patterns (skip research-phase):
- **Phase 1 (Foundation + Navigation):** Stack is fully determined, patterns are established. GRDB, MapLibre, SwiftData, @Observable — all have official documentation and existing usage in the codebase. CDN pipeline has a known toolchain (GDAL + PMTiles + Cloudflare R2).
- **Phase 2 (Profiles + Planning):** Pure SwiftData CRUD with SwiftUI forms. No novel patterns.
- **Phase 5 (Track Replay):** AVAudioPlayer + timeline scrubbing patterns exist. Novel only in the aviation-specific sync detail.
- **Phase 6 (Polish + TestFlight):** Privacy manifest, Instruments profiling, App Store submission — all well-documented by Apple.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All critical choices verified against official docs and confirmed package releases. Version compatibility matrix confirmed. SPM identifiers verified against current GitHub releases. |
| Features | HIGH | Verified against ForeFlight, Garmin Pilot, WingX, FltPlan Go, CloudAhoy product pages and pilot community forums. Competitor pricing and feature matrix confirmed. |
| Architecture | HIGH | iOS 26/@Observable/Foundation Models patterns confirmed via WWDC25 sessions and Apple docs. MapLibre GeoJSON patterns confirmed via official docs. Concurrency patterns from TN3193 and WWDC25. |
| Pitfalls | HIGH | 3 of 12 pitfalls confirmed first-hand via prototype post-mortem. Remainder confirmed via Apple Developer Forums, WWDC sessions, and domain-specific sources. |

**Overall confidence: HIGH**

### Gaps to Address

- **Foundation Models prompt quality:** The research confirms the 4,096-token architecture constraint and the need for `FlightSummaryBuilder`, but the actual prompt quality for aviation-context debrief is unknowable until tested with real 45+ minute flight recordings. The debrief quality is the product's primary value proposition — allocate time in Phase 4 for iterative prompt tuning before declaring the phase complete.
- **SpeechAnalyzer long-form reliability:** The iOS 26 SpeechAnalyzer API for cockpit audio (ambient noise, ATC radio, engine noise, intercom) over 1-2 hours of continuous transcription is untested in the research. Aviation vocabulary post-processing quality will need iteration in Phase 3 with real cockpit audio.
- **FAA TFR feed stability:** The ARCHITECTURE.md notes the FAA TFR XML feed is "brittle — XML format changes." Plan for a parsing layer that can be updated independently of app releases, or monitor for changes.
- **Chart CDN operational timeline:** The GeoTIFF → MBTiles → Cloudflare R2 pipeline is server-side infrastructure that must be operational before Phase 1 can be completed. This is a build-time dependency that could block Phase 1 if not started early.

## Sources

### Primary (HIGH confidence)
- MapLibre Native iOS GitHub — v6.24.0 confirmed March 11, 2026
- MapLibre SwiftUI DSL GitHub — v0.21.1, January 20, 2026
- GRDB.swift Releases GitHub — v7.10.0, February 15, 2026; Swift 6.1+ requirement confirmed
- Apple Developer Documentation: LanguageModelSession, CLLocationUpdate, AVAudioSession WWDC25
- TN3193 — Managing the on-device foundation model's context window (4,096 token limit confirmed)
- Swift.org — Swift 6.2 release announcement
- NOAA Aviation Weather API — OpenAPI spec, 100 req/min confirmed
- FAA — 56-Day Visual Chart Cycle PDF (update schedule confirmed)
- Existing Xcode project (`efb-212.xcodeproj/project.pbxproj`) — SPM dependencies and iOS 26.0 deployment target confirmed

### Secondary (MEDIUM confidence)
- createwithswift.com — Foundation Models `@Generable`, `@Guide`, `LanguageModelSession` patterns
- artemnovichkov.com — Foundation Models device requirements and availability states
- avanderlee.com — Swift 6.2 Approachable Concurrency patterns
- fatbobman.com — SwiftData vs. GRDB performance trade-offs; SwiftData migration caveats
- azamsharp.com — Foundation Models `@Observable` integration patterns; SwiftData architecture
- ipadpilotnews.com — EFB competitor feature comparison; GPS altitude vs. pressure altitude
- NatashaTheRobot — Foundation Models 4,096 token context confirmation
- Apple Developer Forums — `@Observable` + `@MainActor` interaction; AVAudioSession interruption handling

### Tertiary (MEDIUM-LOW confidence)
- WWDC 2025 SpeechAnalyzer guide (dev.to) — volatile vs. final behavior; long-form audio patterns
- Prototype post-mortem (OpenEFB Feb 2026) — AppState god object, annotation perf cliff, `@unchecked Sendable`, Swift literal seed data (first-hand, HIGH confidence for those specific patterns)

---
*Research completed: 2026-03-20*
*Ready for roadmap: yes*
