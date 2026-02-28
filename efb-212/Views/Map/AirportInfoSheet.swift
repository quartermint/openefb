//
//  AirportInfoSheet.swift
//  efb-212
//
//  Sheet displayed when user taps an airport on the map.
//  Compact aviation-style card — no scroll needed on iPad.
//

import SwiftUI

struct AirportInfoSheet: View {
    let airport: Airport
    let initialWeather: WeatherCache?
    var weatherViewModel: WeatherViewModel?
    @Environment(\.dismiss) private var dismiss
    @State private var isLoadingWeather: Bool = false

    /// Resolved weather — either passed in or fetched on-demand.
    private var weather: WeatherCache? {
        // Prefer fresh data from the view model if available
        if let vm = weatherViewModel, let fetched = vm.weatherData[airport.icao] {
            return fetched
        }
        return initialWeather
    }

    init(airport: Airport, weather: WeatherCache?, weatherViewModel: WeatherViewModel? = nil) {
        self.airport = airport
        self.initialWeather = weather
        self.weatherViewModel = weatherViewModel
    }

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            Capsule()
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 10)

            // Header bar
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(airport.icao)
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))

                    Text(airport.name)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Weather badge (top-right)
                if let weather {
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 6) {
                            FlightCategoryDot(category: weather.flightCategory)
                            Text(weather.flightCategory.rawValue.uppercased())
                                .font(.headline)
                                .foregroundStyle(flightCategoryColor(weather.flightCategory))
                        }
                        if weather.isStale {
                            Text("STALE")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.orange)
                        }
                    }
                }

                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .padding(.leading, 8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            // Quick info chips
            HStack(spacing: 12) {
                InfoChip(icon: "arrow.up", label: "\(Int(airport.elevation))' MSL")
                InfoChip(icon: "airplane.circle", label: airport.type.rawValue.capitalized)
                if let patternAlt = airport.patternAltitude {
                    InfoChip(icon: "arrow.triangle.turn.up.right.circle", label: "TPA \(patternAlt)' AGL")
                }
                if !airport.fuelTypes.isEmpty {
                    InfoChip(icon: "fuelpump", label: airport.fuelTypes.joined(separator: ", "))
                }
                if airport.hasBeaconLight {
                    InfoChip(icon: "light.beacon.max", label: "BCN")
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            Divider().padding(.vertical, 12)

            // Main content grid — two columns
            HStack(alignment: .top, spacing: 20) {
                // Left column: Runways + Frequencies
                VStack(alignment: .leading, spacing: 16) {
                    // Frequencies (compact)
                    if !airport.frequencies.isEmpty || airport.ctafFrequency != nil {
                        FrequencyBlock(airport: airport)
                    }

                    // Runways
                    if !airport.runways.isEmpty {
                        RunwayBlock(runways: airport.runways)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Right column: Weather details
                VStack(alignment: .leading, spacing: 12) {
                    if let weather {
                        WeatherBlock(weather: weather)
                    } else if isLoadingWeather {
                        HStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Loading weather...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("No weather available")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Mag var
                    if let magVar = airport.magneticVariation {
                        HStack(spacing: 4) {
                            Image(systemName: "safari")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            let direction = magVar < 0 ? "W" : "E"
                            Text("Mag Var \(String(format: "%.1f", abs(magVar)))\u{00B0}\(direction)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 20)

            Spacer(minLength: 0)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .presentationBackground(.regularMaterial)
        .task {
            // Fetch weather on-demand if not already cached
            if weather == nil, let vm = weatherViewModel {
                isLoadingWeather = true
                await vm.fetchWeather(for: airport.icao)
                isLoadingWeather = false
            }
        }
    }

    private func flightCategoryColor(_ category: FlightCategory) -> Color {
        switch category {
        case .vfr:  return .green
        case .mvfr: return .blue
        case .ifr:  return .red
        case .lifr: return Color(red: 0.8, green: 0.0, blue: 0.8)
        }
    }
}

// MARK: - Info Chip

private struct InfoChip: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.12))
        .clipShape(Capsule())
    }
}

// MARK: - Frequency Block

private struct FrequencyBlock: View {
    let airport: Airport

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("FREQUENCIES")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)

            // CTAF / UNICOM first (most important)
            if let ctaf = airport.ctafFrequency {
                FreqLine(label: "CTAF", freq: ctaf)
            }
            if let unicom = airport.unicomFrequency, unicom != airport.ctafFrequency {
                FreqLine(label: "UNICOM", freq: unicom)
            }

            // Other frequencies
            let sorted = airport.frequencies.sorted { freqOrder($0.type) < freqOrder($1.type) }
            ForEach(sorted.prefix(6)) { freq in
                FreqLine(label: freq.type.rawValue.uppercased(), freq: freq.frequency)
            }
        }
    }

    private func freqOrder(_ type: FrequencyType) -> Int {
        switch type {
        case .tower: return 0
        case .ground: return 1
        case .atis: return 2
        case .awos: return 3
        case .approach: return 4
        case .departure: return 5
        case .clearance: return 6
        case .ctaf: return 7
        case .unicom: return 8
        case .multicom: return 9
        }
    }
}

private struct FreqLine: View {
    let label: String
    let freq: Double

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)
            Text(String(format: "%.3f", freq))
                .font(.system(.subheadline, design: .monospaced, weight: .medium))
        }
    }
}

// MARK: - Runway Block

private struct RunwayBlock: View {
    let runways: [Runway]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("RUNWAYS")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)

            ForEach(runways) { runway in
                HStack(spacing: 12) {
                    Text(runway.id)
                        .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                        .frame(width: 50, alignment: .leading)

                    Text("\(runway.length)' x \(runway.width)'")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(runway.surface.rawValue.capitalized)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if runway.lighting != .none {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                    }
                }
            }
        }
    }
}

// MARK: - Weather Block

private struct WeatherBlock: View {
    let weather: WeatherCache

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WEATHER")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)

            // Wind
            if let wind = weather.wind {
                HStack(spacing: 6) {
                    Image(systemName: "wind")
                        .font(.caption)
                    if wind.isVariable {
                        Text("VRB @ \(wind.speed) KT")
                            .font(.subheadline)
                    } else {
                        Text(String(format: "%03d\u{00B0} @ %d KT", wind.direction, wind.speed))
                            .font(.system(.subheadline, design: .monospaced))
                    }
                    if let gusts = wind.gusts {
                        Text("G\(gusts)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(.orange)
                    }
                }
            }

            // Temp / Dewpoint
            HStack(spacing: 16) {
                if let temp = weather.temperature {
                    HStack(spacing: 4) {
                        Image(systemName: "thermometer.medium")
                            .font(.caption)
                        Text(String(format: "%.0f\u{00B0}C", temp))
                            .font(.subheadline)
                    }
                }
                if let dew = weather.dewpoint {
                    HStack(spacing: 4) {
                        Image(systemName: "drop")
                            .font(.caption)
                        Text(String(format: "%.0f\u{00B0}C", dew))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Visibility + Ceiling
            HStack(spacing: 16) {
                if let vis = weather.visibility {
                    HStack(spacing: 4) {
                        Image(systemName: "eye")
                            .font(.caption)
                        Text(String(format: "%.0f SM", vis))
                            .font(.subheadline)
                    }
                }
                if let ceiling = weather.ceiling {
                    HStack(spacing: 4) {
                        Image(systemName: "cloud")
                            .font(.caption)
                        Text("\(ceiling)' AGL")
                            .font(.subheadline)
                    }
                }
            }

            // Raw METAR
            if let metar = weather.metar {
                Text(metar)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .padding(.top, 2)
            }

            // Age
            Text(ageDescription)
                .font(.caption2)
                .foregroundStyle(weather.isStale ? .orange : .secondary)
        }
    }

    private var ageDescription: String {
        let minutes = Int(weather.age / 60)
        if minutes < 1 { return "Just now" }
        if minutes < 60 { return "\(minutes)m ago" }
        let hours = minutes / 60
        return "\(hours)h \(minutes % 60)m ago"
    }
}

// MARK: - Previews

#Preview("Airport Info Sheet") {
    Color.clear.sheet(isPresented: .constant(true)) {
        AirportInfoSheet(
            airport: Airport(
                icao: "KPAO",
                faaID: "PAO",
                name: "Palo Alto",
                latitude: 37.461,
                longitude: -122.115,
                elevation: 4,
                type: .airport,
                ownership: .publicOwned,
                ctafFrequency: 118.6,
                unicomFrequency: 122.95,
                artccID: "ZOA",
                magneticVariation: -13.5,
                patternAltitude: 800,
                fuelTypes: ["100LL"],
                hasBeaconLight: true,
                runways: [
                    Runway(
                        id: "13/31", length: 2443, width: 70,
                        surface: .asphalt, lighting: .fullTime,
                        baseEndID: "13", reciprocalEndID: "31",
                        baseEndLatitude: 37.458, baseEndLongitude: -122.119,
                        reciprocalEndLatitude: 37.464, reciprocalEndLongitude: -122.111,
                        baseEndElevation: 4, reciprocalEndElevation: 4
                    )
                ],
                frequencies: [
                    Frequency(type: .tower, frequency: 118.6, name: "Palo Alto Tower"),
                    Frequency(type: .atis, frequency: 135.275, name: "Palo Alto ATIS")
                ]
            ),
            weather: WeatherCache(
                stationID: "KPAO",
                metar: "KPAO 121756Z 31008KT 10SM FEW025 16/09 A3002",
                flightCategory: .vfr,
                temperature: 16,
                dewpoint: 9,
                wind: WindInfo(direction: 310, speed: 8, gusts: nil, isVariable: false),
                visibility: 10,
                ceiling: 2500
            )
        )
    }
}
