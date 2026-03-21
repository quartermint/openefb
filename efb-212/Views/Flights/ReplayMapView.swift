//
//  ReplayMapView.swift
//  efb-212
//
//  UIViewRepresentable MapView configured for replay mode.
//  Creates a SEPARATE MLNMapView instance (not reusing the navigation map)
//  to avoid disrupting live navigation state.
//  Observes ReplayEngine state for position marker and track polyline updates.
//
//  REPLAY-01: Orange GPS track polyline with animated position marker.
//  REPLAY-02: Map auto-follows marker position during playback.
//

import SwiftUI
import MapLibre

struct ReplayMapView: UIViewRepresentable {

    let replayEngine: ReplayEngine
    @Binding var autoFollow: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(replayEngine: replayEngine, autoFollow: $autoFollow)
    }

    func makeUIView(context: Context) -> MLNMapView {
        let mapView = MLNMapView(frame: .zero)

        // Initial CONUS center -- will be overridden by fitMapToTrack
        mapView.setCenter(
            CLLocationCoordinate2D(latitude: 39.0, longitude: -98.0),
            zoomLevel: 5.0,
            animated: false
        )

        // Replay map does not show user location
        mapView.showsUserLocation = false
        mapView.compassView.compassVisibility = .hidden

        // Wire delegate for style loaded + gesture detection
        mapView.delegate = context.coordinator

        // Create a dedicated MapService for this replay map instance
        let mapService = MapService()
        mapService.configure(mapView: mapView)
        context.coordinator.mapService = mapService

        return mapView
    }

    func updateUIView(_ mapView: MLNMapView, context: Context) {
        guard let mapService = context.coordinator.mapService else { return }

        // Update replay marker position from engine state
        mapService.updateReplayMarker(
            coordinate: replayEngine.currentCoordinate,
            heading: replayEngine.currentHeading
        )

        // Auto-follow: center map on marker without animation (20Hz updates)
        if autoFollow {
            mapService.centerOnCoordinate(replayEngine.currentCoordinate, animated: false)
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, MLNMapViewDelegate {
        let replayEngine: ReplayEngine
        var autoFollow: Binding<Bool>
        var mapService: MapService?
        private var hasLoadedStyle = false

        init(replayEngine: ReplayEngine, autoFollow: Binding<Bool>) {
            self.replayEngine = replayEngine
            self.autoFollow = autoFollow
            super.init()
        }

        // Style finished loading -- add replay layers and draw the track
        @MainActor
        func mapView(_ mapView: MLNMapView, didFinishLoading style: MLNStyle) {
            guard !hasLoadedStyle else { return }
            hasLoadedStyle = true

            guard let mapService = mapService else { return }

            mapService.addReplayLayers(to: style)
            mapService.updateReplayTrack(replayEngine.trackPoints)
            mapService.fitMapToTrack(replayEngine.trackPoints)
        }

        // Detect user pan gestures to disable auto-follow
        @MainActor
        func mapView(_ mapView: MLNMapView, regionDidChangeWith reason: MLNCameraChangeReason, animated: Bool) {
            // .gesturePan indicates user dragged the map
            if reason.contains(.gesturePan) {
                autoFollow.wrappedValue = false
            }
        }

        deinit {
            // Clean up replay layers when coordinator is deallocated
            Task { @MainActor [mapService] in
                mapService?.removeReplayLayers()
            }
        }
    }
}
