//
//  AirportInfoSheet.swift
//  efb-212
//
//  Bottom sheet with airport details, runways, frequencies, weather,
//  and manual refresh button. Half-height default per user decision.
//  Per UI-SPEC: .presentationBackground(.regularMaterial), 24pt horizontal padding.
//

import SwiftUI

struct AirportInfoSheet: View {

    @Environment(AppState.self) private var appState

    let databaseService: any DatabaseServiceProtocol
    let weatherService: any WeatherServiceProtocol

    @State private var airport: Airport?
    @State private var weatherViewModel: WeatherViewModel?
    @State private var isRawMETARExpanded: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                if let airport {
                    VStack(alignment: .leading, spacing: 20) {
                        headerSection(airport)
                        infoChipsRow(airport)
                        twoColumnBody(airport)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                } else {
                    ProgressView("Loading airport...")
                        .padding(.top, 40)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        appState.isPresentingAirportInfo = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.title2)
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
        .presentationDetents([.medium])
        .presentationBackground(.regularMaterial)
        .onAppear {
            loadAirport()
        }
    }

    // MARK: - Header Section

    @ViewBuilder
    private func headerSection(_ airport: Airport) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                // ICAO identifier
                HStack(spacing: 8) {
                    Text(airport.icao)
                        .font(.system(.largeTitle, design: .rounded, weight: .semibold))

                    // Flight category dot + label
                    if let wx = weatherViewModel?.currentWeather {
                        HStack(spacing: 4) {
                            FlightCategoryDot(category: wx.flightCategory)
                            Text(wx.flightCategory.rawValue.uppercased())
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(FlightCategoryDot(category: wx.flightCategory).color)
                        }
                    }
                }

                // Airport name
                Text(airport.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    // MARK: - Info Chips Row

    @ViewBuilder
    private func infoChipsRow(_ airport: Airport) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Elevation chip
                infoChip(icon: "arrow.up", text: "\(Int(airport.elevation))' MSL")

                // Type chip
                infoChip(icon: "airplane", text: airport.type.rawValue.capitalized)

                // Pattern altitude chip
                if let tpa = airport.patternAltitude {
                    infoChip(icon: "arrow.clockwise", text: "TPA \(tpa)'")
                }

                // Fuel chip
                if !airport.fuelTypes.isEmpty {
                    infoChip(icon: "fuelpump", text: airport.fuelTypes.joined(separator: ", "))
                }
            }
        }
    }

    @ViewBuilder
    private func infoChip(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.secondary.opacity(0.12))
        .clipShape(Capsule())
    }

    // MARK: - Two Column Body

    @ViewBuilder
    private func twoColumnBody(_ airport: Airport) -> some View {
        HStack(alignment: .top, spacing: 24) {
            // Left column: Frequencies + Runways
            VStack(alignment: .leading, spacing: 16) {
                frequenciesSection(airport)
                runwaysSection(airport)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right column: Weather
            VStack(alignment: .leading, spacing: 16) {
                weatherSection()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Frequencies Section

    @ViewBuilder
    private func frequenciesSection(_ airport: Airport) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("FREQUENCIES")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            if airport.frequencies.isEmpty {
                // Show CTAF/UNICOM if available in airport model
                if let ctaf = airport.ctafFrequency {
                    frequencyRow(type: "CTAF", value: ctaf)
                }
                if let unicom = airport.unicomFrequency {
                    frequencyRow(type: "UNICOM", value: unicom)
                }
                if airport.ctafFrequency == nil && airport.unicomFrequency == nil {
                    Text("No frequencies available")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            } else {
                ForEach(airport.frequencies) { freq in
                    frequencyRow(type: freq.type.rawValue.uppercased(), value: freq.frequency)
                }
            }
        }
    }

    @ViewBuilder
    private func frequencyRow(type: String, value: Double) -> some View {
        HStack {
            Text(type)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .leading)
            Text(String(format: "%.3f", value))
                .font(.subheadline.monospaced())
        }
    }

    // MARK: - Runways Section

    @ViewBuilder
    private func runwaysSection(_ airport: Airport) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("RUNWAYS")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            if airport.runways.isEmpty {
                Text("No runway data available")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(airport.runways) { runway in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(runway.id)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("\(runway.length)'x\(runway.width)'")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text(runway.surface.rawValue.capitalized)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }

    // MARK: - Weather Section

    @ViewBuilder
    private func weatherSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header with manual refresh button
            HStack {
                Text("WEATHER")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Spacer()

                // Manual refresh button per locked decision
                Button(action: {
                    Task {
                        await weatherViewModel?.refreshWeather()
                    }
                }) {
                    if weatherViewModel?.isLoading == true {
                        ProgressView()
                            .controlSize(.small)
                            .frame(width: 24, height: 24)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .frame(width: 24, height: 24)
                    }
                }
                .foregroundStyle(.secondary)
                .accessibilityLabel("Refresh weather")
            }

            // Weather content
            if let wx = weatherViewModel?.currentWeather {
                weatherDataView(wx)
            } else if weatherViewModel?.isLoading == true {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Loading weather...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if weatherViewModel?.error != nil {
                Text("No weather available")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                Text("No weather available")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    @ViewBuilder
    private func weatherDataView(_ wx: WeatherCache) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Flight category + staleness badge
            HStack {
                FlightCategoryDot(category: wx.flightCategory)
                Text(wx.flightCategory.rawValue.uppercased())
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
                WeatherBadge(observationTime: wx.observationTime)
            }

            // Decoded weather fields
            if let vm = weatherViewModel {
                weatherFieldRow("Wind", value: vm.decodedWind)
                weatherFieldRow("Temp", value: vm.decodedTemp)
                weatherFieldRow("Dewpt", value: vm.decodedDew)
                weatherFieldRow("Vis", value: vm.decodedVisibility)
                weatherFieldRow("Ceiling", value: vm.decodedCeiling)
            }

            // Raw METAR (expandable per user decision)
            if let rawMETAR = wx.rawMETAR {
                Button {
                    withAnimation { isRawMETARExpanded.toggle() }
                } label: {
                    HStack {
                        Text("Raw METAR")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Image(systemName: isRawMETARExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)

                if isRawMETARExpanded {
                    Text(rawMETAR)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.primary)
                        .padding(8)
                        .background(.secondary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }

            // TAF (if available)
            if let taf = weatherViewModel?.currentTAF {
                Text("TAF")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                Text(taf)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.primary)
                    .padding(8)
                    .background(.secondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
    }

    @ViewBuilder
    private func weatherFieldRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .leading)
            Text(value)
                .font(.caption.monospaced())
        }
    }

    // MARK: - Data Loading

    private func loadAirport() {
        guard let icao = appState.selectedAirportID else { return }

        // Load airport from database
        do {
            airport = try databaseService.airport(byICAO: icao)
        } catch {
            airport = nil
        }

        // Initialize weather view model and load weather
        let vm = WeatherViewModel(weatherService: weatherService)
        weatherViewModel = vm
        Task {
            await vm.loadWeather(for: icao)
        }
    }
}

#Preview {
    AirportInfoSheet(
        databaseService: PlaceholderDatabaseService(),
        weatherService: PlaceholderWeatherService()
    )
    .environment(AppState())
}
