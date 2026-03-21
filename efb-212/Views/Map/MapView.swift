//
//  MapView.swift
//  efb-212
//
//  UIViewRepresentable wrapper for MLNMapView with GeoJSON source management.
//  Creates the map, sets initial CONUS center, wires delegate through Coordinator,
//  and adds tap gesture for GeoJSON feature detection (airport tapping).
//

import SwiftUI
import MapLibre

struct MapView: UIViewRepresentable {

    let mapService: MapService
    let mapViewModel: MapViewModel

    // MARK: - UIViewRepresentable

    func makeCoordinator() -> Coordinator {
        Coordinator(mapViewModel: mapViewModel, mapService: mapService)
    }

    func makeUIView(context: Context) -> MLNMapView {
        let mapView = MLNMapView(frame: .zero)

        // Initial CONUS center (39N, 98W, zoom 5) per user decision
        mapView.setCenter(
            CLLocationCoordinate2D(latitude: 39.0, longitude: -98.0),
            zoomLevel: 5.0,
            animated: false
        )

        // We render our own ownship -- disable default user location display
        mapView.showsUserLocation = false

        // Hide default compass -- we provide our own controls
        mapView.compassView.compassVisibility = .hidden

        // Set delegate through coordinator
        mapView.delegate = context.coordinator

        // Configure MapService with this map view
        mapService.configure(mapView: mapView)

        // Add tap gesture for GeoJSON feature detection (airport tapping)
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleMapTap(_:))
        )
        // Don't interfere with map's own gesture recognizers
        for recognizer in mapView.gestureRecognizers ?? [] {
            tapGesture.require(toFail: recognizer)
        }
        mapView.addGestureRecognizer(tapGesture)

        return mapView
    }

    func updateUIView(_ mapView: MLNMapView, context: Context) {
        // Sync ownship position
        if let position = mapViewModel.appState.ownshipPosition {
            let heading = mapViewModel.appState.track
            mapService.updateOwnship(location: position, heading: heading)

            // Handle first location animation
            if mapViewModel.appState.firstLocationReceived {
                mapViewModel.onFirstLocationReceived(location: position)
            }
        }

        // Sync layer visibility
        for layer in MapLayer.allCases {
            let visible = mapViewModel.appState.visibleLayers.contains(layer)
            mapService.setLayerVisibility(layer, visible: visible)
        }

        // Sync sectional opacity
        mapService.setSectionalOpacity(mapViewModel.appState.sectionalOpacity)
    }

    // MARK: - Coordinator

    nonisolated class Coordinator: NSObject, MLNMapViewDelegate {
        let mapViewModel: MapViewModel
        let mapService: MapService

        init(mapViewModel: MapViewModel, mapService: MapService) {
            self.mapViewModel = mapViewModel
            self.mapService = mapService
            super.init()
        }

        // Style finished loading -- initialize all layers
        @MainActor
        func mapView(_ mapView: MLNMapView, didFinishLoading style: MLNStyle) {
            mapViewModel.onMapStyleLoaded(style: style)
        }

        // Region changed -- trigger debounced data reload
        @MainActor
        func mapViewRegionDidChangeAnimated(_ mapView: MLNMapView) {
            mapViewModel.onRegionChanged(
                center: mapView.centerCoordinate,
                zoom: mapView.zoomLevel
            )
        }

        // Handle tap on map for GeoJSON feature detection (airports)
        @MainActor
        @objc func handleMapTap(_ sender: UITapGestureRecognizer) {
            guard sender.state == .ended else { return }
            guard let mapView = mapService.mapView else { return }

            let point = sender.location(in: mapView)

            // Query visible features at tap point in the airport circle layer
            let features = mapView.visibleFeatures(
                at: point,
                styleLayerIdentifiers: Set(["airport-circles"])
            )

            // Extract ICAO from first matching feature
            if let feature = features.first,
               let icao = feature.attribute(forKey: "icao") as? String {
                mapViewModel.onAirportTapped(icao: icao)
            }
        }
    }
}
