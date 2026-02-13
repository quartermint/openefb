//
//  NearestAirportView.swift
//  efb-212
//
//  Emergency nearest-airport list sorted by distance from current position.
//  Safety-critical feature: large tappable rows, high contrast, glove-friendly.
//  Tapping a row opens AirportInfoSheet for full details.
//

import SwiftUI

struct NearestAirportView: View {
    @ObservedObject var viewModel: NearestAirportViewModel
    let weatherViewModel: WeatherViewModel?
    @Environment(\.dismiss) private var dismiss

    @State private var selectedAirport: Airport?
    @State private var showingAirportInfo: Bool = false

    var body: some View {
        NavigationStack {
            Group {
                if !viewModel.hasGPS {
                    noGPSView
                } else if viewModel.isLoading && viewModel.nearestAirports.isEmpty {
                    loadingView
                } else if viewModel.nearestAirports.isEmpty {
                    emptyView
                } else {
                    airportList
                }
            }
            .navigationTitle("Nearest Airports")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    emergencyBadge
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.headline)
                }
            }
            .task {
                await viewModel.refresh()
            }
            .sheet(isPresented: $showingAirportInfo) {
                if let airport = selectedAirport {
                    let weather = weatherViewModel?.weatherData[airport.icao]
                    AirportInfoSheet(airport: airport, weather: weather)
                }
            }
        }
    }

    // MARK: - Airport List

    @ViewBuilder
    private var airportList: some View {
        List {
            ForEach(viewModel.nearestAirports) { nearby in
                NearestAirportRow(nearby: nearby)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedAirport = nearby.airport
                        showingAirportInfo = true
                    }
            }
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.refresh()
        }
    }

    // MARK: - Empty States

    @ViewBuilder
    private var noGPSView: some View {
        ContentUnavailableView {
            Label("GPS Unavailable", systemImage: "location.slash.fill")
                .foregroundStyle(.red)
        } description: {
            Text("Enable Location Services to find nearby airports.")
        }
    }

    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Searching nearby airports...")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var emptyView: some View {
        ContentUnavailableView {
            Label("No Airports Found", systemImage: "airplane.circle")
        } description: {
            Text("No airports found within search radius. Ensure aviation data has been imported in Settings.")
        }
    }

    // MARK: - Emergency Badge

    @ViewBuilder
    private var emergencyBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.white)
            Text("NEAREST")
                .font(.caption)
                .fontWeight(.black)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.red)
        .clipShape(Capsule())
    }
}

// MARK: - NearestAirportRow

struct NearestAirportRow: View {
    let nearby: NearbyAirport

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Top line: identifier + name + towered indicator
            HStack(alignment: .firstTextBaseline) {
                Text(nearby.airport.icao)
                    .font(.title2)
                    .fontWeight(.bold)
                    .monospacedDigit()

                if nearby.isTowered {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }

                Text(nearby.airport.name)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer()

                // Distance + bearing
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.1f nm", nearby.distanceNM))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                    Text(String(format: "%03.0f\u{00B0}", nearby.bearingTrue))  // degrees true
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }

            // Bottom line: runway info + CTAF + elevation
            HStack(spacing: 16) {
                // Longest runway
                if let length = nearby.longestRunwayLength {
                    Label {
                        HStack(spacing: 2) {
                            Text("\(length)'")  // feet
                            if let surface = nearby.longestRunwaySurface {
                                Text(surface.rawValue.capitalized)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } icon: {
                        Image(systemName: "ruler")
                    }
                    .font(.subheadline)
                }

                // CTAF frequency
                if let ctaf = nearby.ctafFrequency {
                    Label {
                        Text(String(format: "%.3f", ctaf))  // MHz
                            .monospacedDigit()
                    } icon: {
                        Image(systemName: "radio")
                    }
                    .font(.subheadline)
                }

                // Elevation
                Label {
                    Text("\(Int(nearby.airport.elevation))' MSL")  // feet MSL
                } icon: {
                    Image(systemName: "mountain.2")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Spacer()

                // Airport type indicator
                airportTypeIcon
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    // MARK: - Airport Type Icon

    @ViewBuilder
    private var airportTypeIcon: some View {
        switch nearby.airport.type {
        case .airport:
            if nearby.isTowered {
                Image(systemName: "building.2")
                    .foregroundStyle(.blue)
                    .font(.caption)
            } else {
                Image(systemName: "circle.fill")
                    .foregroundStyle(.purple)
                    .font(.system(size: 8))
            }
        case .heliport:
            Image(systemName: "h.circle.fill")
                .foregroundStyle(.orange)
                .font(.caption)
        case .seaplane:
            Image(systemName: "water.waves")
                .foregroundStyle(.cyan)
                .font(.caption)
        case .ultralight:
            Image(systemName: "leaf.fill")
                .foregroundStyle(.green)
                .font(.caption)
        }
    }

    // MARK: - Accessibility

    private var accessibilityDescription: String {
        var parts = [
            nearby.airport.icao,
            nearby.airport.name,
            String(format: "%.1f nautical miles", nearby.distanceNM),
            String(format: "bearing %03.0f degrees", nearby.bearingTrue)
        ]
        if let length = nearby.longestRunwayLength {
            parts.append("runway \(length) feet")
        }
        if nearby.isTowered {
            parts.append("towered")
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Preview

#Preview("Nearest Airports") {
    NearestAirportView(
        viewModel: {
            let vm = NearestAirportViewModel(
                databaseManager: PlaceholderDatabaseManager(),
                locationManager: PlaceholderLocationManager()
            )
            return vm
        }(),
        weatherViewModel: nil
    )
}
