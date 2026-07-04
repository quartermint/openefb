# Archive Configuration — verified 2026-07-04

Pulled from `xcodebuild -showBuildSettings -configuration Release`.

## Verified settings (Release)
| Setting | Value | Notes |
|---|---|---|
| PRODUCT_BUNDLE_IDENTIFIER | `quartermint.efb-212` | matches CLAUDE.md |
| MARKETING_VERSION | `1.0` | store version |
| CURRENT_PROJECT_VERSION | `1` | build number |
| IPHONEOS_DEPLOYMENT_TARGET | `26.0` | iOS 26 minimum |
| PRODUCT_NAME | `efb-212` | internal name (display name is "OpenEFB" via app) |
| CODE_SIGN_STYLE | `Automatic` | |
| DEVELOPMENT_TEAM | `SKGLKG576D` | |
| TARGETED_DEVICE_FAMILY | `1,2` | **iPhone + iPad — see decision below** |
| SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD | `YES` | app will be offered on Apple Silicon Macs |
| GENERATE_INFOPLIST_FILE | `YES` | many Info.plist keys come from INFOPLIST_KEY_* build settings |
| SKIP_INSTALL | `NO` | correct for an app target |

## Privacy usage strings (present, verified)
- `NSMicrophoneUsageDescription` (Info.plist): "OpenEFB records cockpit audio during flights for transcription and debrief."
- `NSSpeechRecognitionUsageDescription` (Info.plist): "OpenEFB transcribes cockpit audio in real-time to create flight transcripts."
- `INFOPLIST_KEY_NSLocationWhenInUseUsageDescription`: "OpenEFB uses your location to show your position on the aviation map and provide navigation guidance."
- `INFOPLIST_KEY_NSLocationAlwaysAndWhenInUseUsageDescription`: "OpenEFB uses your location in the background to continue tracking your flight when the screen is off."
- `UIBackgroundModes` includes `location` (backed by the Always usage string above — consistent).

## Two decisions to make before archiving

### 1. Export compliance (recommended: add the key)
`ITSAppUsesNonExemptEncryption` is **not set**. Without it, App Store Connect
asks the export-compliance question on every single upload. The app only uses
standard HTTPS (aviationweather.gov for METAR/TAF) and no custom/proprietary
crypto, which is exempt. Add:

```
ITSAppUsesNonExemptEncryption = NO
```
as an `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption` build setting (or an
Info.plist entry). This removes the per-upload prompt.

### 2. Device family (iPad-only?)
Currently `1,2` (iPhone + iPad) with Mac-Designed-for-iPad ON. The PRD describes
OpenEFB as an **iPad VFR EFB**. If iPhone/Mac are not intended launch targets,
set `TARGETED_DEVICE_FAMILY = 2` (iPad only) before archiving — otherwise the
listing must satisfy iPhone screenshot requirements and iPhone-layout QA too.
This is a product call, not a blocker; left as-is it will still archive.

## Archive steps
1. Scheme `efb-212`, Release configuration.
2. Destination: Any iOS Device (arm64).
3. Product → Archive.
4. Organizer → Distribute App → App Store Connect → Upload.
5. Automatic signing with team SKGLKG576D handles provisioning.
