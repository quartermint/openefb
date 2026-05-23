# Phase 2: Profiles + Flight Planning - Context

**Gathered:** 2026-03-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver aircraft and pilot profile management, A→B flight planning with fuel/time calculations, and pilot currency tracking. Builds on Phase 1's AppState, SwiftData container, and aviation database. A pilot can enter their aircraft specs, create a flight plan, and check their currency before flying.

</domain>

<decisions>
## Implementation Decisions

### Profile Management
- Support multiple aircraft and pilot profiles with one "active" selection — pilots fly different aircraft, some share iPads
- Form-based editing with labeled fields, inline validation (N-number format, medical class picker, date pickers for expiry dates)
- V-speed fields (Vr, Vx, Vy, Vs0, Vs1, Vne, Vno, Vfe) are optional in aircraft profile — nice reference but not required to create a profile
- Profiles persisted in SwiftData with CloudKit-ready schema (sync disabled for v1, foundation for multi-device later)

### Flight Planning
- Route entry via airport search for departure and destination; direct line drawn on map — simple A→B per v1 scope, no intermediate waypoints
- Summary card shows distance (nm), ETE (h:mm), fuel burn (gal) calculated from active aircraft profile — all visible in one glance
- Multiple flight plans can be saved; most recent auto-loads on next launch for convenience
- Route displayed as magenta great-circle line (aviation standard) with departure/destination pins on the map

### Currency Tracking
- Currency status displayed as traffic-light badges (green/yellow/red) on pilot profile screen — green when >30 days from expiry, yellow when ≤30 days, red when expired
- Track three currency types: medical certificate expiry, flight review (24 calendar months), and 61.57 night passenger-carrying (3 takeoffs + landings in 90 days)
- Currency warning badge shown on Aircraft tab icon plus inline on profile screen — visible but not intrusive during normal use
- 61.57 night currency uses manual entry in logbook (night landing count) until Phase 4 auto-populates from flight recording data

### Claude's Discretion
- Exact form layout and field ordering for profile editing
- Aircraft type picker implementation (free text vs predefined list)
- Flight plan card positioning relative to map
- Animation for route drawing on map
- SwiftData model versioning strategy details

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `AircraftProfile.swift` — SwiftData @Model with N-number, type, fuel capacity, burn rate, cruise speed (reference for new @Observable version)
- `PilotProfile.swift` — SwiftData @Model with name, certificate, medical class/expiry, flight review date
- `FlightPlanViewModel.swift` — Distance/ETE/fuel calculation logic (cherry-pick math)
- `FlightPlanView.swift` — Departure/destination airport search UI pattern
- `AircraftDefaults.swift` — Preset aircraft configurations (C172, PA28, etc.)
- `AircraftProfileView.swift`, `PilotProfileView.swift` — Existing profile editing forms (reference)

### Established Patterns
- SwiftData @Model classes in Data/Models/
- ViewModel pattern with @Published properties for form state
- Airport search integration with AviationDatabase.searchAirports()
- Profile views in Views/Aircraft/ directory

### Integration Points
- AppState will need FlightPlanState sub-state from Phase 1
- AviationDatabase.searchAirports() for departure/destination selection
- MapService for route line rendering
- Instrument strip DTG/ETE values fed from flight plan calculations

</code_context>

<specifics>
## Specific Ideas

- AircraftDefaults should include common GA aircraft presets (C172, PA28, SR22, DA40) for quick profile setup
- Fuel burn calculation: distance / cruise speed * burn rate — simple proportional for v1 direct-to
- ETE calculation: distance / ground speed (or cruise speed if no GPS)
- Currency computation follows exact FAR 61.23 (medical), 61.56 (flight review), 61.57 (recent experience) rules

</specifics>

<deferred>
## Deferred Ideas

- Multi-leg routing with per-leg calculations (v2)
- Weight & balance calculator (v2)
- ForeFlight CSV import/export (v2)
- CloudKit sync activation (v2)

</deferred>

---
*Phase: 02-profiles-flight-planning*
*Context gathered: 2026-03-20 via Smart Discuss (autonomous)*
