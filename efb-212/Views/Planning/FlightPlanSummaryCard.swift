//
//  FlightPlanSummaryCard.swift
//  efb-212
//
//  Compact floating card showing flight plan summary data:
//  route header (DEP -> DEST), distance (nm), ETE (h:mm), fuel (gal).
//  Used both on the Flights tab and as a map overlay on the Map tab.
//

import SwiftUI

struct FlightPlanSummaryCard: View {
    let distanceNM: Double             // nautical miles
    let ete: String                    // pre-formatted "h:mm"
    let fuelGallons: Double?           // gallons (nil if no aircraft profile)
    let departure: String              // ICAO identifier
    let destination: String            // ICAO identifier

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Route header: DEP -> DEST
            HStack {
                Text(departure)
                    .font(.headline.bold())
                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
                Text(destination)
                    .font(.headline.bold())
            }

            Divider()

            // Summary metrics in a row
            HStack(spacing: 16) {
                VStack {
                    Text(String(format: "%.1f", distanceNM))
                        .font(.title3.bold())
                    Text("nm")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack {
                    Text(ete)
                        .font(.title3.bold())
                    Text("ETE")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let fuel = fuelGallons {
                    VStack {
                        Text(String(format: "%.1f", fuel))
                            .font(.title3.bold())
                        Text("gal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 4)
    }
}

#Preview {
    FlightPlanSummaryCard(
        distanceNM: 125.4,
        ete: "1:15",
        fuelGallons: 12.3,
        departure: "KPAO",
        destination: "KMOD"
    )
    .padding()
}
