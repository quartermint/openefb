//
//  InstrumentStripView.swift
//  efb-212
//
//  Bottom strip showing key flight instruments:
//  GS (ground speed), ALT (altitude), VS (vertical speed),
//  TRK (track), DTG (distance to go), ETE (estimated time enroute).
//  All values read from AppState which is updated by location services.
//

import SwiftUI

struct InstrumentStripView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 0) {
            // Ground Speed — knots
            InstrumentCell(
                label: "GS",
                value: String(format: "%.0f", appState.groundSpeed),
                unit: "KT"
            )

            instrumentDivider

            // Altitude — feet MSL
            InstrumentCell(
                label: "ALT",
                value: String(format: "%.0f", appState.altitude),
                unit: "FT"
            )

            instrumentDivider

            // Vertical Speed — feet per minute (signed: +climb, -descend)
            InstrumentCell(
                label: "VS",
                value: String(format: "%+.0f", appState.verticalSpeed),
                unit: "FPM"
            )

            instrumentDivider

            // Track — degrees true, zero-padded to 3 digits
            InstrumentCell(
                label: "TRK",
                value: String(format: "%03.0f", appState.track),
                unit: "\u{00B0}" // degree symbol
            )

            // Distance to next waypoint — nautical miles (shown only if flight plan active)
            if let dtg = appState.distanceToNext {
                instrumentDivider
                InstrumentCell(
                    label: "DTG",
                    value: String(format: "%.1f", dtg),
                    unit: "NM"
                )
            }

            // Estimated time enroute — HH:MM or MM:SS (shown only if flight plan active)
            if let ete = appState.estimatedTimeEnroute {
                instrumentDivider
                InstrumentCell(
                    label: "ETE",
                    value: formatETE(ete),
                    unit: ""
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helpers

    /// Divider between instrument cells.
    private var instrumentDivider: some View {
        Divider()
            .frame(height: 32)
            .padding(.horizontal, 4)
    }

    /// Format ETE as HH:MM if >= 1 hour, otherwise MM:SS.
    /// - Parameter interval: Time interval in seconds.
    /// - Returns: Formatted string (e.g., "1:23" or "05:30").
    private func formatETE(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        if totalSeconds >= 3600 {
            // Hours:Minutes
            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            return String(format: "%d:%02d", hours, minutes)
        } else {
            // Minutes:Seconds
            let minutes = totalSeconds / 60
            let seconds = totalSeconds % 60
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// MARK: - InstrumentCell

/// Single instrument readout cell displaying label, value, and unit.
struct InstrumentCell: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(.title3, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(minWidth: 60)
        .padding(.horizontal, 4)
    }
}

// MARK: - Previews

#Preview("Instrument Strip — Enroute") {
    InstrumentStripView()
        .environmentObject(previewAppState(
            groundSpeed: 105,
            altitude: 3500,
            verticalSpeed: 200,
            track: 285,
            distanceToNext: 12.4,
            estimatedTimeEnroute: 720
        ))
        .padding()
}

#Preview("Instrument Strip — Ground") {
    InstrumentStripView()
        .environmentObject(previewAppState(
            groundSpeed: 0,
            altitude: 7,
            verticalSpeed: 0,
            track: 0,
            distanceToNext: nil,
            estimatedTimeEnroute: nil
        ))
        .padding()
}

// MARK: - Preview Helpers

/// Creates a mock AppState for preview purposes.
private func previewAppState(
    groundSpeed: Double,
    altitude: Double,
    verticalSpeed: Double,
    track: Double,
    distanceToNext: Double?,
    estimatedTimeEnroute: TimeInterval?
) -> AppState {
    let state = AppState(
        locationManager: PlaceholderLocationManager(),
        databaseManager: PlaceholderDatabaseManager(),
        weatherService: PlaceholderWeatherService()
    )
    state.groundSpeed = groundSpeed
    state.altitude = altitude
    state.verticalSpeed = verticalSpeed
    state.track = track
    state.distanceToNext = distanceToNext
    state.estimatedTimeEnroute = estimatedTimeEnroute
    return state
}
