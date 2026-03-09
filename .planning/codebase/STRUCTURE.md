# Directory Structure

## Project Layout

```
efb-212/
├── CLAUDE.md                          # Agent instructions and project conventions
├── PRD.md                             # Product requirements document (source of truth)
├── README.md                          # Project README
├── efb-212.xcodeproj/                 # Xcode project (manages SPM deps)
│
├── efb-212/                           # Main app target (61 Swift files)
│   ├── efb_212App.swift               # @main entry point, DI setup, SwiftData container
│   ├── ContentView.swift              # Root TabView (map, flights, logbook, aircraft, settings)
│   │
│   ├── Core/                          # Shared foundations
│   │   ├── AppState.swift             # Root @MainActor ObservableObject (global state)
│   │   ├── AviationModels.swift       # Domain models: Airport, Runway, Frequency, Navaid, Airspace, TFR, FlightPlan, Waypoint, WeatherCache, ChartRegion
│   │   ├── DeviceCapabilities.swift   # Device detection (GPS, cellular, screen size)
│   │   ├── EFBError.swift             # Centralized error enum (LocalizedError + Identifiable)
│   │   ├── Placeholders.swift         # Placeholder service implementations for DI stubs
│   │   ├── Protocols.swift            # All service protocols (DatabaseManager, Location, Weather, TFR, Network, Audio)
│   │   ├── Types.swift                # Shared enums (AppTab, MapMode, MapLayer, PowerState, aviation types) and lightweight structs (WindInfo, BoundingBox, VSpeeds)
│   │   └── Extensions/
│   │       ├── CLLocation+Aviation.swift   # distanceInNM, bearing, unit conversions
│   │       └── Date+Aviation.swift         # Date formatting for aviation
│   │
│   ├── Data/                          # Data layer
│   │   ├── AviationDatabase.swift     # GRDB wrapper: R-tree, FTS5, CRUD, spatial queries (849 lines)
│   │   ├── DatabaseManager.swift      # Protocol impl: coordinates GRDB + SwiftData
│   │   ├── AirportSeedData.swift      # Aggregator: calls all regional seed files
│   │   ├── Models/                    # SwiftData @Model classes
│   │   │   ├── AircraftProfile.swift
│   │   │   ├── FlightRecord.swift
│   │   │   └── PilotProfile.swift
│   │   └── SeedData/                  # Bundled airport/navaid/airspace data (~3,700 airports)
│   │       ├── AlaskaHawaiiAirports.swift
│   │       ├── MidwestAirports.swift
│   │       ├── MountainWestAirports.swift
│   │       ├── NortheastAirports.swift
│   │       ├── PacificNorthwestAirports.swift
│   │       ├── SoutheastAirports.swift
│   │       ├── SouthwestAirports.swift
│   │       ├── TexasAirports.swift
│   │       ├── WestCoastAirports.swift
│   │       ├── AirspaceSeedData.swift     # Bay Area airspace boundaries
│   │       └── NavaidSeedData.swift       # VOR/NDB navaids
│   │
│   ├── Services/                      # Business logic and external APIs
│   │   ├── ChartManager.swift         # VFR chart download, validation, expiration (nonisolated actor)
│   │   ├── EFBRecordingCoordinator.swift  # Phase 2 STUB — flight recording placeholder
│   │   ├── FAALookupService.swift     # FAA N-number registry HTML scraper
│   │   ├── LocationManager.swift      # CLLocationManager wrapper with aviation units
│   │   ├── MapService.swift           # MLNMapView wrapper: layers, annotations, overlays (835 lines)
│   │   ├── PowerManager.swift         # Battery monitoring, adaptive degradation
│   │   ├── SecurityManager.swift      # Keychain CRUD, Secure Enclave key gen (nonisolated actor)
│   │   ├── TFRService.swift           # TFR fetch — currently stub data (nonisolated actor)
│   │   └── WeatherService.swift       # NOAA API client with caching (nonisolated actor)
│   │
│   ├── ViewModels/                    # One ViewModel per major view
│   │   ├── FlightPlanViewModel.swift  # Flight plan creation, waypoint management, calculations
│   │   ├── LogbookViewModel.swift     # Flight record CRUD via SwiftData
│   │   ├── MapViewModel.swift         # Map ↔ AppState coordination, airport/weather/TFR loading
│   │   ├── NearestAirportViewModel.swift  # Emergency nearest airport logic
│   │   ├── SettingsViewModel.swift    # App settings management
│   │   └── WeatherViewModel.swift     # Weather data display, METAR/TAF formatting
│   │
│   └── Views/                         # SwiftUI views organized by feature
│       ├── Aircraft/
│       │   ├── AircraftProfileView.swift
│       │   └── PilotProfileView.swift
│       ├── Components/                # Reusable UI components
│       │   ├── FlightCategoryDot.swift
│       │   ├── SearchBar.swift
│       │   └── WeatherBadge.swift
│       ├── Flights/
│       │   ├── FlightDetailView.swift
│       │   └── FlightListView.swift
│       ├── Logbook/
│       │   └── LogbookView.swift
│       ├── Map/
│       │   ├── AirportInfoSheet.swift     # Airport detail bottom sheet
│       │   ├── InstrumentStripView.swift   # GS/ALT/VS/TRK bar
│       │   ├── LayerControlsView.swift     # Layer toggle panel
│       │   ├── MapView.swift              # UIViewRepresentable wrapper for MLNMapView
│       │   ├── NearestAirportHUD.swift    # Always-visible nearest airport HUD
│       │   └── NearestAirportView.swift   # Emergency nearest airport screen
│       ├── Planning/
│       │   └── FlightPlanView.swift
│       └── Settings/
│           ├── ChartDownloadView.swift
│           └── SettingsView.swift
│
├── efb-212Tests/                      # Unit and integration tests (22 Swift files, 241 test methods)
│   ├── efb_212Tests.swift             # Root test file
│   ├── DataTests/
│   │   ├── AirportSeedDataTests.swift     # Seed data integrity (13 tests)
│   │   ├── AviationDatabaseTests.swift    # GRDB spatial/FTS/cache (47 tests)
│   │   ├── AviationModelTests.swift       # Model construction and properties (27 tests)
│   │   └── EFBErrorTests.swift            # Error messages and severity (5 tests)
│   ├── IntegrationTests/
│   │   ├── CrossCountryFlowTests.swift    # End-to-end flight plan flow (5 tests)
│   │   └── MapLoadingFlowTests.swift      # Map region change flow (8 tests)
│   ├── Mocks/
│   │   ├── MockDatabaseManager.swift
│   │   ├── MockLocationManager.swift
│   │   ├── MockNetworkManager.swift
│   │   ├── MockTFRService.swift
│   │   └── MockWeatherService.swift
│   ├── ServiceTests/
│   │   ├── ChartManagerTests.swift        # Download, validation, expiration (23 tests)
│   │   ├── LocationManagerTests.swift     # Aviation unit conversions (17 tests)
│   │   ├── PowerManagerTests.swift        # Battery state transitions (8 tests)
│   │   └── WeatherServiceTests.swift      # METAR parsing, caching (21 tests)
│   └── ViewModelTests/
│       ├── FlightPlanViewModelTests.swift     # Waypoint/route calculations (19 tests)
│       ├── LogbookViewModelTests.swift        # Flight record management (14 tests)
│       ├── MapViewModelTests.swift            # Airport loading, selection (16 tests)
│       └── NearestAirportViewModelTests.swift # Nearest airport logic (14 tests)
│
└── efb-212UITests/                    # UI tests (2 files, 3 tests)
    ├── efb_212UITests.swift
    └── efb_212UITestsLaunchTests.swift
```

## File Size Distribution

| Category | Files | Total Lines |
|----------|-------|-------------|
| App source | 61 | ~13,200 |
| Test files | 22 | ~4,200 |
| **Total** | **83** | **~17,400** |

## Largest Files

| File | Lines | Role |
|------|-------|------|
| `AviationDatabase.swift` | 849 | GRDB wrapper with all spatial/FTS queries |
| `MapService.swift` | 835 | MLNMapView management, all map layers |
| `AviationModels.swift` | 416 | All domain model structs |
| `WeatherService.swift` | 385 | NOAA API client with parsing |
| `ChartManager.swift` | 359 | Chart download and lifecycle |
| `MapViewModel.swift` | 370 | Map coordination logic |
| `Types.swift` | 279 | Shared enums and lightweight types |
| `SecurityManager.swift` | 236 | Keychain and Secure Enclave |

## Key Naming Conventions

- **Views:** `{Feature}View.swift` → `MapView`, `FlightPlanView`
- **ViewModels:** `{Feature}ViewModel.swift` → `MapViewModel`, `WeatherViewModel`
- **Services:** Descriptive name → `WeatherService`, `ChartManager`, `LocationManager`
- **Protocols:** `{Name}Protocol` suffix → `DatabaseManagerProtocol`, `WeatherServiceProtocol`
- **Mocks:** `Mock{Name}` prefix → `MockDatabaseManager`, `MockWeatherService`
- **Placeholders:** `Placeholder{Name}` prefix → `PlaceholderWeatherService`
- **Seed data:** Regional files → `WestCoastAirports.swift`, `NortheastAirports.swift`
- **Annotation prefixes:** `APT:`, `WX:`, `NAV:` — used in MapService for annotation type identification
