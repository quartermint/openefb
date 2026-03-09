# External Integrations

## Active Integrations

### NOAA Aviation Weather API
- **Base URL:** `https://aviationweather.gov/api/data`
- **Endpoints used:**
  - `GET /metar?ids={ICAOs}&format=json` — fetch METAR observations
  - `GET /taf?ids={ICAOs}&format=json` — fetch TAF forecasts
- **Auth:** None required (free, public API)
- **Rate limit:** ~100 requests/minute
- **Caching:** In-memory (actor-isolated dictionary) + GRDB persistent cache, 15-minute TTL
- **Error handling:** Graceful degradation — returns cached data on fetch failure
- **Service:** `efb-212/Services/WeatherService.swift` (nonisolated actor)
- **Response models:** `METARResponse`, `TAFResponse` (private, nested in `WeatherService.swift`)

### OpenFreeMap Tile Server
- **URL:** `https://tiles.openfreemap.org/styles/liberty`
- **Purpose:** Base map tiles for the moving map (roads, terrain, labels)
- **Auth:** None required (free, open source)
- **Integration:** Set as `styleURL` on `MLNMapView` in `MapService.configure()`

### FAA Aeronautical Charts
- **URL pattern:** `https://aeronav.faa.gov/visual/{cycle_date}/sectional-files/{region}.zip`
- **Purpose:** VFR sectional chart raster tiles (downloaded as MBTiles)
- **Auth:** None (public domain, US government data)
- **Chart cycle:** 56-day FAA cycle, epoch January 27, 2022
- **Regions:** 15 US sectional chart regions defined in `ChartManager.availableRegions`
- **Service:** `efb-212/Services/ChartManager.swift` (nonisolated actor)
- **Validation:** SQLite header magic byte check on downloaded MBTiles files

### FAA N-Number Registry
- **URL:** `https://registry.faa.gov/AircraftInquiry/Search/NNumberResult?NNumberTxt={N}`
- **Purpose:** Aircraft registration lookup (manufacturer, model, year, engine)
- **Auth:** None (public registry)
- **Parsing:** HTML scraping via regex — extracts `data-label` fields from `<td>` elements
- **Service:** `efb-212/Services/FAALookupService.swift`

## Databases

### GRDB (Aviation Database)
- **File:** `Application Support/aviation.sqlite`
- **Mode:** WAL (Write-Ahead Logging)
- **Tables:** `airports`, `runways`, `frequencies`, `navaids`, `airspaces`, `weatherCache`
- **Virtual tables:** `airports_rtree` (R-tree spatial index), `airports_fts` (FTS5 full-text search)
- **Migrations:** v1 (airports/runways/frequencies/navaids/weather), v2 (airspaces)
- **Managed by:** `AviationDatabase` class wrapping `DatabasePool`
- **Seeded with:** ~3,700 airports + navaids + airspaces from bundled Swift data files (10 regional files)

### SwiftData (User Data)
- **Models:** `AircraftProfileModel`, `FlightRecordModel`, `PilotProfileModel`
- **Purpose:** User-created data (profiles, logged flights, settings)
- **Container:** Configured in `efb_212App.swift` via `.modelContainer(for:)`
- **CloudKit:** Prepared for optional premium sync (not yet enabled)

## iOS System APIs

| API | Purpose | Service |
|-----|---------|---------|
| CoreLocation | GPS position, speed, heading, altitude | `LocationManager.swift` |
| UIDevice.battery | Battery level and charging state monitoring | `PowerManager.swift` |
| Keychain Services | Secure storage for API tokens, encryption keys | `SecurityManager.swift` |
| Secure Enclave | 256-bit EC key generation for flight data encryption | `SecurityManager.swift` |

## Planned Integrations (Phase 2)

| Integration | Purpose | Status |
|-------------|---------|--------|
| FAA TFR API (tfr.faa.gov) | Live TFR data | Currently using stub data in `TFRService.swift` |
| SFR Flight Recording | GPS track logging, cockpit audio, transcription | Blocked on SPM package extraction |
| Apple Foundation Models | On-device AI flight debrief | Blocked on availability |
| SwiftNASR | Full FAA NASR data import (20K airports) | Not yet integrated |
