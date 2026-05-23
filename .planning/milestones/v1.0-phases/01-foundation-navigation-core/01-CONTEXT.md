# Phase 1: Foundation + Navigation Core - Context

**Gathered:** 2026-03-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver a working iPad VFR EFB from a fresh Xcode project: @Observable architecture, GRDB aviation database with 20K+ airports, MapLibre moving map with VFR sectional overlay, weather service, airspace/TFR visualization, instrument strip, nearest airport emergency HUD, and offline capability. A pilot can open the app and navigate with full situational awareness.

</domain>

<decisions>
## Implementation Decisions

### Map Experience & Layout
- Initial map view shows Continental US (39°N, -98°W, zoom 5) on first launch, then animates to user's GPS position when location permission is granted and fix acquired
- Ownship indicator is an aviation chevron/triangle pointing in direction of travel, matching ForeFlight/Garmin conventions pilots expect
- Map controls (zoom, compass, layer toggle) placed on right edge for iPad landscape orientation, keeping left side clear for instrument strip
- Default VFR sectional opacity is 70% with adjustable slider, so terrain/streets remain visible underneath for orientation

### Airport Information & Search
- Airport info presented as iOS-native bottom sheet (half-height default, expandable to full) to keep map visible for spatial context
- At low zoom levels, small airports are clustered while towered airports (Class B/C/D) always remain visible to prevent clutter while keeping safety-critical airports prominent
- Single search bar supporting ICAO identifier, airport name, and city search with results as a scrollable list
- Nearest airport HUD is a persistent top-right badge showing closest airport + distance/bearing; tap to expand full sorted list with runways and direct-to option

### Weather Display
- Weather dots on map are small uniform circles color-coded by flight category: green (VFR), blue (MVFR), red (IFR), magenta (LIFR) per FAA standard
- METAR display in airport info shows decoded human-readable format as primary view (wind, visibility, ceiling, temp/dewpoint highlighted) with raw METAR expandable for experienced pilots
- Staleness indicator shows relative time ("15m ago") as text badge, yellow when >30 minutes old, red when >60 minutes old — progressive urgency
- Weather auto-refreshes with 15-minute METAR cache, auto-refresh when airport info is opened, plus manual refresh button

### Instrument Strip & Navigation HUD
- Instrument strip positioned at bottom of map view as a full-width horizontal bar — standard EFB placement
- Values displayed as large numeric values with small unit labels (e.g., "125 kts"), aviation-standard rounding (ALT to nearest 10 ft, GS to nearest 1 kt)
- When GPS is unavailable, values show dashes "---" with a subtle "No GPS" indicator — clear without being alarming
- DTG and ETE values only appear when a flight plan or direct-to is active; blank/hidden otherwise to avoid confusion when not actively navigating

### Claude's Discretion
- Specific color palette and typography choices for the instrument strip
- Animation timing for ownship position updates and map transitions
- Exact clustering zoom thresholds for airport density management
- Internal caching strategy for weather data (in-memory vs GRDB write-through)
- GeoJSON source configuration details for MapLibre layers

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `AviationModels.swift` — Airport, Runway, Frequency, Navaid, Airspace structs (domain models, cherry-pick)
- `EFBError.swift` — Centralized error enum with 13 cases, severity levels (reusable as-is)
- `AviationDatabase.swift` — GRDB setup with R-tree spatial index, FTS5 search patterns (reference for fresh implementation)
- `WeatherService.swift` — NOAA API client with METAR/TAF parsing (reference for API integration)
- `CLLocation+Aviation.swift`, `Date+Aviation.swift` — Unit conversion extensions
- `Types.swift` — FlightCategory enum, MapMode, MapLayer, PowerState enums

### Established Patterns
- Protocol-first DI: every service has a protocol (WeatherServiceProtocol, DatabaseManagerProtocol, etc.)
- `@unchecked Sendable` on database classes with nonisolated methods (GRDB handles thread safety)
- Combine PassthroughSubject for location events → sink in ViewModels
- Annotation title prefixes for map layer identification: `APT:`, `WX:`, `NAV:`
- EFBError propagation: services throw, ViewModels catch and set `lastError`

### Integration Points
- `efb_212App.swift` — App entry point, will need complete rewrite for @Observable injection
- `ContentView.swift` — TabView with 5 tabs (map, flights, logbook, aircraft, settings)
- MapLibre 6.23.0 and GRDB 7.9.0 already configured as SPM dependencies
- NOAA API (free, no key): `https://aviationweather.gov/api/data/metar` and `/taf`

</code_context>

<specifics>
## Specific Ideas

- Fresh start from blank Xcode project using iOS 26 @Observable (not ObservableObject) — existing code is reference only
- GeoJSON sources instead of individual MLNPointAnnotation for 20K+ airport rendering performance
- Bundled pre-built SQLite database (not SwiftNASR on-device parsing) for instant offline access
- Server-side chart pipeline (GeoTIFF → MBTiles via GDAL) hosted on Cloudflare R2 CDN
- Chart CDN infrastructure must be operational before Phase 1 verification can pass

</specifics>

<deferred>
## Deferred Ideas

- CloudKit sync foundation (built but not enabled until post-TestFlight)
- SwiftNASR integration for live FAA data updates (bundled SQLite is sufficient for v1)

</deferred>

---
*Phase: 01-foundation-navigation-core*
*Context gathered: 2026-03-20 via Smart Discuss (autonomous)*
