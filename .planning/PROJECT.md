# OpenEFB v1.0 - Public TestFlight

## What This Is

A free, open-source VFR Electronic Flight Bag for iPad that combines moving-map navigation with flight recording and on-device AI-powered post-flight debrief. The first iOS EFB that's simultaneously free, open-source, VFR-focused, and includes integrated flight recording with AI analysis. Built from scratch on iOS 26 with modern Swift architecture.

## Core Value

A pilot can install the app, fly with it as their primary EFB, record their flight, and get an AI debrief afterward, all for free and all on-device with no account required.

## Requirements

### Validated

(None yet - ship to validate)

### Active

- [ ] Moving map with GPS ownship tracking, ground speed, altitude, vertical speed, track
- [ ] VFR sectional chart raster overlay with opacity control
- [ ] 20,000+ US airports from FAA NASR data with R-tree spatial queries
- [ ] Airport info sheet: runways, frequencies, field elevation, weather, remarks
- [ ] METAR/TAF weather with flight category color coding (VFR/MVFR/IFR/LIFR)
- [ ] Weather map dots color-coded by flight category
- [ ] Basic flight planning: departure, destination, route on map, distance/time/fuel
- [ ] Instrument strip: GS, ALT, VSI, TRK, DTG, ETE
- [ ] Nearest airport emergency feature with distance, bearing, runways, direct-to
- [ ] Live TFR display from FAA data with proximity alerts
- [ ] Airspace boundary visualization with Class B/C/D proximity alerts
- [ ] Aircraft profile: N-number, type, fuel capacity, burn rate, cruise speed, V-speeds
- [ ] Pilot profile: name, certificate, medical class/expiry, flight review date
- [ ] Map modes: VFR sectional, street map, satellite, terrain
- [ ] Layer controls: airspace, TFRs, airports, navaids, weather on/off
- [ ] Airport/navaid search by identifier, name, city
- [ ] One-tap flight recording: GPS track + cockpit audio + transcription
- [ ] Auto-start recording when ground speed exceeds threshold
- [ ] Cockpit-optimized audio engine (6+ hour recording, configurable quality)
- [ ] Real-time speech-to-text with aviation vocabulary processing
- [ ] Automatic flight phase detection (preflight through postflight)
- [ ] On-device AI post-flight debrief via Apple Foundation Models
- [ ] Structured debrief: narrative summary, observations by phase, improvements, rating
- [ ] Digital logbook with entries auto-populated from recording data
- [ ] Currency tracking: medical expiry, flight review, night landings (61.57)
- [ ] Track replay: playback on map with synchronized audio and transcript
- [ ] Offline-capable: bundled airport DB, downloaded chart tiles, cached weather
- [ ] Background location for in-flight recording
- [ ] Network reachability monitoring with graceful degradation
- [ ] Public TestFlight distribution

### Out of Scope

- Claude API premium debrief tier - validate on-device debrief first, add cloud tier after TestFlight feedback
- IFR procedures (approach plates, SIDs/STARs) - VFR-focused product
- ADS-B traffic/weather display - requires external hardware integration
- Weight & balance calculator - defer to future milestone
- Multi-leg routing with per-leg calculations - direct-to is sufficient for v1
- CFI/student mode - defer until pilot adoption validates demand
- ForeFlight CSV import/export - defer to post-TestFlight
- Community PIREPs - requires server infrastructure
- NEXRAD radar overlay - significant complexity, defer
- Radio coach AI training mode - defer to future milestone
- CloudKit sync - build the foundation but don't enable for v1

## Context

### Fresh Start Decision

The existing codebase (61 Swift files, Feb 2026) was built in 3 weeks by parallel agents targeting iOS 26 but using `ObservableObject` + `@Published` + Combine sink chains. Assessment found:
- AppState is a god object holding 6+ concerns
- Map rendering uses individual annotations (performance cliff at 20K airports)
- `@unchecked Sendable` on 6+ types bypasses compiler concurrency checks
- 3,700 airports baked as Swift literal files (compile-time cost, binary bloat)
- WeatherService.cachedWeather() always returns nil
- MapService has no protocol (untestable)
- 60%+ of code would need rewriting for iOS 26 best practices anyway

Decision: Fresh start with iOS 26 `@Observable` architecture, cherry-picking proven domain code (GRDB spatial query patterns, NOAA weather API client, aviation domain models).

### SFR as Recording Spec

Sovereign Flight Recorder (42 files, 8,396 LOC) provides the design spec for the recording engine, not code to import. SFR targets iOS 17 with Core Data; OpenEFB targets iOS 26 with GRDB + SwiftData. Key algorithms and thresholds from SFR (GPS adaptive sampling, audio quality profiles, flight phase detection hysteresis, aviation vocabulary processor patterns) transfer as design knowledge.

### Apple Foundation Models (Available)

iOS 26.3 shipping, SDK confirmed in Xcode 26.0.1. Confirmed APIs:
- `@Generable` macro for compile-time structured output schemas
- `@Guide` macro for property constraints
- `LanguageModelSession` for multi-turn, Observable, streaming
- `PartiallyGenerated<T>` for streaming partial structured output
- `Transcript` (Codable) for persisting/resuming conversations
- `session.prewarm()` for responsive generation
- Text-only (no multimodal), single concurrent request, context window tested empirically

### Data Strategy

- **Airports:** Pre-built SQLite database with 20K+ NASR airports bundled with app. No on-device parsing.
- **Chart tiles:** Server-side pipeline (GeoTIFF to MBTiles via GDAL), hosted on Cloudflare R2 CDN. Device downloads ready-to-use tiles.
- **Weather:** NOAA Aviation Weather API (free, no key). 15-min METAR cache, 1-hr TAF cache.
- **TFRs:** Live FAA TFR data replacing current stub implementation.
- **User data:** SwiftData for profiles, flights, settings (CloudKit-ready foundation, not enabled).

### Target Audience

Public TestFlight beta. VFR GA pilots, 50-150 hrs/year, iPad in cockpit. Must work across diverse aircraft, airports, and regions, not just Bay Area.

## Constraints

- **Platform:** iPad, iOS 26.0+, Swift 6.0+, SwiftUI
- **Architecture:** @Observable + actors + structured concurrency. No ObservableObject.
- **Map engine:** MapLibre Native iOS (only option supporting raster tile overlays for VFR sectionals)
- **Database:** GRDB (aviation data with R-tree/FTS5) + SwiftData (user data, CloudKit-ready)
- **AI:** Apple Foundation Models only (no cloud dependency for v1)
- **Privacy:** Zero cloud dependency for core features. No account required. On-device processing.
- **License:** MPL-2.0 (open source)
- **Bundle ID:** quartermint.efb-212
- **Chart hosting:** Requires CDN infrastructure (Cloudflare R2) for pre-processed MBTiles
- **TestFlight:** Requires Apple Developer account, app review compliance

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Fresh start over refactor | 60%+ of existing code needed rewriting; iOS 26 @Observable changes app layer fundamentally | - Pending |
| Build recording native, SFR as spec | SFR targets iOS 17/Core Data, incompatible concurrency model; algorithms transfer as design knowledge | - Pending |
| Bundle SQLite over SwiftNASR | Faster launch, simpler, works offline immediately. SwiftNASR is correct long-term but adds first-launch complexity | - Pending |
| Server-side chart pipeline | On-device GeoTIFF conversion is complex and slow. CDN serves ready-to-use MBTiles | - Pending |
| Foundation Models only, no Claude API | Validate on-device debrief quality first. Add premium cloud tier based on TestFlight feedback | - Pending |
| @Observable over ObservableObject | iOS 26 target makes @Observable the right default. Cleaner state management, less boilerplate | - Pending |
| GeoJSON sources over annotations | Supports 20K+ airports without performance degradation. Clustering built-in | - Pending |
| Public TestFlight (not private) | Broader testing validates the product for diverse pilots, aircraft, and regions | - Pending |

---
*Last updated: 2026-03-20 after initialization*
