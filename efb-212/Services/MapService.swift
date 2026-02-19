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

        // TFR overlays — visible at all zoom levels (safety-critical)
        let showTFRs = activeLayers.contains(.tfrs)
        for ids in activeTFRIDs {
            if let tfrLayer = style.layer(withIdentifier: ids.layerID) {
                tfrLayer.isVisible = showTFRs
            }
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

    /// Reusable annotation identifier for weather dots.
    private static let weatherAnnotationIdentifier = "weather-annotation"

    /// Add color-coded weather dots (flight category) at airport locations.
    /// Each dot color represents VFR (green), MVFR (blue), IFR (red), or LIFR (magenta).
    /// - Parameters:
    ///   - weather: Array of WeatherCache entries with station data.
    ///   - coordinates: Dictionary mapping station ICAO ID to its coordinate.
    func addWeatherDots(_ weather: [WeatherCache], coordinates: [String: CLLocationCoordinate2D]) {
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

        // Weather dots are rendered as point annotations colored by flight category.
        let annotations = weather.compactMap { wx -> MLNPointAnnotation? in
            guard let coordinate = coordinates[wx.stationID] else { return nil }
            let point = MLNPointAnnotation()
            point.coordinate = coordinate
            point.title = "WX:\(wx.stationID):\(wx.flightCategory.rawValue)"
            point.subtitle = "\(wx.flightCategory.rawValue.uppercased()) — \(wx.stationID)"
            return point
        }

        if !annotations.isEmpty {
            mapView.addAnnotations(annotations)
        }
    }

    /// Remove all weather dot annotations from the map.
    func removeWeatherDots() {
        guard let mapView = mapView else { return }

        let weatherAnnotations = mapView.annotations?.filter { annotation in
            if let point = annotation as? MLNPointAnnotation {
                return point.title?.hasPrefix("WX:") == true
            }
            return false
        } ?? []

        if !weatherAnnotations.isEmpty {
            mapView.removeAnnotations(weatherAnnotations)
        }
    }

    // MARK: - Navaid Annotations

    /// Reusable annotation identifier for navaid markers.
    private static let navaidAnnotationIdentifier = "navaid-annotation"

    /// Add navaid annotations to the map.
    /// Removes any existing navaid annotations before adding new ones.
    /// - Parameter navaids: Array of Navaid models to display.
    func addNavaidAnnotations(_ navaids: [Navaid]) {
        guard let mapView = mapView else { return }

        // Remove existing navaid annotations
        let existingAnnotations = mapView.annotations?.filter { annotation in
            if let point = annotation as? MLNPointAnnotation {
                return point.title?.hasPrefix("NAV:") == true
            }
            return false
        } ?? []

        if !existingAnnotations.isEmpty {
            mapView.removeAnnotations(existingAnnotations)
        }

        // Add new annotations
        let annotations = navaids.map { navaid -> MLNPointAnnotation in
            let point = MLNPointAnnotation()
            point.coordinate = navaid.coordinate
            // Prefix title with "NAV:" so we can identify navaid annotations later
            point.title = "NAV:\(navaid.id)"
            let freqStr = navaid.type == .ndb || navaid.type == .ndbDme
                ? String(format: "%.0f kHz", navaid.frequency)
                : String(format: "%.1f MHz", navaid.frequency)
            point.subtitle = "\(navaid.name) \(navaid.type.rawValue.uppercased()) \(freqStr)"
            return point
        }

        if !annotations.isEmpty {
            mapView.addAnnotations(annotations)
        }
    }

    /// Remove all navaid annotations from the map.
    func removeNavaidAnnotations() {
        guard let mapView = mapView else { return }

        let navaidAnnotations = mapView.annotations?.filter { annotation in
            if let point = annotation as? MLNPointAnnotation {
                return point.title?.hasPrefix("NAV:") == true
            }
            return false
        } ?? []

        if !navaidAnnotations.isEmpty {
            mapView.removeAnnotations(navaidAnnotations)
        }
    }

    // MARK: - Airspace Polygons

    /// Tracks active airspace source/layer identifiers for cleanup.
    private var activeAirspaceIDs: [(sourceID: String, layerID: String)] = []

    /// Add airspace boundary polygons to the map.
    /// Removes any existing airspace polygons before adding new ones.
    /// Colors by classification: Bravo=blue, Charlie=purple, Delta=orange.
    /// - Parameter airspaces: Array of Airspace models to display.
    func addAirspacePolygons(_ airspaces: [Airspace]) {
        removeAirspacePolygons()

        guard let mapView = mapView, let style = mapView.style else { return }
        guard !airspaces.isEmpty else { return }

        for (index, airspace) in airspaces.enumerated() {
            let sourceID = "airspace-source-\(index)"
            let fillLayerID = "airspace-fill-\(index)"
            let outlineLayerID = "airspace-outline-\(index)"

            let shape: MLNShape

            switch airspace.geometry {
            case .polygon(let coordinates):
                var coords = coordinates.map { pair in
                    CLLocationCoordinate2D(
                        latitude: pair.count >= 1 ? pair[0] : 0,
                        longitude: pair.count >= 2 ? pair[1] : 0
                    )
                }
                guard coords.count >= 3 else { continue }
                let polygon = MLNPolygon(coordinates: &coords, count: UInt(coords.count))
                shape = polygon

            case .circle(let center, let radiusNM):
                guard center.count >= 2 else { continue }
                let centerCoord = CLLocationCoordinate2D(latitude: center[0], longitude: center[1])
                var coords = Self.circleCoordinates(center: centerCoord, radiusNM: radiusNM, points: 36)
                let polygon = MLNPolygon(coordinates: &coords, count: UInt(coords.count))
                shape = polygon
            }

            let source = MLNShapeSource(identifier: sourceID, shape: shape, options: nil)
            style.addSource(source)

            let color = Self.airspaceColor(for: airspace.classification)

            // Semi-transparent fill
            let fillLayer = MLNFillStyleLayer(identifier: fillLayerID, source: source)
            fillLayer.fillColor = NSExpression(forConstantValue: color)
            fillLayer.fillOpacity = NSExpression(forConstantValue: 0.12)
            style.addLayer(fillLayer)

            // Colored outline
            let outlineLayer = MLNLineStyleLayer(identifier: outlineLayerID, source: source)
            outlineLayer.lineColor = NSExpression(forConstantValue: color)
            outlineLayer.lineWidth = NSExpression(forConstantValue: 1.5)
            outlineLayer.lineDashPattern = NSExpression(forConstantValue: [4, 2])
            style.addLayer(outlineLayer)

            activeAirspaceIDs.append((sourceID: sourceID, layerID: fillLayerID))
            activeAirspaceIDs.append((sourceID: sourceID, layerID: outlineLayerID))
        }
    }

    /// Remove all airspace polygon overlays from the map.
    func removeAirspacePolygons() {
        guard let style = mapView?.style else { return }

        var sourceIDs = Set<String>()

        for ids in activeAirspaceIDs {
            if let layer = style.layer(withIdentifier: ids.layerID) {
                style.removeLayer(layer)
            }
            sourceIDs.insert(ids.sourceID)
        }

        for sourceID in sourceIDs {
            if let source = style.source(withIdentifier: sourceID) {
                style.removeSource(source)
            }
        }

        activeAirspaceIDs.removeAll()
    }

    /// Map AirspaceClass to UIColor for polygon rendering.
    /// Bravo = blue, Charlie = purple, Delta = orange, others = gray.
    private static func airspaceColor(for classification: AirspaceClass) -> UIColor {
        switch classification {
        case .bravo:      return .systemBlue
        case .charlie:    return .systemPurple
        case .delta:      return .systemOrange
        case .echo:       return .systemGray
        case .restricted, .prohibited: return .systemRed
        case .moa:        return .systemBrown
        case .alert, .warning: return .systemYellow
        case .tfr:        return .systemRed
        case .golf:       return .systemGray
        }
    }

    // MARK: - TFR Overlays

    /// Tracks active TFR source/layer identifiers for cleanup.
    private var activeTFRIDs: [(sourceID: String, layerID: String)] = []

    /// Add TFR overlays to the map as red semi-transparent polygons/circles.
    /// Removes any existing TFR overlays before adding new ones.
    /// - Parameter tfrs: Array of active TFRs to display.
    func addTFROverlays(_ tfrs: [TFR]) {
        removeTFROverlays()

        guard let mapView = mapView, let style = mapView.style else { return }
        guard !tfrs.isEmpty else { return }

        for (index, tfr) in tfrs.enumerated() {
            let sourceID = "tfr-source-\(index)"
            let fillLayerID = "tfr-fill-\(index)"
            let outlineLayerID = "tfr-outline-\(index)"

            let shape: MLNShape

            if let radiusNM = tfr.radiusNM, radiusNM > 0 {
                // Circular TFR — approximate circle as a 36-point polygon
                let coordinates = Self.circleCoordinates(
                    center: tfr.coordinate,
                    radiusNM: radiusNM,
                    points: 36
                )
                var coords = coordinates
                let polygon = MLNPolygon(coordinates: &coords, count: UInt(coords.count))
                shape = polygon
            } else if !tfr.boundaries.isEmpty {
                // Polygon TFR — use boundary coordinates
                var coords = tfr.boundaries.map { pair in
                    CLLocationCoordinate2D(
                        latitude: pair.count >= 1 ? pair[0] : 0,
                        longitude: pair.count >= 2 ? pair[1] : 0
                    )
                }
                let polygon = MLNPolygon(coordinates: &coords, count: UInt(coords.count))
                shape = polygon
            } else {
                // Fallback — point marker with small default radius (1 NM)
                var coords = Self.circleCoordinates(
                    center: tfr.coordinate,
                    radiusNM: 1.0,
                    points: 36
                )
                let polygon = MLNPolygon(coordinates: &coords, count: UInt(coords.count))
                shape = polygon
            }

            let source = MLNShapeSource(identifier: sourceID, shape: shape, options: nil)
            style.addSource(source)

            // Semi-transparent red fill
            let fillLayer = MLNFillStyleLayer(identifier: fillLayerID, source: source)
            fillLayer.fillColor = NSExpression(forConstantValue: UIColor.systemRed)
            fillLayer.fillOpacity = NSExpression(forConstantValue: 0.25)
            style.addLayer(fillLayer)

            // Red outline
            let outlineLayer = MLNLineStyleLayer(identifier: outlineLayerID, source: source)
            outlineLayer.lineColor = NSExpression(forConstantValue: UIColor.systemRed)
            outlineLayer.lineWidth = NSExpression(forConstantValue: 2.0)
            style.addLayer(outlineLayer)

            activeTFRIDs.append((sourceID: sourceID, layerID: fillLayerID))
            activeTFRIDs.append((sourceID: sourceID, layerID: outlineLayerID))
        }
    }

    /// Remove all TFR overlays from the map.
    func removeTFROverlays() {
        guard let style = mapView?.style else { return }

        // Collect unique source IDs to remove after layers
        var sourceIDs = Set<String>()

        for ids in activeTFRIDs {
            if let layer = style.layer(withIdentifier: ids.layerID) {
                style.removeLayer(layer)
            }
            sourceIDs.insert(ids.sourceID)
        }

        for sourceID in sourceIDs {
            if let source = style.source(withIdentifier: sourceID) {
                style.removeSource(source)
            }
        }

        activeTFRIDs.removeAll()
    }

    /// Generate coordinates for an approximate circle on the map.
    /// - Parameters:
    ///   - center: Center coordinate.
    ///   - radiusNM: Radius in nautical miles.
    ///   - points: Number of polygon points (higher = smoother circle).
    /// - Returns: Array of coordinates forming the circle polygon.
    private static func circleCoordinates(
        center: CLLocationCoordinate2D,
        radiusNM: Double,
        points: Int
    ) -> [CLLocationCoordinate2D] {
        // 1 NM = 1/60 degree of latitude (approximately)
        let radiusDegLat = radiusNM / 60.0
        // Longitude degrees per NM varies with latitude
        let radiusDegLon = radiusNM / (60.0 * cos(center.latitude * .pi / 180.0))

        var coordinates: [CLLocationCoordinate2D] = []
        for i in 0..<points {
            let angle = Double(i) * (2.0 * .pi / Double(points))
            let lat = center.latitude + radiusDegLat * sin(angle)
            let lon = center.longitude + radiusDegLon * cos(angle)
            coordinates.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }
        // Close the polygon
        if let first = coordinates.first {
            coordinates.append(first)
        }
        return coordinates
    }

    // MARK: - User Location

    /// Enable the native user location dot on the map.
    /// Call after location authorization has been granted.
    func enableUserLocation() {
        mapView?.showsUserLocation = true
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

        guard let title = annotation.title ?? nil else { return nil }

        // Weather dot annotations — "WX:KPAO:vfr"
        if title.hasPrefix("WX:") {
            let reuseIdentifier = MapService.weatherAnnotationIdentifier
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)

            if annotationView == nil {
                annotationView = MLNAnnotationView(reuseIdentifier: reuseIdentifier)
                annotationView?.frame = CGRect(x: 0, y: 0, width: 14, height: 14)
                annotationView?.layer.cornerRadius = 7
                annotationView?.layer.borderWidth = 1.5
                annotationView?.layer.borderColor = UIColor.white.cgColor
            }

            // Parse flight category from title: "WX:KPAO:vfr"
            let parts = title.split(separator: ":")
            let categoryRaw = parts.count >= 3 ? String(parts[2]) : "vfr"
            let category = FlightCategory(rawValue: categoryRaw) ?? .vfr
            annotationView?.backgroundColor = Self.color(for: category)

            return annotationView
        }

        // Navaid annotations — "NAV:SFO"
        if title.hasPrefix("NAV:") {
            let reuseIdentifier = MapService.navaidAnnotationIdentifier
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)

            if annotationView == nil {
                annotationView = MLNAnnotationView(reuseIdentifier: reuseIdentifier)
                annotationView?.frame = CGRect(x: 0, y: 0, width: 10, height: 10)
                annotationView?.backgroundColor = .systemPurple
                annotationView?.layer.cornerRadius = 5
                annotationView?.layer.borderWidth = 1
                annotationView?.layer.borderColor = UIColor.white.cgColor
            }

            return annotationView
        }

        // Airport annotations — "APT:KPAO"
        if title.hasPrefix("APT:") {
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

        return nil
    }

    /// Map FlightCategory to UIColor for weather dot rendering.
    private static func color(for category: FlightCategory) -> UIColor {
        switch category {
        case .vfr:  return .systemGreen
        case .mvfr: return .systemBlue
        case .ifr:  return .systemRed
        case .lifr: return .systemPurple
        }
    }
}
