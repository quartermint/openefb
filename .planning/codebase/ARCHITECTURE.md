# Architecture

## Pattern: MVVM + Combine + SwiftUI

The app follows a strict MVVM pattern with protocol-based dependency injection and Combine for reactive data flow.

### Layer Diagram

```
┌─────────────────────────────────────────────┐
│  Views (SwiftUI)                            │
│  Map/ Planning/ Flights/ Logbook/ Settings/ │
├─────────────────────────────────────────────┤
│  ViewModels (@MainActor, ObservableObject)  │
│  MapVM  FlightPlanVM  WeatherVM  SettingsVM │
├─────────────────────────────────────────────┤
│  AppState (@MainActor, ObservableObject)    │
│  Root coordinator — global published state  │
├─────────────────────────────────────────────┤
│  Services (actors + protocols)              │
│  WeatherService  MapService  ChartManager   │
│  LocationManager  PowerManager  Security    │
├─────────────────────────────────────────────┤
│  Data Layer                                 │
│  DatabaseManager → AviationDatabase (GRDB)  │
│                  → SwiftData (user data)    │
└─────────────────────────────────────────────┘
```

## Root State: AppState

- **File:** `efb-212/Core/AppState.swift`
- **Type:** `final class AppState: ObservableObject` (`@MainActor` by default)
- **Injection:** Injected as `.environmentObject(appState)` from `efb_212App.swift`
- **Responsibilities:**
  - Navigation state (selected tab, airport selection, sheet presentation)
  - Map state (center, zoom, mode, visible layers, sectional opacity)
  - Location/ownship state (position, ground speed, altitude, vertical speed, track)
  - Recording state (Phase 2 stub: isRecording, duration, flight phase)
  - Flight plan state (active plan, distance to next, ETE)
  - System state (battery level, power state, GPS availability, network)
- **Services held:** `locationManager`, `databaseManager`, `weatherService` (protocol-typed), `powerManager` (concrete)
- **Communication:** Subscribes to `locationManager.locationPublisher` and `powerManager.$batteryLevel` via Combine

## Dependency Injection

All services are injected via **protocols** defined in `efb-212/Core/Protocols.swift`:

| Protocol | Conformers | Sendability |
|----------|-----------|-------------|
| `DatabaseManagerProtocol` | `DatabaseManager`, `PlaceholderDatabaseManager`, `MockDatabaseManager` | `Sendable` |
| `LocationManagerProtocol` | `LocationManager`, `PlaceholderLocationManager`, `MockLocationManager` | `AnyObject` |
| `WeatherServiceProtocol` | `WeatherService`, `PlaceholderWeatherService`, `MockWeatherService` | `Sendable` |
| `TFRServiceProtocol` | `TFRService`, `PlaceholderTFRService`, `MockTFRService` | `Sendable` |
| `NetworkManagerProtocol` | (not yet implemented) | `Sendable` |
| `AudioManagerProtocol` | (Phase 2 stub) | `AnyObject` |

**Pattern:** Production → `efb_212App.init()` creates real services. Tests → `MockDatabaseManager`, `MockWeatherService`, etc. Stubs → `Placeholder*` classes for UI previews.

## Concurrency Model

The project uses `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, meaning:

- **All types default to `@MainActor`** unless explicitly opted out
- **ViewModels:** `@MainActor` by default (correct for ObservableObject)
- **Actors:** `WeatherService`, `ChartManager`, `TFRService`, `SecurityManager` use `nonisolated actor` to opt out of MainActor and get actor isolation instead
- **Database classes:** `AviationDatabase` and `DatabaseManager` are `final class ... @unchecked Sendable` with `nonisolated` methods, since GRDB handles its own thread safety via `DatabasePool`
- **CLLocationManagerDelegate:** Callbacks use `MainActor.assumeIsolated { }` to bridge the nonisolated delegate methods back to MainActor

## Data Flow

### Location → Map Update
```
CLLocationManager → LocationManager.processLocation()
  → locationSubject.send(location)    [Combine PassthroughSubject]
  → AppState.subscribeToLocationUpdates()  [receives via sink]
    → updates ownshipPosition, groundSpeed, altitude, track, verticalSpeed
  → MapViewModel.subscribeToLocationUpdates()  [receives via sink]
    → MapService.updateOwnship()
```

### Region Change → Airport Reload
```
User pans/zooms map
  → MLNMapViewDelegate.regionDidChangeAnimated
  → MapService notifies MapServiceDelegate
  → MapViewModel.mapService(_:didChangeRegion:zoom:)
    → loadAirportsForRegion(center:radiusNM:)
      → DatabaseManager.airports(near:radiusNM:)  [R-tree query]
      → MapService.addAirportAnnotations()
      → loadWeatherForVisibleAirports()  [if weather layer active]
      → loadTFRsForRegion()             [if TFR layer active]
      → loadAirspacesForRegion()        [if airspace layer active]
```

### Weather Fetch → Map Dots
```
MapViewModel.loadWeatherForVisibleAirports()
  → WeatherService.fetchWeatherForStations()
    → NOAA API GET /metar?ids=...
    → Parse METARResponse → WeatherCache
    → In-memory cache + GRDB write-through
  → MapService.addWeatherDots()
    → MLNPointAnnotation with "WX:{station}:{category}" title
    → Color-coded by FlightCategory (green/blue/red/magenta)
```

## Entry Points

- **App entry:** `efb-212/efb_212App.swift` — `@main struct efb_212App: App`
- **Root view:** `efb-212/ContentView.swift` — TabView with 5 tabs (map, flights, logbook, aircraft, settings)
- **Database init:** `DatabaseManager.init()` → creates/opens `aviation.sqlite`, runs migrations, loads seed data on first launch

## Key Abstractions

### MapService (UIKit Bridge)
- `efb-212/Services/MapService.swift` — wraps `MLNMapView`
- Manages all map layers: sectional overlays, airport annotations, weather dots, navaid annotations, airspace polygons, TFR overlays, route lines
- Uses annotation title prefixes for identification: `APT:`, `WX:`, `NAV:`
- Delegates region changes and airport selection to `MapServiceDelegate` (implemented by `MapViewModel`)

### AviationDatabase (Spatial Queries)
- `efb-212/Data/AviationDatabase.swift` — wraps GRDB `DatabasePool`
- R-tree spatial index for airports: bounding box queries for `airports(near:radiusNM:)` and `nearestAirports(to:count:)`
- FTS5 full-text search: `searchAirports(query:limit:)` searches ICAO, name, FAA ID
- Airspace containment: bounding box pre-filter + ray-casting point-in-polygon for polygons, distance check for circles
- All methods are `nonisolated` (GRDB handles thread safety)

### PowerManager (Adaptive Degradation)
- Three power states: `normal` (full), `batteryConscious` (<20%), `emergency` (<10%)
- Each state defines GPS update interval, map FPS target, weather refresh interval
- LocationManager adjusts `desiredAccuracy` and `distanceFilter` based on power state
