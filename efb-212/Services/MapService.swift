//
//  MapService.swift
//  efb-212
//
//  Wraps MLNMapView and manages chart layers, airspace visualization,
//  ownship tracking, airport annotations, and route rendering.
//
//  Uses MLNMapViewDelegate which requires NSObject conformance.
//  Not isolated to MainActor via nonisolated since UIKit delegate
//  callbacks are already on main thread, but the class itself
//  interacts heavily with UIKit views.
//

import Foundation
import MapLibre
import CoreLocation
import Combine
import SwiftUI

// MARK: - MapServiceDelegate

/// Delegate for MapService events that need to propagate to ViewModels/Views.
protocol MapServiceDelegate: AnyObject {
    func mapService(_ service: MapService, didChangeRegion center: CLLocationCoordinate2D, zoom: Double)
    func mapService(_ service: MapService, didSelectAirport icao: String)
}

// MARK: - MapService

final class MapService: NSObject, ObservableObject {

    // MARK: - Published State

    @Published var currentZoom: Double = 10.0
    @Published var currentCenter: CLLocationCoordinate2D = .init(latitude: 37.46, longitude: -122.12)

    // MARK: - Properties

    weak var delegate: MapServiceDelegate?
    private(set) var mapView: MLNMapView?

    /// Tracks which layers are currently rendered on the map.
    private var activeLayers: Set<MapLayer> = []

    /// Reusable annotation identifier for airport dots.
    private static let airportAnnotationIdentifier = "airport-annotation"

    /// Reusable annotation identifier for ownship marker.
    private static let ownshipAnnotationIdentifier = "ownship-annotation"

    // Default center: Palo Alto Airport (KPAO) — latitude 37.46, longitude -122.12
    private let defaultCenter = CLLocationCoordinate2D(latitude: 37.46, longitude: -122.12)
    private let defaultZoom: Double = 10.0

    // MARK: - Configuration

    /// Configure and attach a map view. Called once from UIViewRepresentable.makeUIView.
    /// - Parameter mapView: The MLNMapView instance to configure.
    func configure(mapView: MLNMapView) {
        self.mapView = mapView
        mapView.delegate = self

        // Use MapLibre demo tiles as base style (replaced with aviation tiles in production)
        mapView.styleURL = URL(string: "https://demotiles.maplibre.org/style.json")

        // Defer user location tracking until permissions are granted.
        // Setting showsUserLocation without proper Info.plist keys can crash.
        // Location will be enabled via enableUserLocation() after authorization.
        mapView.showsUserLocation = false

        // Set initial viewport — KPAO area, zoom level 10
        mapView.setCenter(defaultCenter, zoomLevel: defaultZoom, animated: false)

        // Enable compass and scale bar for aviation situational awareness
        mapView.compassViewPosition = .topRight
        mapView.showsScale = true

        // Attribution position (required by MapLibre license)
        mapView.attributionButtonPosition = .bottomLeft
    }

    // MARK: - VFR Sectional Overlay

    /// Current sectional overlay opacity (0.0 fully transparent, 1.0 fully opaque).
    /// Adjustable by users via Settings > Chart Downloads.
    @Published var sectionalOpacity: Double = 0.85

    /// Tracks active sectional overlay source/layer identifiers for cleanup.
    private var activeSectionalIDs: [(sourceID: String, layerID: String)] = []

    /// Add a VFR sectional chart overlay from an MBTiles file.
    /// Each region gets its own source/layer so multiple sectionals can be displayed simultaneously.
    /// - Parameters:
    ///   - mbtilesPath: URL to the local .mbtiles file containing raster tiles.
    ///   - regionID: Unique region identifier used to namespace the source/layer.
    func addSectionalOverlay(mbtilesPath: URL, regionID: String = "default") {
        guard let mapView = mapView, let style = mapView.style else { return }

        let sourceID = "sectional-source-\(regionID)"
        let layerID = "sectional-raster-\(regionID)"

        // Remove existing source/layer for this region if present
        if let existingLayer = style.layer(withIdentifier: layerID) {
            style.removeLayer(existingLayer)
        }
        if let existingSource = style.source(withIdentifier: sourceID) {
            style.removeSource(existingSource)
        }

        // MBTiles served via mbtiles:// URL scheme supported by MapLibre
        let tileURLTemplate = "mbtiles://\(mbtilesPath.path)"
        let source = MLNRasterTileSource(
            identifier: sourceID,
            tileURLTemplates: [tileURLTemplate],
            options: [
                .tileSize: 256,
                .minimumZoomLevel: 5,
                .maximumZoomLevel: 12
            ]
        )
        style.addSource(source)

        let rasterLayer = MLNRasterStyleLayer(identifier: layerID, source: source)
        rasterLayer.rasterOpacity = NSExpression(forConstantValue: sectionalOpacity)
        style.addLayer(rasterLayer)

        // Track for cleanup
        if !activeSectionalIDs.contains(where: { $0.sourceID == sourceID }) {
            activeSectionalIDs.append((sourceID: sourceID, layerID: layerID))
        }
    }

    /// Remove a specific sectional overlay by region ID.
    /// - Parameter regionID: The region identifier to remove.
    func removeSectionalOverlay(regionID: String) {
        guard let style = mapView?.style else { return }

        let sourceID = "sectional-source-\(regionID)"
        let layerID = "sectional-raster-\(regionID)"

        if let layer = style.layer(withIdentifier: layerID) {
            style.removeLayer(layer)
        }
        if let source = style.source(withIdentifier: sourceID) {
            style.removeSource(source)
        }

        activeSectionalIDs.removeAll { $0.sourceID == sourceID }
    }

    /// Remove all sectional overlays from the map.
    func removeAllSectionalOverlays() {
        guard let style = mapView?.style else { return }

        for ids in activeSectionalIDs {
            if let layer = style.layer(withIdentifier: ids.layerID) {
                style.removeLayer(layer)
            }
            if let source = style.source(withIdentifier: ids.sourceID) {
                style.removeSource(source)
            }
        }
        activeSectionalIDs.removeAll()
    }

    /// Updates the opacity for all active sectional overlay layers.
    /// - Parameter opacity: Value from 0.0 (transparent) to 1.0 (opaque).
    func setSectionalOpacity(_ opacity: Double) {
        sectionalOpacity = opacity
        guard let style = mapView?.style else { return }

        for ids in activeSectionalIDs {
            if let rasterLayer = style.layer(withIdentifier: ids.layerID) as? MLNRasterStyleLayer {
                rasterLayer.rasterOpacity = NSExpression(forConstantValue: opacity)
            }
        }
    }

    /// Load sectional overlays for all downloaded chart regions.
    /// Queries ChartManager for downloaded MBTiles files and adds each as a raster overlay.
    /// - Parameter chartManager: The ChartManager actor to query for downloaded chart paths.
    func loadDownloadedSectionals(from chartManager: ChartManager) async {
        let paths = await chartManager.downloadedChartPaths()
        for (regionID, mbtilesURL) in paths {
            addSectionalOverlay(mbtilesPath: mbtilesURL, regionID: regionID)
        }
    }

    // MARK: - Layer Visibility

    /// Update which map layers are visible based on the provided set and current zoom level.
    /// - Parameter layers: The set of layers that should be visible.
    func updateVisibleLayers(_ layers: Set<MapLayer>) {
        activeLayers = layers
        updateVisibleLayers(for: currentZoom)
    }

    /// Adjust layer visibility based on zoom level.
    /// At low zoom (zoomed out), hide detail layers like navaids and weather dots.
    /// - Parameter zoomLevel: Current map zoom level.
    func updateVisibleLayers(for zoomLevel: Double) {
        guard let style = mapView?.style else { return }

        // Sectional overlay — check all active sectional layers
        let showSectional = activeLayers.contains(.sectional)
        for ids in activeSectionalIDs {
            if let sectionalLayer = style.layer(withIdentifier: ids.layerID) {
                sectionalLayer.isVisible = showSectional
            }
        }

        // Airport annotations visibility is managed via annotation filtering,
        // but we track the intent here.
        // Weather dots, airspace, navaids follow similar patterns when their
        // layers are implemented with style layers.

        // At zoom < 7, hide detail overlays to reduce clutter
        let showDetail = zoomLevel >= 7.0

        if let weatherLayer = style.layer(withIdentifier: "weather-dots") {
            weatherLayer.isVisible = activeLayers.contains(.weatherDots) && showDetail
        }

        if let navaidLayer = style.layer(withIdentifier: "navaids") {
            navaidLayer.isVisible = activeLayers.contains(.navaids) && showDetail
        }
    }

    // MARK: - Airport Annotations

    /// Add airport annotations to the map.
    /// Removes any existing airport annotations before adding new ones.
    /// - Parameter airports: Array of Airport models to display.
    func addAirportAnnotations(_ airports: [Airport]) {
        guard let mapView = mapView else { return }

        // Remove existing airport annotations
        let existingAnnotations = mapView.annotations?.filter { annotation in
            if let point = annotation as? MLNPointAnnotation {
                return point.title?.hasPrefix("APT:") == true
            }
            return false
        } ?? []

        if !existingAnnotations.isEmpty {
            mapView.removeAnnotations(existingAnnotations)
        }

        // Add new annotations
        let annotations = airports.map { airport -> MLNPointAnnotation in
            let point = MLNPointAnnotation()
            point.coordinate = airport.coordinate
            // Prefix title with "APT:" so we can identify airport annotations later
            point.title = "APT:\(airport.icao)"
            point.subtitle = airport.name
            return point
        }

        if !annotations.isEmpty {
            mapView.addAnnotations(annotations)
        }
    }

    // MARK: - Ownship Position

    /// Update the ownship position marker on the map.
    /// MapLibre handles user location dot natively when showsUserLocation is true,
    /// but this method allows manual override (e.g., for ADS-B or external GPS).
    /// - Parameters:
    ///   - location: Current aircraft position.
    ///   - heading: Current magnetic heading (nil if unavailable).
    func updateOwnship(location: CLLocation, heading: CLHeading?) {
        guard let mapView = mapView else { return }

        // Update tracking if in track-up mode
        if mapView.userTrackingMode == .followWithHeading, let heading = heading {
            mapView.setDirection(heading.trueHeading, animated: true)
        }
    }

    // MARK: - Route Line

    /// Display a route line on the map for the active flight plan.
    /// Draws a polyline through all waypoint coordinates.
    /// - Parameter waypoints: Ordered array of waypoints defining the route.
    func showRoute(waypoints: [Waypoint]) {
        guard let mapView = mapView, let style = mapView.style else { return }

        // Remove existing route layer and source
        if let existingLayer = style.layer(withIdentifier: "route-line") {
            style.removeLayer(existingLayer)
        }
        if let existingSource = style.source(withIdentifier: "route-source") {
            style.removeSource(existingSource)
        }

        guard waypoints.count >= 2 else { return }

        // Build coordinate array from waypoints
        var coordinates = waypoints.map { $0.coordinate }

        let polyline = MLNPolyline(coordinates: &coordinates, count: UInt(coordinates.count))
        let source = MLNShapeSource(identifier: "route-source", shape: polyline, options: nil)
        style.addSource(source)

        let lineLayer = MLNLineStyleLayer(identifier: "route-line", source: source)
        lineLayer.lineColor = NSExpression(forConstantValue: UIColor.systemBlue)
        lineLayer.lineWidth = NSExpression(forConstantValue: 3.0)
        lineLayer.lineCap = NSExpression(forConstantValue: "round")
        lineLayer.lineJoin = NSExpression(forConstantValue: "round")
        style.addLayer(lineLayer)
    }

    /// Remove the active route line from the map.
    func clearRoute() {
        guard let style = mapView?.style else { return }

        if let existingLayer = style.layer(withIdentifier: "route-line") {
            style.removeLayer(existingLayer)
        }
        if let existingSource = style.source(withIdentifier: "route-source") {
            style.removeSource(existingSource)
        }
    }

    // MARK: - Weather Dots

    /// Add color-coded weather dots (flight category) at airport locations.
    /// Each dot color represents VFR (green), MVFR (blue), IFR (red), or LIFR (magenta).
    /// - Parameter weather: Array of WeatherCache entries with station locations.
    func addWeatherDots(_ weather: [WeatherCache]) {
        guard let mapView = mapView else { return }

        // Remove existing weather annotations
        let existingAnnotations = mapView.annotations?.filter { annotation in
            if let point = annotation as? MLNPointAnnotation {
                return point.title?.hasPrefix("WX:") == true
            }
            return false
        } ?? []

        if !existingAnnotations.isEmpty {
            mapView.removeAnnotations(existingAnnotations)
        }

        // Weather dots are rendered as point annotations.
        // In a full implementation, these would be circle style layers
        // colored by flight category. For now, use point annotations.
        let annotations = weather.map { wx -> MLNPointAnnotation in
            let point = MLNPointAnnotation()
            // Station coordinates will be resolved via database lookup.
            // For now, the annotation uses the stationID as the title.
            point.title = "WX:\(wx.stationID)"
            point.subtitle = "\(wx.flightCategory.rawValue.uppercased()) — \(wx.stationID)"
            return point
        }

        if !annotations.isEmpty {
            mapView.addAnnotations(annotations)
        }
    }

    // MARK: - Map Mode

    /// Switch between north-up and track-up map orientations.
    /// - Parameter mode: The desired map orientation mode.
    func setMapMode(_ mode: MapMode) {
        guard let mapView = mapView else { return }

        switch mode {
        case .northUp:
            mapView.userTrackingMode = .follow
            mapView.setDirection(0, animated: true) // North up
        case .trackUp:
            mapView.userTrackingMode = .followWithHeading
        }
    }

    // MARK: - Zoom Controls

    /// Zoom in by one level, capped at max zoom 18.
    func zoomIn() {
        guard let mapView = mapView else { return }
        let newZoom = min(mapView.zoomLevel + 1, 18)
        mapView.setZoomLevel(newZoom, animated: true)
    }

    /// Zoom out by one level, floored at min zoom 3.
    func zoomOut() {
        guard let mapView = mapView else { return }
        let newZoom = max(mapView.zoomLevel - 1, 3)
        mapView.setZoomLevel(newZoom, animated: true)
    }

    // MARK: - Center Map

    /// Center the map on a specific coordinate.
    /// - Parameters:
    ///   - coordinate: Target coordinate.
    ///   - zoomLevel: Optional zoom level (nil keeps current zoom).
    ///   - animated: Whether to animate the transition.
    func centerOn(
        coordinate: CLLocationCoordinate2D,
        zoomLevel: Double? = nil,
        animated: Bool = true
    ) {
        guard let mapView = mapView else { return }
        let zoom = zoomLevel ?? mapView.zoomLevel
        mapView.setCenter(coordinate, zoomLevel: zoom, animated: animated)
    }
}

// MARK: - MLNMapViewDelegate

extension MapService: MLNMapViewDelegate {

    func mapView(_ mapView: MLNMapView, regionDidChangeAnimated animated: Bool) {
        currentZoom = mapView.zoomLevel
        currentCenter = mapView.centerCoordinate

        // Update layer visibility based on new zoom level
        updateVisibleLayers(for: mapView.zoomLevel)

        // Notify delegate of region change (for airport loading, etc.)
        delegate?.mapService(self, didChangeRegion: mapView.centerCoordinate, zoom: mapView.zoomLevel)
    }

    func mapView(_ mapView: MLNMapView, didSelect annotation: any MLNAnnotation) {
        guard let title = annotation.title ?? nil else { return }

        // Airport annotation tapped — extract ICAO from "APT:KPAO" format
        if title.hasPrefix("APT:") {
            let icao = String(title.dropFirst(4))
            delegate?.mapService(self, didSelectAirport: icao)
        }
    }

    func mapView(_ mapView: MLNMapView, viewFor annotation: any MLNAnnotation) -> MLNAnnotationView? {
        // Use default user location annotation
        if annotation is MLNUserLocation {
            return nil
        }

        // For airport annotations, return a colored dot
        guard let title = annotation.title ?? nil, title.hasPrefix("APT:") else {
            return nil
        }

        let reuseIdentifier = MapService.airportAnnotationIdentifier
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)

        if annotationView == nil {
            annotationView = MLNAnnotationView(reuseIdentifier: reuseIdentifier)
            annotationView?.frame = CGRect(x: 0, y: 0, width: 12, height: 12)
            annotationView?.backgroundColor = .systemCyan
            annotationView?.layer.cornerRadius = 6
            annotationView?.layer.borderWidth = 1
            annotationView?.layer.borderColor = UIColor.white.cgColor
        }

        return annotationView
    }
}
