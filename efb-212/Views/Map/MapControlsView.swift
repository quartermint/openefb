//
//  MapControlsView.swift
//  efb-212
//
//  Right-edge floating controls per UI-SPEC: map mode toggle,
//  zoom in/out, and layer toggle button. All buttons 44pt minimum
//  touch target with .ultraThinMaterial background.
//

import SwiftUI
import MapLibre

struct MapControlsView: View {
    let mapViewModel: MapViewModel
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 8) {
            // Map mode toggle (north-up / track-up)
            Button {
                let newMode: MapMode = appState.mapMode == .northUp ? .trackUp : .northUp
                mapViewModel.setMapMode(newMode)
            } label: {
                Image(systemName: appState.mapMode == .northUp
                      ? "location.north.fill"
                      : "location.north.line.fill")
                    .font(.title3)
                    .frame(width: 44, height: 44)
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .accessibilityLabel(
                appState.mapMode == .northUp
                    ? "Switch to track up"
                    : "Switch to north up"
            )

            // Zoom controls (combined background)
            VStack(spacing: 0) {
                // Zoom in
                Button {
                    let newZoom = min(appState.mapZoom + 1, 18)
                    mapViewModel.mapService.mapView?.setZoomLevel(newZoom, animated: true)
                } label: {
                    Image(systemName: "plus")
                        .font(.title3)
                        .frame(width: 44, height: 40)
                }
                .accessibilityLabel("Zoom in")

                Divider()
                    .frame(width: 30)

                // Zoom out
                Button {
                    let newZoom = max(appState.mapZoom - 1, 2)
                    mapViewModel.mapService.mapView?.setZoomLevel(newZoom, animated: true)
                } label: {
                    Image(systemName: "minus")
                        .font(.title3)
                        .frame(width: 44, height: 40)
                }
                .accessibilityLabel("Zoom out")
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Layer toggle button
            Button {
                appState.isPresentingLayerControls.toggle()
            } label: {
                Image(systemName: "square.3.layers.3d")
                    .font(.title3)
                    .frame(width: 44, height: 44)
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .accessibilityLabel("Toggle map layers")
        }
    }
}
