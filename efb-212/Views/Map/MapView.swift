//
//  MapView.swift
//  efb-212
//
//  UIViewRepresentable wrapping MLNMapView for SwiftUI integration.
//  Delegates all map logic to MapService; this file only bridges UIKit <-> SwiftUI.
//

import SwiftUI
import MapLibre

struct MapView: UIViewRepresentable {
    @EnvironmentObject var appState: AppState
    let mapService: MapService

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> MLNMapView {
        let mapView = MLNMapView(frame: .zero)
        mapService.configure(mapView: mapView)
        return mapView
    }

    func updateUIView(_ mapView: MLNMapView, context: Context) {
        // Sync map mode from AppState (north-up vs track-up)
        switch appState.mapMode {
        case .northUp:
            if mapView.userTrackingMode != .follow {
                mapView.userTrackingMode = .follow
                mapView.setDirection(0, animated: true)
            }
        case .trackUp:
            if mapView.userTrackingMode != .followWithHeading {
                mapView.userTrackingMode = .followWithHeading
            }
        }

        // Sync visible layers from AppState
        mapService.updateVisibleLayers(appState.visibleLayers)
    }
}
