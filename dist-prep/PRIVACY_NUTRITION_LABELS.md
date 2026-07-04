# Privacy Nutrition Labels — derived from code, 2026-07-04

App Store Connect asks: what data does your app **collect** (Apple's definition:
transmitted off the device and available to you or third parties)? These answers
are derived from actual code, not assumptions.

## Recommended answer: **Data Not Collected**

Evidence from the codebase:

| Data type | Used in-app? | Leaves device? | Basis |
|---|---|---|---|
| Precise location (GPS) | Yes (moving map, nearest-airport, flight track) | **No** | Stored in SwiftData/GRDB on device. Weather requests use airport **station IDs** (`?ids=KOAK`), never raw coordinates — `WeatherService.swift:43,67,113`. |
| Audio (cockpit mic) | Yes (recording) | **No** | Recorded and stored locally; used for on-device transcription. |
| Speech/transcripts | Yes (flight transcripts) | **No** | `TranscriptionService.swift:278` sets `requiresOnDeviceRecognition = true` — transcription runs on-device, audio is not sent to Apple servers. |
| Flights / logbook / pilot & aircraft profiles | Yes | **No** | SwiftData, on-device (CloudKit-ready but not enabled for launch per PRD). |
| Analytics / crash / ads / identifiers | — | — | **None found** — no Firebase, Crashlytics, analytics, or ad SDKs in the project. |

The only outbound network call is to `aviationweather.gov` (NOAA public METAR/TAF
API, no key, no account). It transmits public airport station identifiers, not
personal or device data. Under Apple's definition this is not "data collection."

## Answers to enter in App Store Connect
- **Do you or your third-party partners collect data from this app?** → **No**
- Result: the app displays "Data Not Collected" on its App Store privacy card.

## Verify before you submit (two quick confirmations)
1. Confirm **CloudKit sync stays disabled** for the launch build. If premium
   CloudKit sync is turned on, flights/profiles would sync to the user's own
   iCloud — still "not collected by developer," but re-check the questionnaire.
2. Confirm no analytics/crash SDK is added between now and archive. If one is
   added later, revisit this file.
