# Phase 1: Foundation + Navigation Core - Research

**Researched:** 2026-03-20
**Domain:** iPad VFR EFB -- iOS 26 SwiftUI, MapLibre, GRDB, NOAA Weather API, CLLocationUpdate
**Confidence:** HIGH

## Summary

Phase 1 delivers a complete VFR EFB from a fresh Xcode project: GPS ownship on a moving map with VFR sectional overlay, 20K+ airport database with search, METAR/TAF weather with flight category dots, airspace boundaries, TFR display, proximity alerts, instrument strip, nearest airport HUD, and offline capability. This is the largest and most foundational phase, covering 19 requirements across navigation, aviation data, weather, and infrastructure.

The existing codebase (61 Swift files, 215+ tests) is treated as **reference only** -- the fresh start uses iOS 26 `@Observable` (not `ObservableObject`), `CLLocationUpdate` AsyncSequence (not delegate-based `CLLocationManager`), and GeoJSON sources for 20K+ airports (not individual `MLNPointAnnotation`). The bundled pre-built SQLite database strategy is validated -- GRDB supports read-only bundle databases with proper journal mode handling. The NOAA Aviation Weather API is free, stable, and confirmed working with JSON format. The FAA TFR API situation is messy (no clean official JSON endpoint), so a scraping/parsing approach or third-party data source will be needed.

**Primary recommendation:** Build from fresh Xcode project targeting iOS 26 with `@Observable` AppState, bundled NASR SQLite via GRDB (read-only from bundle, copy-on-first-launch for write access), MapLibre 6.24.0 with GeoJSON sources for all map layers, `CLLocationUpdate.liveUpdates()` for GPS, and `NWPathMonitor` for reachability. Use the existing code as proven pattern reference, not as copy-paste source.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Initial map view shows Continental US (39 deg N, -98 deg W, zoom 5) on first launch, then animates to user's GPS position when location permission is granted and fix acquired
- Ownship indicator is an aviation chevron/triangle pointing in direction of travel, matching ForeFlight/Garmin conventions pilots expect
- Map controls (zoom, compass, layer toggle) placed on right edge for iPad landscape orientation, keeping left side clear for instrument strip
- Default VFR sectional opacity is 70% with adjustable slider, so terrain/streets remain visible underneath for orientation
- Airport info presented as iOS-native bottom sheet (half-height default, expandable to full) to keep map visible for spatial context
- At low zoom levels, small airports are clustered while towered airports (Class B/C/D) always remain visible to prevent clutter while keeping safety-critical airports prominent
- Single search bar supporting ICAO identifier, airport name, and city search with results as a scrollable list
- Nearest airport HUD is a persistent top-right badge showing closest airport + distance/bearing; tap to expand full sorted list with runways and direct-to option
- Weather dots on map are small uniform circles color-coded by flight category: green (VFR), blue (MVFR), red (IFR), magenta (LIFR) per FAA standard
- METAR display in airport info shows decoded human-readable format as primary view (wind, visibility, ceiling, temp/dewpoint highlighted) with raw METAR expandable for experienced pilots
- Staleness indicator shows relative time ("15m ago") as text badge, yellow when >30 minutes old, red when >60 minutes old -- progressive urgency
- Weather auto-refreshes with 15-minute METAR cache, auto-refresh when airport info is opened, plus manual refresh button
- Instrument strip positioned at bottom of map view as a full-width horizontal bar -- standard EFB placement
- Values displayed as large numeric values with small unit labels (e.g., "125 kts"), aviation-standard rounding (ALT to nearest 10 ft, GS to nearest 1 kt)
- When GPS is unavailable, values show dashes "---" with a subtle "No GPS" indicator -- clear without being alarming
- DTG and ETE values only appear when a flight plan or direct-to is active; blank/hidden otherwise to avoid confusion when not actively navigating
- Fresh start from blank Xcode project using iOS 26 @Observable (not ObservableObject) -- existing code is reference only
- GeoJSON sources instead of individual MLNPointAnnotation for 20K+ airport rendering performance
- Bundled pre-built SQLite database (not SwiftNASR on-device parsing) for instant offline access
- Server-side chart pipeline (GeoTIFF to MBTiles via GDAL) hosted on Cloudflare R2 CDN
- Chart CDN infrastructure must be operational before Phase 1 verification can pass

### Claude's Discretion
- Specific color palette and typography choices for the instrument strip
- Animation timing for ownship position updates and map transitions
- Exact clustering zoom thresholds for airport density management
- Internal caching strategy for weather data (in-memory vs GRDB write-through)
- GeoJSON source configuration details for MapLibre layers

### Deferred Ideas (OUT OF SCOPE)
- CloudKit sync foundation (built but not enabled until post-TestFlight)
- SwiftNASR integration for live FAA data updates (bundled SQLite is sufficient for v1)
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| NAV-01 | Pilot sees GPS position on map with heading indicator in real time | CLLocationUpdate.liveUpdates() AsyncSequence for GPS; custom ownship chevron layer in MapLibre GeoJSON |
| NAV-02 | VFR sectional chart overlay with adjustable opacity | MLNRasterTileSource with mbtiles:// URL scheme; opacity slider via rasterOpacity NSExpression |
| NAV-03 | Instrument strip showing GS/ALT/VSI/TRK/DTG/ETE | CLLocationUpdate provides speed, altitude, course; VSI computed from successive samples |
| NAV-04 | Map mode switching: VFR sectional, street, satellite, terrain | Multiple MLNRasterTileSource/MLNVectorTileSource with style URL switching |
| NAV-05 | Toggle map layers on/off: airspace, TFRs, airports, navaids, weather | GeoJSON source + style layer visibility toggling per MapLayer enum |
| NAV-06 | Nearest airport sorted list with distance, bearing, direct-to | GRDB R-tree spatial query + great-circle distance sort; CLLocation bearing calculation |
| NAV-07 | Background GPS tracking when screen off | CLBackgroundActivitySession + CLLocationUpdate.liveUpdates(); UIBackgroundModes "location" |
| DATA-01 | 20K+ US airports from FAA NASR data with R-tree spatial query | Bundled pre-built SQLite with GRDB R-tree virtual table; copy-on-first-launch pattern |
| DATA-02 | Airport info sheet with runways, frequencies, elevation, weather | iOS bottom sheet (.sheet presentationDetents); GRDB JOIN queries for airport + runways + frequencies |
| DATA-03 | Search airports/navaids by ICAO, name, city | GRDB FTS5 full-text search index on airports_fts virtual table |
| DATA-04 | Class B/C/D airspace boundaries on map with floor/ceiling labels | GeoJSON polygon source with MLNFillStyleLayer + MLNSymbolStyleLayer for labels |
| DATA-05 | Live TFR polygons from FAA data | FAA TFR data via tfr.faa.gov scraping or ADDS NOTAM; GeoJSON polygon rendering |
| DATA-06 | Proximity alerts for Class B/C/D airspace and active TFR | Point-in-polygon containment check + distance threshold alerts on GPS update |
| WX-01 | METAR/TAF with flight category color coding | NOAA Aviation Weather API JSON; FlightCategory enum with VFR/MVFR/IFR/LIFR determination |
| WX-02 | Color-coded weather dots on map by flight category | GeoJSON point source with data-driven circle layer styling by flight category property |
| WX-03 | Weather staleness badge | Date math on fetchedAt/observationTime; progressive urgency thresholds (30m yellow, 60m red) |
| INFRA-01 | Offline capability with bundled database and cached data | Bundled SQLite + downloaded MBTiles + in-memory weather cache; NWPathMonitor for status |
| INFRA-02 | Network reachability monitoring with cached/stale data indication | NWPathMonitor on dedicated DispatchQueue; publish isConnected state to AppState |
| INFRA-03 | Chart tiles from CDN with 56-day FAA cycle expiration metadata | Cloudflare R2 CDN serving MBTiles; ChartRegion model with effectiveDate/expirationDate |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| MapLibre Native iOS | 6.24.0 | Map rendering, raster tile overlays, GeoJSON layers | Open-source, no API key, MBTiles offline support, Metal-accelerated |
| GRDB.swift | 7.10.0 | SQLite with R-tree spatial indexes, FTS5 search, WAL mode | Best Swift SQLite library for spatial queries; proven at 20K+ records |
| SwiftData | iOS 26 built-in | User data (profiles, settings, flight records) | CloudKit-ready, native SwiftUI integration, VersionedSchema migration |
| MapLibre (SPM) | `maplibre/maplibre-gl-native-distribution` >= 6.0.0 | Already configured in project | SPM dependency, upToNextMajorVersion |
| GRDB (SPM) | `groue/GRDB.swift` >= 7.0.0 | Already configured in project | SPM dependency, upToNextMajorVersion |

### Supporting (Apple Frameworks -- no additional SPM)
| Framework | Purpose | When to Use |
|-----------|---------|-------------|
| CoreLocation (`CLLocationUpdate`) | GPS position via AsyncSequence | All GPS tracking; replaces delegate-based CLLocationManager |
| Network (`NWPathMonitor`) | Reachability monitoring | Offline/online status detection |
| Observation (`@Observable`) | Reactive state management | AppState, ViewModels -- replaces ObservableObject/@Published |
| SwiftUI (`.sheet`, `.presentationDetents`) | Airport info bottom sheet | Airport detail presentation |
| Combine | Event streams from services | Location publisher, weather refresh timer, power state |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| GeoJSON sources | MLNPointAnnotation (current code) | Annotations hit performance wall at 5K+ points; GeoJSON is GPU-rendered |
| CLLocationUpdate AsyncSequence | CLLocationManager delegate (current code) | Delegate pattern works but requires more boilerplate; AsyncSequence is idiomatic Swift 6 |
| NWPathMonitor | Reachability (3rd party) | NWPathMonitor is Apple-native, no dependency needed |
| Bundled SQLite | SwiftNASR on-device parsing | SwiftNASR parsing takes 30-60s on launch; bundled DB is instant |

**Installation:**
SPM dependencies already configured in `efb-212.xcodeproj`:
- `https://github.com/groue/GRDB.swift` (>= 7.0.0)
- `https://github.com/maplibre/maplibre-gl-native-distribution` (>= 6.0.0)

No additional SPM packages needed for Phase 1.

**Version verification:**
- MapLibre iOS: 6.24.0 (published 2026-03-11) -- verified via GitHub API
- GRDB.swift: 7.10.0 (published 2026-02-15) -- verified via GitHub API
- Both within the upToNextMajorVersion constraints already in the project

## Architecture Patterns

### Recommended Project Structure (Fresh Start)
```
efb-212/
├── App/
│   └── efb_212App.swift              # @main, @Observable AppState injection
├── Core/
│   ├── AppState.swift                # @Observable root state (NOT ObservableObject)
│   ├── NavigationState.swift         # Sub-state: selected tab, airport selection
│   ├── MapState.swift                # Sub-state: center, zoom, mode, layers, opacity
│   ├── LocationState.swift           # Sub-state: ownship position, GS, ALT, VSI, TRK
│   ├── EFBError.swift                # Centralized error types (reuse existing)
│   ├── Types.swift                   # Enums: AppTab, MapMode, MapLayer, etc. (reuse)
│   ├── AviationModels.swift          # Airport, Runway, Frequency, Navaid, etc. (reuse)
│   └── Extensions/
│       ├── CLLocation+Aviation.swift # NM conversion, bearing (reuse)
│       └── Date+Aviation.swift       # Zulu time formatting (reuse)
├── Views/
│   ├── Map/
│   │   ├── MapContainerView.swift    # Main map + instrument strip + controls
│   │   ├── MapView.swift             # MLNMapView UIViewRepresentable wrapper
│   │   ├── InstrumentStripView.swift # Bottom bar: GS, ALT, VSI, TRK, DTG, ETE
│   │   ├── AirportInfoSheet.swift    # Bottom sheet with airport details
│   │   ├── LayerControlsView.swift   # Layer toggle panel
│   │   ├── MapControlsView.swift     # Zoom, compass, mode controls (right edge)
│   │   ├── NearestAirportHUD.swift   # Top-right persistent badge
│   │   └── SearchBarView.swift       # ICAO/name/city search
│   ├── Settings/
│   │   ├── SettingsView.swift        # App settings
│   │   └── ChartDownloadView.swift   # Chart region picker
│   └── Components/
│       ├── WeatherBadge.swift        # Staleness indicator
│       ├── FlightCategoryDot.swift   # VFR/MVFR/IFR/LIFR dot
│       └── OpacitySlider.swift       # Chart opacity control
├── ViewModels/
│   ├── MapViewModel.swift            # Map coordination, airport loading
│   ├── WeatherViewModel.swift        # Weather fetch, cache management
│   ├── NearestAirportViewModel.swift # Nearest airport list
│   └── SearchViewModel.swift         # Airport/navaid search
├── Services/
│   ├── LocationService.swift         # CLLocationUpdate.liveUpdates() wrapper
│   ├── WeatherService.swift          # NOAA API client (reference existing)
│   ├── TFRService.swift              # FAA TFR data fetching
│   ├── ProximityAlertService.swift   # Airspace/TFR proximity detection
│   ├── ChartManager.swift            # MBTiles download + validation
│   ├── ReachabilityService.swift     # NWPathMonitor wrapper
│   └── PowerManager.swift            # Battery monitoring (reference existing)
├── Data/
│   ├── AviationDatabase.swift        # GRDB with R-tree, FTS5 (reference existing)
│   ├── DatabaseManager.swift         # Protocol + coordinator
│   └── Models/                       # SwiftData @Model classes
│       └── UserSettings.swift        # @Model for user preferences
├── Resources/
│   ├── Assets.xcassets/
│   └── aviation.sqlite               # Pre-built bundled NASR database
└── Protocols/
    └── Protocols.swift               # All service protocols (reference existing)
```

### Pattern 1: @Observable AppState (iOS 26 fresh start)
**What:** Replace `ObservableObject` with `@Observable` macro for root state coordinator. Decompose into sub-state structs for granular observation.
**When to use:** All new code in this project. Do NOT use `ObservableObject` or `@Published`.
**Example:**
```swift
// Source: Apple Developer Documentation - Observation framework
import Observation
import CoreLocation

@Observable
@MainActor
final class AppState {
    // Navigation
    var selectedTab: AppTab = .map
    var isPresentingAirportInfo: Bool = false
    var selectedAirportID: String?

    // Map
    var mapCenter: CLLocationCoordinate2D = .init(latitude: 39.0, longitude: -98.0)
    var mapZoom: Double = 5.0
    var mapMode: MapMode = .northUp
    var visibleLayers: Set<MapLayer> = [.sectional, .airports, .ownship]
    var sectionalOpacity: Double = 0.70

    // Location / Ownship
    var ownshipPosition: CLLocation?
    var groundSpeed: Double = 0      // knots
    var altitude: Double = 0         // feet MSL
    var verticalSpeed: Double = 0    // feet per minute
    var track: Double = 0            // degrees true
    var gpsAvailable: Bool = false

    // System
    var networkAvailable: Bool = false
    var batteryLevel: Double = 1.0
    var powerState: PowerState = .normal
}
```

### Pattern 2: CLLocationUpdate AsyncSequence (replaces CLLocationManager delegate)
**What:** Use iOS 17+ `CLLocationUpdate.liveUpdates()` for GPS tracking in a structured concurrency Task.
**When to use:** All GPS tracking. Background location via `CLBackgroundActivitySession`.
**Example:**
```swift
// Source: Apple WWDC23 - Discover streamlined location updates
import CoreLocation

actor LocationService {
    private var backgroundSession: CLBackgroundActivitySession?

    func startTracking() async {
        // Enable background tracking
        backgroundSession = CLBackgroundActivitySession()

        let updates = CLLocationUpdate.liveUpdates(.otherNavigation)
        for try await update in updates {
            guard let location = update.location else { continue }
            // Process location update
            await MainActor.run {
                // Update AppState with aviation units
            }
        }
    }

    func stopTracking() {
        backgroundSession?.invalidate()
        backgroundSession = nil
    }
}
```

### Pattern 3: GeoJSON Sources for 20K+ Airports (replaces MLNPointAnnotation)
**What:** Use `MLNShapeSource` with GeoJSON `FeatureCollection` for all airport/navaid/weather rendering. GPU-accelerated, handles 20K+ points without performance issues.
**When to use:** All map point/polygon layers. Never use `MLNPointAnnotation` for bulk data.
**Example:**
```swift
// Source: MapLibre Style Spec - Sources
func addAirportGeoJSON(_ airports: [Airport], to style: MLNStyle) {
    let features = airports.map { airport -> [String: Any] in
        [
            "type": "Feature",
            "geometry": [
                "type": "Point",
                "coordinates": [airport.longitude, airport.latitude]
            ],
            "properties": [
                "icao": airport.icao,
                "name": airport.name,
                "type": airport.type.rawValue,
                "isTowered": airport.frequencies.contains { $0.type == .tower }
            ]
        ]
    }

    let geojson: [String: Any] = [
        "type": "FeatureCollection",
        "features": features
    ]

    let data = try! JSONSerialization.data(withJSONObject: geojson)
    let shape = try! MLNShape(data: data, encoding: String.Encoding.utf8.rawValue)
    let source = MLNShapeSource(identifier: "airports", shape: shape, options: nil)
    style.addSource(source)

    // Circle layer for airport dots
    let circleLayer = MLNCircleStyleLayer(identifier: "airport-circles", source: source)
    circleLayer.circleRadius = NSExpression(forConstantValue: 5)
    circleLayer.circleColor = NSExpression(forConstantValue: UIColor.systemCyan)
    style.addLayer(circleLayer)
}
```

### Pattern 4: Bundled SQLite with Copy-on-First-Launch
**What:** Ship a pre-built SQLite database in the app bundle. On first launch, copy to Application Support for write access (weather cache writes). Read aviation data from the copied database.
**When to use:** Aviation database initialization.
**Example:**
```swift
// Source: GRDB.swift documentation - Bundled databases
func setupDatabase() throws -> DatabasePool {
    let fileManager = FileManager.default
    let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    let dbPath = appSupport.appendingPathComponent("aviation.sqlite")

    if !fileManager.fileExists(atPath: dbPath.path) {
        // First launch: copy bundled database to writable location
        guard let bundledPath = Bundle.main.url(forResource: "aviation", withExtension: "sqlite") else {
            throw EFBError.databaseCorrupted
        }
        try fileManager.createDirectory(at: appSupport, withIntermediateDirectories: true)
        try fileManager.copyItem(at: bundledPath, to: dbPath)
    }

    var config = Configuration()
    config.prepareDatabase { db in
        try db.execute(sql: "PRAGMA journal_mode = WAL")
    }
    return try DatabasePool(path: dbPath.path, configuration: config)
}
```

### Pattern 5: SwiftData VersionedSchema V1
**What:** Use VersionedSchema for SwiftData models from day one so future migrations are clean.
**When to use:** All SwiftData @Model definitions.
**Example:**
```swift
// Source: Apple Developer Documentation - VersionedSchema
import SwiftData

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [UserSettings.self] }

    @Model
    final class UserSettings {
        var defaultMapMode: String = "northUp"
        var sectionalOpacity: Double = 0.70
        var weatherRefreshInterval: Double = 900
        var createdAt: Date = Date()

        init() {}
    }
}

enum SchemaMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}
```

### Anti-Patterns to Avoid
- **ObservableObject/@Published in new code:** Use `@Observable` macro. The existing code uses `ObservableObject` -- do not carry that pattern forward. `@Observable` provides granular property tracking, reducing unnecessary view updates.
- **MLNPointAnnotation for bulk data:** The existing `MapService` uses individual annotations for airports/navaids/weather dots. At 20K+ airports, this will cause severe performance issues. Use GeoJSON `MLNShapeSource` with style layers instead.
- **CLLocationManager delegate pattern:** The existing `LocationManager` uses delegate callbacks. For the fresh start, use `CLLocationUpdate.liveUpdates()` AsyncSequence which is cleaner and supports structured concurrency natively.
- **Hardcoded seed data for airports:** The existing code has 11 regional seed data files with ~3,700 airports hardcoded in Swift. Replace with a bundled pre-built SQLite database.
- **nonisolated on everything:** The existing code marks many methods `nonisolated` to escape MainActor default isolation. With `@Observable` and proper actor design, this should be minimized. Use actors for services, `@MainActor` for ViewModels and AppState.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Spatial proximity queries | Custom distance loops over all airports | GRDB R-tree virtual table (`airports_rtree`) | R-tree is O(log n) vs O(n) full scan; handles 20K+ airports instantly |
| Full-text search | String matching loops | GRDB FTS5 virtual table (`airports_fts`) | FTS5 handles prefix matching, ranking, diacritics; orders of magnitude faster |
| Network reachability | Custom URLSession ping | `NWPathMonitor` (Network framework) | Apple-native, handles WiFi/cellular transitions, no polling needed |
| METAR flight category | Manual ceiling/visibility parsing | Existing `determineFlightCategory()` logic from WeatherService | FAA thresholds are well-defined; existing code handles edge cases correctly |
| Point-in-polygon | Custom raycasting | Existing `pointInPolygon()` from AviationDatabase | Ray-casting algorithm is correct and tested; airspace containment needs it |
| Great-circle distance | Haversine formula | `CLLocation.distance(from:)` + conversion to NM | Apple's implementation handles edge cases and is hardware-accelerated |
| Map tile caching | Custom file/HTTP cache | MapLibre built-in tile cache + MBTiles offline | MapLibre handles tile expiry, memory pressure, disk cache automatically |
| ISO 8601 date parsing | Custom DateFormatter | `ISO8601DateFormatter` with `withFractionalSeconds` | Handles NOAA's various timestamp formats correctly |

**Key insight:** The aviation domain has well-defined standards (FAA flight categories, METAR format, coordinate systems) and the existing codebase has working implementations for most of the tricky parsing. Reference these patterns rather than reimplementing.

## Common Pitfalls

### Pitfall 1: GRDB WAL Mode on Bundled Read-Only Database
**What goes wrong:** Opening a bundled SQLite database that was created in WAL mode fails because the app bundle is read-only and GRDB cannot create the `-wal` and `-shm` files.
**Why it happens:** `DatabasePool` opens in WAL mode by default. If the bundled database was created in WAL mode, SQLite looks for the missing WAL files.
**How to avoid:** Before bundling the database, convert it to DELETE journal mode with `sqlite3 aviation.sqlite "PRAGMA journal_mode=DELETE"`. Then copy-on-first-launch to Application Support where WAL mode can be enabled.
**Warning signs:** SQLite error 14 ("unable to open database file") or error 10 ("disk I/O error") on first launch.

### Pitfall 2: MapLibre MBTiles URL Scheme
**What goes wrong:** Raster tiles don't render or show blank/broken tiles.
**Why it happens:** The `mbtiles://` URL scheme requires the exact file path format, and the tileSize must match the MBTiles configuration (usually 256 for raster, 512 for vector retina tiles).
**How to avoid:** Use `mbtiles:///absolute/path/to/file.mbtiles` (note triple slash for absolute path). Verify tileSize matches the tiles in the MBTiles file. Test with a known-good MBTiles file first.
**Warning signs:** Blank map areas where sectional should appear; console errors about tile loading failures.

### Pitfall 3: CLLocationUpdate in Background
**What goes wrong:** GPS updates stop when the app goes to background or screen locks.
**Why it happens:** Without `CLBackgroundActivitySession`, iOS suspends location updates in background.
**How to avoid:** Create a `CLBackgroundActivitySession` before starting `CLLocationUpdate.liveUpdates()`. Add "location" to `UIBackgroundModes` in Info.plist. Add `NSLocationAlwaysAndWhenInUseUsageDescription` to Info.plist.
**Warning signs:** GPS indicator shows "No GPS" after screen lock; instrument strip freezes.

### Pitfall 4: GeoJSON Source Update Performance
**What goes wrong:** Map stutters or freezes when updating airport GeoJSON source on region change.
**Why it happens:** Rebuilding the entire GeoJSON FeatureCollection and replacing the source on every pan/zoom creates GC pressure and re-renders the entire layer.
**How to avoid:** Debounce region change events (500ms minimum). Only update when the viewport moves significantly (>5 NM from last query center). Use `MLNShapeSource.shape` setter to update in-place rather than removing/re-adding the source.
**Warning signs:** Map frame drops below 30fps during panning; visible flicker on airport dots.

### Pitfall 5: NOAA API Rate Limiting
**What goes wrong:** Weather fetches start returning 429 errors or empty responses.
**Why it happens:** Bulk-fetching weather for all visible airports on every map pan exceeds the 100 req/min rate limit, especially when using individual station requests.
**How to avoid:** Use the bulk endpoint `?ids=KPAO,KSFO,KSJC,...` to fetch multiple stations in one request (up to ~400 IDs). Cache aggressively (15-minute TTL). Only fetch weather for airports in the current viewport, not globally.
**Warning signs:** WeatherCache entries stop updating; console shows HTTP 429 responses.

### Pitfall 6: FAA TFR Data Access
**What goes wrong:** No clean JSON endpoint exists for TFR data from FAA.
**Why it happens:** The FAA publishes TFRs via tfr.faa.gov as HTML pages with linked shapefiles. The official NPM package for fetching TFRs has been deprecated/archived. The NOAA Aviation Weather API does NOT include TFR/NOTAM endpoints.
**How to avoid:** For Phase 1, continue with the realistic stub data approach (existing TFRService pattern). For live data, options are: (1) scrape tfr.faa.gov HTML + parse linked XML/shapefiles, (2) use a third-party API like AirHub, or (3) parse ADDS NOTAM data. Flag as a Phase 1 limitation -- stub data validates the rendering pipeline while live API integration can be iterated.
**Warning signs:** FAA changes their TFR page format and breaks the scraper.

### Pitfall 7: MainActor Isolation with GRDB
**What goes wrong:** Compiler errors about crossing actor boundaries when calling GRDB methods from ViewModels.
**Why it happens:** GRDB operations are synchronous and not MainActor-isolated, but ViewModels are `@MainActor`. The existing code handles this with `nonisolated` and `@unchecked Sendable`.
**How to avoid:** Keep AviationDatabase as `@unchecked Sendable` with `nonisolated` methods (GRDB handles its own thread safety via DatabasePool). Call database methods from Task blocks that hop off MainActor, then update state back on MainActor.
**Warning signs:** Swift concurrency warnings about non-sendable types crossing actor boundaries.

### Pitfall 8: Initial Map Center vs User Location Animation
**What goes wrong:** Map jumps abruptly from Continental US view to user position, or stays stuck on CONUS even after GPS fix.
**Why it happens:** The decision says "shows Continental US, then animates to user's GPS position." This requires carefully sequencing the initial viewport set and the first GPS update animation.
**How to avoid:** Set initial center to (39, -98) zoom 5 without animation. When the first CLLocationUpdate arrives, use `mapView.setCenter(..., animated: true)` with a zoom transition to level 10. Set a flag to prevent re-animation on subsequent updates.
**Warning signs:** Map snaps instead of animating; map keeps re-centering on every GPS update interrupting user panning.

## Code Examples

### NOAA METAR API Request (verified working)
```swift
// Source: https://aviationweather.gov/data/api/
// Bulk METAR fetch for multiple stations in JSON format
let stationIDs = ["KPAO", "KSFO", "KSJC", "KHWD"]
let joined = stationIDs.joined(separator: ",")
let url = URL(string: "https://aviationweather.gov/api/data/metar?ids=\(joined)&format=json")!

// Response is a JSON array of METAR objects:
// [{"icaoId":"KPAO","rawOb":"KPAO 201756Z ...","temp":18.0,"dewp":10.0,
//   "wdir":310,"wspd":12,"visib":"10+","clouds":[{"cover":"FEW","base":3500}],
//   "obsTime":"2026-03-20T17:56:00Z"}, ...]
```

### NOAA TAF API Request
```swift
// Source: https://aviationweather.gov/data/api/
let url = URL(string: "https://aviationweather.gov/api/data/taf?ids=KSFO&format=json")!
// Response: [{"icaoId":"KSFO","rawTAF":"TAF KSFO 201730Z ..."}]
```

### MapLibre UIViewRepresentable (iOS 26 SwiftUI)
```swift
// Source: MapLibre iOS documentation
import SwiftUI
import MapLibre

struct MapView: UIViewRepresentable {
    let mapService: MapService

    func makeUIView(context: Context) -> MLNMapView {
        let mapView = MLNMapView()
        mapService.configure(mapView: mapView)
        return mapView
    }

    func updateUIView(_ mapView: MLNMapView, context: Context) {
        // Update map state from AppState if needed
    }
}
```

### NWPathMonitor Reachability
```swift
// Source: Apple Network framework documentation
import Network

@Observable
final class ReachabilityService {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "ReachabilityMonitor")

    var isConnected: Bool = false
    var isExpensive: Bool = false  // cellular

    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = (path.status == .satisfied)
                self?.isExpensive = path.isExpensive
            }
        }
        monitor.start(queue: queue)
    }

    func stop() {
        monitor.cancel()
    }
}
```

### Weather Staleness Badge
```swift
// Source: User decision - progressive urgency thresholds
struct WeatherBadge: View {
    let observationTime: Date?

    private var minutesAgo: Int {
        guard let obs = observationTime else { return 0 }
        return Int(Date().timeIntervalSince(obs) / 60)
    }

    private var badgeColor: Color {
        if minutesAgo > 60 { return .red }
        if minutesAgo > 30 { return .yellow }
        return .secondary
    }

    var body: some View {
        Text("\(minutesAgo)m ago")
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(badgeColor.opacity(0.2))
            .foregroundColor(badgeColor)
            .cornerRadius(4)
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `ObservableObject` + `@Published` | `@Observable` macro (Observation framework) | WWDC 2023, iOS 17 | Granular property tracking, fewer unnecessary view re-renders |
| `CLLocationManager` delegate | `CLLocationUpdate.liveUpdates()` AsyncSequence | WWDC 2023, iOS 17 | Structured concurrency, automatic background session management |
| `CLBackgroundActivitySession` required for background | Still required for background GPS | iOS 17+ | Must create session before starting liveUpdates for background |
| `SCNetworkReachability` / Reachability.swift | `NWPathMonitor` (Network framework) | iOS 12+ (2018) | Apple-native, handles all network types, no 3rd party |
| Separate R-tree manual sync | GRDB R-tree with manual population | Stable | Still requires manual INSERT into rtree table alongside main table |
| MLNPointAnnotation for map markers | MLNShapeSource + GeoJSON for bulk rendering | MapLibre 6.x | GPU-accelerated rendering of 20K+ points without performance issues |

**Deprecated/outdated:**
- `ObservableObject`: Still functional but `@Observable` is the modern replacement. New code should not use it.
- `CLLocationManager` delegate-only pattern: AsyncSequence via `CLLocationUpdate` is preferred for new code. Delegate still works for backward compatibility.
- Hardcoded seed data arrays: The existing 11 regional airport files with ~3,700 hardcoded airports should be replaced entirely by the bundled SQLite database.

## Open Questions

1. **Pre-built NASR SQLite Database Generation**
   - What we know: The decision is to bundle a pre-built SQLite database with 20K+ airports, not parse SwiftNASR on-device. The existing GRDB schema (R-tree, FTS5) is proven.
   - What's unclear: The exact pipeline to generate this database. Options: (a) write a macOS command-line tool that uses SwiftNASR to parse NASR data and write to SQLite via GRDB, (b) use Python with sqlite3 to parse the raw NASR fixed-width files, (c) find an existing pre-built database.
   - Recommendation: Create a small macOS/Swift command-line tool (`NASRImporter`) as a build-time dependency. Run it locally to generate `aviation.sqlite`, then add the output to the app bundle as a resource. This is a one-time setup cost that pays dividends (56-day update cycle).

2. **FAA TFR Live Data Source**
   - What we know: The NOAA Aviation Weather API has no TFR endpoint. The FAA's tfr.faa.gov site has shapefiles but no clean JSON API. The NPM package is deprecated.
   - What's unclear: Whether to build a custom scraper, use a third-party API, or accept stub data for v1.
   - Recommendation: Ship Phase 1 with stub TFR data (existing pattern). Add a TODO for live TFR integration. The rendering pipeline is proven -- the data source is the only gap.

3. **Chart CDN Infrastructure**
   - What we know: Must be operational before Phase 1 verification. GeoTIFF to MBTiles via GDAL, hosted on Cloudflare R2.
   - What's unclear: Whether this pipeline has been built yet. It's flagged as a Phase 1 blocker in STATE.md.
   - Recommendation: Plan task execution should surface this as a parallel workstream. The Xcode app work can proceed independently -- chart overlay code can be tested with a locally-generated MBTiles file.

4. **Airspace Geometry Data Source**
   - What we know: The existing code has airspace boundary data in seed data files. Real airspace geometry comes from FAA NASR airspace shape data.
   - What's unclear: Whether the bundled SQLite will include airspace geometry or if that needs a separate data source.
   - Recommendation: Include airspace geometry in the bundled `aviation.sqlite` alongside airports and navaids. The existing GRDB schema already supports airspace storage with bounding-box spatial indexing.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (import Testing) + XCTest (legacy) |
| Config file | efb-212.xcodeproj test targets (efb-212Tests, efb-212UITests) |
| Quick run command | `xcodebuild test -scheme efb-212 -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' -only-testing:efb-212Tests 2>&1 \| tail -20` |
| Full suite command | `xcodebuild test -scheme efb-212 -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' 2>&1 \| tail -30` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| NAV-01 | GPS position renders on map | unit (LocationService) + manual (simulator GPS) | `xcodebuild test ... -only-testing:efb-212Tests/ServiceTests` | Partial (LocationManagerTests exists) |
| NAV-02 | VFR sectional overlay with opacity | unit (ChartManager) + manual (visual) | `xcodebuild test ... -only-testing:efb-212Tests/ServiceTests/ChartManagerTests` | Yes (ChartManagerTests.swift) |
| NAV-03 | Instrument strip values | unit (LocationService aviation unit conversion) | `xcodebuild test ... -only-testing:efb-212Tests/ViewModelTests/MapViewModelTests` | Yes (MapViewModelTests.swift) |
| NAV-04 | Map mode switching | manual-only | N/A -- requires visual verification | No |
| NAV-05 | Layer toggle on/off | unit (MapViewModel layer state) | `xcodebuild test ... -only-testing:efb-212Tests/ViewModelTests/MapViewModelTests` | Yes |
| NAV-06 | Nearest airport with distance/bearing | unit (NearestAirportViewModel) | `xcodebuild test ... -only-testing:efb-212Tests/ViewModelTests/NearestAirportViewModelTests` | Yes |
| NAV-07 | Background GPS tracking | manual-only | N/A -- requires device with GPS, screen lock | No |
| DATA-01 | 20K+ airports R-tree query | unit (AviationDatabase) | `xcodebuild test ... -only-testing:efb-212Tests/DataTests/AviationDatabaseTests` | Yes |
| DATA-02 | Airport info sheet content | unit (database JOIN query) | `xcodebuild test ... -only-testing:efb-212Tests/DataTests` | Yes |
| DATA-03 | Search by ICAO/name/city | unit (FTS5 search) | `xcodebuild test ... -only-testing:efb-212Tests/DataTests/AviationDatabaseTests` | Yes |
| DATA-04 | Airspace boundaries with labels | manual-only | N/A -- visual verification | No |
| DATA-05 | TFR polygon display | unit (TFRService parsing) + manual | `xcodebuild test ... -only-testing:efb-212Tests/ServiceTests` | Partial (MockTFRService exists) |
| DATA-06 | Proximity alerts | unit (ProximityAlertService) | New test file needed | No -- Wave 0 |
| WX-01 | METAR/TAF with flight category | unit (WeatherService parsing) | `xcodebuild test ... -only-testing:efb-212Tests/ServiceTests/WeatherServiceTests` | Yes |
| WX-02 | Weather dots on map | unit (GeoJSON generation) | New test file needed | No -- Wave 0 |
| WX-03 | Staleness badge | unit (date math) | New test file needed | No -- Wave 0 |
| INFRA-01 | Offline capability | integration (bundled DB loads) | `xcodebuild test ... -only-testing:efb-212Tests/IntegrationTests` | Yes (CrossCountryFlowTests) |
| INFRA-02 | Reachability monitoring | unit (ReachabilityService) | New test file needed | No -- Wave 0 |
| INFRA-03 | Chart CDN with expiration | unit (ChartManager) | `xcodebuild test ... -only-testing:efb-212Tests/ServiceTests/ChartManagerTests` | Yes |

### Sampling Rate
- **Per task commit:** Quick test run (affected test files only)
- **Per wave merge:** Full test suite
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `efb-212Tests/ServiceTests/ProximityAlertServiceTests.swift` -- covers DATA-06
- [ ] `efb-212Tests/ServiceTests/ReachabilityServiceTests.swift` -- covers INFRA-02
- [ ] `efb-212Tests/ViewModelTests/WeatherBadgeTests.swift` -- covers WX-03
- [ ] `efb-212Tests/DataTests/GeoJSONGenerationTests.swift` -- covers WX-02 (GeoJSON source generation)
- [ ] Existing tests may need updates for `@Observable` migration (mocks use `ObservableObject` patterns)

## Sources

### Primary (HIGH confidence)
- Existing codebase: `efb-212/` directory -- 61 Swift files, 215+ tests, proven GRDB/MapLibre/NOAA patterns
- GRDB.swift v7.10.0 -- GitHub releases API (verified 2026-02-15 publish date)
- MapLibre Native iOS v6.24.0 -- GitHub releases API (verified 2026-03-11 publish date)
- Apple Developer Documentation -- CLLocationUpdate, @Observable, NWPathMonitor, SwiftData VersionedSchema
- NOAA Aviation Weather API -- https://aviationweather.gov/data/api/ (verified working endpoints)

### Secondary (MEDIUM confidence)
- MapLibre MBTiles support -- `mbtiles://` URL scheme documented in tile URL templates reference
- FAA TFR data access -- tfr.faa.gov serves HTML + shapefiles; no clean JSON API confirmed via multiple sources
- NOAA API 2025 redesign -- some parameter and schema changes in September 2025 (need to verify current response format matches existing parsing code)

### Tertiary (LOW confidence)
- Apple Foundation Models availability timeline for iOS 26 -- not relevant for Phase 1 but flagged for Phase 4
- Exact MBTiles tileSize for FAA VFR sectional charts -- needs verification with actual generated tiles

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- All libraries verified as current, already configured in project, SPM constraints valid
- Architecture: HIGH -- @Observable, CLLocationUpdate, GeoJSON patterns well-documented; existing code provides proven reference
- Pitfalls: HIGH -- Identified from direct codebase analysis and verified against official documentation
- Data sources: MEDIUM -- NOAA API confirmed; FAA TFR API gap identified; bundled SQLite pipeline needs to be built
- Test infrastructure: HIGH -- Existing test structure with mocks, categorized tests, both Swift Testing and XCTest

**Research date:** 2026-03-20
**Valid until:** 2026-04-20 (30 days -- stable domain, no fast-moving dependencies)
