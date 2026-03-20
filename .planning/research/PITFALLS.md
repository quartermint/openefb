# Pitfalls Research

**Domain:** iPad VFR EFB — moving-map navigation, flight recording, on-device AI debrief
**Researched:** 2026-03-20
**Confidence:** HIGH (multiple verified sources across all categories)

---

## Critical Pitfalls

### Pitfall 1: AppState God Object — Observable Edition

**What goes wrong:**
The project already hit this in the prototype with `ObservableObject`. The same trap exists with `@Observable`. A single root coordinator accumulates nested state, computed properties, subscriptions, and side-effects until no single change can be made safely. With `@Observable`, the problem is compounded: the macro observes only properties that are read during SwiftUI body evaluation, so adding new state to a monolith can silently break observation granularity and cause missed or over-triggered redraws.

**Why it happens:**
It's the path of least resistance. AppState starts as a legitimate coordinator, then gets the "one more thing" treatment 20 times in a row because it's already imported everywhere.

**How to avoid:**
Domain-split from day one: `NavigationState`, `MapState`, `RecordingState`, `FlightPlanState`, `WeatherState` as separate `@Observable` classes. AppState holds references to domain states but no domain logic itself. Each domain state is owned by the view subtree that needs it, injected via environment when sharing is required. Never add a property to AppState because it's "convenient."

**Warning signs:**
- AppState file exceeds 200 lines
- Any ViewModel imports AppState directly rather than one domain state
- A "simple" feature requires modifying AppState

**Phase to address:** Phase 1 foundation (day one of fresh start)

---

### Pitfall 2: MapLibre SwiftUI State Loop

**What goes wrong:**
Wrapping `MLNMapView` in `UIViewRepresentable` creates a structural mismatch: the SwiftUI view struct is a value type recreated on every state change, but UIKit views are reference types with persistent identity. Returning `Coordinator(self)` passes a stale copy of the struct. Map delegate callbacks that update SwiftUI state synchronously trigger "Modifying state during view update" crashes. Dragging the map fires camera updates that update SwiftUI state that triggers `updateUIView` that fires camera updates — infinite loop.

**Why it happens:**
UIViewRepresentable tutorials omit the coordinator ownership nuance. SwiftUI's `@Observable` propagation makes state-update loops more likely than with `ObservableObject` because observation is more granular and eager.

**How to avoid:**
Use `maplibre/swiftui-dsl` (the official MapLibre SwiftUI DSL) rather than rolling a custom `UIViewRepresentable`. If custom wrapping is required: store map state in an `@Observable` class (not a struct), have the Coordinator hold a strong reference to that class (not to `self`), and dispatch all delegate-to-SwiftUI updates with `Task { @MainActor in ... }` to break synchronous update cycles.

**Warning signs:**
- Coordinator stores `var parent: MapLibreSwiftUIView` (struct copy)
- Map camera updates trigger view body re-evaluation in an Xcode profiler flame graph
- Console shows "Modifying state during view update" warnings

**Phase to address:** Phase 1 (map foundation) — get the SwiftUI bridge right before adding any layers

---

### Pitfall 3: GeoJSON Source vs. Annotation Perf Cliff

**What goes wrong:**
The prototype already hit this. Adding 20,000+ airports as individual `MLNPointAnnotation` objects brings the map to its knees. Each annotation is a separate UIView, hitched through UIKit's responder chain. The performance cliff is around 500-1,000 annotations; at 20K the UI locks.

**Why it happens:**
Annotations are the "obvious" API for putting points on a map. The GeoJSON source + symbol layer approach requires understanding the style layer system, which is less intuitive.

**How to avoid:**
All airport/navaid/PIREP points go through `MLNShapeSource` with `MLNSymbolStyleLayer`. This keeps rendering on the GPU, supports clustering via `MLNShapeSourceOption.clustered`, and scales to millions of features. Never use `MLNPointAnnotation` for data-driven features; reserve it only for user-placed single waypoints.

**Warning signs:**
- Any call to `mapView.addAnnotation()` or `mapView.addAnnotations()` for database-sourced points
- Frame rate drops when zooming over populated areas
- Profiler shows UIKit layout on main thread proportional to airport density

**Phase to address:** Phase 1 (airport rendering) — use GeoJSON from the first airport dot drawn

---

### Pitfall 4: Apple Foundation Models — 4K Token Context Cliff

**What goes wrong:**
The combined input + output token limit for Apple Foundation Models is 4,096 tokens (~3,000 words). A typical 1-hour flight transcript is 5,000-15,000 words. Passing the full transcript directly to `LanguageModelSession` will either truncate silently, fail with a context overflow error, or produce a debrief that covers only the first 15 minutes of the flight.

**Why it happens:**
The 4K limit is not prominently surfaced. Developers prototype with short test transcripts, hit no issues, then discover the constraint only when testing real 45-minute flight recordings.

**How to avoid:**
Design a chunking + summarization pipeline before writing any debrief code. Strategy: segment transcript by detected flight phase (preflight/taxi/takeoff/cruise/approach/landing), summarize each segment independently, then synthesize a final debrief from phase summaries. Use `@Generable` with `@Guide` constraints to get structured output per phase, not one giant prompt. Pre-warm with `session.prewarm()` at flight end, not on-demand.

**Warning signs:**
- Debrief prompt constructed as `"Analyze this flight: \(fullTranscript)"`
- No chunking code in the debrief pipeline
- Context window management not tested with >20 minute real flights

**Phase to address:** Phase 2 (AI debrief design) — establish chunking architecture in the debrief spec before implementation

---

### Pitfall 5: Foundation Models Device Availability — Silently Non-Functional

**What goes wrong:**
Apple Foundation Models require Apple Intelligence, which requires: iPhone 15 Pro/Pro Max or iPhone 16+, iPad Air M1+ or iPad Pro M1+, iOS/iPadOS 26+, Apple Intelligence enabled in Settings, and ~7GB free storage. An iPad mini (non-A17 Pro), an older iPad Pro (pre-M1), or a device with Apple Intelligence disabled will have `SystemLanguageModel.default.availability` return `.notAvailable`. If the app doesn't check availability, the debrief feature either crashes or silently produces nothing.

**Why it happens:**
Development happens on a supported device (iPad Pro M4). The constraint is invisible until testing on diverse hardware.

**How to avoid:**
Gate the entire AI debrief feature on `SystemLanguageModel.default.availability == .available`. Show a clear UI state for unsupported devices ("AI debrief requires an iPad with Apple Intelligence"). Design the logbook and track replay features to function fully without AI — the debrief is an enhancement, not a requirement for the core product.

**Warning signs:**
- No availability check in the debrief ViewModel
- UI shows "Generating debrief..." with a spinner indefinitely on unsupported devices
- No test path that simulates unavailable Foundation Models

**Phase to address:** Phase 2 (AI debrief) — availability check is the first line of code written

---

### Pitfall 6: Background Location + Audio Session Conflict During Recording

**What goes wrong:**
Recording GPS track + cockpit audio simultaneously requires two background entitlements: `background-modes: location` and `background-modes: audio`. If the audio session is not configured correctly (`AVAudioSessionCategoryPlayAndRecord` with `.allowBluetooth` and `.defaultToSpeaker` options), iOS may suspend the app or terminate background audio after a phone call interruption, Siri activation, or system notification. After an interruption, the audio session must be explicitly reactivated — the system will not restart it automatically when the app is backgrounded.

**Why it happens:**
Testing in the foreground shows no issues. Background behavior after interruption is only discovered through real-device field testing (plugging in headphones, receiving a call mid-flight).

**How to avoid:**
Observe `AVAudioSessionInterruptionNotification`. On `.ended` interruption with `.shouldResume` option, re-activate the session and re-start the recording engine. Never deactivate the session while recording. Test the full interruption lifecycle explicitly: receive phone call, hang up, verify recording resumed. Configure session category before any recording starts, not lazily.

**Warning signs:**
- No interruption notification observer in the audio engine
- Audio session setup happens on first record tap rather than app launch
- No field test on real device with a simulated phone call during recording

**Phase to address:** Phase 2 (recording engine) — interruption handling is a spec requirement, not a polish item

---

### Pitfall 7: Chart Tile Update Cycle Blind Spot

**What goes wrong:**
FAA VFR sectional charts update every 56 days. A pilot using an EFB with expired charts for navigation is a safety hazard and a potential App Store rejection vector. If the chart tile pipeline runs once and tiles are served without expiration metadata, the app has no way to warn users when charts are outdated. This is especially dangerous because charts don't look wrong — TFRs, airspace changes, and obstacle updates are silent.

**Why it happens:**
Chart expiration is an operational concern that developers don't think about during the infrastructure phase. It's only raised when a chart cycle rolls over in production.

**How to avoid:**
Embed chart cycle metadata (effective date, expiration date, cycle number) in the tile server response headers or a companion JSON file. The app should check chart currency on launch and show a prominent warning badge when charts are within 7 days of expiration. The 56-day cycle is fixed (see: FAA 56-Day Visual Chart Cycle PDF). Build the server-side pipeline to process new cycles automatically before the expiration date.

**Warning signs:**
- No chart metadata endpoint in the tile server design
- No expiration UI component in the chart layer architecture
- Chart tile pipeline is a one-time manual process rather than scheduled automation

**Phase to address:** Phase 1 (chart infrastructure) — expiration metadata must be part of the initial CDN design

---

### Pitfall 8: GPS Altitude Confusion — Geometric vs. Pressure

**What goes wrong:**
CoreLocation provides geometric altitude (GPS altitude), not pressure altitude (what pilots read on their altimeter). Geometric altitude can be 50-100+ feet off from indicated altitude, especially in high-temperature or non-standard atmospheric conditions. If the instrument strip displays `location.altitude` with "ft MSL" without qualification, pilots will compare it to their panel altimeter and distrust the app. The gap increases with temperature extremes.

**Why it happens:**
GPS altitude looks like "altitude" and CoreLocation makes it easy to access. The barometric vs. geometric distinction is an aviation-specific concern invisible to developers without flying background.

**How to avoid:**
Always label GPS altitude as "GPS ALT" not "ALT" in the instrument strip. Add a small info badge explaining the source on tap. Never display GPS altitude as if it's equivalent to indicated altitude. iPad models with a barometric sensor (Air 2+, mini 4+, all Pros) can provide barometric altitude via `CMAltimeter` as a supplementary source — but this still requires calibration and is not certified for navigation. The instrument strip should make the data source explicit.

**Warning signs:**
- Instrument strip shows "ALT: 3,450 ft MSL" without GPS qualifier
- No in-app explanation of why GPS altitude differs from panel altimeter
- CMAltimeter data displayed without distinguishing it from GPS altitude

**Phase to address:** Phase 1 (instrument strip) — data source labeling is a requirement, not optional

---

### Pitfall 9: SpeechAnalyzer Volatile vs. Final Results Confusion

**What goes wrong:**
iOS 26 SpeechAnalyzer (the replacement for `SFSpeechRecognizer`) distinguishes between "volatile" (in-progress) and "final" transcription results. Storing volatile results as if they were final produces a transcript with duplicate, overlapping, and partially-recognized segments. A 1-hour flight transcript stored this way is unusable for AI debrief because the segment boundaries are corrupted.

**Why it happens:**
The older `SFSpeechRecognizer` API was simpler. The volatile/final distinction in SpeechAnalyzer is new and the consequences of ignoring it aren't immediate — the transcript looks reasonable during short tests.

**How to avoid:**
Only commit transcript segments to the GRDB/SwiftData store when `result.isFinal == true`. Maintain a separate in-memory buffer for volatile segments to display in the live transcription UI. Design the recording data model with explicit `isFinal` tracking from the start, not retrofitted later.

**Warning signs:**
- Transcript segments stored without a `isFinal` flag
- Live transcript UI and stored transcript built from the same data source
- No test for a 30+ minute transcription session checking segment count and coverage

**Phase to address:** Phase 2 (recording + transcription) — data model design must account for volatile/final before any storage code is written

---

### Pitfall 10: SwiftData iOS 26 — Missing VersionedSchema on First Ship

**What goes wrong:**
SwiftData requires every schema to be versioned (using `VersionedSchema`) if you ever intend to migrate. Shipping an unversioned schema and then versioning it later requires a two-release migration dance: first release wraps the existing model into V1 (no structural changes, just versioning), second release introduces V2 with actual changes. Skipping versioned schema on the initial ship means the first user-facing schema change will require this two-step process, delaying the change by a full release cycle.

**Why it happens:**
Versioned schema adds ceremony and tutorials omit it for brevity. The impact is invisible until the first schema change hits.

**How to avoid:**
Start with `VersionedSchema` and `SchemaMigrationPlan` on day one, even if V1 has no migrations. Ship V1 with a versioned schema. All future schema changes are then straightforward V2, V3 migrations. This is especially important for SwiftData models that store user flight data — corrupting a pilot's logbook is a trust-destroying failure.

**Warning signs:**
- `@Model` classes defined without a containing `VersionedSchema` enum
- No `SchemaMigrationPlan` type in the SwiftData layer
- Schema migration documentation absent from the data model file

**Phase to address:** Phase 1 (data model) — versioned schema on day one, no exceptions

---

### Pitfall 11: Privacy Manifest Incompleteness Causes TestFlight Rejection

**What goes wrong:**
Apple rejected 12% of App Store submissions in Q1 2025 for Privacy Manifest violations. For TestFlight external beta (public distribution), Apple reviews the first build before releasing it to testers. An EFB app using location, microphone, and speech recognition is high-surface-area. Missing or incorrect entries in `PrivacyInfo.xcprivacy` for required reason APIs will block TestFlight distribution.

**Why it happens:**
Privacy manifests are checked at submission time, not compile time. Developers miss entries for indirect API usage (through third-party SDKs like MapLibre).

**How to avoid:**
Audit every privacy-sensitive API used: `CLLocationManager` (location), `AVAudioSession` (microphone), `SFSpeechRecognizer`/`SpeechAnalyzer` (speech), `CMAltimeter` (motion), file access patterns. MapLibre Native has its own privacy manifest that should aggregate automatically — verify it does. Add all required NSUsageDescription keys with specific, accurate descriptions. Test privacy manifest completeness with Xcode's privacy report tool before the first TestFlight submission.

**Warning signs:**
- `PrivacyInfo.xcprivacy` has fewer than 5 entries for an app using location + audio + speech
- MapLibre dependency's privacy manifest not verified
- First TestFlight submission attempted without a privacy manifest review pass

**Phase to address:** Phase 1 (project setup) and before any TestFlight submission

---

### Pitfall 12: NOAA API Rate Limit Under Multi-User Load

**What goes wrong:**
The NOAA Aviation Weather API rate-limits at 100 requests/minute. A single user with 20 airports visible on screen requesting METAR for each airport on map pan is already 20+ requests/pan. At modest TestFlight scale (100 simultaneous testers actively flying), naive implementations saturate this limit causing HTTP 429 responses that manifest as blank weather dots on the map.

**Why it happens:**
Solo development testing never exceeds 5-10 requests/minute. The rate limit is invisible until concurrent users arrive.

**How to avoid:**
Implement a bounded batch request strategy: request weather for all visible airports in a single bulk call (NOAA API supports `stationString` with comma-separated station IDs). Cache METARs for 15 minutes minimum — METAR update frequency doesn't justify shorter TTL. Implement exponential backoff with jitter on 429 responses. For TestFlight, monitor request volume from day one.

**Warning signs:**
- One NOAA request per airport per map update cycle
- Cache TTL under 10 minutes
- No 429 error handling in the weather service

**Phase to address:** Phase 1 (weather service) — bulk request pattern from the start

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Seed airport data as Swift literals | Simple, no build step | Binary bloat, compile time +60s, no update path | Never — use bundled SQLite |
| `@unchecked Sendable` on model types | Silences Swift 6 concurrency errors instantly | Bypasses all race condition detection, real crashes in production | Never in new code — fix the actual isolation |
| Unversioned SwiftData schema | Less ceremony at project start | Requires two-release migration dance for first schema change | Never — always ship VersionedSchema V1 |
| Single shared `LanguageModelSession` | Simpler session management | Only one concurrent request permitted; second caller blocks indefinitely | Never — use per-task sessions or a queue |
| `location.altitude` labeled as "ALT" | Looks correct | Pilot distrust when value differs from panel altimeter | Never — always qualify GPS altitude source |
| Storing SpeechAnalyzer volatile results | Live transcript feel | Corrupted transcript with duplicates and overlaps | Never in persisted storage — volatile is display-only |
| MapLibre annotation API for airports | Works for <100 airports | Performance cliff at ~500, unusable at 20K | Acceptable for single user-placed waypoints only |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| MapLibre SwiftUI | `UIViewRepresentable` with `Coordinator(self)` | Use `swiftui-dsl` or store Coordinator reference to `@Observable` class, never struct |
| MapLibre SwiftUI | Synchronous state update from map delegate | `Task { @MainActor in ... }` wrapper on all delegate-to-SwiftUI updates |
| NOAA Aviation Weather | One request per station per map update | Bulk `stationString` request, 15-min METAR cache, exponential backoff on 429 |
| Apple Foundation Models | Pass full transcript as single prompt | Chunk by flight phase, summarize each phase, synthesize final debrief |
| Apple Foundation Models | Assume model is always available | Check `SystemLanguageModel.default.availability` and provide graceful degradation |
| SpeechAnalyzer | Store all transcription results to DB | Only persist `isFinal == true` segments; keep volatile in memory for UI only |
| AVAudioSession | Start session lazily on first record tap | Configure session at app launch; handle `AVAudioSessionInterruptionNotification` |
| SwiftData | Define `@Model` classes without VersionedSchema | Wrap in `VersionedSchema` V1 from day one |
| FAA Chart CDN | One-time tile generation | Automate 56-day pipeline, embed cycle metadata in responses |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| `MLNPointAnnotation` for 20K airports | Map freezes during zoom/pan, UIKit layout takes 80%+ of frame time | GeoJSON `MLNShapeSource` + `MLNSymbolStyleLayer` from day one | ~500 annotations visible simultaneously |
| `@Observable` class used as actor | Compiler errors from MainActor/actor isolation conflicts, or `@unchecked Sendable` proliferation | ViewModels are `@MainActor` `@Observable` classes; services are actors; never combine | First actor isolation conflict in a SwiftUI view |
| Full transcript in Foundation Models prompt | Context overflow error, debrief covers only flight start | Phase-chunking summarization pipeline | Transcripts over ~2,500 words (~20 minutes at normal speech rate) |
| Weather dots for all 20K airports | Request storm on pan, 429 errors, battery drain | Only fetch weather for airports within visible map bounds + 20% buffer | More than ~80 airports in viewport |
| Audio + GPS + map rendering simultaneously | Battery dies in 2 hours, device overheats | Background audio uses minimal quality profile in-flight; map rendering reduces tile preload range | During climb-out on a hot day |
| SwiftData `@Model` fetch without `FetchDescriptor` limits | Memory spike reading all flight records | Always use `FetchDescriptor` with `fetchLimit`; paginate logbook list | After 50+ recorded flights |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Storing pilot certificate number / medical class in SwiftData without encryption | PII exposure if device stolen | Use SwiftData with Data Protection `.complete` file attribute; never log these fields |
| Logging flight audio data paths in crash reports | Audio file paths leak to third-party crash SDKs | Sanitize file paths in error reporting; never include transcript content in logs |
| Serving chart tiles from public R2 bucket with wildcard CORS | Tile scraping by competitors | Use signed URLs or Cloudflare Worker with origin validation for tile requests |
| Background location running without user consent re-prompt after update | App Store rejection, user distrust | Re-request authorization if it downgrades from `.authorizedAlways` to `.authorizedWhenInUse` on update |
| Open-source codebase with API keys or CDN credentials in history | Key rotation required, potential abuse | Require credentials via environment/config from day one; audit git history before making repo public |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| No clear indication of GPS altitude vs. panel altimeter | Pilot confusion, distrust of app | Label "GPS ALT" explicitly; info badge explains geometric vs. pressure altitude |
| Debrief starts generating immediately after landing | Pilot may still be taxiing, distracted | Offer "Generate Debrief" as an explicit tap after engine shutdown, with a delay suggestion |
| Recording stops silently after phone call interruption | Pilot reviews flight, recording is 20 minutes instead of 1.5 hours | Show persistent recording banner; alert if recording unexpectedly pauses |
| Expired charts with no warning | Pilot navigating on outdated airspace data | Prominent expiration banner 7 days before and after chart cycle rollover |
| Weather dots showing for airports that haven't reported in 3+ hours | Stale METAR displayed as current conditions | Weather dot age badge; grey out dots older than 2 hours |
| Nearest airport list in emergency with unlighted runways at night | Pilot diverts to airport with no runway lighting | Surface material + lighting type in nearest airport result |

---

## "Looks Done But Isn't" Checklist

- [ ] **GPS Tracking:** Works in simulator? Verify on real device in flight — simulator accuracy does not reflect real-world GPS acquisition delay.
- [ ] **Background Recording:** Tested after phone call interruption and resume? Check that audio AND GPS both resume automatically.
- [ ] **Chart Currency:** Tiles served with expiration metadata? App shows warning when charts are within 7 days of rollover?
- [ ] **AI Debrief:** Tested with 45+ minute real flight transcript (not synthetic test data)? Context chunking verified?
- [ ] **Foundation Models Availability:** Tested on an iPad that does NOT support Apple Intelligence? Graceful fallback shown?
- [ ] **Weather Service:** Tested when NOAA API returns 429? Cached stale data shown with age badge?
- [ ] **SwiftData Migration:** Schema wrapped in VersionedSchema V1? First migration plan written even if V1→V1?
- [ ] **Privacy Manifest:** Xcode privacy report clean? All NSUsageDescription keys present with specific descriptions?
- [ ] **TestFlight External Beta:** First build submitted for external review (24-48hr delay)? Not same day as feature complete?
- [ ] **Altitude Display:** Instrument strip labeled "GPS ALT" not "ALT MSL"? Tap reveals data source explanation?
- [ ] **Transcript Storage:** Only `isFinal == true` segments written to GRDB? Verified no duplicates in 30-min test?
- [ ] **Airport Rendering:** 20K airport dataset tested at every zoom level? GeoJSON source, not annotations?

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| AppState god object after 3 phases built on it | HIGH | Extract domain states one at a time into separate `@Observable` classes; update injection site by site; accept a 1-2 week refactor sprint |
| Annotation-based map at 20K airports | MEDIUM | Replace annotation add/remove with GeoJSON source in MapService; map features carry same data, just different render path |
| Unversioned SwiftData schema after TestFlight users | HIGH | Release: wrap current model in VersionedSchema V1 (no changes). Wait for 90% update adoption. Release: V2 with actual change. Cannot skip this two-step. |
| Corrupt transcripts from volatile result storage | MEDIUM | Re-process raw audio files with a corrected SpeechAnalyzer pipeline; users re-generate debrief from stored audio |
| Charts served without expiration metadata | MEDIUM | Add metadata endpoint to CDN pipeline; client version check on next update; existing users get corrected metadata on next app update |
| Privacy manifest rejected by Apple | LOW | Fix manifest entries, resubmit — 24-48hr re-review turnaround |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| AppState god object | Phase 1 foundation | AppState.swift < 100 lines; domain state classes exist and are injected |
| MapLibre SwiftUI state loop | Phase 1 map foundation | No "Modifying state during view update" in console; smooth pan at 60fps |
| GeoJSON vs. annotations | Phase 1 airport rendering | 20K airports visible at 60fps on iPad Air M1; Instruments shows no UIKit layout on main thread |
| Foundation Models 4K token cliff | Phase 2 AI debrief design | 45-min flight transcript chunked into phases; each phase summary under 800 tokens |
| Foundation Models device availability | Phase 2 AI debrief | Graceful degradation UI tested on unsupported device simulator |
| Background recording interruption | Phase 2 recording engine | Recording tested through simulated phone call, Siri activation, headphone disconnect |
| Chart tile 56-day cycle | Phase 1 chart infrastructure | CDN response includes `chart-expires` header; app shows expiration warning 7 days prior |
| GPS altitude labeling | Phase 1 instrument strip | Instrument strip shows "GPS ALT" with info badge; usability tested with a pilot |
| SpeechAnalyzer volatile/final | Phase 2 transcription storage | 30-min session: zero duplicate segments in DB; `isFinal` coverage verified |
| SwiftData unversioned schema | Phase 1 data model | `VersionedSchema` V1 enum present before any @Model class ships |
| Privacy manifest | Phase 1 setup + pre-TestFlight | Xcode privacy report shows no violations; submitted build passes Apple review |
| NOAA rate limiting | Phase 1 weather service | Simulate 100-request/min load; verify graceful 429 handling with stale cache fallback |

---

## Sources

- Apple Developer Documentation: [TN3193 — Managing the on-device foundation model's context window](https://developer.apple.com/documentation/technotes/tn3193-managing-the-on-device-foundation-model-s-context-window)
- [NatashaTheRobot — Introduction to Apple Foundation Models: Limitations, Capabilities](https://www.natashatherobot.com/p/apple-foundation-models) — context window 4,096 combined tokens confirmed
- [AzamSharp — The Ultimate Guide to Foundation Models Framework](https://azamsharp.com/2025/06/18/the-ultimate-guide-to-the-foundation-models-framework.html) — `@Generable` all-properties cost
- [Apple Newsroom — Foundation Models Framework](https://www.apple.com/newsroom/2025/09/apples-foundation-models-framework-unlocks-new-intelligent-app-experiences/) — device availability requirements
- [WWDC 2025 SpeechAnalyzer guide](https://dev.to/arshtechpro/wwdc-2025-the-next-evolution-of-speech-to-text-using-speechanalyzer-6lo) — volatile vs. final, long-form audio
- [Apple Developer Forums — Observation and MainActor](https://developer.apple.com/forums/thread/731822) — `@Observable` + `@MainActor` interaction
- [Jared Sinclair — We Need to Talk About Observation](https://jaredsinclair.com/2025/09/10/observation.html) — `@Observable` struct reinit pitfalls
- [Apple Developer Forums — State loops in UIViewRepresentable](https://developer.apple.com/forums/thread/672430) — coordinator ownership problem
- [Apple Developer Forums — AVAudioSession interruption after background transition](https://developer.apple.com/forums/thread/760896) — error 561145187 cannotStartRecording
- [WWDC SwiftData iOS 26 migration issues](https://dev.to/arshtechpro/wwdc-2025-swiftdata-ios-26-class-inheritance-migration-issues-30bh) — VersionedSchema requirement
- [fatbobman — Key Considerations Before Using SwiftData](https://fatbobman.com/en/posts/key-considerations-before-using-swiftdata/) — performance and migration
- [iPad Pilot News — GPS altitude vs. pressure altitude](https://ipadpilotnews.com/2024/08/understanding-pressure-altitude-and-gps-altitude-in-aviation-apps-pilot/) — 10-20m vertical error
- [NOAA Aviation Weather API documentation](https://aviationweather.gov/data/api/) — 100 req/min rate limit
- [FAA — 56-Day Visual Chart Cycle](https://www.faa.gov/air_traffic/flight_info/aeronav/acf/media/Briefings/56-Day_Visual_Chart_Cycle.pdf) — chart update schedule
- [aviationCharts GitHub — MBTiles pipeline](https://github.com/jlmcgraw/aviationCharts) — GeoTIFF to MBTiles conversion patterns
- Prototype post-mortem (OpenEFB Feb 2026): AppState god object, annotation perf cliff, `@unchecked Sendable`, Swift literal seed data — confirmed first-hand

---
*Pitfalls research for: iPad VFR EFB — MapLibre moving map, flight recording, Apple Foundation Models AI debrief*
*Researched: 2026-03-20*
