//
//  NearestAirportView.swift
//  efb-212
//
//  Full sorted list of nearest airports presented when the HUD is tapped.
//  Shows distance, bearing, runway info, and direct-to button for each airport.
//  Per user decision: "tap to expand full sorted list with runways and direct-to option."
//

import SwiftUI

struct NearestAirportView: View {
    let entries: [NearestAirportEntry]
    let onDirectTo: (Airport) -> Void
    let onAirportTap: (String) -> Void

    var body: some View {
        NavigationStack {
            List(entries) { entry in
                NearestAirportRow(
                    entry: entry,
                    onDirectTo: onDirectTo,
                    onAirportTap: onAirportTap
                )
            }
            .navigationTitle("Nearest Airports")
        }
    }
}

// MARK: - NearestAirportRow

struct NearestAirportRow: View {
    let entry: NearestAirportEntry
    let onDirectTo: (Airport) -> Void
    let onAirportTap: (String) -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.airport.icao)
                        .font(.system(.subheadline, design: .monospaced))
                        .fontWeight(.semibold)
                    Text(entry.airport.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                // Runways summary -- show longest runway
                if let runway = entry.airport.runways.first {
                    Text("\(runway.id) \(runway.length)'\u{00D7}\(runway.width)' \(runway.surface.rawValue)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { onAirportTap(entry.airport.icao) }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f NM", entry.distance))
                    .font(.system(.subheadline, design: .monospaced))
                Text(String(format: "%03.0f\u{00B0}", entry.bearing))
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            Button(action: { onDirectTo(entry.airport) }) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Direct to \(entry.airport.icao)")
        }
    }
}

#Preview {
    let entries = [
        NearestAirportEntry(
            airport: Airport(
                icao: "KPAO",
                name: "Palo Alto",
                latitude: 37.461,
                longitude: -122.115,
                elevation: 7,
                type: .airport,
                ownership: .publicOwned,
                runways: [
                    Runway(
                        id: "13/31", length: 2443, width: 70,
                        surface: .asphalt, lighting: .fullTime,
                        baseEndID: "13", reciprocalEndID: "31",
                        baseEndLatitude: 37.458, baseEndLongitude: -122.118,
                        reciprocalEndLatitude: 37.465, reciprocalEndLongitude: -122.112
                    )
                ]
            ),
            distance: 3.2,
            bearing: 245
        ),
        NearestAirportEntry(
            airport: Airport(
                icao: "KNUQ",
                name: "Moffett Federal",
                latitude: 37.416,
                longitude: -122.049,
                elevation: 32,
                type: .airport,
                ownership: .publicOwned
            ),
            distance: 5.8,
            bearing: 135
        ),
    ]

    NearestAirportView(
        entries: entries,
        onDirectTo: { _ in },
        onAirportTap: { _ in }
    )
}
