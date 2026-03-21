//
//  NearestAirportHUD.swift
//  efb-212
//
//  Persistent top-right badge showing the closest airport with distance and bearing.
//  Tapping opens the full nearest airports list. Per UI-SPEC: capsule shape,
//  .ultraThinMaterial background, 8pt horizontal / 4pt vertical padding,
//  monospaced caption for ICAO and distance.
//

import SwiftUI

struct NearestAirportHUD: View {
    @Environment(AppState.self) private var appState

    let nearestAirport: Airport?
    let distance: Double?   // nautical miles
    let bearing: Double?    // degrees true

    var body: some View {
        if let airport = nearestAirport, let dist = distance, let brg = bearing {
            Button(action: { appState.isPresentingNearestList = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "airplane")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                    Text(airport.icao)
                        .font(.system(.caption2, design: .monospaced))
                        .fontWeight(.semibold)
                    Text(String(format: "%.1f NM", dist))
                        .font(.system(.caption2, design: .monospaced))
                        .fontWeight(.medium)
                    Text(String(format: "%03.0f\u{00B0}", brg))
                        .font(.system(.caption2, design: .monospaced))
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            }
            .accessibilityLabel("Nearest airport \(airport.icao), \(String(format: "%.1f", dist)) nautical miles, bearing \(String(format: "%03.0f", brg)) degrees. Tap to show nearest airports list.")
        }
    }
}

#Preview {
    let sampleAirport = Airport(
        icao: "KPAO",
        name: "Palo Alto",
        latitude: 37.461,
        longitude: -122.115,
        elevation: 7,
        type: .airport,
        ownership: .publicOwned
    )

    NearestAirportHUD(
        nearestAirport: sampleAirport,
        distance: 3.2,
        bearing: 245
    )
    .environment(AppState())
    .padding()
}
