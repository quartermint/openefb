# Architecture Research

**Domain:** iPad VFR Electronic Flight Bag — iOS 26, @Observable, GRDB + SwiftData, MapLibre, Apple Foundation Models
**Researched:** 2026-03-20
**Confidence:** HIGH (iOS 26 / @Observable / Foundation Models confirmed; MapLibre GeoJSON patterns confirmed via docs; concurrency patterns from WWDC25 sessions)

---

## Standard Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│  UI Layer (SwiftUI, @MainActor)                                  │
│                                                                   │
│  ┌─────────┐  ┌──────────┐  ┌─────────┐  ┌──────────────────┐  │
│  │ MapView │  │ FlightVw │  │ LogbkVw │  │ Settings/Aircraft│  │
│  └────┬────┘  └────┬─────┘  └────┬────┘  └────────┬─────────┘  │
│       │            │             │                 │            │
│  ┌────▼────┐  ┌────▼─────┐  ┌───▼─────┐  ┌────────▼─────────┐  │
│  │  MapVM  │  │ FlightVM │  │ LogbkVM │  │   SettingsVM     │  │
│  └────┬────┘  └────┬─────┘  └────┬────┘  └────────┬─────────┘  │
├───────┴────────────┴─────────────┴─────────────────┴────────────┤
│  App State Layer (@MainActor @Observable — decomposed)           │
│                                                                   │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────────────────┐│
│  │  NavState   │  │  MapState    │  │     RecordingState       ││
│  └─────────────┘  └──────────────┘  └──────────────────────────┘│
│  ┌──────────────────┐  ┌───────────────────────────────────────┐ │
│  │  FlightPlanState │  │           SystemState                 │ │
│  └──────────────────┘  └───────────────────────────────────────┘ │
├──────────────────────────────────────────────────────────────────┤
│  Service Layer (nonisolated actors, async/await)                  │
│                                                                   │
│  ┌─────────────┐  ┌─────────────┐  ┌────────────────────────┐   │
│  │  MapService │  │WeatherService│  │  RecordingCoordinator  │   │
│  │ (UIKit wrap)│  │ (NOAA actor) │  │   (GPS+Audio actor)    │   │
│  └─────────────┘  └─────────────┘  └────────────────────────┘   │
│  ┌──────────────┐  ┌─────────────┐  ┌────────────────────────┐  │
│  │ TFRService   │  │ChartManager │  │  DebriefEngine         │  │
│  │ (FAA actor)  │  │ (CDN actor) │  │  (@Observable class)   │  │
│  └──────────────┘  └─────────────┘  └────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │  LocationManager  │  PowerManager  │  SecurityManager    │    │
│  └──────────────────────────────────────────────────────────┘    │
├──────────────────────────────────────────────────────────────────┤
│  Data Layer                                                       │
│                                                                   │
│  ┌──────────────────────────────┐  ┌───────────────────────────┐ │
│  │  AviationDatabase (GRDB)     │  │  SwiftData ModelContainer  │ │
│  │  - R-tree spatial index      │  │  - PilotProfile @Model     │ │
│  │  - FTS5 full-text search     │  │  - AircraftProfile @Model  │ │
│  │  - WAL mode, DatabasePool    │  │  - FlightRecord @Model     │ │
│  │  - 20K airports bundled      │  │  - CloudKit-ready          │ │
│  └──────────────────────────────┘  └───────────────────────────┘ │
│  ┌───────────────────────────────────────────────────────────┐   │
│  │  Chart Storage (MBTiles, Application Support/)             │   │
│  │  Weather Cache (in-memory + GRDB write-through)            │   │
│  └───────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘

External:
  NOAA API (METAR/TAF) — free, keyless
  FAA TFR feed         — live XML/JSON
  Cloudflare R2 CDN    — pre-processed MBTiles for VFR sectionals
```

### Component Responsibilities

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| **NavState** | Selected tab, sheet presentation, airport selection | Views (read), ViewModels (write) |
| **MapState** | Map center/zoom, active mode, visible layers, sectional opacity | MapVM, MapService |
| **RecordingState** | isRecording, currentPhase, duration, trackPoints count | RecordingCoordinator, FlightVM |
| **FlightPlanState** | Active plan, waypoints, DTG/ETE to next | FlightPlanVM, MapService |
| **SystemState** | Battery level, power mode, GPS availability, network | PowerManager, LocationManager |
| **MapService** | MLNMapView wrapper — GeoJSON sources, symbol layers, raster overlays, ownship | MapVM (delegate), AppState (write ownship) |
| **WeatherService** | NOAA API client, METAR/TAF parsing, cache | MapVM (pull), WeatherVM (pull) |
| **TFRService** | FAA TFR fetch, polygon geometry, proximity alerts | MapVM (pull), AppState alerts |
| **ChartManager** | MBTiles download from CDN, expiry tracking, tile loading | MapService (tiles), ChartDownloadView |
| **RecordingCoordinator** | GPS track recording + audio capture + phase detection | LocationManager, AVAudioSession |
| **DebriefEngine** | LanguageModelSession wrapper, structured output, streaming | FlightRecord (input), FlightVM (output) |
| **AviationDatabase** | GRDB DatabasePool — airports, navaids, airspace, spatial/FTS queries | DatabaseManager (facade) |
| **SwiftData Container** | Persistent user data — profiles, flights, settings | ViewModels via @Environment |
| **LocationManager** | CLLocationManager, aviation unit conversions, background updates | AppState (position), RecordingCoordinator |
| **PowerManager** | Battery monitoring, adaptive GPS/FPS/weather refresh intervals | LocationManager, MapService, WeatherService |

---

## Recommended Project Structure

```
efb-212/
├── App/
│   ├── efb_212App.swift              # @main — DI init, ModelContainer setup
│   └── ContentView.swift             # Root TabView
│
├── Core/
│   ├── AppState/
│   │   ├── AppState.swift            # @Observable root — owns sub-states, injects services
│   │   ├── NavState.swift            # @Observable — navigation, selected items, sheets
│   │   ├── MapState.swift            # @Observable — map config, layer toggles
│   │   ├── RecordingState.swift      # @Observable — recording lifecycle
│   │   ├── FlightPlanState.swift     # @Observable — active plan
│   │   └── SystemState.swift         # @Observable — power, GPS, network
│   ├── Models/
│   │   ├── AviationModels.swift      # Airport, Navaid, Airspace, TFR, WeatherCache
│   │   ├── FlightModels.swift        # FlightRecord, TrackPoint, FlightPhase
│   │   └── DebriefModels.swift       # @Generable FlightDebrief, FlightObservation
│   ├── Errors/
│   │   └── EFBError.swift            # Centralized LocalizedError enum
│   ├── Types/
│   │   └── Types.swift               # AppTab, MapMode, MapLayer, PowerState, etc.
│   ├── Protocols/
│   │   └── Protocols.swift           # DatabaseManagerProtocol, WeatherServiceProtocol, etc.
│   └── Extensions/
│       ├── CLLocation+Aviation.swift
│       └── Date+Aviation.swift
│
├── Data/
│   ├── Aviation/
│   │   ├── AviationDatabase.swift    # GRDB DatabasePool — all aviation data queries
│   │   └── DatabaseManager.swift    # Protocol + dual-DB coordinator
│   ├── UserData/
│   │   ├── PilotProfile.swift        # SwiftData @Model
│   │   ├── AircraftProfile.swift     # SwiftData @Model
│   │   └── FlightRecord.swift        # SwiftData @Model
│   └── BundledDB/
│       └── aviation.sqlite           # Pre-built 20K airport database (bundled resource)
│
├── Services/
│   ├── Map/
│   │   ├── MapService.swift          # MLNMapView wrapper — layers + delegation
│   │   └── GeoJSONBuilder.swift      # Feature collection builders for airports/weather
│   ├── Weather/
│   │   └── WeatherService.swift      # NOAA actor — METAR/TAF fetch + cache
│   ├── Airspace/
│   │   └── TFRService.swift          # FAA TFR actor — live data + polygon geometry
│   ├── Charts/
│   │   └── ChartManager.swift        # CDN download, MBTiles lifecycle, expiry
│   ├── Recording/
│   │   ├── RecordingCoordinator.swift # GPS track + audio orchestrator
│   │   ├── TrackLogRecorder.swift    # Adaptive GPS sampling, flight phase detection
│   │   └── AudioCaptureEngine.swift  # AVAudioSession, 6hr recording, quality profiles
│   ├── Debrief/
│   │   └── DebriefEngine.swift       # LanguageModelSession, streaming, context management
│   ├── Location/
│   │   ├── LocationManager.swift     # CLLocationManager + aviation unit bridge
│   │   └── PowerManager.swift        # Battery monitoring + adaptive degradation
│   └── Security/
│       └── SecurityManager.swift     # Keychain, Secure Enclave
│
├── ViewModels/
│   ├── MapViewModel.swift            # Map ↔ AppState ↔ MapService coordination
│   ├── FlightPlanViewModel.swift     # Plan creation, route calculations
│   ├── WeatherViewModel.swift        # METAR/TAF display formatting
│   ├── RecordingViewModel.swift      # Recording lifecycle UI state
│   ├── FlightDetailViewModel.swift   # Flight detail, debrief trigger, replay
│   ├── LogbookViewModel.swift        # SwiftData flight record CRUD
│   ├── NearestAirportViewModel.swift # Emergency nearest airport
│   └── SettingsViewModel.swift       # App config, chart downloads
│
└── Views/
    ├── Map/
    │   ├── MapView.swift             # UIViewRepresentable for MLNMapView
    │   ├── InstrumentStripView.swift # GS/ALT/VSI/TRK bar
    │   ├── LayerControlsView.swift   # Layer toggle panel
    │   ├── AirportInfoSheet.swift    # Bottom sheet with weather/runways
    │   ├── NearestAirportHUD.swift   # Always-visible emergency HUD
    │   └── NearestAirportView.swift  # Emergency detail screen
    ├── Planning/
    │   └── FlightPlanView.swift
    ├── Flights/
    │   ├── FlightListView.swift
    │   ├── FlightDetailView.swift
    │   ├── DebriefView.swift         # Streaming debrief display
    │   └── TrackReplayView.swift     # Map replay with audio sync
    ├── Logbook/
    │   └── LogbookView.swift
    ├── Aircraft/
    │   ├── AircraftProfileView.swift
    │   └── PilotProfileView.swift
    ├── Settings/
    │   ├── SettingsView.swift
    │   └── ChartDownloadView.swift
    └── Components/
        ├── FlightCategoryDot.swift
        ├── WeatherBadge.swift
        ├── SearchBar.swift
        └── StreamingTextView.swift   # Partial text animation for debrief
```

### Structure Rationale

- **Core/AppState/ (decomposed):** Splitting the god-object AppState into focused sub-states (MapState, RecordingState, etc.) limits view re-render scope. With `@Observable`, only properties actually accessed by a view trigger re-renders — sub-state objects enable this granular tracking. Each sub-state is owned by root AppState to maintain a single injection point.
- **Services/ (by domain):** Each service subdirectory is a domain boundary. Recording services are grouped separately from weather/map so the recording engine can be built/tested without map dependencies.
- **Data/BundledDB/:** Bundled SQLite is a resource file, not Swift literal seed data. Eliminates compile-time cost and binary bloat from the current SeedData/*.swift approach.
- **ViewModels/ (flat):** ViewModels don't nest. Each owns exactly one screen's state, delegates domain logic to services.

---

## Architectural Patterns

### Pattern 1: Decomposed @Observable AppState

**What:** Root AppState holds references to sub-state objects (NavState, MapState, etc.), each of which is independently @Observable. AppState is injected once via `.environment(appState)`, sub-states accessed as `appState.map`, `appState.nav`, etc.

**When to use:** Any piece of state read by more than one ViewModel. Navigation, map config, and system state are good candidates.

**Trade-offs:** Single injection point preserved. Views only re-render when the specific sub-state properties they access change — not all of AppState. Adding new state domains doesn't require modifying AppState's core.

**Example:**
```swift
@MainActor
@Observable
final class AppState {
    let nav = NavState()
    let map = MapState()
    let recording = RecordingState()
    let plan = FlightPlanState()
    let system = SystemState()

    // Services injected at init, held here for lifetime management
    let locationManager: any LocationManagerProtocol
    let databaseManager: any DatabaseManagerProtocol
    // ...
}

@MainActor
@Observable
final class MapState {
    var center: CLLocationCoordinate2D = .kDefaultCenter
    var zoomLevel: Double = 8
    var mode: MapMode = .vfrSectional
    var visibleLayers: Set<MapLayer> = .defaultLayers
    var sectionalOpacity: Double = 0.7
}
```

### Pattern 2: GeoJSON Source + Symbol Layer for Map Points

**What:** Instead of individual `MLNPointAnnotation` objects (which break at hundreds of items), all airport/weather/navaid points go through a single `MLNShapeSource` with clustering enabled. MapService maintains one source per data type, updates via `shapeSource.shape = featureCollection`.

**When to use:** Any map data layer with more than ~50 concurrent visible points. Mandatory for airports (up to 200+ visible in a region) and weather dots.

**Trade-offs:** GeoJSON cluster sources handle 20K features without performance degradation. Symbol layers render GPU-side. Updating requires rebuilding the feature collection, but that's a GeoJSON object not a view re-render. Initial setup is more complex than annotations.

**Example:**
```swift
// MapService setup (called once on map load)
func setupAirportLayer(on mapView: MLNMapView) {
    let source = MLNShapeSource(
        identifier: "airports",
        shape: nil,
        options: [
            .clustered: true,
            .clusterRadius: 50,
            .maximumZoomLevelForClustering: 12
        ]
    )
    mapView.style?.addSource(source)
    airportSource = source

    let symbolLayer = MLNSymbolStyleLayer(
        identifier: "airport-symbols",
        source: source
    )
    symbolLayer.iconImageName = NSExpression(forConstantValue: "airport-icon")
    symbolLayer.textField = NSExpression(
        forKeyPath: "icao_id"
    )
    mapView.style?.addLayer(symbolLayer)
}

// Update airports (called on region change)
func updateAirports(_ airports: [Airport]) {
    let features = airports.map { airport -> MLNPointFeature in
        let feature = MLNPointFeature()
        feature.coordinate = airport.coordinate
        feature.attributes = [
            "icao_id": airport.icaoIdentifier,
            "name": airport.name,
            "elevation": airport.fieldElevation
        ]
        return feature
    }
    airportSource?.shape = MLNShapeCollectionFeature(shapes: features)
}
```

### Pattern 3: nonisolated Actor Services

**What:** Services that do background work (WeatherService, TFRService, ChartManager, DebriefEngine) are declared as `nonisolated actor`. This opts them out of the global `@MainActor` default (set via `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`) while still providing actor-isolated state internally.

**When to use:** Any service that does network I/O, file I/O, or CPU-heavy work (parsing, spatial queries). Do not apply to services that primarily drive UI state.

**Trade-offs:** Forces `await` at call sites from @MainActor ViewModels/AppState, which is correct. Keeps UI thread free. The compiler enforces actor boundaries.

**Example:**
```swift
nonisolated actor WeatherService: WeatherServiceProtocol {
    private var metarCache: [String: WeatherCache] = [:]

    func fetchWeatherForStations(_ stations: [String]) async throws -> [String: WeatherCache] {
        // Network fetch — runs on actor's executor, not main thread
        let response = try await URLSession.shared.data(from: noaaURL(stations))
        let parsed = try parseMetarResponse(response.0)
        // Update cache (actor-isolated)
        for (id, cache) in parsed { metarCache[id] = cache }
        return parsed
    }
}

// ViewModel call site:
@MainActor
class MapViewModel {
    func loadWeather() async {
        let weather = try? await weatherService.fetchWeatherForStations(visibleStations)
        // Back on main actor — update state
        weatherData = weather ?? [:]
    }
}
```

### Pattern 4: DebriefEngine with @Observable + LanguageModelSession

**What:** A dedicated `@Observable` class (not actor) wraps `LanguageModelSession`. It uses `@MainActor` for UI-observable state while offloading generation to the session's own executor via structured concurrency. Pre-warming happens at FlightDetailView appear, not on debrief button tap.

**When to use:** All Foundation Models integration. The session is stateful and must be kept alive for multi-turn conversations. One session per debrief run — don't reuse across flights.

**Trade-offs:** 4096-token context window is a hard constraint. The pre-processing layer (GPS track → compact summary) must fit flight data into ~3,000 tokens, leaving ~1,000 for the model's response. Context window overflow throws `LanguageModelSession.GenerationError.exceededContextWindowSize` — the caller must catch and either truncate input or fall back to Claude API tier.

**Example:**
```swift
@MainActor
@Observable
final class DebriefEngine {
    var debrief: FlightDebrief?
    var partialDebrief: FlightDebrief.PartiallyGenerated?
    var isGenerating = false
    var error: Error?

    private var session: LanguageModelSession?

    func prewarm() {
        session = LanguageModelSession()
        Task { try? await session?.prewarm() }
    }

    func generateDebrief(for summary: FlightSummary) async {
        guard let session else { return }
        isGenerating = true
        defer { isGenerating = false }

        do {
            let stream = session.streamResponse(
                to: buildPrompt(from: summary),
                generating: FlightDebrief.self
            )
            for try await partial in stream {
                partialDebrief = partial
            }
            debrief = partialDebrief?.complete
        } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
            error = EFBError.debriefContextWindowExceeded
            // Trigger fallback to Claude API tier
        }
    }
}
```

### Pattern 5: Background Recording Coordinator

**What:** `RecordingCoordinator` is a `nonisolated actor` that orchestrates `CLLocationManager` updates and `AVAudioEngine` simultaneously. GPS track points are buffered in the actor, flushed to GRDB periodically. Audio is written directly to a file URL. Background location requires `UIBackgroundModes: [location]` in Info.plist and `allowsBackgroundLocationUpdates = true`.

**When to use:** This is the only architecture that safely handles simultaneous background location + audio recording without data races. The actor ensures no concurrent mutation of the track buffer.

**Trade-offs:** Background audio requires `AVAudioSession.Category.record` or `.playAndRecord`. Starting audio recording activates the audio session, which is a system resource — must handle `AVAudioSession` interruptions (phone calls, Siri). Flight phase detection (airborne vs. ground) gates auto-start/stop.

**Example:**
```swift
nonisolated actor RecordingCoordinator {
    private var trackBuffer: [TrackPoint] = []
    private let flushThreshold = 50 // Flush every 50 GPS points

    // Called from LocationManager delegate (bridged to actor)
    func receiveLocation(_ location: CLLocation) async {
        let point = TrackPoint(location: location, timestamp: .now)
        trackBuffer.append(point)
        if trackBuffer.count >= flushThreshold {
            await flushTrackToDB()
        }
    }

    private func flushTrackToDB() async {
        let points = trackBuffer
        trackBuffer.removeAll()
        try? await databaseManager.saveTrackPoints(points)
    }
}
```

---

## Data Flow

### Location → Ownship Display
```
CLLocationManager
    ↓ delegate callback (bridged to MainActor)
LocationManager
    ↓ publishes via AsyncStream or Combine
AppState.system (updates position, speed, altitude, track)
    ↓ @Observable property access
InstrumentStripView re-renders
MapService.updateOwnshipLayer(position)  ← MapViewModel observes AppState
```

### Region Change → Airport + Weather Display
```
User pans/zooms map
    ↓ MLNMapViewDelegate.regionDidChangeAnimated
MapService notifies MapViewModel via delegate
    ↓
MapViewModel.handleRegionChange(center, zoom)
    ↓ async let
    ├── databaseManager.airports(near:radius:)  [GRDB R-tree, background]
    ├── tfrService.tfrsForRegion(_:)            [actor, may network]
    └── airspaceDB.airspacesForRegion(_:)       [GRDB, background]
    ↓ await all
MapService.updateAirportSource(airports)         [GeoJSON source update]
MapService.updateTFRLayer(tfrs)
    ↓ (if weather layer active)
WeatherService.fetchWeatherForStations(icaoIds)  [actor, NOAA API]
    ↓
MapService.updateWeatherSource(weatherMap)
```

### Recording → Debrief Flow
```
Pilot taps Record
    ↓
RecordingCoordinator.startRecording()
    ↓ simultaneous
    ├── LocationManager: background GPS at 1-second intervals
    ├── AudioCaptureEngine: AVAudioEngine → file
    └── FlightPhaseDetector: monitors GS threshold for auto-stop
    ↓ (landing detected or manual stop)
RecordingCoordinator.stopRecording() → FlightRecord saved to SwiftData
    ↓
FlightDetailView appears → DebriefEngine.prewarm()
    ↓ (pilot taps "Generate Debrief")
FlightSummaryBuilder.build(from: flightRecord)  [GPS + audio events → ~3,000 tokens]
    ↓
DebriefEngine.generateDebrief(for: summary)
    ↓ streaming via PartiallyGenerated<FlightDebrief>
DebriefView renders partial results as they arrive
    ↓ (complete)
FlightRecord.debrief = debrief  [persisted to SwiftData]
```

### Chart Download → Map Display
```
Pilot opens Chart Download (or app background refresh)
    ↓
ChartManager.checkForUpdates()
    ↓ CDN metadata check (Cloudflare R2)
ChartRegion.expirationDate < now + 7 days?
    ↓ yes
ChartManager.downloadRegion(region) → MBTiles file → Application Support/Charts/
    ↓
MapState.availableCharts.insert(region)
    ↓ (when VFR sectional layer enabled)
MapService.addRasterTileSource(mbtiles: localURL)
MapService.addRasterLayer(above: baseMap)
```

---

## Component Build Order

Dependencies cascade upward — build each tier before the one above it.

```
Tier 0 — Core Types (no dependencies)
├── EFBError, Types, AppState sub-states (MapState, SystemState, etc.)
├── AviationModels, FlightModels, DebriefModels (@Generable)
└── All service protocols

Tier 1 — Data Layer
├── AviationDatabase (GRDB: schema, migrations, R-tree, FTS5)
├── DatabaseManager (coordinates GRDB + SwiftData container)
└── BundledDB seeded and queryable (airports.sqlite as resource)

Tier 2 — Core Services (actor-isolated, no UI deps)
├── LocationManager (GPS + aviation units)
├── PowerManager (battery adaptive degradation)
├── WeatherService (NOAA actor)
├── TFRService (FAA actor)
└── ChartManager (CDN download, MBTiles lifecycle)

Tier 3 — Map Layer (depends on Tier 1+2)
├── MapService (MLNMapView wrapper, GeoJSON sources, symbol layers, raster overlay)
└── GeoJSONBuilder (feature collections for airports, weather, navaids)

Tier 4 — Recording Engine (depends on Tier 1+2)
├── TrackLogRecorder (GPS adaptive sampling, phase detection)
├── AudioCaptureEngine (AVAudioSession, 6hr recording)
└── RecordingCoordinator (orchestrates both, background-capable)

Tier 5 — Debrief Engine (depends on Tier 1, Tier 4 FlightRecord)
├── FlightSummaryBuilder (GPS + audio events → token-compact summary)
└── DebriefEngine (LanguageModelSession, streaming, context overflow handling)

Tier 6 — ViewModels + UI (depends on all below)
├── MapViewModel (MapService + AppState bridge)
├── RecordingViewModel (RecordingCoordinator + RecordingState)
├── FlightDetailViewModel (debrief trigger, replay controls)
└── All remaining ViewModels + Views
```

---

## Scaling Considerations

This is a single-device app with no server-side scaling concerns. The relevant "scaling" is performance under real-world data volumes.

| Scale | Architecture Adjustments |
|-------|--------------------------|
| 3,700 airports (current) | Annotation-based rendering barely works. GeoJSON sources recommended even at this scale. |
| 20,000 airports (target) | Requires GeoJSON cluster sources. Individual annotations will freeze on pan/zoom. |
| 6-hour audio recording | AVAudioEngine file-based recording. In-memory buffer recording will OOM. Use `AVAudioFile` write-through. |
| 4096-token context window | Pre-processing must compress flight data aggressively. Build FlightSummaryBuilder to stay under 3,000 tokens. |
| Background recording | Background location + audio requires explicit Info.plist modes and audio session configuration. Test on real device — simulator behavior differs. |

### Scaling Priorities

1. **First bottleneck:** Map rendering at 200+ visible airports. GeoJSON sources with clustering eliminate this entirely — must be done before Phase 1 ships.
2. **Second bottleneck:** Foundation Models context window at 4096 tokens. FlightSummaryBuilder must be built with a budget in mind. A 2-hour VFR flight with normal radio comms produces ~15,000+ tokens of raw data — compression to ~3,000 tokens is non-trivial.

---

## Anti-Patterns

### Anti-Pattern 1: AppState as God Object

**What people do:** Add every new property to AppState — navigation state, map config, recording state, weather alerts, flight plan, power state, etc. all in one `@Observable` class.

**Why it's wrong:** Every property access in any view subscribes to the entire AppState. With `@Observable`, granular tracking works per-property, but when AppState has 40+ properties touched by 15 views, it becomes impossible to reason about invalidation. Testing requires constructing the entire object for a unit test on one concern.

**Do this instead:** Decompose into focused sub-state objects. AppState owns them as properties. Views access `appState.map.zoomLevel`, not `appState.mapZoomLevel`. Each sub-state is independently testable, independently injectable.

### Anti-Pattern 2: Individual MLNPointAnnotation per Airport

**What people do:** For each airport in the R-tree query result, create one `MLNPointAnnotation`, set its coordinate, add to the map. 200 airports = 200 annotations.

**Why it's wrong:** MapLibre must layout, render, and hit-test every annotation individually. At 200 annotations, panning feels sluggish. At 500+ (zoomed out), the UI drops frames. The annotation view cache helps but doesn't eliminate the layout cost.

**Do this instead:** One `MLNShapeSource` for all airports with `clustered: true`. Build an `MLNShapeCollectionFeature` from query results, assign to `source.shape`. MapLibre handles all rendering GPU-side via the symbol layer. Tap detection uses `mapView(_:didSelect:)` with feature inspection instead of annotation callbacks.

### Anti-Pattern 3: @unchecked Sendable to Silence Concurrency Warnings

**What people do:** The compiler flags a type as non-Sendable across actor boundaries. Rather than fixing the root cause, add `@unchecked Sendable` to silence the warning.

**Why it's wrong:** Bypasses Swift's data race safety guarantees. In the previous prototype, 6+ types had `@unchecked Sendable` — this is a signal of unresolved concurrency design, not a solution. If a type needs to cross actor boundaries, it must be genuinely immutable (struct/enum) or protected by its own actor.

**Do this instead:** Make data transfer types `struct` (value semantics, automatically Sendable in Swift 6). For classes that genuinely need actor protection, wrap in an actor. For GRDB specifically, all database access goes through `DatabasePool.read/write` which handles thread safety internally — the surrounding type can be a struct or `nonisolated actor` without `@unchecked`.

### Anti-Pattern 4: Blocking Main Thread with Database Queries

**What people do:** Call `databaseManager.airports(near:)` directly on the main actor to update map state synchronously.

**Why it's wrong:** Even fast R-tree queries on a large database can take 5-20ms. Blocking the main thread for 20ms produces visible jank at 60fps. On older iPads, GRDB queries against 20K rows can take 50ms+.

**Do this instead:** All `AviationDatabase` methods are `nonisolated` — call them from inside a `Task { }` in the ViewModel, `await` the result, then update `@Observable` state on return to `@MainActor`. Use `async let` to parallelize airport + TFR + airspace queries on region change.

### Anti-Pattern 5: Creating a New LanguageModelSession per Request

**What people do:** Instantiate `LanguageModelSession()` inside the debrief generation function, use it for one request, discard it.

**Why it's wrong:** Session creation initializes the model context and is expensive. More critically, multi-turn conversation context is lost — any follow-up questions from the pilot start from zero. Session pre-warming (`prewarm()`) only helps if the session is kept alive.

**Do this instead:** `DebriefEngine` owns one session per flight debrief lifecycle. Create on `FlightDetailView` appear, prewarm immediately, generate when the pilot requests it. Discard when the view dismisses. For a new debrief on a different flight, create a fresh session.

---

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| NOAA Aviation Weather API | REST, no key, 100 req/min, `actor WeatherService` | `https://aviationweather.gov/api/data/metar?ids=...` — free for commercial use |
| FAA TFR XML Feed | REST, no key, polling every 5-15 min | `https://tfr.faa.gov/tfr2/list.jsp` — parsing is brittle, XML format changes |
| Cloudflare R2 CDN | HTTPS MBTiles download, `ChartManager` actor | Requires server-side GeoTIFF → MBTiles conversion pipeline (outside app) |
| Apple Foundation Models | On-device only, `LanguageModelSession` | Requires iOS 26.0+; availability check required (`SystemLanguageModel.default.isAvailable`) |
| FAA N-number Registry | HTML scraping, `FAALookupService` | Fragile — replace with official API if available |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| MapViewModel ↔ MapService | Direct method calls + `MapServiceDelegate` protocol | MapService is UIKit (NSObject) — cannot be an actor. Delegate pattern is correct here. |
| AppState ↔ Services | Services held as protocol-typed properties; AppState subscribes via AsyncStream or Combine for continuous updates (location, power) | Don't call services directly from Views — always through ViewModels or AppState |
| RecordingCoordinator ↔ LocationManager | LocationManager delivers updates to coordinator via AsyncStream; avoids Combine for background-safe operation | CLLocationManagerDelegate callbacks must bridge to the recording actor safely |
| DebriefEngine ↔ FlightRecord | FlightRecord passed as value type input to `generateDebrief(for:)` — no retained reference | Prevents session from holding a SwiftData model reference across actor boundaries |
| SwiftData ↔ GRDB | No cross-database joins. SwiftData for user data; GRDB for aviation reference data. FlightRecord in SwiftData references GRDB airports by ICAO identifier (String), not by object reference | Keeps database boundaries clean |

---

## Sources

- [WWDC25: Embracing Swift concurrency](https://developer.apple.com/videos/play/wwdc2025/268/) — nonisolated API patterns, actor isolation best practices
- [Apple Foundation Models docs](https://developer.apple.com/documentation/FoundationModels) — LanguageModelSession, @Generable, context window
- [TN3193: Managing the Foundation Model context window](https://developer.apple.com/documentation/technotes/tn3193-managing-the-on-device-foundation-model-s-context-window) — token budget management
- [MapLibre Native iOS GeoJSON documentation](https://maplibre.org/maplibre-native/ios/latest/documentation/maplibre-native-for-ios/geojson/) — MLNShapeSource, clustering options
- [MGLShapeSource Class Reference](https://maplibre.org/maplibre-native/ios/api/Classes/MGLShapeSource.html) — clustering configuration options
- [The Ultimate Guide to Foundation Models Framework (AzamSharp)](https://azamsharp.com/2025/06/18/the-ultimate-guide-to-the-foundation-models-framework.html) — @Observable + LanguageModelSession patterns
- [SwiftData Architecture Patterns (AzamSharp 2025)](https://azamsharp.com/2025/03/28/swiftdata-architecture-patterns-and-practices.html) — @ModelActor, Sendable constraints
- [Key Considerations Before Using SwiftData (fatbobman)](https://fatbobman.com/en/posts/key-considerations-before-using-swiftdata/) — GRDB vs SwiftData performance trade-offs
- [iOS background processing with CoreLocation](https://medium.com/@samermurad555/ios-background-processing-with-corelocation-97106943408c) — background location + audio session patterns
- Existing codebase: `.planning/codebase/ARCHITECTURE.md`, `.planning/codebase/CONCERNS.md`
- PROJECT.md: fresh-start decisions, data strategy, key architecture constraints

---

*Architecture research for: iPad VFR EFB — iOS 26, @Observable, GRDB + SwiftData, MapLibre, Apple Foundation Models*
*Researched: 2026-03-20*
