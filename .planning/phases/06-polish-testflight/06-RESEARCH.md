# Phase 6: Polish + TestFlight - Research

**Researched:** 2026-03-21
**Domain:** Apple App Store compliance (privacy manifests, entitlements), iOS performance profiling, TestFlight distribution
**Confidence:** HIGH

## Summary

Phase 6 delivers App Store compliance, performance validation, and public TestFlight distribution. The three plans break down cleanly: (1) privacy manifest + entitlements, (2) performance profiling + expiration/staleness UI hardening, and (3) TestFlight submission with onboarding.

The app already has strong foundations: Info.plist has background modes (`location`, `audio`), microphone and speech recognition usage descriptions, and location usage descriptions are declared in the Xcode build settings. ChartExpirationBadge and WeatherBadge components exist and are functional. The primary gaps are: no PrivacyInfo.xcprivacy file exists yet, the Settings tab is a placeholder (`Text("Settings Placeholder")`), WeatherBadge is only used on AirportInfoSheet (needs to appear on map dots tooltip and instrument strip weather), and there is no onboarding flow.

**Primary recommendation:** Create PrivacyInfo.xcprivacy as the first action -- it blocks TestFlight submission. Focus performance work on real-device profiling with Instruments. Build a minimal 2-3 screen onboarding using TabView with PageTabViewStyle (standard SwiftUI pattern, no external dependencies).

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Chart expiration: yellow badge overlay on map when charts are within 7 days of 56-day FAA cycle expiry; red "EXPIRED" badge when past cycle -- visible but not obstructive to map interaction
- Weather staleness: consistent "Xm ago" badge on every weather readout surface (map dots, airport info sheet, instrument strip weather section) -- enforces Phase 1 design decision across all displays
- Performance: no visible performance indicators to the user -- silently hit targets (60fps map with 20K airports, <200MB memory, acceptable battery impact during recording). Pilots care about smoothness, not metrics
- Privacy manifest declares: location (continuous, in-flight navigation), microphone (cockpit recording), speech recognition -- with clear, honest purpose strings matching actual usage

### TestFlight & Onboarding
- First-time user onboarding: minimal 2-3 screen walkthrough covering location permission request, map overview, and record button introduction -- then drops into the app. Pilots learn by doing
- TestFlight feedback via Apple's built-in screenshot + feedback mechanism, plus an in-app "Send Feedback" link in Settings -- sufficient for beta testing
- Beta disclaimer: non-blocking banner on first launch stating "Beta -- Report issues via TestFlight feedback" -- sets expectations without being annoying, dismissed and not shown again
- Chart CDN fallback: if CDN infrastructure is not ready, app ships with a placeholder message and falls back to the base map layer -- do not block TestFlight distribution on CDN pipeline readiness

### Claude's Discretion
- PrivacyInfo.xcprivacy exact structure and API declarations
- Instruments profiling methodology and specific performance thresholds
- Onboarding screen visual design and copy
- TestFlight metadata and review notes
- App icon and launch screen design
- Background mode declarations in entitlements

### Deferred Ideas (OUT OF SCOPE)
- App Store public release (after TestFlight validation)
- Custom app icon variants
- Accessibility audit (VoiceOver, Dynamic Type) -- important but defer to post-beta
- Localization (English only for v1)
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INFRA-04 | App includes privacy manifest compliant with App Store requirements | PrivacyInfo.xcprivacy structure documented below with exact keys, data types, and API declarations. Covers location, microphone, speech recognition data collection and required reason APIs (UserDefaults). |
| INFRA-05 | App is distributed via public TestFlight | TestFlight external testing workflow documented: App Store Connect setup, beta review requirements, public link creation, tester limits (10K). Review takes ~24 hours for first build. |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Xcode Instruments | Xcode 16.3+ | Performance profiling (Allocations, Leaks, Core Animation, Energy Log) | Apple's official profiling toolchain; only way to measure real-device GPU/battery impact |
| App Store Connect | N/A | TestFlight distribution, beta review submission | Apple's only distribution path for TestFlight |
| SwiftUI TabView + PageTabViewStyle | iOS 26 built-in | Onboarding walkthrough screens | Standard pattern for page-based onboarding, zero dependencies |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| @AppStorage | iOS 26 built-in | Persisting "has seen onboarding" and "has dismissed beta banner" flags | Small user preferences that need UserDefaults backing |
| os.Logger | iOS 26 built-in | Structured logging during profiling | Already used in AudioRecorder; extend to perf-critical paths |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| @AppStorage for onboarding flag | SwiftData UserSettings model | UserSettings already exists but @AppStorage is simpler for single booleans; avoid schema change for a flag |
| Xcode Instruments | Third-party profilers (Emerge Tools, Firebase Performance) | Instruments is free, integrated, and measures GPU/battery directly on device |

## Architecture Patterns

### Recommended File Structure (Phase 6 additions)
```
efb-212/
├── PrivacyInfo.xcprivacy              # NEW: Privacy manifest (project root level)
├── Info.plist                          # EXISTING: Add nothing (usage descriptions in build settings)
├── Views/
│   ├── Onboarding/
│   │   └── OnboardingView.swift        # NEW: 2-3 screen walkthrough
│   ├── Settings/
│   │   └── SettingsView.swift          # NEW: Replace placeholder, add feedback link
│   └── Components/
│       ├── WeatherBadge.swift          # EXISTING: No changes needed
│       ├── ChartExpirationBadge.swift  # EXISTING: No changes needed
│       └── BetaBanner.swift            # NEW: One-time dismissable beta disclaimer
└── Core/
    └── AppState.swift                  # MODIFY: Add hasSeenOnboarding flag
```

### Pattern 1: PrivacyInfo.xcprivacy Placement
**What:** The privacy manifest must be placed at the app bundle root level, named exactly `PrivacyInfo.xcprivacy`. It must be included in the target's "Copy Bundle Resources" build phase.
**When to use:** Always -- required for App Store Connect submission since May 2024.
**Example:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- No tracking -->
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyTrackingDomains</key>
    <array/>

    <!-- Collected data types: location + audio -->
    <key>NSPrivacyCollectedDataTypes</key>
    <array>
        <!-- Precise Location -->
        <dict>
            <key>NSPrivacyCollectedDataType</key>
            <string>NSPrivacyCollectedDataTypePreciseLocation</string>
            <key>NSPrivacyCollectedDataTypeLinked</key>
            <false/>
            <key>NSPrivacyCollectedDataTypeTracking</key>
            <false/>
            <key>NSPrivacyCollectedDataTypePurposes</key>
            <array>
                <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
            </array>
        </dict>
        <!-- Audio Data (cockpit recording) -->
        <dict>
            <key>NSPrivacyCollectedDataType</key>
            <string>NSPrivacyCollectedDataTypeAudioData</string>
            <key>NSPrivacyCollectedDataTypeLinked</key>
            <false/>
            <key>NSPrivacyCollectedDataTypeTracking</key>
            <false/>
            <key>NSPrivacyCollectedDataTypePurposes</key>
            <array>
                <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
            </array>
        </dict>
    </array>

    <!-- Required reason APIs -->
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <!-- UserDefaults (if @AppStorage is used for onboarding/settings flags) -->
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```
**Source:** [Apple Developer Documentation - Privacy manifest files](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files), [Apple Developer - Adding a privacy manifest](https://developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk)

### Pattern 2: Onboarding with TabView PageStyle
**What:** Minimal walkthrough using SwiftUI TabView with `.tabViewStyle(.page)` for swipeable screens. Persists completion via @AppStorage.
**When to use:** First launch only, gated by `hasSeenOnboarding` flag.
**Example:**
```swift
struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0

    var body: some View {
        TabView(selection: $currentPage) {
            // Screen 1: Welcome + location permission
            OnboardingPage(
                systemImage: "location.fill",
                title: "Navigate with GPS",
                description: "OpenEFB uses your location to show your position on VFR charts.",
                tag: 0
            )
            // Screen 2: Map overview
            OnboardingPage(
                systemImage: "map",
                title: "Your Moving Map",
                description: "VFR sectional charts, weather, airports, and airspace at your fingertips.",
                tag: 1
            )
            // Screen 3: Record + go
            OnboardingPage(
                systemImage: "record.circle",
                title: "Record Every Flight",
                description: "One tap to record GPS track and cockpit audio. Get an AI debrief after.",
                tag: 2,
                showGetStarted: true,
                onGetStarted: { hasSeenOnboarding = true }
            )
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
    }
}
```

### Pattern 3: Beta Disclaimer Banner
**What:** Non-blocking banner shown on first launch after onboarding, dismissed once and persisted via @AppStorage.
**When to use:** All TestFlight builds only.
**Example:**
```swift
struct BetaBanner: View {
    @AppStorage("hasDismissedBetaBanner") private var dismissed = false

    var body: some View {
        if !dismissed {
            HStack {
                Image(systemName: "info.circle")
                Text("Beta -- Report issues via TestFlight feedback")
                    .font(.caption)
                Spacer()
                Button { dismissed = true } label: {
                    Image(systemName: "xmark")
                        .font(.caption2)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}
```

### Pattern 4: Settings View with Feedback Link
**What:** Replace the `Text("Settings Placeholder")` in ContentView with a real SettingsView containing app version, feedback link, and chart management placeholder.
**When to use:** Settings tab -- currently a placeholder.

### Anti-Patterns to Avoid
- **Blocking TestFlight on CDN readiness:** Per user decision, chart CDN may not be ready. Ship with placeholder message and base map fallback. Never block TestFlight distribution.
- **Visible performance metrics:** Per user decision, no FPS counters, memory displays, or battery indicators. Pilots care about smoothness, not numbers.
- **Complex onboarding:** More than 3 screens or requiring any data input during onboarding will cause abandonment. Let pilots discover features by flying.
- **Force-unwrapping location/microphone permissions in onboarding:** Request location in onboarding screen 1 but handle denial gracefully. The app works (degraded) without GPS.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Privacy manifest | Manual plist construction from scratch | Xcode's built-in PrivacyInfo.xcprivacy editor (File > New > Privacy Manifest) | Xcode validates structure and shows picker UI for API categories and data types |
| Privacy report generation | Manual auditing of all frameworks | Xcode Product > Archive > Generate Privacy Report | Automatically aggregates privacy manifests from all frameworks (GRDB, MapLibre, etc.) |
| TestFlight distribution | Manual IPA distribution | App Store Connect + Xcode Organizer | Only supported path; handles review, signing, and distribution |
| Memory leak detection | Manual retain cycle hunting | Instruments Leaks template + Xcode Memory Graph Debugger | Automated detection of retain cycles and leaked objects |
| Battery impact measurement | Estimating from CPU usage | Instruments Energy Log template on real device | Only accurate way to measure actual mAh drain per hour |

**Key insight:** Apple's toolchain handles all compliance and profiling needs natively. There are no third-party tools needed for Phase 6.

## Common Pitfalls

### Pitfall 1: Missing Privacy Manifest for Third-Party SDKs
**What goes wrong:** App Store Connect rejects the build because a third-party SDK (MapLibre, GRDB) uses a required reason API without declaring it in a privacy manifest.
**Why it happens:** Each framework bundle needs its own PrivacyInfo.xcprivacy. SPM packages may or may not include one.
**How to avoid:** After archiving, use Product > Archive > Generate Privacy Report to see the aggregated manifest. Verify MapLibre and GRDB include their own manifests (GRDB's exists and declares nothing -- verified in codebase). If MapLibre lacks one, file an issue or add declarations at the app level.
**Warning signs:** ITMS-91053 error during upload ("Missing API Declaration").

### Pitfall 2: Background Audio Rejection
**What goes wrong:** Apple rejects the app because UIBackgroundModes includes `audio` but the app doesn't continuously play/record audio.
**Why it happens:** The `audio` background mode is for apps that provide continuous audio (music, recording). If the app only records intermittently, Apple may flag it.
**How to avoid:** The `audio` key in Info.plist is justified because the app records 6+ hour cockpit audio sessions. Document this in TestFlight review notes: "Audio background mode is used for continuous cockpit audio recording during flights (up to 6+ hours)."
**Warning signs:** Rejection citing Guideline 2.5.4 (Background Modes).

### Pitfall 3: Location "Always" Without Justification
**What goes wrong:** Apple rejects because the app requests "Always" location but the justification isn't clear.
**Why it happens:** VFR EFB genuinely needs background location to track GPS when screen is off during flight.
**How to avoid:** The existing usage descriptions are well-written: "OpenEFB uses your location in the background to continue tracking your flight when the screen is off." This matches the actual use case. In TestFlight review notes, explain the in-flight use case explicitly.
**Warning signs:** Rejection citing Guideline 5.1.1 (Data Collection and Storage) or 5.1.2 (Data Use and Sharing).

### Pitfall 4: TestFlight External Review Takes Longer Than Expected
**What goes wrong:** First external build requires Apple beta review, which can take 24-48 hours. Developer assumes instant distribution.
**Why it happens:** External testing requires a review pass (different from App Store review but still a gate). Subsequent builds to the same group may not require review.
**How to avoid:** Submit the first external build early in the phase. Start with internal testing (up to 100 App Store Connect users, no review needed) while waiting for external approval.
**Warning signs:** Build stuck in "Waiting for Review" status.

### Pitfall 5: @AppStorage Not Declared in Privacy Manifest
**What goes wrong:** Using @AppStorage (which wraps UserDefaults) without declaring `NSPrivacyAccessedAPICategoryUserDefaults` in the privacy manifest.
**Why it happens:** Developers forget that @AppStorage triggers the required reason API for UserDefaults.
**How to avoid:** If any @AppStorage property wrappers are added (for onboarding flag, beta banner flag, user settings), include `NSPrivacyAccessedAPICategoryUserDefaults` with reason `CA92.1` in the privacy manifest.
**Warning signs:** ITMS-91053 error mentioning UserDefaults.

### Pitfall 6: WeatherBadge Not on All Surfaces
**What goes wrong:** Weather staleness badge appears on airport info sheet but not on map weather dots or instrument strip, violating the user's explicit requirement.
**Why it happens:** WeatherBadge was built in Phase 1 but only wired to AirportInfoSheet. Map weather dots are rendered as GeoJSON circles by MapService (not SwiftUI views), so they can't easily show a SwiftUI badge.
**How to avoid:** For map dots: the dots themselves are already color-coded by flight category. Add a map-level "Weather data age" indicator (e.g., small badge in the layer controls showing oldest weather observation age). For instrument strip: weather is not currently displayed there -- if a weather section is added, include the badge. Document the intent: "Weather staleness is communicated via badge wherever weather text/data is displayed."
**Warning signs:** User testing reveals stale weather shown without age indicator.

## Code Examples

### Current State: Info.plist Background Modes (Existing)
```xml
<!-- Already in Info.plist -->
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
    <string>audio</string>
</array>
<key>NSMicrophoneUsageDescription</key>
<string>OpenEFB records cockpit audio during flights for transcription and debrief.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>OpenEFB transcribes cockpit audio in real-time to create flight transcripts.</string>
```

### Current State: Location Usage (In Build Settings)
```
INFOPLIST_KEY_NSLocationAlwaysAndWhenInUseUsageDescription =
  "OpenEFB uses your location in the background to continue tracking your flight when the screen is off."
INFOPLIST_KEY_NSLocationWhenInUseUsageDescription =
  "OpenEFB uses your location to show your position on the aviation map and provide navigation guidance."
```

### Current State: ChartExpirationBadge (Already Functional)
```swift
// Already integrated in MapContainerView and LayerControlsView
// ChartExpirationBadge(daysRemaining: viewModel.chartDaysRemaining)
// Shows yellow for <=7 days, red for expired, hidden otherwise
```

### Current State: WeatherBadge (Needs Wider Integration)
```swift
// Currently only in AirportInfoSheet.swift line 294:
// WeatherBadge(observationTime: wx.observationTime)
// Needs to be added to: instrument strip weather display (if added),
// and a map-level weather age indicator
```

### TestFlight Review Notes Template
```
Beta Test Description:
OpenEFB is a free, open-source VFR electronic flight bag for iPad.
It provides moving-map navigation with VFR sectional charts, flight
recording with cockpit audio capture, and AI-powered flight debrief.

What to Test:
- Moving map with GPS tracking and VFR chart overlay
- Airport database search and info sheets with live METAR/TAF
- Flight recording (GPS track + cockpit audio)
- AI debrief after flight
- Track replay with synchronized audio

Sign-In Information:
No account required. The app works entirely on-device.

Beta App Review Notes:
This app uses background location (UIBackgroundModes: location) for
continuous GPS tracking during flight. It uses background audio
(UIBackgroundModes: audio) for cockpit audio recording sessions of
6+ hours. Speech recognition is used for real-time cockpit audio
transcription. All data stays on-device; no data is transmitted
to any server. The app targets VFR pilots flying with iPad.
```

### Onboarding Location Permission Request
```swift
// Request location permission during onboarding screen 1
// LocationService.startTracking() already calls requestWhenInUseAuthorization
// then requestAlwaysAuthorization after initial grant
// This happens naturally when user taps "Get Started" and map loads
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| No privacy manifest required | PrivacyInfo.xcprivacy mandatory | May 2024 | All apps must include; rejection without it |
| Manual privacy questionnaire only | Privacy manifest + App Privacy Details both required | May 2024 | Manifest is checked automatically; details are checked by review |
| TestFlight internal only for small teams | Public links for up to 10K testers | 2018+ | Can share a URL publicly for VFR pilot community |
| UIKit onboarding with page view controller | SwiftUI TabView + .page style | iOS 14+ | Simpler, fewer lines, consistent with app's SwiftUI architecture |

## Open Questions

1. **MapLibre Privacy Manifest**
   - What we know: GRDB includes a PrivacyInfo.xcprivacy (verified, declares nothing). MapLibre Native iOS is included via SPM.
   - What's unclear: Whether MapLibre's latest SPM distribution includes its own privacy manifest.
   - Recommendation: After building the archive, run Generate Privacy Report. If MapLibre triggers API usage without declarations, add the required declarations at the app level for the APIs MapLibre uses.

2. **Chart CDN Readiness**
   - What we know: Per user decision, do not block TestFlight on CDN. The base map layer (MapLibre streets/satellite) works without charts.
   - What's unclear: Whether the ChartManager code will error out gracefully when no CDN is available.
   - Recommendation: Test that chart download failure is handled gracefully. ChartManager already throws `EFBError.chartDownloadFailed` which should show a user-friendly message.

3. **Weather Staleness on Map Dots**
   - What we know: Map weather dots are rendered as GeoJSON circles via MapService (not SwiftUI). You cannot attach a SwiftUI WeatherBadge to them.
   - What's unclear: Best UX for showing weather data age on the map itself.
   - Recommendation: Add a small "Weather: Xm ago" badge near the weather layer toggle in LayerControlsView, showing the age of the oldest visible weather observation. This satisfies "every weather readout surface" for the map context.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (@Test, #expect) + XCTest |
| Config file | efb-212.xcodeproj scheme `efb-212` |
| Quick run command | `xcodebuild test -scheme efb-212 -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' -only-testing:efb-212Tests` |
| Full suite command | `xcodebuild test -scheme efb-212 -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)'` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| INFRA-04 | Privacy manifest is valid and included in bundle | unit | Verify PrivacyInfo.xcprivacy exists in built bundle resources | Wave 0 |
| INFRA-04 | Privacy manifest declares location, audio, UserDefaults APIs | unit | Parse PrivacyInfo.xcprivacy plist and assert required keys present | Wave 0 |
| INFRA-05 | App builds for release configuration without errors | smoke | `xcodebuild build -scheme efb-212 -configuration Release -destination generic/platform=iOS` | Wave 0 |
| INFRA-05 | Onboarding appears on first launch, persists dismissal | manual-only | Cannot automate @AppStorage state in unit tests without UI test host | Justification: UI flow requires TestFlight device |
| INFRA-05 | Settings view loads with feedback link | unit | Assert SettingsView renders with expected elements | Wave 0 |

### Sampling Rate
- **Per task commit:** Quick run command (unit tests only)
- **Per wave merge:** Full suite
- **Phase gate:** Full suite green + successful archive build + privacy report generated

### Wave 0 Gaps
- [ ] `efb-212Tests/PrivacyManifestTests.swift` -- verify PrivacyInfo.xcprivacy is bundled and contains required declarations
- [ ] `efb-212Tests/ViewTests/SettingsViewTests.swift` -- verify Settings tab content
- [ ] Verify release build succeeds: `xcodebuild build -scheme efb-212 -configuration Release -destination generic/platform=iOS`

## Sources

### Primary (HIGH confidence)
- [Apple Developer - Privacy manifest files](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files) -- privacy manifest structure and requirements
- [Apple Developer - Adding a privacy manifest](https://developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk) -- step-by-step manifest creation
- [Apple Developer - Describing use of required reason API](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api) -- API categories and reason codes
- [Apple Developer - TestFlight overview](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/) -- TestFlight workflow
- [Apple Developer - Invite external testers](https://developer.apple.com/help/app-store-connect/test-a-beta-version/invite-external-testers/) -- public link setup
- [Apple Developer - Provide test information](https://developer.apple.com/help/app-store-connect/test-a-beta-version/provide-test-information/) -- beta review requirements
- [Apple Developer - UIBackgroundModes](https://developer.apple.com/documentation/bundleresources/information-property-list/uibackgroundmodes) -- background mode declarations
- [Apple Developer - Configuring background execution modes](https://developer.apple.com/documentation/xcode/configuring-background-execution-modes) -- Xcode background mode setup

### Secondary (MEDIUM confidence)
- [Bugfender - Apple Privacy Requirements](https://bugfender.com/blog/apple-privacy-requirements/) -- privacy manifest structure walkthrough with API category examples
- [Twinr - Apple App Store Rejection Reasons 2025](https://twinr.dev/blogs/apple-app-store-rejection-reasons-2025/) -- common rejection patterns
- [iOS App Distribution Guide 2026](https://foresightmobile.com/blog/ios-app-distribution-guide-2026) -- TestFlight review timelines
- [Apple Developer - Gathering memory info](https://developer.apple.com/documentation/xcode/gathering-information-about-memory-use) -- Instruments memory profiling

### Tertiary (LOW confidence)
- [GitHub Gist - PrivacyInfo.xcprivacy sample](https://gist.github.com/chockenberry/2c1c829dba9c7f34c9a7e8e04335be42) -- example manifest (minimal, UserDefaults only)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- Apple's own tools, no third-party dependencies needed
- Architecture: HIGH -- privacy manifest format well-documented, onboarding pattern is standard SwiftUI
- Pitfalls: HIGH -- common rejection reasons are well-documented by the developer community, and this app's actual usage descriptions are honest and match real functionality
- Performance profiling: MEDIUM -- general Instruments methodology is well-known, but MapLibre-specific GeoJSON rendering performance thresholds would need empirical measurement on device

**Research date:** 2026-03-21
**Valid until:** 2026-04-21 (stable domain -- Apple privacy requirements and TestFlight process change slowly)
