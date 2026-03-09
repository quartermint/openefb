# Testing

## Framework & Structure

- **Framework:** Swift Testing (`import Testing`, `@Test`, `@Suite`, `#expect`)
- **No XCTest:** All unit/integration tests use the modern Swift Testing framework
- **UI Tests:** XCTest-based (`efb-212UITests/`) — minimal (3 tests)
- **Total:** 241 test methods across 17 test files (22 Swift files including mocks)

## Test Organization

```
efb-212Tests/
├── DataTests/          # Database, models, seed data
├── IntegrationTests/   # Cross-component flow tests
├── Mocks/              # Protocol-conforming mock implementations
├── ServiceTests/       # Service layer unit tests
└── ViewModelTests/     # ViewModel unit tests
```

## Test Distribution

| Category | Files | Tests | Focus |
|----------|-------|-------|-------|
| DataTests | 4 | 92 | AviationDatabase (R-tree, FTS5, weather cache, airspace containment), model construction, seed data integrity, error types |
| ServiceTests | 4 | 69 | WeatherService (METAR parsing, caching, flight category), ChartManager (download, validation, expiration), LocationManager (unit conversions), PowerManager (state transitions) |
| ViewModelTests | 4 | 63 | MapViewModel (airport loading, selection), FlightPlanViewModel (waypoints, calculations), LogbookViewModel (CRUD), NearestAirportViewModel (distance logic) |
| IntegrationTests | 2 | 13 | Cross-country flight planning flow, map region change + airport loading |
| UITests | 2 | 3 | Launch test, basic UI interaction |
| Root | 1 | 1 | Placeholder test |

## Mock Strategy

Every service protocol has a corresponding mock in `efb-212Tests/Mocks/`:

| Mock | Protocol | Pattern |
|------|----------|---------|
| `MockDatabaseManager` | `DatabaseManagerProtocol` | In-memory arrays, filters by property |
| `MockLocationManager` | `LocationManagerProtocol` | Settable `location`/`heading`, PassthroughSubject for publisher |
| `MockWeatherService` | `WeatherServiceProtocol` | Returns pre-set WeatherCache or throws |
| `MockTFRService` | `TFRServiceProtocol` | Returns pre-set TFR array |
| `MockNetworkManager` | `NetworkManagerProtocol` | Settable responses |

Mock pattern example:
```swift
final class MockDatabaseManager: DatabaseManagerProtocol, @unchecked Sendable {
    var airports: [Airport] = []      // Set in test setup
    var weatherCache: [String: WeatherCache] = [:]

    func airport(byICAO icao: String) async throws -> Airport? {
        airports.first { $0.icao == icao }
    }

    func airports(near coordinate: CLLocationCoordinate2D, radiusNM: Double) async throws -> [Airport] {
        airports  // Returns all — test controls the data
    }
}
```

## Testing Patterns

### Swift Testing Suite
```swift
@Suite("AviationDatabase Tests", .serialized)
struct AviationDatabaseTests {
    @Test func insertAndCount() throws { ... }
    @Test func searchByICAO() throws { ... }
}
```

### Database Tests (Temporary File)
```swift
static func makeTempDB() throws -> AviationDatabase {
    let tempDir = FileManager.default.temporaryDirectory
    let dbPath = tempDir.appendingPathComponent("test-\(UUID().uuidString).sqlite").path
    return try AviationDatabase(path: dbPath)
}
```
Each test creates a fresh temporary database — no shared state between tests.

### Async Test Methods
```swift
@Test func tfrServiceFetchReturnsResults() async throws {
    let service = TFRService()
    let bayAreaCoord = CLLocationCoordinate2D(latitude: 37.46, longitude: -122.12)
    let tfrs = try await service.fetchActiveTFRs(near: bayAreaCoord, radiusNM: 50.0)
    #expect(!tfrs.isEmpty)
}
```

### Test Helpers
Static factory methods create test fixtures with sensible defaults:
```swift
static func makeTestAirport(
    icao: String = "KPAO",
    name: String = "Palo Alto",
    latitude: Double = 37.4611,
    longitude: Double = -122.1150,
    ...
) -> Airport { ... }

static let kpao = makeTestAirport(icao: "KPAO", ...)
static let ksql = makeTestAirport(icao: "KSQL", ...)
```

## Coverage Targets

From CLAUDE.md:
- **Services:** >80% coverage target
- **ViewModels:** >60% coverage target
- **Views:** Not directly tested (SwiftUI previews serve as visual verification)

## Running Tests

```bash
# Xcode
# Cmd+U in Xcode

# Command line
xcodebuild test -scheme efb-212 -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)'
```

## What's Not Tested

- **MapService:** Requires MLNMapView (UIKit) — no unit tests, visual verification only
- **SecurityManager:** Keychain operations — tested manually on device
- **FAALookupService:** Requires network — no offline mock/test
- **UI layout/appearance:** Relies on SwiftUI previews and manual verification
- **EFBRecordingCoordinator:** Phase 2 stub — no behavior to test
