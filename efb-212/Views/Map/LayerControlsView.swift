//
//  LayerControlsView.swift
//  efb-212
//
//  Overlay controls for toggling map layers, switching map mode
//  (north-up / track-up), and zoom in/out.
//  Rendered as a floating panel on the map view.
//

import SwiftUI

struct LayerControlsView: View {
    @EnvironmentObject var appState: AppState
    let mapService: MapService

    /// Controls whether the layer toggles popover is visible.
    @State private var showLayerToggles: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            // MARK: - Map Mode Toggle

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    appState.mapMode = appState.mapMode == .northUp ? .trackUp : .northUp
                }
            } label: {
                Image(systemName: appState.mapMode == .northUp ? "location.north.fill" : "location.north.line")
                    .font(.title3)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .accessibilityLabel(appState.mapMode == .northUp ? "Switch to track up" : "Switch to north up")

            // MARK: - Zoom Controls

            VStack(spacing: 0) {
                Button {
                    mapService.zoomIn()
                } label: {
                    Image(systemName: "plus")
                        .font(.title3)
                        .frame(width: 44, height: 40)
                }
                .accessibilityLabel("Zoom in")

                Divider()

                Button {
                    mapService.zoomOut()
                } label: {
                    Image(systemName: "minus")
                        .font(.title3)
                        .frame(width: 44, height: 40)
                }
                .accessibilityLabel("Zoom out")
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // MARK: - Layer Toggle Button

            Button {
                showLayerToggles.toggle()
            } label: {
                Image(systemName: "square.3.layers.3d")
                    .font(.title3)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Toggle map layers")
            .popover(isPresented: $showLayerToggles, arrowEdge: .trailing) {
                LayerTogglePanel(visibleLayers: $appState.visibleLayers)
                    .frame(width: 220)
                    .presentationCompactAdaptation(.popover)
            }
        }
    }
}

// MARK: - Layer Toggle Panel

/// Popover panel with toggles for each map layer.
private struct LayerTogglePanel: View {
    @Binding var visibleLayers: Set<MapLayer>

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Map Layers")
                .font(.headline)
                .padding(.bottom, 4)

            ForEach(MapLayer.allCases, id: \.self) { layer in
                Toggle(isOn: layerBinding(for: layer)) {
                    Label(layer.displayName, systemImage: layer.systemImage)
                        .font(.subheadline)
                }
                .toggleStyle(.switch)
                .tint(layer.tintColor)
            }
        }
        .padding()
    }

    /// Creates a binding that adds/removes the layer from the visible set.
    private func layerBinding(for layer: MapLayer) -> Binding<Bool> {
        Binding(
            get: { visibleLayers.contains(layer) },
            set: { isOn in
                if isOn {
                    visibleLayers.insert(layer)
                } else {
                    visibleLayers.remove(layer)
                }
            }
        )
    }
}

// MARK: - MapLayer UI Extensions

extension MapLayer {
    /// Human-readable display name for the layer toggle UI.
    var displayName: String {
        switch self {
        case .sectional: return "VFR Sectional"
        case .airports: return "Airports"
        case .airspace: return "Airspace"
        case .tfrs: return "TFRs"
        case .weatherDots: return "Weather"
        case .navaids: return "Navaids"
        case .route: return "Route"
        case .ownship: return "Ownship"
        }
    }

    /// SF Symbol name for the layer toggle UI.
    var systemImage: String {
        switch self {
        case .sectional: return "map"
        case .airports: return "airplane.circle"
        case .airspace: return "circle.hexagongrid"
        case .tfrs: return "exclamationmark.triangle"
        case .weatherDots: return "cloud.sun"
        case .navaids: return "antenna.radiowaves.left.and.right"
        case .route: return "point.topleft.down.to.point.bottomright.curvepath"
        case .ownship: return "location.fill"
        }
    }

    /// Tint color for the layer toggle switch.
    var tintColor: Color {
        switch self {
        case .sectional: return .green
        case .airports: return .cyan
        case .airspace: return .orange
        case .tfrs: return .red
        case .weatherDots: return .blue
        case .navaids: return .purple
        case .route: return .blue
        case .ownship: return .green
        }
    }
}
