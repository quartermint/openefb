//
//  AirportInfoSheet.swift
//  efb-212
//
//  Sheet displayed when user taps an airport on the map.
//  Shows airport details, runways, frequencies, and cached weather.
//

import SwiftUI

struct AirportInfoSheet: View {
    let airport: Airport
    let weather: WeatherCache?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                airportHeaderSection
                runwaysSection
                frequenciesSection
                weatherSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle(airport.icao)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Airport Header

    @ViewBuilder
    private var airportHeaderSection: some View {
        Section("Airport") {
            // Name
            LabeledContent("Name", value: airport.name)

            // ICAO identifier
            LabeledContent("ICAO", value: airport.icao)

            // FAA LID (if different from ICAO)
            if let faaID = airport.faaID {
                LabeledContent("FAA LID", value: faaID)
            }

            // Elevation in feet MSL
            LabeledContent("Elevation") {
                Text("\(Int(airport.elevation))' MSL")  // feet MSL
            }

            // Airport type
            LabeledContent("Type", value: airport.type.rawValue.capitalized)

            // Pattern altitude in feet AGL
            if let patternAlt = airport.patternAltitude {
                LabeledContent("Pattern Altitude") {
                    Text("\(patternAlt)' AGL")  // feet AGL
                }
            }

            // CTAF frequency in MHz
            if let ctaf = airport.ctafFrequency {
                LabeledContent("CTAF") {
                    Text(formatFrequency(ctaf))
                }
            }

            // UNICOM frequency in MHz
            if let unicom = airport.unicomFrequency {
                LabeledContent("UNICOM") {
                    Text(formatFrequency(unicom))
                }
            }

            // Fuel types available
            if !airport.fuelTypes.isEmpty {
                LabeledContent("Fuel") {
                    Text(airport.fuelTypes.joined(separator: ", "))
                }
            }

            // Beacon light
            if airport.hasBeaconLight {
                LabeledContent("Beacon", value: "Yes")
            }

            // Magnetic variation in degrees
            if let magVar = airport.magneticVariation {
                LabeledContent("Mag Var") {
                    let direction = magVar < 0 ? "W" : "E"
                    Text(String(format: "%.1f\u{00B0} %@", abs(magVar), direction))  // degrees
                }
            }
        }
    }

    // MARK: - Runways

    @ViewBuilder
    private var runwaysSection: some View {
        if !airport.runways.isEmpty {
            Section("Runways") {
                ForEach(airport.runways) { runway in
                    RunwayRow(runway: runway)
                }
            }
        }
    }

    // MARK: - Frequencies

    @ViewBuilder
    private var frequenciesSection: some View {
        if !airport.frequencies.isEmpty {
            Section("Frequencies") {
                ForEach(frequenciesByType, id: \.0) { group in
                    ForEach(group.1) { freq in
                        FrequencyRow(frequency: freq)
                    }
                }
            }
        }
    }

    /// Groups frequencies by type for organized display.
    private var frequenciesByType: [(String, [Frequency])] {
        let grouped = Dictionary(grouping: airport.frequencies) { $0.type }
        return grouped
            .sorted { $0.key.sortOrder < $1.key.sortOrder }
            .map { (key, value) in (key.rawValue.uppercased(), value) }
    }

    // MARK: - Weather

    @ViewBuilder
    private var weatherSection: some View {
        if let weather {
            Section {
                WeatherSummaryRow(weather: weather)
            } header: {
                HStack {
                    Text("Weather")
                    Spacer()
                    if weather.isStale {
                        Text("STALE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    /// Formats a frequency value in MHz to standard aviation display (xxx.xxx).
    private func formatFrequency(_ freq: Double) -> String {
        String(format: "%.3f", freq)  // MHz
    }
}

// MARK: - Runway Row

struct RunwayRow: View {
    let runway: Runway

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Runway designator (e.g., "13/31")
            HStack {
                Text("Rwy \(runway.id)")
                    .font(.headline)
                Spacer()
                Text(runway.surface.rawValue.capitalized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                // Dimensions: length x width in feet
                Label {
                    Text("\(runway.length)' x \(runway.width)'")  // feet
                } icon: {
                    Image(systemName: "ruler")
                }
                .font(.subheadline)

                // Lighting
                Label {
                    Text(lightingDescription)
                } icon: {
                    Image(systemName: "lightbulb")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            // Threshold elevations if available (TDZE in feet MSL)
            if runway.baseEndElevation != nil || runway.reciprocalEndElevation != nil {
                HStack(spacing: 16) {
                    if let baseElev = runway.baseEndElevation {
                        Text("\(runway.baseEndID) TDZE: \(Int(baseElev))' MSL")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let recipElev = runway.reciprocalEndElevation {
                        Text("\(runway.reciprocalEndID) TDZE: \(Int(recipElev))' MSL")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var lightingDescription: String {
        switch runway.lighting {
        case .none:     return "No lights"
        case .partTime: return "Part-time"
        case .fullTime: return "Full-time"
        }
    }
}

// MARK: - Frequency Row

struct FrequencyRow: View {
    let frequency: Frequency

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(frequency.name)
                    .font(.subheadline)
                Text(frequency.type.rawValue.uppercased())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(String(format: "%.3f", frequency.frequency))  // MHz
                .font(.subheadline)
                .monospacedDigit()
        }
    }
}

// MARK: - Weather Summary Row

struct WeatherSummaryRow: View {
    let weather: WeatherCache

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Flight category with colored dot
            HStack(spacing: 6) {
                FlightCategoryDot(category: weather.flightCategory)
                Text(weather.flightCategory.rawValue.uppercased())
                    .font(.headline)
                    .foregroundStyle(flightCategoryColor)
                Spacer()
                Text(ageDescription)
                    .font(.caption)
                    .foregroundStyle(weather.isStale ? .orange : .secondary)
            }

            // Key weather parameters
            HStack(spacing: 16) {
                // Temperature in Celsius
                if let temp = weather.temperature {
                    WeatherValueLabel(
                        icon: "thermometer.medium",
                        value: String(format: "%.0f\u{00B0}C", temp)  // Celsius
                    )
                }

                // Wind direction/speed in degrees true / knots
                if let wind = weather.wind {
                    WeatherValueLabel(
                        icon: "wind",
                        value: windDescription(wind)
                    )
                }

                // Visibility in statute miles
                if let vis = weather.visibility {
                    WeatherValueLabel(
                        icon: "eye",
                        value: String(format: "%.1f SM", vis)  // statute miles
                    )
                }

                // Ceiling in feet AGL
                if let ceiling = weather.ceiling {
                    WeatherValueLabel(
                        icon: "cloud",
                        value: "\(ceiling)' AGL"  // feet AGL
                    )
                }
            }

            // Raw METAR text (scrollable if long)
            if let metar = weather.metar {
                Text(metar)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    /// Human-readable age of the weather observation.
    private var ageDescription: String {
        let minutes = Int(weather.age / 60)
        if minutes < 1 {
            return "Just now"
        } else if minutes < 60 {
            return "\(minutes)m ago"
        } else {
            let hours = minutes / 60
            return "\(hours)h \(minutes % 60)m ago"
        }
    }

    /// Formats wind info to standard aviation notation.
    /// Example: "270@12G18" means 270 degrees true, 12 knots gusting 18 knots.
    private func windDescription(_ wind: WindInfo) -> String {
        var result: String
        if wind.isVariable {
            result = "VRB@\(wind.speed)"  // variable direction
        } else {
            result = String(format: "%03d@%d", wind.direction, wind.speed)  // degrees true @ knots
        }
        if let gusts = wind.gusts {
            result += "G\(gusts)"  // gusts in knots
        }
        return result
    }

    private var flightCategoryColor: Color {
        switch weather.flightCategory {
        case .vfr:  return .green
        case .mvfr: return .blue
        case .ifr:  return .red
        case .lifr: return Color(red: 0.8, green: 0.0, blue: 0.8)
        }
    }
}

// MARK: - Weather Value Label

/// Compact icon + value display for weather parameters.
private struct WeatherValueLabel: View {
    let icon: String
    let value: String

    var body: some View {
        Label {
            Text(value)
                .monospacedDigit()
        } icon: {
            Image(systemName: icon)
        }
        .font(.subheadline)
    }
}

// MARK: - FrequencyType Sort Order

private extension FrequencyType {
    /// Sort order for frequency display — most important first.
    var sortOrder: Int {
        switch self {
        case .ctaf:       return 0
        case .tower:      return 1
        case .ground:     return 2
        case .clearance:  return 3
        case .atis:       return 4
        case .awos:       return 5
        case .approach:   return 6
        case .departure:  return 7
        case .unicom:     return 8
        case .multicom:   return 9
        }
    }
}

#Preview("Airport Info Sheet") {
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
            fssID: nil,
            magneticVariation: -13.5,
            patternAltitude: 800,
            fuelTypes: ["100LL"],
            hasBeaconLight: true,
            runways: [
                Runway(
                    id: "13/31",
                    length: 2443,
                    width: 70,
                    surface: .asphalt,
                    lighting: .fullTime,
                    baseEndID: "13",
                    reciprocalEndID: "31",
                    baseEndLatitude: 37.458,
                    baseEndLongitude: -122.119,
                    reciprocalEndLatitude: 37.464,
                    reciprocalEndLongitude: -122.111,
                    baseEndElevation: 4,
                    reciprocalEndElevation: 4
                )
            ],
            frequencies: [
                Frequency(id: UUID(), type: .tower, frequency: 118.6, name: "Palo Alto Tower"),
                Frequency(id: UUID(), type: .atis, frequency: 135.275, name: "Palo Alto ATIS")
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
