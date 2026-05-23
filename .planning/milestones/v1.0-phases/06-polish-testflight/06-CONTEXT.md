# Phase 6: Polish + TestFlight - Context

**Gathered:** 2026-03-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver App Store compliance (privacy manifest, entitlements), performance validation on real hardware, chart expiration and weather staleness indicators, first-time user onboarding, and public TestFlight distribution. The app passes Apple review and is installable by any VFR pilot with an iPad running iOS 26.

</domain>

<decisions>
## Implementation Decisions

### Expiration & Staleness Indicators
- Chart expiration: yellow badge overlay on map when charts are within 7 days of 56-day FAA cycle expiry; red "EXPIRED" badge when past cycle — visible but not obstructive to map interaction
- Weather staleness: consistent "Xm ago" badge on every weather readout surface (map dots, airport info sheet, instrument strip weather section) — enforces Phase 1 design decision across all displays
- Performance: no visible performance indicators to the user — silently hit targets (60fps map with 20K airports, <200MB memory, acceptable battery impact during recording). Pilots care about smoothness, not metrics
- Privacy manifest declares: location (continuous, in-flight navigation), microphone (cockpit recording), speech recognition — with clear, honest purpose strings matching actual usage

### TestFlight & Onboarding
- First-time user onboarding: minimal 2-3 screen walkthrough covering location permission request, map overview, and record button introduction — then drops into the app. Pilots learn by doing
- TestFlight feedback via Apple's built-in screenshot + feedback mechanism, plus an in-app "Send Feedback" link in Settings — sufficient for beta testing
- Beta disclaimer: non-blocking banner on first launch stating "Beta — Report issues via TestFlight feedback" — sets expectations without being annoying, dismissed and not shown again
- Chart CDN fallback: if CDN infrastructure is not ready, app ships with a placeholder message and falls back to the base map layer — do not block TestFlight distribution on CDN pipeline readiness

### Claude's Discretion
- PrivacyInfo.xcprivacy exact structure and API declarations
- Instruments profiling methodology and specific performance thresholds
- Onboarding screen visual design and copy
- TestFlight metadata and review notes
- App icon and launch screen design
- Background mode declarations in entitlements

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ChartManager.swift` — Chart download and expiration tracking (has isExpired logic)
- `WeatherBadge.swift` — Existing weather staleness badge component
- `SettingsView.swift` — Settings screen where feedback link lives
- `DeviceCapabilities.swift` — Device detection for performance targets

### Established Patterns
- EFBError for error handling across all surfaces
- ChartRegion.isExpired and WeatherCache.isStale already exist as concepts
- TabView with 5 tabs in ContentView.swift

### Integration Points
- All Phase 1-5 features must work together end-to-end
- Background mode entitlements: location updates + audio recording + audio playback
- App Store Connect for TestFlight distribution
- PrivacyInfo.xcprivacy at project root

</code_context>

<specifics>
## Specific Ideas

- Real-device testing critical: recording lifecycle (phone call interruption, Siri, headphone disconnect) needs iPad hardware, not just simulator
- Chart expiration check: compare current date against last chart download date + 56 days
- Memory profiling: focus on map rendering with 20K airports loaded as GeoJSON and long recording sessions (6+ hours)
- TestFlight external testing requires Apple review — submit early, iterate on feedback

</specifics>

<deferred>
## Deferred Ideas

- App Store public release (after TestFlight validation)
- Custom app icon variants
- Accessibility audit (VoiceOver, Dynamic Type) — important but defer to post-beta
- Localization (English only for v1)

</deferred>

---
*Phase: 06-polish-testflight*
*Context gathered: 2026-03-20 via Smart Discuss (autonomous)*
