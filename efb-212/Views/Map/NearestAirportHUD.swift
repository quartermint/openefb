//
//  NearestAirportHUD.swift
//  efb-212
//
//  Floating indicator showing the nearest airport with distance, bearing arrow,
//  and ICAO identifier. Always visible on the map for situational awareness.
//

import SwiftUI
import CoreLocation

struct NearestAirportHUD: View {
    let airport: Airport?
    let ownshipPosition: CLLocation?

    private var distanceNM: Double? {
        guard let airport, let position = ownshipPosition else { return nil }
        let aptLocation = CLLocation(latitude: airport.latitude, longitude: airport.longitude)
        return position.distanceInNM(to: aptLocation)
    }

    private var bearingDegrees: Double? {
        guard let airport, let position = ownshipPosition else { return nil }
        let aptLocation = CLLocation(latitude: airport.latitude, longitude: airport.longitude)
        return position.bearing(to: aptLocation)
    }

    var body: some View {
        if let airport, let distanceNM, let bearingDegrees {
            HStack(spacing: 8) {
                // Bearing arrow
                Image(systemName: "location.north.fill")
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .rotationEffect(.degrees(bearingDegrees))

                // Airport ICAO
                Text(airport.icao)
                    .font(.system(.caption, design: .monospaced, weight: .bold))

                // Distance
                Text(String(format: "%.1f NM", distanceNM))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)

                // Bearing text
                Text(String(format: "%03.0f\u{00B0}", bearingDegrees))
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
        }
    }
}
