# App Store Connect Metadata — draft, 2026-07-04

Draft copy in Ryan's voice conventions (no bravado, no em-dash, plain claims).
Review and trim before submitting. Character limits noted.

## Name (30 char max)
`OpenEFB` (7)

Alternative if a descriptor is wanted: `OpenEFB: VFR Flight Bag` (23)

## Subtitle (30 char max)
`VFR moving map and debrief` (26)

## Primary category
**Navigation**

## Secondary category
**Utilities** (alt: Travel)

## Promotional text (170 char max, updatable without review)
`Free, open-source VFR electronic flight bag for iPad. Moving-map navigation, live weather, flight recording, and an on-device debrief after you land.` (149)

## Description (4000 char max)
```
OpenEFB is a free, open-source VFR electronic flight bag for iPad.

It gives VFR pilots a moving map, live weather, and a flight recorder that
turns each flight into a reviewable debrief, all on the device.

MOVING MAP
- Aviation moving map with VFR sectional chart overlays
- Your position and track shown in real time
- Airport, navaid, and airspace information from FAA data
- Nearest-airport readout for quick situational awareness

WEATHER
- METAR and TAF from the NOAA aviation weather service
- Weather shown on the map with age and staleness indicators
- No account or API key required

FLIGHT PLANNING
- Build and edit VFR routes
- Instrument strip with heading, speed, and altitude
- Airspace boundaries and temporary flight restrictions

FLIGHT RECORDING AND DEBRIEF
- Records your GPS track and cockpit audio during the flight
- Transcribes cockpit audio on the device, so audio is not sent to a server
- Replay your flight afterward with a synchronized track and transcript
- Digital logbook for your flights

PRIVACY
- Your location, audio, transcripts, flights, and logbook stay on your device
- No analytics, no ads, no tracking
- Open source under MPL-2.0

OpenEFB is built for personal VFR flying. It is not certified for navigation
and is not a substitute for official charts, current weather briefings, or
required onboard equipment. Always cross-check with approved sources.
```

## Keywords (100 char max, comma-separated, no spaces after commas)
`efb,vfr,aviation,pilot,flight,moving map,sectional,metar,taf,logbook,navigation,aviation weather` (96)

## Support URL
`https://github.com/<org>/openefb` (confirm the public repo URL)

## Marketing URL (optional)
Leave blank or point to the repo/README.

## Copyright
`2026 Quartermint`

## App Review notes (private, to reviewer)
```
OpenEFB is a VFR electronic flight bag. To exercise it fully:
- Location: grant "While Using" to see the moving map center on the simulated
  location. Background location is used to keep recording a flight track with
  the screen off.
- Microphone and Speech Recognition: used only to record and transcribe cockpit
  audio on-device during a flight recording. Transcription is forced on-device
  (requiresOnDeviceRecognition = true).
- Weather uses the public NOAA aviationweather.gov API (no key, no account).
No login is required.
```

## Age rating
Expected 4+ (no objectionable content). Confirm in the questionnaire.

## What to fill in
- Confirm public GitHub repo URL for Support URL.
- Confirm final display name (app shows "OpenEFB"; Xcode PRODUCT_NAME is efb-212).
- Screenshots: see ../screenshots (regenerate at required store resolutions).
