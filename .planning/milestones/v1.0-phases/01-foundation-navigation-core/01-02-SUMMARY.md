---
phase: 01-foundation-navigation-core
plan: 02
subsystem: database
tags: [grdb, sqlite, rtree, fts5, spatial-queries, aviation-data, nasr]

# Dependency graph
requires:
  - phase: 01-01
    provides: "Aviation domain models (Airport, Runway, Frequency, Navaid, Airspace), DatabaseServiceProtocol, EFBError"
provides:
  - "AviationDatabase GRDB wrapper with R-tree spatial queries, FTS5 full-text search, point-in-polygon containment"
  - "DatabaseManager implementing DatabaseServiceProtocol"
  - "Bundled aviation.sqlite with 522 airports, runways, frequencies, navaids, airspaces"
  - "NASR importer CLI tool for regenerating aviation database"
affects: [01-03, 01-04, 01-05, all-map-and-search-features]

# Tech tracking
tech-stack:
  added: [GRDB DatabasePool, SQLite R-tree, SQLite FTS5]
  patterns: ["Copy-on-first-launch from bundle to Application Support", "R-tree bounding box expansion for spatial proximity", "FTS5 prefix matching with * wildcard", "Ray-casting point-in-polygon for airspace containment", "Haversine great-circle distance sorting", "@unchecked Sendable with nonisolated methods for GRDB thread safety"]

key-files:
  created:
    - efb-212/Data/AviationDatabase.swift
    - efb-212/Data/DatabaseManager.swift
    - efb-212/Resources/aviation.sqlite
    - tools/nasr-importer/Package.swift
    - tools/nasr-importer/Sources/main.swift
  modified: []

key-decisions:
  - "AviationDatabase uses DatabasePool (not DatabaseQueue) for concurrent reads with WAL mode"
  - "Copy-on-first-launch to Application Support/efb-212/ subdirectory for write access"
  - "nearestAirports uses expanding radius strategy (25nm, doubling to 200nm max) rather than ORDER BY distance"
  - "Bundled DB uses DELETE journal mode; app opens with WAL mode for runtime performance"
  - "Seed database approach (522 airports) sufficient for Phase 1; full 20K NASR import deferred"
  - "Airspace bounding boxes stored in schema columns (min_lat, max_lat, min_lon, max_lon) for R-tree"

patterns-established:
  - "GRDB spatial query pattern: bounding box via R-tree INNER JOIN, then great-circle distance sort"
  - "FTS5 search pattern: append * for prefix matching, ORDER BY rank for relevance"
  - "Airspace containment: R-tree filter + ray-casting point-in-polygon for polygons, Haversine for circles"
  - "Airport detail loading: basic query without runways/frequencies for list performance, full JOIN for detail view"
  - "Database seeding: Swift CLI tool in tools/ directory generates bundled resources"

requirements-completed: [DATA-01, DATA-02, DATA-03, DATA-04]

# Metrics
duration: 14min
completed: 2026-03-21
---

# Phase 01 Plan 02: Aviation Database Summary

**GRDB aviation database with R-tree spatial queries, FTS5 search, 522 bundled airports, and NASR importer tool**

## Performance

- **Duration:** 14 min
- **Started:** 2026-03-21T01:52:20Z
- **Completed:** 2026-03-21T02:06:58Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Built AviationDatabase GRDB wrapper with DatabasePool, copy-on-first-launch pattern, WAL mode, R-tree spatial indexes, and FTS5 full-text search
- Created DatabaseManager implementing DatabaseServiceProtocol with all 6 query methods delegating to AviationDatabase
- Built NASR importer CLI tool that generates aviation.sqlite with 522 airports (30 Class B, 9 Bay Area GA, 150+ state airports, 300+ grid GA), 34 navaids, and 45 airspaces
- Verified R-tree spatial queries (Bay Area bounding box returns 7 airports), FTS5 search ("palo*" returns KPAO), and DELETE journal mode for bundle safety

## Task Commits

Each task was committed atomically:

1. **Task 1: AviationDatabase GRDB wrapper and DatabaseManager** - `0ee9570` (feat)
2. **Task 2: NASR importer tool and bundled aviation.sqlite** - `d258899` (feat)

## Files Created/Modified

- `efb-212/Data/AviationDatabase.swift` - GRDB DatabasePool wrapper with R-tree spatial queries, FTS5 search, point-in-polygon containment, Haversine distance sorting
- `efb-212/Data/DatabaseManager.swift` - DatabaseServiceProtocol implementation delegating to AviationDatabase
- `efb-212/Resources/aviation.sqlite` - Pre-built 360KB database with 522 airports, 522 runways, 733 frequencies, 34 navaids, 45 airspaces
- `tools/nasr-importer/Package.swift` - SPM package for the database generator tool (macOS 14+, GRDB dependency)
- `tools/nasr-importer/Sources/main.swift` - CLI that creates schema, inserts seed data, builds R-tree and FTS5 indexes
- `tools/nasr-importer/Package.resolved` - Pinned GRDB dependency version

## Decisions Made

- **DatabasePool over DatabaseQueue:** Used DatabasePool for concurrent reads (multiple map layers querying simultaneously). WAL mode enables reader-writer concurrency.
- **Application Support subdirectory:** Copy database to `Application Support/efb-212/aviation.sqlite` rather than flat Application Support to avoid namespace collisions.
- **Expanding radius for nearestAirports:** Start at 25 NM, double until count met (max 200 NM). More efficient than sorting entire database by distance.
- **Seed database (522 airports) for Phase 1:** Full 20K NASR import deferred -- the schema and query layer are identical regardless of data volume. 522 airports covers all towered airports and provides spatial coverage across CONUS.
- **Airspace circular approximation:** Class B/C airspaces represented as circles (center + radius) rather than complex polygons for Phase 1. The schema supports both polygon and circle geometries.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None. The seed database has fewer airports than the target 20K, but this is documented in the plan as acceptable for Phase 1. The schema and query infrastructure supports the full dataset.

## Next Phase Readiness

- AviationDatabase and DatabaseManager ready for injection into AppState and ViewModels
- R-tree spatial queries ready for map view airport loading (airports near visible region)
- FTS5 search ready for airport search bar
- Point-in-polygon ready for airspace proximity alerts
- nearestAirports ready for emergency HUD nearest airport feature

## Self-Check: PASSED

All 5 key files verified present. Both task commits (0ee9570, d258899) verified in git log.

---
*Phase: 01-foundation-navigation-core*
*Completed: 2026-03-21*
