# OpenEFB

[![Swift 5.0+](https://img.shields.io/badge/Swift-5.0+-FA7343?logo=swift&logoColor=white)](https://swift.org)
[![iOS 26](https://img.shields.io/badge/iOS-26-000000?logo=apple&logoColor=white)](https://developer.apple.com)
[![License: MPL-2.0](https://img.shields.io/badge/License-MPL--2.0-brightgreen.svg)](LICENSE)

A free, open-source iPad VFR Electronic Flight Bag that combines moving-map navigation with flight recording and AI-powered post-flight debrief.

## The Problem

ForeFlight costs $120-360/yr. Every data source it uses -- FAA airports, VFR sectional charts, NOAA weather -- is **free and public domain**. Android pilots have Avare (free, open-source). iOS pilots have nothing. OpenEFB fills that gap.

## What Makes It Different

1. **Open-source and free** -- all flight-critical features, forever
2. **Simplicity-first** -- VFR-focused, not an IFR app with VFR bolted on
3. **Integrated flight recording** -- GPS track + cockpit audio + radio transcription, built into the EFB
4. **AI-powered debrief** -- post-flight analysis with radio phraseology scoring and key-moment identification

## Features

**Navigation**
- Moving map with VFR sectional chart overlays (FAA GeoTIFFs)
- Full US airport database (~20,000 airports) with spatial search
- Airport info sheets (runways, frequencies, weather)
- GPS ownship tracking with instrument strip (GS, ALT, VSI, TRK)

**Weather**
- METAR/TAF display with flight category color coding (VFR/MVFR/IFR/LIFR)
- Weather map dots across all visible airports
- Real-time NOAA Aviation Weather API integration

**Flight Planning**
- Departure to destination route planning with map overlay
- Nearest airport emergency feature
- Aircraft and pilot profiles
- Chart download manager with offline support

**Complete Offline Operation**
- All aviation data cached locally
- VFR sectional charts stored as MBTiles
- No network required after initial data download

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Platform | iPad, iOS 26.0 |
| Language | Swift 5.0+, SwiftUI |
| Architecture | MVVM + Combine |
| Map Engine | MapLibre Native iOS (open-source, no API fees) |
| Aviation Data | SwiftNASR (FAA NASR -- 20K US airports) |
| Database | GRDB (aviation data, R-tree spatial indexes) + SwiftData (user data) |
| Weather | NOAA Aviation Weather API (free, no key required) |
| Charts | FAA VFR Sectional GeoTIFFs converted to MBTiles |
| Recording | Sovereign Flight Recorder packages (GPS, audio, transcription) |
| AI Debrief | Apple Foundation Models (on-device) + Claude API (opt-in) |

## Build and Run

```bash
git clone https://github.com/quartermint/openefb.git
cd openefb
open openefb.xcodeproj

# Select iPad simulator or connected device -> Cmd+R
# Run tests: Cmd+U
```

> **Note:** The Xcode project is currently named `efb-212.xcodeproj` (pending rename). Open with `open efb-212.xcodeproj` until the project file is updated.

## Project Structure

```
openefb/
├── App/                       # App entry point
├── Views/
│   ├── Map/                   # Moving map, instrument strip, airport info
│   ├── Planning/              # Flight plan creation
│   ├── Flights/               # Flight list, detail, debrief
│   ├── Logbook/               # Digital logbook
│   ├── Aircraft/              # Aircraft + pilot profiles
│   ├── Settings/              # App settings, chart downloads
│   └── Components/            # Reusable UI components
├── ViewModels/                # One ViewModel per major view
├── Services/                  # Business logic, API clients, managers
├── Data/
│   ├── AviationDatabase.swift # GRDB -- airports, navaids, airspace
│   └── Models/                # SwiftData @Model classes (user data)
├── Core/
│   ├── AppState.swift         # Root state coordinator
│   └── Extensions/            # Swift extensions
└── Resources/                 # Assets
```

## Data Sources

All free, all public domain:

| Source | Data | Update Cycle |
|--------|------|-------------|
| [FAA NASR](https://nfdc.faa.gov) | Airports, runways, frequencies, navaids, airspace | 28 days |
| [FAA Aeronav](https://aeronav.faa.gov) | VFR sectional chart GeoTIFFs | 56 days |
| [NOAA Aviation Weather](https://aviationweather.gov/data/api/) | METARs, TAFs, PIREPs, SIGMETs | Real-time |
| [FAA TFR](https://tfr.faa.gov) | Temporary flight restrictions | Real-time |

## Roadmap

| Phase | Focus | Status |
|-------|-------|--------|
| **Phase 1** | Core VFR EFB (map, airports, weather, planning) | Complete |
| **Phase 2** | Flight recording + AI debrief | In progress |
| **Phase 3** | IFR procedures, ADS-B traffic, advanced features | Planned |

## Contributing

This project is in early development. Contribution guidelines coming soon. In the meantime, open an issue or start a discussion.

1. Fork the repository
2. Create a feature branch
3. Make your changes and run tests (`Cmd+U`)
4. Open a pull request

## License

[MPL-2.0](LICENSE) -- file-level copyleft. Use it, fork it, improve it, contribute back.

## Disclaimer

OpenEFB is a supplemental reference tool. It is **not** intended as a primary means of navigation. Pilots are responsible for maintaining situational awareness through all available means including current paper charts, ATC communication, and visual references. This software has not been tested, approved, or certified by the FAA or any other aviation authority.
