# Feature Research

**Domain:** iPad VFR Electronic Flight Bag with integrated flight recording and AI debrief
**Researched:** 2026-03-20
**Confidence:** HIGH (verified against ForeFlight, Garmin Pilot, WingX, FltPlan Go, AvNav, CloudAhoy, and pilot community forums)

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features pilots assume exist in any EFB. Missing one = app feels unfinished, pilots return to ForeFlight.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Moving map with GPS ownship | Every EFB since 2010 has this. Pilots won't launch without position on map. | MEDIUM | MapLibre + CLLocationManager. Background location required. |
| VFR sectional chart overlay | It's in the name — VFR pilot's primary navigation reference. All competitors provide this. | HIGH | Requires CDN tile pipeline (GeoTIFF → MBTiles). MapLibre raster layer. |
| 20K+ US airport database | Pilots tap any airport dot for info. Missing airports = app is broken. | MEDIUM | Bundle SQLite (GRDB + FTS5). FAA NASR data, 28-day AIRAC cycle. |
| Airport info: runways, frequencies, elevation, remarks | Standard content from A/FD. ForeFlight, Garmin, WingX all provide this. | LOW | Data bundled from NASR. Sheet presentation. |
| METAR/TAF with flight category color coding | Weather is the primary pre-flight go/no-go decision tool for VFR pilots. | MEDIUM | NOAA Aviation Weather API, free, no key. VFR/MVFR/IFR/LIFR colors. |
| Weather dots on map (color by flight category) | Pilots need at-a-glance visual weather across their route. Standard since ~2012. | MEDIUM | Place GeoJSON source on MapLibre, color by raw or METAR derived category. |
| Airspace boundary visualization | Class B/C/D and MOA displayed on sectionals, but app must render altitude floors/ceilings clearly. | HIGH | GRDB spatial queries. FAA NASR airspace data. MapLibre polygon layers. |
| TFR display | Presidential TFRs = certificate suspension if violated. Pilots expect live TFR data. | MEDIUM | FAA TFR API. Polygon rendering. Alert when route intersects. |
| Basic flight planning: departure, destination, route | Pilots need to plan, not just navigate. Even free apps (FltPlan Go) provide this. | MEDIUM | Simple waypoint chain. Distance, time, fuel estimations. |
| Instrument strip / data bar | GS, ALT, TRK, VSI at a glance during flight. Every cockpit-focused EFB has one. | LOW | Overlay view on map. Data from CLLocation. |
| Airport and navaid search | Pilots search by identifier (KSFO), name, or city. Standard. | LOW | FTS5 full-text search on bundled GRDB. |
| Layer controls (on/off for airspace, TFR, weather, airports) | Map gets cluttered. Pilots need to declutter. All apps provide toggle controls. | LOW | Simple state flags driving MapLibre source visibility. |
| Map mode selector | Sectional, satellite, terrain, street. Satellite useful for unfamiliar airports. | LOW | MapLibre style switching. |
| Offline capability | Cockpit has no cell service at altitude, or in rural areas. Must work offline. | HIGH | Bundle airport DB. Pre-download chart tiles. Cache METAR at preflight. |
| Background location (in-flight use) | App must track position when screen is off or another app is in foreground. | MEDIUM | iOS Background Modes: location. Requires justification for App Store. |
| Nearest airport / emergency feature | Memory item: engine failure → nearest airport. ForeFlight, Garmin both highlight glide-range airports. | MEDIUM | R-tree spatial query by current location. Sort by distance. Direct-to bearing. |
| Aircraft profile (type, speeds, fuel) | Needed for flight planning calculations (time, fuel burn, V-speeds). | LOW | SwiftData model. Simple form entry. |
| Pilot profile (name, certificate, medical, flight review) | Currency tracking requires these dates. Pilots expect profile management. | LOW | SwiftData model. |
| Network degradation handling | Pilots must know when weather data is stale. All serious EFBs show data age. | LOW | Cache timestamps. Stale badges on weather overlays. |

### Differentiators (Competitive Advantage)

Features that set OpenEFB apart. No current app combines all of these, especially not for free.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Integrated flight recording (GPS + audio) | No current free EFB records cockpit audio. CloudAhoy (paid, separate app), Stratus Insight (requires hardware). OpenEFB does it natively, free. | HIGH | AVAudioSession in airplane mode. Long-duration recording. GPS adaptive sampling. |
| On-device AI post-flight debrief | No iOS EFB offers on-device AI debrief. ForeFlight Debrief is GPS-only, cloud-scored, requires Essential plan ($240/yr). CloudAhoy requires separate app + account. Zero competitors have on-device LLM debrief. | HIGH | Apple Foundation Models (iOS 26+). `@Generable` structured output. Requires transcript + track data as input. |
| Debrief narrative by flight phase | No competitor produces natural language narrative with per-phase observations. CloudAhoy gives maneuver scoring, ForeFlight gives a numeric score. OpenEFB produces human-readable insights from cockpit audio transcript + GPS. | HIGH | Depends on transcript quality. Flight phase detection must be accurate. |
| Real-time speech-to-text with aviation vocabulary | Stratus Insight does ATC transcription (requires audio cable hardware). OpenEFB does cockpit audio → text on-device, aviation vocabulary post-processing, no hardware required. | HIGH | Apple Speech framework. Custom aviation vocabulary processor. |
| Auto-start recording on takeoff | Competitors require manual recording start. Forgotten recording = no debrief. Auto-detect ground speed threshold → auto-start removes friction. | MEDIUM | CLLocation speed threshold. State machine in FlightRecordingCoordinator. |
| Automatic flight phase detection | Enables structured debrief per phase (preflight, taxi, takeoff, cruise, pattern, landing). No free EFB segments by flight phase automatically. | MEDIUM | Speed + altitude + VSI heuristics. Hysteresis to prevent thrashing. |
| Digital logbook auto-populated from recording | After landing, logbook entry is pre-filled: departure, destination, duration, date, aircraft. Pilot reviews and confirms. ForeFlight requires manual entry unless using Sentry hardware. | MEDIUM | Depends on: flight recording complete + airport ID from spatial query. |
| Currency tracking without hardware | ForeFlight currency works but requires an active subscription. OpenEFB tracks medical expiry, flight review date, 61.57 passenger-carrying currency — free, on-device, no account. | MEDIUM | SwiftData queries over logbook entries. Pure computation, no server needed. |
| Track replay with synchronized audio + transcript | CloudAhoy does 3D replay without audio. ForeFlight does map replay without audio. OpenEFB syncs GPS track playback with cockpit audio and scrolling transcript simultaneously. Unique in the market. | HIGH | Timeline synchronization between AVAudioPlayer position and CLLocation playback. |
| Free with no account required | WingX VFR is nominally free ($0.99/yr). FltPlan Go is free but requires fltplan.com account. ForeFlight free tier doesn't exist. OpenEFB: install, fly, debrief. No account, no paywall, no hardware dependency. | LOW | App architecture decision, not a feature per se. But it IS the differentiator. |
| Open source (MPL-2.0) | No major EFB is open source. Avare (Android) is open source but unmaintained. Pilots can trust OpenEFB's data handling, contribute, or self-host chart tiles. Privacy-first trust signal. | LOW | License choice, not implementation complexity. |

### Anti-Features (Commonly Requested, Often Problematic)

Features pilots or stakeholders might request that should be explicitly declined in v1.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| IFR approach plates (Jeppesen/FAA) | Pilots want one app for all flying. ForeFlight includes plates. | IFR plates require maintaining a separate chart pipeline (FAA DTPP), updating every 28 days, handling effective date logic, and compliance with FAA advisory on using EFBs as primary IFR reference. Doubles scope, zero differentiation vs ForeFlight. VFR-focused product; IFR pilots have ForeFlight. | Link to ForeFlight or Foreflight's free plate viewer. Clear scope boundary in onboarding. |
| ADS-B traffic display | Every pilot wants traffic awareness. ForeFlight/Garmin support this with Sentry/Stratus hardware. | Requires external ADS-B receiver hardware (Sentry, Stratus, GDL 39). Hardware dependency contradicts "no hardware required" core value. Traffic data via software only is not available (FAA doesn't offer FIS-B without ADS-B Out). | Educate pilots that ATC flight following provides traffic advisories. Note this as a future hardware-optional enhancement. |
| NEXRAD radar overlay | Pilots want to see real-time precipitation. ForeFlight, Garmin both provide this. | NEXRAD requires either: (a) ADS-B receiver for FIS-B NEXRAD, same hardware dependency problem, or (b) internet-based NEXRAD which fails in-flight. Either way: stale data risk in cockpit, no hardware = no NEXRAD. | Show weather station METARs color-coded on map. That's the practical VFR tool — if VFR weather is bad enough to need radar, you shouldn't be VFR. |
| Weight and balance calculator | Pilots want comprehensive pre-flight tools in one app. | W&B requires maintaining aircraft-specific loading envelopes for hundreds of aircraft types. Data must be FAA-approved for regulatory use. ForeFlight has this because they negotiated data partnerships. Building this correctly is a 6-month project on its own. | Recommend dedicated W&B apps (Avplan W&B, aircraft POH). Note as v2+ consideration. |
| Community PIREPs (pilot reports) | Pilots value real-world reports from other pilots. | Requires server infrastructure, user accounts, data moderation, and FAA regulatory compliance on pilot report submission (FAA has its own PIREP system). Building a parallel PIREP system is not valuable when FAA PIREPs are already available. | Display FAA PIREP data (available from NOAA Aviation Weather API) instead. |
| ForeFlight CSV import/export | Pilots want their logbook data portable. | ForeFlight's export format changes, requires reverse-engineering, and ForeFlight actively de-emphasizes external compatibility to lock pilots in. Supporting this creates a maintenance burden that grows with every ForeFlight update. | Export standard formats: CSV (ICAO fields), MyFlightbook format. Import via GPX for track logs. |
| Social/sharing features (flight sharing, leaderboards) | Makes app feel modern. | Requires server infrastructure, accounts, moderation. Violates core privacy-first, no-account value proposition. Scope creep that distracts from the core recording+debrief loop. | Post-flight export to GPX/KMZ for sharing via AirDrop or Files app. No server dependency. |
| Cloud sync / CloudKit enabled in v1 | Pilots want data on all their devices. | CloudKit sync requires significant testing across edge cases (conflict resolution, offline merge). Premature enablement creates subtle data corruption bugs that are hard to debug. Foundation is built; activation deferred until v2. | Build SwiftData with CloudKit-ready models, enable after TestFlight validates data model stability. |
| Multi-leg routing with per-leg fuel/time | ForeFlight has this. Some pilots fly complex cross-countries. | Adds significant UI complexity to flight planning. For v1 VFR pilots, direct-to routing plus a single fuel calculation is sufficient. Adds 4-6 weeks of development for a feature used by <10% of VFR pilots. | Implement direct-to and simple A→B→C chaining. Multi-leg optimization is v2. |
| CFI/student mode (dual logging, endorsements) | CFIs want to use it with students. | Dual logging, CFI signature capture, endorsement records, and student management is essentially a second product (a flight school tool). Requires different UX, additional data models, and regulatory compliance for digital endorsements. | Design logbook to support future dual-time logging. Full CFI mode is v2+ after pilot demand is validated. |

---

## Feature Dependencies

```
GPS + Location Services
    └──required by──> Moving Map (ownship position)
    └──required by──> Flight Recording (GPS track)
    └──required by──> Nearest Airport (spatial query against current position)
    └──required by──> Airspace Proximity Alerts (geofence against current position)
    └──required by──> Auto-Start Recording (speed threshold detection)

Airport Database (GRDB + NASR)
    └──required by──> Airport Info Sheet
    └──required by──> Airport Search
    └──required by──> Nearest Airport Feature
    └──required by──> Logbook Auto-Population (departure/destination lookup from GPS)
    └──required by──> Airspace Boundary Rendering (airspace tied to airports)

Chart Tile CDN (Cloudflare R2 + MBTiles pipeline)
    └──required by──> VFR Sectional Overlay
    └──required by──> Offline Chart Capability (pre-downloaded tiles)

NOAA Weather API
    └──required by──> METAR/TAF Display
    └──required by──> Weather Map Dots
    └──enables──> Pre-Flight Briefing Quality

Flight Recording (GPS Track + Audio)
    └──required by──> Real-Time Transcription (audio input needed)
    └──required by──> Flight Phase Detection (speed/altitude stream needed)
    └──required by──> Track Replay (recorded track + audio needed)
    └──required by──> AI Post-Flight Debrief (transcript + track needed)
    └──required by──> Logbook Auto-Population (flight duration from recording)

Real-Time Transcription
    └──required by──> AI Post-Flight Debrief (transcript is primary input)
    └──required by──> Track Replay Sync (transcript timeline needed for playback sync)

Flight Phase Detection
    └──enhances──> AI Post-Flight Debrief (phases structure the debrief narrative)
    └──enhances──> Logbook Auto-Population (phase transitions identify T/O + landing times)

Apple Foundation Models (iOS 26+)
    └──required by──> AI Post-Flight Debrief
    └──required by──> Structured Debrief Output (narrative, observations, rating)

Pilot Profile (name, certificate, medical, flight review)
    └──required by──> Currency Tracking (medical expiry date, flight review date)

Aircraft Profile (type, speeds, fuel burn)
    └──required by──> Flight Planning Calculations (time, fuel)
    └──enhances──> Currency Tracking (aircraft category affects currency rules)

Logbook (flight history)
    └──required by──> Currency Tracking (61.57 requires 3 T/O + landings in 90 days)
    └──enhanced by──> Logbook Auto-Population (less friction = more complete records)

TFR Display
    └──enhances──> Airspace Proximity Alerts (TFRs are a distinct layer)
    └──conflicts with──> Offline Capability (TFRs must be live; stale TFR data is dangerous)
```

### Dependency Notes

- **AI Debrief requires both Flight Recording AND Transcription:** The debrief model has two inputs — the GPS track (for spatial/altitude/speed context) and the transcript (for crew context, radio calls, and verbal markers). Neither alone is sufficient for a meaningful debrief.
- **Currency Tracking requires a populated Logbook:** Logbook auto-population reduces the friction to get currency data into the system. If auto-population is delayed, currency tracking is less useful.
- **TFR Display conflicts with pure offline mode:** TFRs are time-sensitive and must be fetched live or very recently cached. App must clearly distinguish between "offline with stale TFR data" and "online with live TFR data." Never display stale TFRs as current.
- **Sectional overlay requires CDN infrastructure:** On-device GeoTIFF conversion is not viable (too slow, too complex). Chart tiles must be pre-processed server-side and served via CDN. This is a build-phase dependency, not a code dependency.
- **Apple Foundation Models requires iOS 26:** AI debrief is gated on the iOS 26 deployment target. This is already fixed in the project constraints.

---

## MVP Definition

### Launch With (TestFlight v1)

Minimum viable product — what a pilot needs to replace ForeFlight for a VFR cross-country, plus the unique debrief loop that justifies a new app.

- [x] Moving map with GPS ownship — core navigation, non-negotiable
- [x] VFR sectional overlay with opacity control — primary chart reference
- [x] Airport database (20K+ NASR) with search and info sheet — must recognize airports pilot is flying to
- [x] METAR/TAF with flight category colors + weather map dots — go/no-go decision support
- [x] Airspace boundaries (Class B/C/D) — airspace awareness is regulatory, not optional
- [x] TFR display with proximity alerts — TFR violation = certificate action
- [x] Nearest airport emergency feature — safety feature, high pilot value, not complex
- [x] Basic flight planning: departure, destination, route, instrument strip — needed for cross-country
- [x] Layer controls + map mode selector — declutter for in-flight use
- [x] Offline chart tiles + airport database — works in cell-dead areas
- [x] Background location — app must work when locked during flight
- [x] Flight recording: GPS + cockpit audio + auto-start on takeoff — core differentiator
- [x] Real-time speech-to-text with aviation vocabulary — enables debrief
- [x] Automatic flight phase detection — structures the debrief
- [x] AI post-flight debrief: narrative, phase observations, improvements, rating — primary differentiator
- [x] Digital logbook with auto-population from recording — retention feature, pilots come back
- [x] Currency tracking: medical, flight review, 61.57 — useful daily, not just in-flight
- [x] Track replay with synchronized audio and transcript — review tool, reinforces recording value
- [x] Aircraft + pilot profiles — required by flight planning and currency features
- [x] Public TestFlight distribution — validates product across diverse pilots

### Add After Validation (v1.x)

Features to add once TestFlight feedback confirms core assumptions.

- [ ] Cloud premium debrief tier (Claude API) — add if pilots report Foundation Models quality is insufficient for complex flights
- [ ] ForeFlight track log import — add if pilots want historical debrief on existing data
- [ ] CloudKit sync (enable existing foundation) — add once data model is proven stable through TestFlight
- [ ] Export to GPX/KMZ — add when pilots ask for it in feedback
- [ ] PIREP display from NOAA — quick add using existing weather API, low effort
- [ ] Multi-leg route planning — add if TestFlight pilots report cross-country limitations

### Future Consideration (v2+)

Features to defer until product-market fit is established and pilot adoption data is available.

- [ ] ADS-B integration (optional hardware) — only after proving value without hardware requirement
- [ ] CFI/student mode with dual logging — only if flight school segment shows demand
- [ ] Weight and balance calculator — significant scope, only if pilot feedback ranks this high
- [ ] NEXRAD radar (with ADS-B) — hardware-dependent, defer
- [ ] Android / non-iPad platforms — iOS first, expand if adoption warrants
- [ ] Radio coach / AI training mode during flight — ambitious, needs validation of debrief quality first
- [ ] Instrument currency tracking (IFR) — out of scope for VFR product

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Moving map + GPS ownship | HIGH | MEDIUM | P1 |
| VFR sectional overlay | HIGH | HIGH | P1 |
| Airport database + search | HIGH | MEDIUM | P1 |
| METAR/TAF + weather dots | HIGH | MEDIUM | P1 |
| Flight recording (GPS + audio) | HIGH | HIGH | P1 |
| AI post-flight debrief | HIGH | HIGH | P1 |
| Real-time transcription | HIGH | HIGH | P1 |
| Airspace boundaries | HIGH | HIGH | P1 |
| TFR display + alerts | HIGH | MEDIUM | P1 |
| Nearest airport feature | HIGH | LOW | P1 |
| Offline capability | HIGH | HIGH | P1 |
| Digital logbook (auto-populated) | HIGH | MEDIUM | P1 |
| Track replay with audio sync | MEDIUM | HIGH | P1 |
| Currency tracking | MEDIUM | MEDIUM | P1 |
| Flight phase detection | MEDIUM | MEDIUM | P1 |
| Instrument strip | MEDIUM | LOW | P1 |
| Aircraft + pilot profiles | MEDIUM | LOW | P1 |
| Background location | HIGH | LOW | P1 |
| Layer controls + map modes | MEDIUM | LOW | P1 |
| Cloud premium debrief tier | MEDIUM | HIGH | P2 |
| CloudKit sync (enable) | MEDIUM | MEDIUM | P2 |
| GPX/KMZ export | LOW | LOW | P2 |
| PIREP display | LOW | LOW | P2 |
| Multi-leg route planning | MEDIUM | HIGH | P2 |
| ForeFlight track log import | LOW | MEDIUM | P2 |
| ADS-B hardware integration | MEDIUM | HIGH | P3 |
| Weight and balance | MEDIUM | HIGH | P3 |
| CFI/student mode | MEDIUM | HIGH | P3 |
| NEXRAD radar | HIGH | HIGH | P3 |

**Priority key:**
- P1: Must have for TestFlight launch
- P2: Add after TestFlight validation
- P3: Future consideration (v2+)

---

## Competitor Feature Analysis

| Feature | ForeFlight | Garmin Pilot | FltPlan Go (Free) | WingX VFR | OpenEFB |
|---------|------------|--------------|-------------------|-----------|---------|
| Moving map + ownship | Yes | Yes | Yes | Yes | Yes |
| VFR sectional overlay | Yes | Yes | Yes | Yes | Yes |
| Airport database | Yes | Yes | Yes | Yes | Yes |
| METAR/TAF weather | Yes | Yes | Yes | Yes | Yes |
| Airspace display | Yes | Yes | Yes | Yes | Yes |
| TFR display | Yes | Yes | Yes | Yes | Yes |
| Flight planning | Yes | Yes | Yes | Yes | Basic |
| Digital logbook | Yes (subscription) | Yes (subscription) | No | No | Yes (free) |
| Currency tracking | Yes (subscription) | Limited | No | No | Yes (free) |
| Offline charts | Yes (download) | Yes (download) | Yes (download) | Yes (download) | Yes (download) |
| GPS track log | Yes | Yes | Limited | Limited | Yes |
| Track replay | Yes | Yes | No | No | Yes + audio |
| Post-flight debrief scoring | Yes (Essential plan, $240/yr) | No | No | No | Yes (free, on-device AI) |
| Cockpit audio recording | No | No | No | No | Yes |
| Transcription (on-device) | No | No | No | No | Yes |
| AI narrative debrief | No | No | No | No | Yes |
| Hardware required | Sentry/Stratus recommended | Garmin integration | None | None | None |
| Price | $125-$370/yr | $109-$209/yr | Free | $0.99/yr | Free |
| Account required | Yes | Yes | Yes (fltplan.com) | Yes | No |
| Open source | No | No | No | No | Yes (MPL-2.0) |
| iOS 26 / @Observable | No | No | No | No | Yes |

**Key insight:** Every competitor charges a subscription for digital logbook and debrief features. No competitor offers on-device AI narrative debrief from cockpit audio. The combination of free + no account + AI debrief + open source is entirely unoccupied in the market. OpenEFB's closest competition for the recording/debrief loop is CloudAhoy ($59-$119/yr, separate app, requires account, GPS-only debrief without audio).

---

## Sources

- [ForeFlight vs Garmin Pilot key differences 2026 - iPad Pilot News](https://ipadpilotnews.com/2026/02/foreflight-vs-garmin-pilot-key-differences-to-help-you-decide/)
- [ForeFlight Debrief product page](https://foreflight.com/enhancements/foreflight-debrief)
- [ForeFlight Track Log Review](https://foreflight.com/enhancements/track-log-review)
- [ForeFlight Logbook product page](https://foreflight.com/products/logbook/)
- [Top 20 apps for pilots 2026 - iPad Pilot News](https://ipadpilotnews.com/2026/02/the-top-20-apps-for-pilots-2026-edition/)
- [Pilot app directory 2025 - iPad Pilot News](https://ipadpilotnews.com/2025/03/pilots-aviation-app-directory-2025-edition/)
- [CloudAhoy post-flight debrief](https://www.cloudahoy.com/)
- [FltPlan Go features](https://flttrack.fltplan.com/FltPlanInfo/FltPlan_Go-Android-iPad_Info.html)
- [WingX VFR Free tier](https://www.aero-news.net/index.cfm?do=main.textpost&id=338ea125-cf32-4475-9e97-45f61b8a867e)
- [AvNav EFB: 3D + AI](https://www.avnav.com/)
- [AI flight debrief: Axis taps AI for training debriefing - AIN Online](https://www.ainonline.com/aviation-news/business-aviation/2025-12-02/axis-taps-ai-improve-flight-training-debriefing)
- [Pilot pain points forum - Pilots of America](https://www.pilotsofamerica.com/community/threads/what-are-currently-the-best-efb%E2%80%99s-for-ipad.147235/)
- [Digital pilot logbook apps 2026](https://www.wingmanlog.in/post/best-digital-pilot-logbook-apps-in-2025)
- [Best pilot logbook apps 2025 - Axis Intelligence](https://axis-intelligence.com/best-pilot-logbook-apps-2025-tested/)
- [EFB legal briefing 2025 - iPad Pilot News](https://ipadpilotnews.com/2025/05/electronic-flight-bag-legal-briefing-for-pilots-2025-edition/)

---
*Feature research for: iPad VFR EFB with integrated flight recording and AI debrief*
*Researched: 2026-03-20*
