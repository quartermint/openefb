# Code Conventions

## Swift Style

### Actor Isolation

The project sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, which means:

```swift
// This is implicitly @MainActor:
final class MapViewModel: ObservableObject { ... }

// Services opt out explicitly:
nonisolated actor WeatherService: WeatherServiceProtocol { ... }

// Database classes use @unchecked Sendable with nonisolated methods:
final class AviationDatabase: @unchecked Sendable {
    nonisolated func airport(byICAO icao: String) throws -> Airport? { ... }
}

// CLLocationManagerDelegate callbacks bridge back to MainActor:
nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let latest = locations.last else { return }
    MainActor.assumeIsolated {
        processLocation(latest)
    }
}

// Struct initializers that need to be nonisolated (e.g., for GRDB/Codable):
nonisolated init(icao: String, ...) { ... }
```

### Protocol-First DI

Every service has a corresponding protocol. Production, placeholder, and mock implementations all conform:

```swift
// Protocol definition in Core/Protocols.swift
protocol WeatherServiceProtocol: Sendable {
    func fetchMETAR(for stationID: String) async throws -> WeatherCache
    func fetchTAF(for stationID: String) async throws -> String
    func fetchWeatherForStations(_ stationIDs: [String]) async throws -> [WeatherCache]
    func cachedWeather(for stationID: String) -> WeatherCache?
}

// Injection via init:
init(
    databaseManager: any DatabaseManagerProtocol,
    mapService: MapService,
    weatherService: any WeatherServiceProtocol = PlaceholderWeatherService()
)
```

### ObservableObject + @Published

ViewModels and services that surface state to views use `ObservableObject` with `@Published`:

```swift
final class MapViewModel: ObservableObject {
    @Published var visibleAirports: [Airport] = []
    @Published var nearestAirport: Airport?
    @Published var isLoadingAirports: Bool = false
    @Published var lastError: EFBError?
}
```

### Combine Usage

Services communicate via Combine publishers. Common patterns:

```swift
// PassthroughSubject for location events:
private let locationSubject = PassthroughSubject<CLLocation, Never>()
var locationPublisher: AnyPublisher<CLLocation, Never> {
    locationSubject.eraseToAnyPublisher()
}

// Subscribing with sink + weak self:
locationManager.locationPublisher
    .receive(on: DispatchQueue.main)
    .sink { [weak self] location in
        guard let self else { return }
        self.processLocation(location)
    }
    .store(in: &cancellables)

// Debouncing rapid events:
appState.$visibleLayers
    .removeDuplicates()
    .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
    .sink { [weak self] _ in ... }
    .store(in: &cancellables)

// assign(to:) for simple property binding:
powerManager.$batteryLevel
    .receive(on: DispatchQueue.main)
    .assign(to: &$batteryLevel)
```

## Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Views | PascalCase + `View` suffix | `MapView.swift`, `AirportInfoSheet.swift` |
| ViewModels | PascalCase + `ViewModel` suffix | `MapViewModel.swift` |
| Services | PascalCase descriptive | `WeatherService.swift`, `ChartManager.swift` |
| Protocols | PascalCase + `Protocol` suffix | `DatabaseManagerProtocol` |
| Mocks | `Mock` prefix | `MockDatabaseManager` |
| Placeholders | `Placeholder` prefix | `PlaceholderWeatherService` |
| Enums | PascalCase, cases camelCase | `enum MapLayer: String { case sectional }` |
| Aviation units | Always documented | `// knots`, `// feet MSL`, `// degrees true`, `// nautical miles` |
| Constants | Static let | `private static let metersPerSecondToKnots: Double = 1.94384` |

## Error Handling

Centralized via `EFBError` enum (`efb-212/Core/EFBError.swift`):

```swift
enum EFBError: LocalizedError, Identifiable {
    case gpsUnavailable
    case chartExpired(Date)
    case weatherFetchFailed(underlying: Error)
    case airportNotFound(String)
    // ... 13 total cases

    var severity: ErrorSeverity { ... }  // critical, error, warning, info
    var errorDescription: String? { ... } // user-facing message
}
```

- **No force unwraps (`!`)** in production code (documented in CLAUDE.md)
- **Graceful degradation:** Weather and TFR fetch failures return cached/empty data rather than throwing to the UI
- **Error propagation:** Services throw `EFBError`, ViewModels catch and set `@Published var lastError: EFBError?`

## Aviation-Specific Conventions

- **All units documented in comments:** `// knots`, `// feet MSL`, `// degrees true`, `// nautical miles`, `// statute miles`, `// feet AGL`, `// MHz`, `// kHz`
- **Unit conversion constants** defined as static lets with clear names: `metersPerSecondToKnots`, `metersToFeet`
- **Weather staleness:** Always tracked — `WeatherCache.age`, `WeatherCache.isStale` (>60 min from fetch)
- **Chart expiration:** Always checked — `ChartRegion.isExpired`, 56-day FAA cycle
- **Flight categories:** VFR/MVFR/IFR/LIFR determined by ceiling and visibility per FAA definitions
- **Coordinate system:** Latitude/longitude as `Double`, altitude in feet MSL, speeds in knots
- **ICAO identifiers:** 4-character strings (e.g., "KPAO"), used as primary keys

## File Organization

- **One primary type per file**, file name matches type name
- **MARK comments** for section organization: `// MARK: - Section Name`
- **Extension-based protocol conformance:** `extension MapService: MLNMapViewDelegate { ... }` in the same file
- **Header comments** on every file describing purpose and actor isolation status
- **Models in AviationModels.swift:** All domain model structs are consolidated in one file (Airport, Runway, Frequency, Navaid, etc.)
- **Types in Types.swift:** All shared enums and lightweight structs consolidated in one file
