//
//  FlightPlanView.swift
//  efb-212
//
//  Flight plan creation and editing view.
//  Allows entry of departure/destination ICAO codes, shows computed
//  route info, and displays weather at both airports.
//  MainActor by default (SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor).
//

import SwiftUI

struct FlightPlanView: View {

    @ObservedObject var viewModel: FlightPlanViewModel
    @ObservedObject var weatherViewModel: WeatherViewModel

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Route Entry
                Section("Route") {
                    HStack {
                        Text("From")
                            .foregroundStyle(.secondary)
                            .frame(width: 50, alignment: .leading)
                        TextField("ICAO (e.g., KPAO)", text: $viewModel.departureICAO)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .font(.system(.body, design: .monospaced))
                    }

                    HStack {
                        Text("To")
                            .foregroundStyle(.secondary)
                            .frame(width: 50, alignment: .leading)
                        TextField("ICAO (e.g., KSQL)", text: $viewModel.destinationICAO)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .font(.system(.body, design: .monospaced))
                    }
                }

                // MARK: - Actions
                Section {
                    Button {
                        Task {
                            await viewModel.createFlightPlan()
                            // Fetch weather for both airports after plan creation
                            if viewModel.activePlan != nil {
                                await fetchRouteWeather()
                            }
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if viewModel.isCreatingPlan {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text("Create Plan")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(viewModel.departureICAO.isEmpty || viewModel.destinationICAO.isEmpty || viewModel.isCreatingPlan)

                    if viewModel.activePlan != nil {
                        Button(role: .destructive) {
                            viewModel.clearFlightPlan()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Clear Plan")
                                Spacer()
                            }
                        }
                    }
                }

                // MARK: - Airport Info
                if let depAirport = viewModel.departureAirport {
                    Section("Departure") {
                        airportInfoRow(airport: depAirport)
                        weatherRow(for: depAirport.icao)
                    }
                }

                if let destAirport = viewModel.destinationAirport {
                    Section("Destination") {
                        airportInfoRow(airport: destAirport)
                        weatherRow(for: destAirport.icao)
                    }
                }

                // MARK: - Route Details
                if viewModel.activePlan != nil {
                    Section("Route Details") {
                        if let distance = viewModel.formattedDistance {
                            detailRow(label: "Distance", value: distance)
                        }
                        if let ete = viewModel.formattedETE {
                            detailRow(label: "Est. Time En Route", value: ete)
                        }
                        if let fuel = viewModel.formattedFuel {
                            detailRow(label: "Est. Fuel", value: fuel)
                        }
                        if let altitude = viewModel.formattedAltitude {
                            detailRow(label: "Cruise Altitude", value: altitude)
                        }
                        if let speed = viewModel.formattedSpeed {
                            detailRow(label: "Cruise Speed", value: speed)
                        }
                    }
                }
            }
            .navigationTitle("Flight Plan")
            .alert(item: $viewModel.error) { error in
                Alert(
                    title: Text("Flight Plan Error"),
                    message: Text(error.localizedDescription),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    // MARK: - Subviews

    /// Row displaying airport name and elevation.
    @ViewBuilder
    private func airportInfoRow(airport: Airport) -> some View {
        HStack {
            Text(airport.icao)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.semibold)
            Text(airport.name)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(Int(airport.elevation)) ft MSL")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    /// Row displaying weather info for a station, if available.
    @ViewBuilder
    private func weatherRow(for stationID: String) -> some View {
        if let weather = weatherViewModel.weatherData[stationID.uppercased()] {
            HStack(spacing: 8) {
                FlightCategoryDot(category: weather.flightCategory, size: 10)
                Text(weather.flightCategory.rawValue.uppercased())
                    .font(.caption)
                    .fontWeight(.medium)

                if let metar = weather.metar {
                    Text(metar)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                WeatherBadge(weather: weather)
            }
        } else {
            HStack {
                Text("No weather data")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Fetch") {
                    Task {
                        await weatherViewModel.fetchWeather(for: stationID)
                    }
                }
                .font(.caption)
            }
        }
    }

    /// Generic key-value detail row.
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }

    // MARK: - Helpers

    /// Fetch weather for departure and destination airports.
    private func fetchRouteWeather() async {
        var stations: [String] = []
        if let dep = viewModel.departureAirport {
            stations.append(dep.icao)
        }
        if let dest = viewModel.destinationAirport {
            stations.append(dest.icao)
        }
        if !stations.isEmpty {
            await weatherViewModel.fetchWeatherForStations(stations)
        }
    }
}

// MARK: - Preview

#Preview {
    // Preview requires mock services — show structure only
    Text("FlightPlanView requires FlightPlanViewModel and WeatherViewModel")
        .padding()
}
