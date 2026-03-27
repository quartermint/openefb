# OpenEFB — Open-Source iPad VFR Electronic Flight Bag

## Project Overview

- **Product:** Free, open-source VFR EFB for iPad — moving-map navigation + flight recording + AI debrief
- **Bundle ID:** quartermint.efb-212
- **Target:** iPad, iOS 26.0, Swift 5.0+, SwiftUI
- **License:** MPL-2.0
- **Full product specification:** See `PRD.md` in this directory (source of truth for ALL product decisions)

## Architecture

- **Pattern:** MVVM + Combine + SwiftUI
- **State:** `@MainActor AppState` as root `ObservableObject` — global coordinator holding `NavigationState`, `MapState`, `RecordingState`, `FlightPlanState`
- **Data:** Dual database — GRDB for aviation data (airports, airspace, navaids — needs R-tree spatial indexes, 20K+ records, WAL mode), SwiftData for user data (profiles, flights, settings — CloudKit-ready for premium sync)
- **Map:** MapLibre Native iOS (`MLNMapView`) with raster tile overlays for VFR sectional charts
- **Concurrency:** Actors for managers (`ChartManager`, `SecurityManager`), `@MainActor` for ViewModels
- **Communication:** Services communicate via Combine publishers, not direct references
- **Testability:** All services injected via protocols — every service has a corresponding protocol

## Build & Run

```bash
# Open in Xcode
open efb-212.xcodeproj

# Build and run (Xcode)
# Select iPad simulator or connected device → Cmd+R

# Run tests
# Cmd+U in Xcode, or:
xcodebuild test -scheme efb-212 -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)'

# Clean build
xcodebuild clean build -scheme efb-212
```

## File Organization

```
efb-212/
├── App/
│   └── efb_212App.swift          # App entry point, scene setup
├── Views/
│   ├── Map/                       # Moving map, instrument strip, airport info
│   ├── Planning/                  # Flight plan creation/editing
│   ├── Flights/                   # Flight list, detail, debrief, replay
│   ├── Logbook/                   # Digital logbook
│   ├── Aircraft/                  # Aircraft + pilot profiles
│   ├── Settings/                  # App settings, chart downloads
│   └── Components/                # Reusable UI components (badges, dots, search)
├── ViewModels/                    # One ViewModel per major view
├── Services/                      # Business logic, API clients, managers
├── Data/
│   ├── AviationDatabase.swift     # GRDB — airports, navaids, airspace
│   ├── DatabaseManager.swift      # Protocol + coordinator
│   └── Models/                    # SwiftData @Model classes (user data)
├── Core/
│   ├── AppState.swift             # Root state coordinator
│   ├── EFBError.swift             # Centralized error types
│   ├── DeviceCapabilities.swift   # Device detection (GPS, cellular, screen)
│   └── Extensions/                # Swift extensions
└── Resources/
    └── Assets.xcassets/
```

## Naming Conventions

| Type | Convention | Example |
|------|-----------|---------|
| Views | PascalCase + "View" suffix | `MapView.swift` |
| ViewModels | PascalCase + "ViewModel" suffix | `MapViewModel.swift` |
| Services | PascalCase descriptive name | `WeatherService.swift`, `ChartManager.swift` |
| Protocols | PascalCase + "Protocol" suffix | `DatabaseManagerProtocol` |
| Actors | PascalCase descriptive name | `SecurityManager`, `ChartManager` |
| Files | Match primary type name | `MapViewModel.swift` contains `MapViewModel` |
| Aviation units | Always documented in comments | `// knots`, `// feet MSL`, `// degrees true` |

## Key Dependencies

| Package | Purpose | Add via |
|---------|---------|---------|
| **MapLibre Native iOS** | Map rendering with raster tile overlay support | SPM: `maplibre/maplibre-gl-native-distribution` |
| **SwiftNASR** | FAA airport/navaid data parsing (20K US airports) | SPM |
| **GRDB.swift** | SQLite with R-tree spatial indexes for aviation data | SPM: `groue/GRDB.swift` |
| **SFR Packages** | Flight recording (GPS, audio, transcription, debrief) | Local SPM: `~/sovereign-flight-recorder/` |
| **NOAA Aviation Weather API** | METAR/TAF/PIREP/TFR data | REST API — free, no key, 100 req/min |

## Development Standards

- All ViewModels are `@MainActor`
- All manager/service actors use Swift concurrency (`async/await`)
- Protocol-first design for testability (every service has a protocol)
- Test coverage targets: >80% for services, >60% for ViewModels
- No force unwraps (`!`) in production code
- All aviation units documented in comments (knots, feet MSL, degrees true, nautical miles, etc.)
- Errors use the centralized `EFBError` enum conforming to `LocalizedError`
- Weather data always displays age/staleness badges
- Chart data always displays expiration status

## Critical Files

| File | Role |
|------|------|
| `PRD.md` | **Source of truth** — full product spec, architecture, data models, sprint plan |
| `CLAUDE.md` | This file — agent instructions and project conventions |
| `efb_212App.swift` | App entry point (will hold AppState injection) |
| `Core/AppState.swift` | Global state coordinator — modify with care, shared across all views |
| `Data/AviationDatabase.swift` | GRDB aviation database — airports, navaids, airspace |
| `Data/DatabaseManager.swift` | Database protocol + coordinator for dual-DB architecture |
| `Services/MapService.swift` | MapLibre integration — chart layers, airspace, ownship |

## SFR Code Reuse

- **Source:** `~/sovereign-flight-recorder/` (7,000+ LOC, 35 Swift files)
- **Will be extracted into SPM packages:** SFRCore, SFRAudio, SFRGPS, SFRTranscription, SFRDebrief, SFRCompliance, SFRSecurity, SFRExport
- **Key reusable components:**
  - `Flight` model + all nested types (TrackPoint, TranscriptSegment, DebriefSummary, etc.)
  - `TrackLogRecorder` — GPS engine with adaptive sampling, airborne detection
  - `CockpitAudioEngine` — 6+ hour cockpit recording with quality profiles
  - `AviationVocabularyProcessor` — speech-to-text post-processing for aviation terms
  - `FlightManager` — recording lifecycle state machine
  - `ComplianceModels` — PilotProfile, AircraftProfile, currency checks
- **See PRD.md Section 10** for the full extraction plan and dependency graph
- **Modifications needed:** Add `public` access modifiers, extend AircraftProfile with V-speeds/fuel, extend PilotProfile with certificate type/ratings

## Agent Team Guidelines

### Working with the PRD

- **PRD.md is the single source of truth** for all product decisions, data models, and architecture
- **Section 8.5** has implementation-level architecture with code patterns — use these as starting points
- **Section 18** has sprint breakdown — work sprint-by-sprint in order (1→2→3→4→5→6)
- **Section 19** has visual verification — check each component against criteria before marking done

### Sprint Execution

- Each agent should own **1 sprint** or **1 vertical slice** (e.g., "map layer" or "weather service")
- Sprint dependencies are explicit — don't start Sprint N+1 until Sprint N's foundations are solid
- **Avoid modifying AppState without coordinating** — it's shared state, changes affect everything
- Run tests after every significant change
- Commit after each sprint completion with descriptive message

### Agent Specialization

| Agent Role | Focus Area | Key Files |
|------------|-----------|-----------|
| **Foundation** | AppState, models, database schema, project structure | Core/, Data/, Package dependencies |
| **Map** | MapLibre integration, tile rendering, layers, ownship | Views/Map/, Services/MapService.swift |
| **Aviation Data** | SwiftNASR, airport DB, search, spatial queries | Data/AviationDatabase.swift, SwiftNASR integration |
| **Weather** | NOAA API, METAR/TAF, caching, map dots | Services/WeatherService.swift, ViewModels/WeatherViewModel |
| **Planning** | Flight plans, route rendering, instrument strip | Views/Planning/, ViewModels/FlightPlanViewModel |
| **Recording** | SFR integration, EFBRecordingCoordinator | Services/EFBRecordingCoordinator.swift |

### Coordination Rules

1. One agent owns `AppState.swift` — others propose changes via PR/review
2. Database schema changes must be reviewed (affects all data consumers)
3. Service protocol changes require updating both the protocol and all mocks
4. New SPM dependencies require updating the Xcode project file
5. Visual verification (Section 19) is required before any sprint is "done"

## Current State (as of 2026-03)

**Status:** Active development — Sprint 1-3 complete
**Last Active:** February 2026
**Built:** 61 Swift files, 215+ tests, 3,700 airports seeded. Moving map with VFR sectional overlay, airport database with R-tree spatial queries, METAR/TAF weather service, nearest airport emergency HUD, flight planning, instrument strip, airspace boundaries, TFR service.
**Next:** Phase 2 — blocked on SFR package extraction (flight recording) and Apple Foundation Models (AI debrief)

## Known Issues

- Phase 2 depends on extracting SFR code into reusable SPM packages (not yet done)
- Apple Foundation Models availability for on-device AI debrief TBD
- SFR code reuse requires adding `public` access modifiers to extracted packages

## Ecosystem Role

- **Tier:** T1 / Perception
- **Produces:** Flight telemetry and navigation data (local SwiftData)
- **Vault pipeline:** Not yet connected to lifevault
- **Throughline ref:** See ~/throughline/architecture/data-flows.md
