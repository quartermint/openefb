# Stack Research

**Domain:** iPad VFR Electronic Flight Bag — moving map, flight recording, on-device AI debrief, offline-first
**Researched:** 2026-03-20
**Confidence:** HIGH (all critical choices verified against official docs or confirmed package releases)

---

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| **Swift 6.2** | 6.2 | Language | Ships with Xcode 26. "Approachable Concurrency" (main-actor-by-default for app targets) eliminates most annotation boilerplate while enforcing data-race safety. Required for Foundation Models and modern async APIs. Use Swift 6.2 language mode, not 5.0 compatibility mode. |
| **SwiftUI + @Observable** | iOS 26 | UI framework + state | iOS 26 is the minimum target; `@Observable` (Observation framework, not Combine/ObservableObject) is the correct default. No `@Published`, no `sink()`, no `AnyCancellable`. ViewModels become plain `@Observable` classes. `Observations` struct (new in iOS 26) handles reactive subscriptions where needed. |
| **MapLibre Native iOS** | 6.24.0 | Map rendering engine | Only open-source iOS map SDK supporting raster tile overlays — required for VFR sectional charts. Maintained actively (6.24.0 released March 11, 2026). Binary distributed via SPM from `maplibre/maplibre-gl-native-distribution`. Use GeoJSON sources (not individual annotations) for airport/navaid clusters to handle 20K+ points without performance degradation. |
| **MapLibre SwiftUI DSL** | 0.21.1 | SwiftUI map integration | Official MapLibre package for declarative SwiftUI integration. Wraps `MLNMapView` in SwiftUI-friendly DSL. Latest: v0.21.1 (January 20, 2026). Pre-1.0 but production-ready — API may change but project is well-maintained by Stadia Maps team now under MapLibre umbrella. |
| **GRDB.swift** | 7.10.0 | Aviation SQLite database | Best-in-class SQLite toolkit for Swift 6. Supports R-tree spatial indexes (required for nearest-airport queries across 20K airports), FTS5 full-text search (airport name/identifier search), WAL mode, and Swift 6 Sendable conformances. SwiftData cannot use R-tree or custom indexes — wrong tool for aviation data. Minimum: `upToNextMajorVersion` from 7.0.0. |
| **SwiftData** | iOS 26 | User data persistence | CloudKit-ready ORM for user-generated data: pilot profiles, aircraft profiles, flight records, logbook entries. Correct tool when: data is relational to the user, volumes are small (hundreds not thousands), and CloudKit sync is on the roadmap. Not a replacement for GRDB — these are complementary. |
| **Core Location (CLLocationUpdate)** | iOS 17+ API, iOS 26 target | GPS tracking | `CLLocationUpdate.liveUpdates()` returns `AsyncSequence` — integrates cleanly with Swift 6 structured concurrency. Use `.airborne` configuration for in-flight GPS. `CLBackgroundActivitySession` enables background location. No delegate pattern required. |
| **AVFoundation (AVAudioRecorder / AVAudioEngine)** | iOS 26 | Cockpit audio recording | `AVAudioSession` category `.record` or `.playAndRecord`. iOS 26 adds `bluetoothHighQualityRecording` option for high-quality Bluetooth input. Use `AVAudioEngine` for tap-based recording with real-time buffer access needed for speech-to-text. Configure for 6+ hour sessions with low-bitrate AAC. |
| **Speech Framework** | iOS 26 | Real-time transcription | `SFSpeechRecognizer` with `SFSpeechAudioBufferRecognitionRequest` for streaming cockpit audio to on-device speech model. No network required when `requiresOnDeviceRecognition = true`. Post-process with aviation vocabulary replacements (GRDB, GRDB → phonetic alphabet, etc.) |
| **Apple Foundation Models** | iOS 26 | On-device AI debrief | `LanguageModelSession` + `@Generable` + `@Guide` macros. Structured output for typed debrief schema (narrative, phase observations, improvements, rating). `session.streamResponse(to:)` for streaming UI. `session.prewarm()` for responsive post-flight UX. Requires Apple Intelligence-capable device with Apple Intelligence enabled. Text-only. Single concurrent session per process. Check `SystemLanguageModel.default.availability` before use and degrade gracefully. |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| **MapLibreSwiftUI (swiftui-dsl)** | 0.21.1 | Declarative MapLibre SwiftUI wrapper | Always — bridges `MLNMapView` to SwiftUI without `UIViewRepresentable` boilerplate. Source: `maplibre/swiftui-dsl` |
| **Network.framework (NWPathMonitor)** | iOS 12+ built-in | Reachability monitoring | Always — detect cellular vs WiFi vs offline. Drives graceful degradation of weather/TFR fetches. No third-party dependency needed. |
| **Combine (limited use)** | iOS 13+ built-in | Timer publishers, NotificationCenter bridges | Only where `AsyncSequence` is insufficient — e.g., `Timer.publish` for weather refresh intervals. Do NOT use for state management (use `@Observable`). |
| **OSLog** | iOS 14+ built-in | Structured logging | Always for service-layer logging. Use subsystem + category per service. Provides crash-time log access via Console.app. No third-party logging needed. |

### External APIs

| API | Authentication | Rate Limits | Purpose |
|-----|---------------|-------------|---------|
| **NOAA Aviation Weather API** | None (free) | 100 req/min | METAR, TAF, PIREPs. Base URL: `https://aviationweather.gov/api/data/`. Updated 2025 with OpenAPI schema. Use `?ids=KXXX&format=json`. |
| **FAA TFR Feed** | None (free) | Scrape-rate friendly | TFR GeoJSON/XML from `https://tfr.faa.gov/tfr3/`. Poll every 5 min in-flight, 15 min on ground. |
| **Cloudflare R2** | Worker + R2 bucket | Egress-free CDN | Host pre-processed MBTiles for VFR sectional charts. Requires server-side pipeline (GDAL GeoTIFF → MBTiles). Consider PMTiles format over MBTiles for CDN efficiency (see below). |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| **Xcode 26** | Primary IDE | Required for Swift 6.2 and Foundation Models SDK. Main-actor-by-default project setting enabled by default for new app targets. |
| **Swift Testing** | Unit/integration tests | Preferred over XCTest for new tests. `@Test`, `#expect`, `@Suite` — less boilerplate than XCTest. Use XCTest only where Swift Testing support is missing (UI tests still use XCTestCase). |
| **Instruments (Core Location / Time Profiler)** | GPS + CPU profiling | Critical for validating battery impact of background location + audio recording combo during 2+ hour flights. |
| **GDAL CLI** | Chart tile pipeline | Server-side: `gdal2tiles.py` converts FAA GeoTIFF sectional charts to slippy-map tiles, then `mb-util` packages to MBTiles. Runs in a Cloudflare Worker or CI pipeline, not on-device. |

---

## Installation

```bash
# In Xcode → File → Add Package Dependencies
# Or add to Package.swift if building as SPM package

# MapLibre Native iOS (binary distribution)
# URL: https://github.com/maplibre/maplibre-gl-native-distribution
# Version: upToNextMajorVersion from 6.0.0

# MapLibre SwiftUI DSL
# URL: https://github.com/maplibre/swiftui-dsl
# Version: upToNextMajorVersion from 0.21.1

# GRDB.swift
# URL: https://github.com/groue/GRDB.swift
# Version: upToNextMajorVersion from 7.0.0

# All other dependencies (Core Location, AVFoundation, Speech, Foundation Models,
# SwiftData, Network.framework, Combine, OSLog) are system frameworks — no SPM needed.
```

---

## Alternatives Considered

| Recommended | Alternative | Why Not Alternative |
|-------------|-------------|---------------------|
| **@Observable** | `ObservableObject` + `@Published` + Combine | iOS 26 target makes ObservableObject the wrong choice. Generates unnecessary Combine subscriptions, requires `AnyCancellable` storage, cannot benefit from compiler's observation tracking. The existing prototype used this and is being rebuilt precisely because of it. |
| **GRDB 7 for aviation data** | SwiftData for all data | SwiftData cannot use R-tree spatial indexes or FTS5 — both are required for `SELECT nearest_airport WHERE distance < X` across 20K records. SwiftData is correct for user-owned data (profiles, flights). |
| **CLLocationUpdate AsyncSequence** | `CLLocationManager` delegate | Delegate pattern requires `@unchecked Sendable` workarounds in Swift 6 strict concurrency. `CLLocationUpdate.liveUpdates()` is the Swift 6-native API. |
| **AVAudioEngine** | `AVAudioRecorder` (simple) | `AVAudioEngine` provides tap-based real-time buffer access needed to pipe audio to `SFSpeechRecognizer` while simultaneously writing to file. `AVAudioRecorder` only writes to file — can't do both. |
| **Foundation Models** | Claude API (cloud) | Project constraint: zero cloud dependency for v1. Foundation Models is on-device, no account, no API key, no privacy risk. Degrade gracefully on non-Apple-Intelligence devices; cloud debrief is a future paid tier. |
| **MapLibre Native iOS** | Apple MapKit | MapKit does not support raster tile overlays in the format required for VFR sectional charts (MBTiles/slippy-map). MapLibre is the only production-ready option for this use case. |
| **MapLibre Native iOS** | Mapbox Maps SDK | Mapbox requires a paid API key and account. MapLibre is the open-source fork — same rendering engine, no account required, compatible with MPL-2.0 license. |
| **SwiftUI (primary)** | UIKit | iOS 26 is a pure SwiftUI project. UIKit is only needed via `UIViewRepresentable` for MapLibre's `MLNMapView` wrapper (handled by swiftui-dsl). |
| **PMTiles (chart CDN)** | MBTiles served via tile server | MBTiles requires a running tile server (operational complexity, cost). PMTiles serves tiles via HTTP range requests directly from R2 — no server, no compute cost, naturally CDN-friendly. |
| **Swift Testing** | XCTest | Swift Testing is the modern Apple testing framework (introduced Xcode 16). Less boilerplate, better diagnostics, native async test support. |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| **ObservableObject / @Published / Combine sink chains** | The existing prototype's fatal flaw. Creates god-object AppState, requires `AnyCancellable` storage, prevents proper actor isolation. Compiler cannot track observation paths. | `@Observable` macro, `Observations` struct (iOS 26), `AsyncSequence` for event streams |
| **`@unchecked Sendable`** | Bypasses Swift 6 data-race checking. The existing codebase has 6+ of these — a warning sign the concurrency model is wrong, not a fix. | Properly isolated actors, `@MainActor` boundaries, `Sendable` value types |
| **Individual MLNPointAnnotation for 20K airports** | The existing prototype's map performance cliff. Annotation objects are heap-allocated per feature — 20K annotations causes lag. | GeoJSON `MLNShapeSource` with `MLNSymbolStyleLayer` for clustering and efficient rendering |
| **SwiftNASR (on-device NASR parsing)** | Adds first-launch complexity: download, parse, index 28-day NASR data on user's device. Slow, error-prone, poor offline-first UX. | Bundle a pre-built SQLite database with the app binary. Update via app update cycle or background refresh — not per-launch. |
| **Airport data baked as Swift literal files** | The existing prototype's binary bloat issue: 3,700 airports as Swift structs = compile-time cost + binary size cost. | SQLite database bundled as a resource file. Zero compile overhead, random access, spatial queries. |
| **Combine for state management** | Reactive state via Combine requires significant boilerplate (`sink`, `store`, `AnyCancellable`), breaks actor isolation, and is superseded by `@Observable` on iOS 17+. | `@Observable` for state, `AsyncSequence` for event streams, `async/await` for one-shot async work |
| **Core Data** | Superseded by SwiftData for user data use cases. No CloudKit sync advantage that SwiftData doesn't also provide. | SwiftData for user data, GRDB for aviation read-only data |
| **Gemini API / OpenAI API / Claude API (v1)** | Violates the zero-cloud-dependency constraint for v1. Privacy risk. Requires account. | Apple Foundation Models. Add cloud debrief tier post-TestFlight as opt-in premium feature. |
| **Mapbox Maps SDK iOS** | Requires paid API key and Mapbox account. License-incompatible with MPL-2.0. | MapLibre Native iOS (open-source fork, identical rendering engine) |

---

## Stack Patterns by Variant

**For services that manage aviation data (airports, airspace, weather):**
- Use `actor` isolation — these are shared mutable state accessed from multiple contexts
- Protocol-first: define `AirportDatabaseProtocol`, `WeatherServiceProtocol`, etc.
- Inject into ViewModels via init, not as global singletons
- Return value types (`struct`) from actor methods — never escape `class` references from actor boundaries

**For ViewModels:**
- `@Observable` class, isolated to `@MainActor`
- Receive updates from actors via `await` calls or `for await` loops in `Task` blocks
- No `AnyCancellable`, no `sink()`, no `@Published`

**For the recording pipeline (GPS + Audio + Transcription simultaneous):**
- Three separate actors: `GPSTracker`, `AudioRecorder`, `TranscriptionEngine`
- Coordinating `RecordingSession` actor manages lifecycle state machine
- Each actor writes independently to its output (GRDB track points, file URL, transcript buffer)
- `@Observable` `RecordingViewModel` on MainActor polls state via `withObservationTracking` or `Observations`

**For chart tile delivery:**
- Server-side pipeline: FAA GeoTIFF → GDAL → MBTiles or PMTiles → Cloudflare R2
- MapLibre reads tiles via custom `MLNTileSourceOptions` pointing to R2 URL pattern
- Downloaded tiles cached on-device in a SQLite file (MapLibre's offline pack API, or manual SQLite)
- PMTiles preferred over MBTiles for CDN: serves from R2 directly via HTTP range requests, no tile server process needed

**For Foundation Models degradation:**
- Always check `SystemLanguageModel.default.availability` before creating a session
- States: `.available`, `.appleIntelligenceNotEnabled`, `.deviceNotEligible`, `.modelNotReady`
- On unavailable: show "AI debrief unavailable on this device" with manual notes field
- On `.modelNotReady`: retry with `session.prewarm()` called proactively at app launch

---

## Version Compatibility

| Package | Minimum | Recommended | Swift Requirement | iOS Requirement |
|---------|---------|-------------|-------------------|-----------------|
| MapLibre Native iOS | 6.0.0 | 6.24.0 | 5.3+ | iOS (no stated minimum beyond Xcode 12 support) |
| MapLibre SwiftUI DSL | 0.21.0 | 0.21.1 | Recent Swift | iOS 14+ |
| GRDB.swift | 7.0.0 | 7.10.0 | Swift 6.1+, Xcode 16.3+ | iOS 13.0+ |
| SwiftData | built-in | iOS 26 SDK | Swift | iOS 17.0+ |
| Foundation Models | built-in | iOS 26 SDK | Swift | iOS 26.0+, Apple Intelligence device |
| CLLocationUpdate | built-in | iOS 26 SDK | Swift | iOS 17.0+ (introduced WWDC23) |
| Swift Testing | built-in | Xcode 26 | Swift 6 | iOS 13+ |

**Compatibility note:** GRDB 7.x requires Swift 6.1+ and Xcode 16.3+. The project uses Xcode 26 which ships with Swift 6.2, so this is satisfied. GRDB's `minimumVersion = 7.0.0` with `upToNextMajorVersion` is correct — avoids any 6.x API that was removed.

**Compatibility note:** MapLibre SwiftUI DSL (swiftui-dsl) targets `maplibre-gl-native-distribution` as a dependency — pinning both to compatible major versions avoids integration issues. 0.21.1 was released January 20, 2026, targeting the 6.x MapLibre release series.

---

## Sources

- [MapLibre Native for iOS — GitHub](https://github.com/maplibre/maplibre-gl-native-distribution) — Latest release 6.24.0 confirmed March 11, 2026 (HIGH confidence)
- [MapLibre SwiftUI DSL — GitHub](https://github.com/maplibre/swiftui-dsl) — v0.21.1, January 20, 2026 (HIGH confidence)
- [GRDB.swift Releases — GitHub](https://github.com/groue/GRDB.swift/releases) — v7.10.0, February 15, 2026, Swift 6.1+ requirement (HIGH confidence)
- [GRDB 7 Beta announcement — Swift Forums](https://forums.swift.org/t/grdb-7-beta/75018) — confirms v7 targets Swift 6 (HIGH confidence)
- [Apple Foundation Models Framework — createwithswift.com](https://www.createwithswift.com/exploring-the-foundation-models-framework/) — `@Generable`, `@Guide`, `LanguageModelSession`, streaming, availability check APIs (MEDIUM confidence, verified against Apple newsroom)
- [LanguageModelSession — Apple Developer Documentation](https://developer.apple.com/documentation/foundationmodels/languagemodelsession) — official API reference (HIGH confidence)
- [Getting Started with Foundation Models — artemnovichkov.com](https://artemnovichkov.com/blog/getting-started-with-apple-foundation-models) — device requirements, availability states, text-only constraint (MEDIUM confidence)
- [CLLocationUpdate — Apple Developer Documentation](https://developer.apple.com/documentation/corelocation/cllocationupdate) — AsyncSequence GPS API, `.airborne` configuration (HIGH confidence)
- [Approachable Concurrency in Swift 6.2 — avanderlee.com](https://www.avanderlee.com/concurrency/approachable-concurrency-in-swift-6-2-a-clear-guide/) — main-actor-by-default, Swift 6.2 concurrency (MEDIUM confidence)
- [Swift 6.2 Released — swift.org](https://www.swift.org/blog/swift-6.2-released/) — release announcement (HIGH confidence)
- [Enhance your app's audio recording capabilities — WWDC25](https://developer.apple.com/videos/play/wwdc2025/251/) — iOS 26 AVAudioSession `bluetoothHighQualityRecording` (HIGH confidence)
- [NOAA Aviation Weather Data API](https://aviationweather.gov/data/api/) — Updated 2025 with OpenAPI spec, `metar?ids=KXXX&format=json` endpoint (HIGH confidence)
- [PMTiles for MapLibre — Protomaps Docs](https://docs.protomaps.com/pmtiles/maplibre) — PMTiles vs MBTiles for CDN hosting (HIGH confidence)
- [Key Considerations Before Using SwiftData — fatbobman.com](https://fatbobman.com/en/posts/key-considerations-before-using-swiftdata/) — SwiftData performance vs GRDB for large datasets (MEDIUM confidence)
- Project Xcode file (`efb-212.xcodeproj/project.pbxproj`) — confirmed GRDB `upToNextMajorVersion` from 7.0.0, MapLibre from 6.0.0, iOS 26.0 deployment target (HIGH confidence)

---

*Stack research for: iPad VFR EFB — moving map, flight recording, on-device AI debrief, offline-first*
*Researched: 2026-03-20*
