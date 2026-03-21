//
//  LayerControlsView.swift
//  efb-212
//
//  Layer toggle panel with .regularMaterial background per UI-SPEC.
//  Controls visibility of airports, airspace, TFRs, weather dots, navaids.
//  Includes sectional opacity slider and chart expiration badge (INFRA-03).
//  Map style picker for VFR Sectional, Street, Satellite, Terrain.
//

import SwiftUI

struct LayerControlsView: View {
    let mapViewModel: MapViewModel
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState

        VStack(alignment: .leading, spacing: 12) {
            // Title
            Text("Map Layers")
                .font(.title3)
                .fontWeight(.semibold)

            Divider()

            // Layer toggles
            layerToggle(layer: .airports, label: "Airports", tint: .cyan)
            layerToggle(layer: .airspace, label: "Airspace", tint: .orange)
            tfrToggle()
            layerToggle(layer: .weatherDots, label: "Weather", tint: .green)

            // Weather data age badge (per user decision: staleness on every weather surface)
            if appState.visibleLayers.contains(.weatherDots),
               let oldestObs = mapViewModel.oldestWeatherObservationTime {
                HStack(spacing: 4) {
                    Text("Data age:")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    WeatherBadge(observationTime: oldestObs)
                }
                .padding(.leading, 52)  // Indent under toggle
            }

            layerToggle(layer: .navaids, label: "Navaids", tint: .purple)

            Divider()

            // Sectional opacity slider
            OpacitySlider(opacity: $appState.sectionalOpacity)

            // Chart expiration status below opacity slider (INFRA-03)
            ChartExpirationBadge(daysRemaining: mapViewModel.chartDaysRemaining)

            Divider()

            // Map style picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Map Style")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                Picker("Map Style", selection: $appState.mapStyle) {
                    ForEach(MapStyle.allCases, id: \.self) { style in
                        Text(styleName(for: style)).tag(style)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 16)
        .frame(width: 260)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Layer Toggle Row

    private func layerToggle(layer: MapLayer, label: String, tint: Color) -> some View {
        Toggle(isOn: Binding(
            get: { appState.visibleLayers.contains(layer) },
            set: { _ in mapViewModel.toggleLayer(layer) }
        )) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .tint(tint)
        .padding(.horizontal, 16)
    }

    // MARK: - TFR Toggle with "Sample data only" caption

    private func tfrToggle() -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Toggle(isOn: Binding(
                get: { appState.visibleLayers.contains(.tfrs) },
                set: { _ in mapViewModel.toggleLayer(.tfrs) }
            )) {
                Text("TFRs")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .tint(.red)

            Text("Sample data only")
                .font(.caption2)
                .foregroundColor(.red)
                .padding(.leading, 4)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Helpers

    private func styleName(for style: MapStyle) -> String {
        switch style {
        case .vfrSectional: return "VFR"
        case .street: return "Street"
        case .satellite: return "Satellite"
        case .terrain: return "Terrain"
        }
    }
}
