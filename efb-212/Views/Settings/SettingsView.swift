//
//  SettingsView.swift
//  efb-212
//
//  Main settings view with sections for map configuration, data management,
//  and about/licensing information.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    @State private var defaultMapMode: MapMode = .northUp
    @State private var showSectional = true
    @State private var showAirports = true
    @State private var showAirspace = false
    @State private var showTFRs = false
    @State private var showWeatherDots = false
    @State private var showNavaids = false

    @State private var showingClearCacheAlert = false
    @State private var cacheCleared = false

    var body: some View {
        List {
            // MARK: - Map Settings
            Section("Map") {
                Picker("Default Orientation", selection: $defaultMapMode) {
                    Text("North Up").tag(MapMode.northUp)
                    Text("Track Up").tag(MapMode.trackUp)
                }

                Toggle("VFR Sectional Charts", isOn: $showSectional)
                Toggle("Airports", isOn: $showAirports)
                Toggle("Airspace Boundaries", isOn: $showAirspace)
                Toggle("TFRs", isOn: $showTFRs)
                Toggle("Weather Dots", isOn: $showWeatherDots)
                Toggle("Navaids (VOR/NDB)", isOn: $showNavaids)
            }

            // MARK: - Data Management
            Section("Data") {
                NavigationLink("Chart Downloads") {
                    ChartDownloadView()
                }

                Button("Clear Weather Cache") {
                    showingClearCacheAlert = true
                }
                .foregroundStyle(.red)

                LabeledContent("Battery Level") {
                    Text(batteryText)
                        .foregroundStyle(batteryColor)
                }

                LabeledContent("Power Mode", value: powerModeText)
            }

            // MARK: - About
            Section("About") {
                LabeledContent("Version", value: appVersion)
                LabeledContent("Build", value: buildNumber)
                LabeledContent("License", value: "MPL-2.0")

                NavigationLink("Open Source Licenses") {
                    OpenSourceLicensesView()
                }
            }
        }
        .navigationTitle("Settings")
        .alert("Clear Weather Cache?", isPresented: $showingClearCacheAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                clearWeatherCache()
            }
        } message: {
            Text("This will remove all cached METAR and TAF data. Fresh data will be downloaded when needed.")
        }
        .onAppear {
            syncMapLayerToggles()
        }
        .onChange(of: defaultMapMode) { _, newMode in
            appState.mapMode = newMode
        }
        .onChange(of: showSectional) { _, _ in syncLayersToAppState() }
        .onChange(of: showAirports) { _, _ in syncLayersToAppState() }
        .onChange(of: showAirspace) { _, _ in syncLayersToAppState() }
        .onChange(of: showTFRs) { _, _ in syncLayersToAppState() }
        .onChange(of: showWeatherDots) { _, _ in syncLayersToAppState() }
        .onChange(of: showNavaids) { _, _ in syncLayersToAppState() }
    }

    // MARK: - Map Layer Sync

    /// Reads current AppState visible layers into local toggle state.
    private func syncMapLayerToggles() {
        defaultMapMode = appState.mapMode
        showSectional = appState.visibleLayers.contains(.sectional)
        showAirports = appState.visibleLayers.contains(.airports)
        showAirspace = appState.visibleLayers.contains(.airspace)
        showTFRs = appState.visibleLayers.contains(.tfrs)
        showWeatherDots = appState.visibleLayers.contains(.weatherDots)
        showNavaids = appState.visibleLayers.contains(.navaids)
    }

    /// Writes local toggle state back to AppState visible layers.
    private func syncLayersToAppState() {
        var layers: Set<MapLayer> = [.ownship, .route] // Always show ownship and route
        if showSectional { layers.insert(.sectional) }
        if showAirports { layers.insert(.airports) }
        if showAirspace { layers.insert(.airspace) }
        if showTFRs { layers.insert(.tfrs) }
        if showWeatherDots { layers.insert(.weatherDots) }
        if showNavaids { layers.insert(.navaids) }
        appState.visibleLayers = layers
    }

    // MARK: - Weather Cache

    private func clearWeatherCache() {
        Task {
            do {
                try await appState.databaseManager.clearWeatherCache()
                cacheCleared = true
            } catch {
                // Non-critical — weather will be re-fetched
            }
        }
    }

    // MARK: - Display Helpers

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    private var batteryText: String {
        let pct = Int(appState.batteryLevel * 100)
        return "\(pct)%"
    }

    private var batteryColor: Color {
        switch appState.powerState {
        case .normal: return .primary
        case .batteryConscious: return .orange
        case .emergency: return .red
        }
    }

    private var powerModeText: String {
        switch appState.powerState {
        case .normal: return "Normal"
        case .batteryConscious: return "Battery Saving"
        case .emergency: return "Emergency"
        }
    }
}

// MARK: - Open Source Licenses

struct OpenSourceLicensesView: View {
    var body: some View {
        List {
            Section {
                Text("""
                OpenEFB is licensed under the Mozilla Public License 2.0 (MPL-2.0). \
                This means you are free to use, modify, and distribute this software, \
                provided that modified files remain under the same license.
                """)
                .font(.callout)
            } header: {
                Text("OpenEFB License")
            }

            Section("Third-Party Libraries") {
                LicenseRow(
                    name: "MapLibre Native iOS",
                    license: "BSD-2-Clause",
                    url: "https://github.com/maplibre/maplibre-gl-native-distribution"
                )
                LicenseRow(
                    name: "GRDB.swift",
                    license: "MIT",
                    url: "https://github.com/groue/GRDB.swift"
                )
                LicenseRow(
                    name: "SwiftNASR",
                    license: "MIT",
                    url: "https://github.com/RISCfuture/SwiftNASR"
                )
            }
        }
        .navigationTitle("Licenses")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LicenseRow: View {
    let name: String
    let license: String
    let url: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name)
                .font(.body)
            Text(license)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(url)
                .font(.caption2)
                .foregroundStyle(.blue)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Previews

#Preview("Settings") {
    NavigationStack {
        SettingsView()
    }
    .environmentObject(
        AppState(
            locationManager: PlaceholderLocationManager(),
            databaseManager: PlaceholderDatabaseManager(),
            weatherService: PlaceholderWeatherService()
        )
    )
}
