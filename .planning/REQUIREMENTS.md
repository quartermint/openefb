# Requirements: OpenEFB v1.0

**Defined:** 2026-03-20
**Core Value:** A pilot can install the app, fly with it as their primary EFB, record their flight, and get an AI debrief afterward, all for free and all on-device with no account required.

## v1 Requirements

Requirements for public TestFlight launch. Each maps to roadmap phases.

### Navigation

- [ ] **NAV-01**: Pilot sees their GPS position on the map with heading indicator updated in real time
- [ ] **NAV-02**: Pilot can overlay VFR sectional charts on the map with adjustable opacity
- [ ] **NAV-03**: Pilot sees instrument strip showing GS (kts), ALT (ft MSL), VSI (fpm), TRK (degrees), DTG (nm), ETE
- [ ] **NAV-04**: Pilot can switch between map modes: VFR sectional, street, satellite, terrain
- [ ] **NAV-05**: Pilot can toggle map layers on/off: airspace, TFRs, airports, navaids, weather
- [ ] **NAV-06**: Pilot can find nearest airports sorted by distance with bearing, runways, and direct-to navigation
- [ ] **NAV-07**: App tracks GPS position in background when screen is off or another app is in foreground

### Aviation Data

- [ ] **DATA-01**: App contains 20,000+ US airports from FAA NASR data queryable by spatial proximity (R-tree)
- [ ] **DATA-02**: Pilot can tap any airport to see info sheet: runways (length/width/surface), frequencies, elevation, weather, remarks
- [ ] **DATA-03**: Pilot can search airports and navaids by ICAO identifier, name, or city
- [ ] **DATA-04**: Pilot sees Class B, C, D airspace boundaries rendered on the map with floor/ceiling labels
- [ ] **DATA-05**: App displays live TFR polygons from FAA data on the map
- [ ] **DATA-06**: App alerts pilot when approaching Class B/C/D airspace or active TFR

### Weather

- [ ] **WX-01**: Pilot can view current METAR and TAF for any airport with flight category color coding (VFR/MVFR/IFR/LIFR)
- [ ] **WX-02**: Map displays color-coded weather dots at reporting stations by flight category
- [ ] **WX-03**: All weather data displays age/staleness badge showing time since observation

### Flight Planning

- [ ] **PLAN-01**: Pilot can create a flight plan with departure, destination, and route displayed on map
- [ ] **PLAN-02**: Flight plan shows distance (nm), estimated time, and estimated fuel burn
- [ ] **PLAN-03**: Pilot can store aircraft profile: N-number, type, fuel capacity, burn rate, cruise speed, V-speeds
- [ ] **PLAN-04**: Pilot can store pilot profile: name, certificate number, medical class/expiry, flight review date

### Recording

- [ ] **REC-01**: Pilot can start/stop flight recording with one tap, capturing GPS track and cockpit audio simultaneously
- [ ] **REC-02**: Recording auto-starts when ground speed exceeds configurable threshold (default 15 kts)
- [ ] **REC-03**: Audio engine records cockpit audio for 6+ hours with configurable quality profiles
- [ ] **REC-04**: App performs real-time speech-to-text with aviation vocabulary post-processing (N-numbers, altitudes, headings, frequencies, runways)
- [ ] **REC-05**: App automatically detects flight phases: preflight, taxi, takeoff, departure, cruise, approach, landing, postflight

### AI Debrief

- [ ] **DEBRIEF-01**: After flight, app generates structured debrief on-device via Apple Foundation Models: narrative summary, per-phase observations, improvements, overall rating
- [ ] **DEBRIEF-02**: Flight data is compressed into a summary under 3,000 tokens before debrief generation (4,096 context window constraint)
- [ ] **DEBRIEF-03**: App gracefully degrades when Foundation Models is unavailable (unsupported device, Apple Intelligence disabled) with clear user messaging

### Logbook & Currency

- [ ] **LOG-01**: App maintains a digital logbook with entries auto-populated from recording: date, departure, arrival, route, duration, aircraft
- [ ] **LOG-02**: Pilot can review and edit auto-populated logbook entries before confirming
- [ ] **LOG-03**: App tracks pilot currency: medical expiry, flight review date, 61.57 night passenger-carrying (3 T/O + landings in 90 days)
- [ ] **LOG-04**: App displays currency warnings when medical, flight review, or 61.57 requirements are approaching expiry

### Track Replay

- [ ] **REPLAY-01**: Pilot can replay recorded flight on the map with position marker following the GPS track
- [ ] **REPLAY-02**: Track replay synchronizes with cockpit audio playback and scrolling transcript timeline

### Infrastructure

- [ ] **INFRA-01**: App works offline with bundled airport database, pre-downloaded chart tiles, and cached weather data
- [ ] **INFRA-02**: App monitors network reachability and clearly indicates when operating with cached/stale data
- [ ] **INFRA-03**: Chart tiles are served from CDN with 56-day FAA cycle expiration metadata; app warns when charts are expired
- [ ] **INFRA-04**: App includes privacy manifest compliant with App Store requirements
- [ ] **INFRA-05**: App is distributed via public TestFlight

## v2 Requirements

Deferred to post-TestFlight validation. Tracked but not in current roadmap.

### Premium Debrief

- **PREMIUM-01**: Enhanced debrief via Claude API for complex or long flights exceeding Foundation Models capability

### Data Portability

- **PORT-01**: Export flight tracks to GPX/KMZ format
- **PORT-02**: Import ForeFlight track logs for historical debrief
- **PORT-03**: Enable CloudKit sync for multi-device access (foundation built in v1)

### Extended Features

- **EXT-01**: Display FAA PIREP data from NOAA API on map
- **EXT-02**: Multi-leg route planning with per-leg fuel/time calculations

## Out of Scope

| Feature | Reason |
|---------|--------|
| IFR approach plates (SIDs/STARs/Jeppesen) | VFR-focused product; doubles scope for zero differentiation vs ForeFlight |
| ADS-B traffic/weather display | Requires external hardware; contradicts no-hardware-required value |
| NEXRAD radar overlay | Requires ADS-B hardware or internet (fails in-flight); stale data risk |
| Weight & balance calculator | Requires aircraft-specific loading envelopes; 6-month project on its own |
| Community PIREPs submission | Requires server infrastructure, accounts, moderation |
| Social/sharing/leaderboards | Requires server; violates privacy-first, no-account value |
| CFI/student mode | Essentially a second product; validate pilot demand first |
| Radio coach AI training | Ambitious; validate debrief quality first |
| ForeFlight CSV import/export | Format changes frequently; maintenance burden |
| Android / non-iPad platforms | iOS first; expand if adoption warrants |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| NAV-01 | Phase 1 | Pending |
| NAV-02 | Phase 1 | Pending |
| NAV-03 | Phase 1 | Pending |
| NAV-04 | Phase 1 | Pending |
| NAV-05 | Phase 1 | Pending |
| NAV-06 | Phase 1 | Pending |
| NAV-07 | Phase 1 | Pending |
| DATA-01 | Phase 1 | Pending |
| DATA-02 | Phase 1 | Pending |
| DATA-03 | Phase 1 | Pending |
| DATA-04 | Phase 1 | Pending |
| DATA-05 | Phase 1 | Pending |
| DATA-06 | Phase 1 | Pending |
| WX-01 | Phase 1 | Pending |
| WX-02 | Phase 1 | Pending |
| WX-03 | Phase 1 | Pending |
| PLAN-01 | Phase 2 | Pending |
| PLAN-02 | Phase 2 | Pending |
| PLAN-03 | Phase 2 | Pending |
| PLAN-04 | Phase 2 | Pending |
| REC-01 | Phase 3 | Pending |
| REC-02 | Phase 3 | Pending |
| REC-03 | Phase 3 | Pending |
| REC-04 | Phase 3 | Pending |
| REC-05 | Phase 3 | Pending |
| DEBRIEF-01 | Phase 4 | Pending |
| DEBRIEF-02 | Phase 4 | Pending |
| DEBRIEF-03 | Phase 4 | Pending |
| LOG-01 | Phase 4 | Pending |
| LOG-02 | Phase 4 | Pending |
| LOG-03 | Phase 4 | Pending |
| LOG-04 | Phase 4 | Pending |
| REPLAY-01 | Phase 5 | Pending |
| REPLAY-02 | Phase 5 | Pending |
| INFRA-01 | Phase 1 | Pending |
| INFRA-02 | Phase 1 | Pending |
| INFRA-03 | Phase 1 | Pending |
| INFRA-04 | Phase 6 | Pending |
| INFRA-05 | Phase 6 | Pending |

**Coverage:**
- v1 requirements: 39 total
- Mapped to phases: 39
- Unmapped: 0

---
*Requirements defined: 2026-03-20*
*Last updated: 2026-03-20 — traceability filled after roadmap creation*
