//
//  MapService.swift
//  efb-212
//
//  MapLibre layer management -- GeoJSON sources, style layers, ownship,
//  sectional overlay, chart expiration metadata (INFRA-03).
//  Runs on MainActor because MLNMapView is UIKit (main thread only).
//

import UIKit
import MapLibre
import SQLite3

@MainActor
final class MapService {

    // MARK: - Properties

    weak var mapView: MLNMapView?

    private var airportSource: MLNShapeSource?
    private var navaidSource: MLNShapeSource?
    private var airspaceSource: MLNShapeSource?
    private var weatherSource: MLNShapeSource?
    private var tfrSource: MLNShapeSource?
    private var ownshipSource: MLNShapeSource?
    private var sectionalLayer: MLNRasterStyleLayer?

    /// Chart expiration date read from MBTiles metadata (INFRA-03)
    private(set) var chartExpirationDate: Date?
    /// Chart effective date read from MBTiles metadata (INFRA-03)
    private(set) var chartEffectiveDate: Date?

    // MARK: - Configuration

    /// Store reference to map view and set initial center (CONUS: 39N, 98W, zoom 5)
    func configure(mapView: MLNMapView) {
        self.mapView = mapView
        mapView.setCenter(
            CLLocationCoordinate2D(latitude: 39.0, longitude: -98.0),
            zoomLevel: 5.0,
            animated: false
        )
    }

    // MARK: - Style Loaded

    /// Called when map style finishes loading. Creates all GeoJSON sources and style layers.
    func onStyleLoaded(style: MLNStyle) {
        addOwnshipLayer(to: style)
        addAirportLayer(to: style)
        addNavaidLayer(to: style)
        addSectionalOverlay(to: style)
        addAirspaceLayer(to: style)
        addWeatherDotLayer(to: style)
        addTFRLayer(to: style)
    }

    // MARK: - Ownship Layer

    private func addOwnshipLayer(to style: MLNStyle) {
        // Create chevron icon programmatically (32x32pt, blue fill, aviation triangle)
        let chevronImage = createOwnshipChevron()
        style.setImage(chevronImage, forName: "ownship-chevron")

        // Single point feature for ownship
        let point = MLNPointFeature()
        point.coordinate = CLLocationCoordinate2D(latitude: 39.0, longitude: -98.0)
        point.attributes = ["heading": 0]

        let source = MLNShapeSource(identifier: "ownship", shape: point, options: nil)
        style.addSource(source)
        self.ownshipSource = source

        let layer = MLNSymbolStyleLayer(identifier: "ownship-symbol", source: source)
        layer.iconImageName = NSExpression(forConstantValue: "ownship-chevron")
        layer.iconRotation = NSExpression(forKeyPath: "heading")
        layer.iconAllowsOverlap = NSExpression(forConstantValue: true)
        layer.iconIgnoresPlacement = NSExpression(forConstantValue: true)
        layer.iconScale = NSExpression(forConstantValue: 1.0)
        layer.iconRotationAlignment = NSExpression(forConstantValue: "map")
        style.addLayer(layer)
    }

    /// Create a 32x32pt aviation chevron icon using UIGraphicsImageRenderer
    private func createOwnshipChevron() -> UIImage {
        let size = CGSize(width: 32, height: 32)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let ctx = context.cgContext
            // Aviation chevron pointing up: triangle shape
            ctx.setFillColor(UIColor.systemBlue.cgColor)
            ctx.beginPath()
            ctx.move(to: CGPoint(x: 16, y: 2))     // top center (nose)
            ctx.addLine(to: CGPoint(x: 26, y: 28))  // bottom right
            ctx.addLine(to: CGPoint(x: 16, y: 22))  // center notch
            ctx.addLine(to: CGPoint(x: 6, y: 28))   // bottom left
            ctx.closePath()
            ctx.fillPath()

            // White outline for contrast
            ctx.setStrokeColor(UIColor.white.cgColor)
            ctx.setLineWidth(1.0)
            ctx.beginPath()
            ctx.move(to: CGPoint(x: 16, y: 2))
            ctx.addLine(to: CGPoint(x: 26, y: 28))
            ctx.addLine(to: CGPoint(x: 16, y: 22))
            ctx.addLine(to: CGPoint(x: 6, y: 28))
            ctx.closePath()
            ctx.strokePath()
        }
    }

    // MARK: - Airport Layer

    private func addAirportLayer(to style: MLNStyle) {
        let source = MLNShapeSource(
            identifier: "airports",
            shape: MLNShapeCollectionFeature(shapes: []),
            options: nil
        )
        style.addSource(source)
        self.airportSource = source

        let circleLayer = MLNCircleStyleLayer(identifier: "airport-circles", source: source)
        circleLayer.circleRadius = NSExpression(forConstantValue: 5)
        circleLayer.circleColor = NSExpression(forConstantValue: UIColor.systemCyan)
        circleLayer.circleStrokeWidth = NSExpression(forConstantValue: 1)
        circleLayer.circleStrokeColor = NSExpression(forConstantValue: UIColor.white)

        // Data-driven visibility: towered airports at all zooms, non-towered at zoom >= 8
        // Use a stepped expression on zoom level + isTowered property
        circleLayer.circleOpacity = NSExpression(
            format: "MGL_IF(isTowered == YES, 1.0, MGL_IF(%K >= 8, 1.0, 0.0))",
            NSExpression.zoomLevelVariable
        )

        style.addLayer(circleLayer)
    }

    // MARK: - Navaid Layer

    private func addNavaidLayer(to style: MLNStyle) {
        let source = MLNShapeSource(
            identifier: "navaids",
            shape: MLNShapeCollectionFeature(shapes: []),
            options: nil
        )
        style.addSource(source)
        self.navaidSource = source

        let circleLayer = MLNCircleStyleLayer(identifier: "navaid-circles", source: source)
        circleLayer.circleRadius = NSExpression(forConstantValue: 4)
        circleLayer.circleColor = NSExpression(forConstantValue: UIColor.systemPurple)
        circleLayer.circleStrokeWidth = NSExpression(forConstantValue: 1)
        circleLayer.circleStrokeColor = NSExpression(forConstantValue: UIColor.white)
        style.addLayer(circleLayer)
    }

    // MARK: - Sectional Overlay

    private func addSectionalOverlay(to style: MLNStyle) {
        // Check for MBTiles file in Application Support
        let fileManager = FileManager.default
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return
        }
        let mbtilesPath = appSupport.appendingPathComponent("efb-212/sectional.mbtiles")

        guard fileManager.fileExists(atPath: mbtilesPath.path) else {
            // No MBTiles file -- charts not downloaded yet. Fail silently.
            return
        }

        // MBTiles raster tile source with mbtiles:// URL scheme
        let tileURL = "mbtiles:///\(mbtilesPath.path)"
        let source = MLNRasterTileSource(
            identifier: "sectional-tiles",
            tileURLTemplates: [tileURL],
            options: [
                .tileSize: 256,
                .minimumZoomLevel: 5,
                .maximumZoomLevel: 12
            ]
        )
        style.addSource(source)

        let rasterLayer = MLNRasterStyleLayer(identifier: "sectional-overlay", source: source)
        rasterLayer.rasterOpacity = NSExpression(forConstantValue: 0.70)
        // Insert sectional below other data layers
        if let firstLayer = style.layers.first {
            style.insertLayer(rasterLayer, above: firstLayer)
        } else {
            style.addLayer(rasterLayer)
        }
        self.sectionalLayer = rasterLayer

        // Read chart expiration metadata (INFRA-03)
        readChartExpirationMetadata(from: mbtilesPath)
    }

    // MARK: - Chart Expiration Metadata (INFRA-03)

    /// Read MBTiles SQLite metadata table for chart cycle dates.
    /// MBTiles files have a `metadata` table with key-value pairs.
    /// Looks for `effective_date` and `expiration_date` keys set by the
    /// server-side GDAL pipeline when generating MBTiles from FAA GeoTIFFs.
    func readChartExpirationMetadata(from mbtilesURL: URL? = nil) {
        let fileManager = FileManager.default
        let url: URL
        if let provided = mbtilesURL {
            url = provided
        } else {
            guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
                return
            }
            url = appSupport.appendingPathComponent("efb-212/sectional.mbtiles")
        }

        guard fileManager.fileExists(atPath: url.path) else {
            chartExpirationDate = nil
            chartEffectiveDate = nil
            return
        }

        // Open MBTiles as SQLite and query metadata table
        var db: OpaquePointer?
        guard sqlite3_open_v2(url.path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            chartExpirationDate = nil
            chartEffectiveDate = nil
            return
        }
        defer { sqlite3_close(db) }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // Also try without fractional seconds
        let fallbackFormatter = ISO8601DateFormatter()
        fallbackFormatter.formatOptions = [.withInternetDateTime]

        // Read effective_date
        chartEffectiveDate = queryMetadata(db: db, key: "effective_date", formatters: [formatter, fallbackFormatter])

        // Read expiration_date
        chartExpirationDate = queryMetadata(db: db, key: "expiration_date", formatters: [formatter, fallbackFormatter])
    }

    private func queryMetadata(db: OpaquePointer?, key: String, formatters: [ISO8601DateFormatter]) -> Date? {
        var statement: OpaquePointer?
        let sql = "SELECT value FROM metadata WHERE name = ?"
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_text(statement, 1, (key as NSString).utf8String, -1, nil)

        guard sqlite3_step(statement) == SQLITE_ROW else { return nil }
        guard let cStr = sqlite3_column_text(statement, 0) else { return nil }
        let value = String(cString: cStr)

        for fmt in formatters {
            if let date = fmt.date(from: value) {
                return date
            }
        }

        // Try plain date format (yyyy-MM-dd)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter.date(from: value)
    }

    // MARK: - Airspace Layer

    private func addAirspaceLayer(to style: MLNStyle) {
        let source = MLNShapeSource(
            identifier: "airspaces",
            shape: MLNShapeCollectionFeature(shapes: []),
            options: nil
        )
        style.addSource(source)
        self.airspaceSource = source

        // Fill layer for airspace polygons
        let fillLayer = MLNFillStyleLayer(identifier: "airspace-fill", source: source)
        // Data-driven: Class B blue 10%, Class C magenta 10%, Class D blue 8%
        fillLayer.fillColor = NSExpression(
            forConditional: NSPredicate(format: "airspaceClass == 'bravo'"),
            trueExpression: NSExpression(forConstantValue: UIColor.systemBlue),
            falseExpression: NSExpression(
                forConditional: NSPredicate(format: "airspaceClass == 'charlie'"),
                trueExpression: NSExpression(forConstantValue: UIColor.systemPurple),
                falseExpression: NSExpression(forConstantValue: UIColor.systemBlue)
            )
        )
        fillLayer.fillOpacity = NSExpression(
            forConditional: NSPredicate(format: "airspaceClass == 'delta'"),
            trueExpression: NSExpression(forConstantValue: 0.08),
            falseExpression: NSExpression(forConstantValue: 0.10)
        )
        style.addLayer(fillLayer)

        // Line layer for airspace borders
        let lineLayer = MLNLineStyleLayer(identifier: "airspace-border", source: source)
        lineLayer.lineColor = NSExpression(
            forConditional: NSPredicate(format: "airspaceClass == 'charlie'"),
            trueExpression: NSExpression(forConstantValue: UIColor.systemPurple),
            falseExpression: NSExpression(forConstantValue: UIColor.systemBlue)
        )
        lineLayer.lineWidth = NSExpression(
            forConditional: NSPredicate(format: "airspaceClass == 'delta'"),
            trueExpression: NSExpression(forConstantValue: 1.5),
            falseExpression: NSExpression(forConstantValue: 2.0)
        )
        style.addLayer(lineLayer)

        // Symbol layer for floor/ceiling labels
        let labelLayer = MLNSymbolStyleLayer(identifier: "airspace-labels", source: source)
        labelLayer.text = NSExpression(forKeyPath: "label")
        labelLayer.textFontSize = NSExpression(forConstantValue: 10)
        labelLayer.textColor = NSExpression(forConstantValue: UIColor.secondaryLabel)
        labelLayer.textAllowsOverlap = NSExpression(forConstantValue: false)
        style.addLayer(labelLayer)
    }

    // MARK: - Weather Dot Layer

    private func addWeatherDotLayer(to style: MLNStyle) {
        let source = MLNShapeSource(
            identifier: "weather-dots",
            shape: MLNShapeCollectionFeature(shapes: []),
            options: nil
        )
        style.addSource(source)
        self.weatherSource = source

        let circleLayer = MLNCircleStyleLayer(identifier: "weather-circles", source: source)
        circleLayer.circleRadius = NSExpression(forConstantValue: 8)
        circleLayer.circleStrokeWidth = NSExpression(forConstantValue: 1)
        circleLayer.circleStrokeColor = NSExpression(forConstantValue: UIColor.white)

        // Data-driven color by flightCategory property: VFR=green, MVFR=blue, IFR=red, LIFR=magenta
        circleLayer.circleColor = NSExpression(
            forConditional: NSPredicate(format: "flightCategory == 'vfr'"),
            trueExpression: NSExpression(forConstantValue: UIColor.systemGreen),
            falseExpression: NSExpression(
                forConditional: NSPredicate(format: "flightCategory == 'mvfr'"),
                trueExpression: NSExpression(forConstantValue: UIColor.systemBlue),
                falseExpression: NSExpression(
                    forConditional: NSPredicate(format: "flightCategory == 'ifr'"),
                    trueExpression: NSExpression(forConstantValue: UIColor.systemRed),
                    falseExpression: NSExpression(forConstantValue: UIColor(red: 0.8, green: 0.0, blue: 0.8, alpha: 1.0))  // LIFR magenta
                )
            )
        )
        style.addLayer(circleLayer)
    }

    // MARK: - TFR Layer

    private func addTFRLayer(to style: MLNStyle) {
        let source = MLNShapeSource(
            identifier: "tfrs",
            shape: MLNShapeCollectionFeature(shapes: []),
            options: nil
        )
        style.addSource(source)
        self.tfrSource = source

        // Red fill at 20% opacity
        let fillLayer = MLNFillStyleLayer(identifier: "tfr-fill", source: source)
        fillLayer.fillColor = NSExpression(forConstantValue: UIColor.systemRed)
        fillLayer.fillOpacity = NSExpression(forConstantValue: 0.20)
        style.addLayer(fillLayer)

        // 2pt solid red border
        let lineLayer = MLNLineStyleLayer(identifier: "tfr-border", source: source)
        lineLayer.lineColor = NSExpression(forConstantValue: UIColor.systemRed)
        lineLayer.lineWidth = NSExpression(forConstantValue: 2.0)
        style.addLayer(lineLayer)
    }

    // MARK: - Update Methods

    /// Update ownship GeoJSON point with new coordinates and heading.
    func updateOwnship(location: CLLocation, heading: Double) {
        let point = MLNPointFeature()
        point.coordinate = location.coordinate
        point.attributes = ["heading": heading]
        ownshipSource?.shape = point
    }

    /// Build GeoJSON FeatureCollection from airport array and update source.
    func updateAirports(_ airports: [Airport]) {
        let features = airports.map { airport -> MLNPointFeature in
            let feature = MLNPointFeature()
            feature.coordinate = airport.coordinate
            feature.attributes = [
                "icao": airport.icao,
                "name": airport.name,
                "type": airport.type.rawValue,
                "isTowered": airport.frequencies.contains { $0.type == .tower }
            ]
            return feature
        }
        let collection = MLNShapeCollectionFeature(shapes: features)
        airportSource?.shape = collection
    }

    /// Build GeoJSON FeatureCollection from navaid array and update source.
    func updateNavaids(_ navaids: [Navaid]) {
        let features = navaids.map { navaid -> MLNPointFeature in
            let feature = MLNPointFeature()
            feature.coordinate = navaid.coordinate
            feature.attributes = [
                "id": navaid.id,
                "name": navaid.name,
                "type": navaid.type.rawValue
            ]
            return feature
        }
        let collection = MLNShapeCollectionFeature(shapes: features)
        navaidSource?.shape = collection
    }

    /// Build GeoJSON FeatureCollection with Polygon geometries from airspace coordinates.
    func updateAirspaces(_ airspaces: [Airspace]) {
        let features: [MLNShape] = airspaces.compactMap { airspace in
            switch airspace.geometry {
            case .polygon(let coordinates):
                guard coordinates.count >= 3 else { return nil }
                var coords = coordinates.map {
                    CLLocationCoordinate2D(latitude: $0[0], longitude: $0[1])
                }
                let polygon = MLNPolygonFeature(coordinates: &coords, count: UInt(coords.count))
                polygon.attributes = [
                    "name": airspace.name,
                    "airspaceClass": airspace.classification.rawValue,
                    "floorAltitude": airspace.floor,
                    "ceilingAltitude": airspace.ceiling,
                    "label": "\(airspace.floor)/\(airspace.ceiling)"
                ]
                return polygon

            case .circle(let center, let radiusNM):
                guard center.count >= 2 else { return nil }
                // Approximate circle as 36-point polygon
                let centerCoord = CLLocationCoordinate2D(latitude: center[0], longitude: center[1])
                let radiusMeters = radiusNM * 1852.0
                var coords = (0..<36).map { i -> CLLocationCoordinate2D in
                    let angle = Double(i) * (360.0 / 36.0) * .pi / 180.0
                    let lat = centerCoord.latitude + (radiusMeters / 111320.0) * cos(angle)
                    let lon = centerCoord.longitude + (radiusMeters / (111320.0 * cos(centerCoord.latitude * .pi / 180.0))) * sin(angle)
                    return CLLocationCoordinate2D(latitude: lat, longitude: lon)
                }
                let polygon = MLNPolygonFeature(coordinates: &coords, count: UInt(coords.count))
                polygon.attributes = [
                    "name": airspace.name,
                    "airspaceClass": airspace.classification.rawValue,
                    "floorAltitude": airspace.floor,
                    "ceilingAltitude": airspace.ceiling,
                    "label": "\(airspace.floor)/\(airspace.ceiling)"
                ]
                return polygon
            }
        }
        let collection = MLNShapeCollectionFeature(shapes: features)
        airspaceSource?.shape = collection
    }

    /// Build GeoJSON FeatureCollection from weather cache for map dots.
    func updateWeatherDots(_ weather: [WeatherCache]) {
        let features = weather.compactMap { wx -> MLNPointFeature? in
            guard let lat = getStationLatitude(wx.stationID),
                  let lon = getStationLongitude(wx.stationID) else {
                // Weather data without coordinates -- skip (coordinates come from airport DB)
                return nil
            }
            let feature = MLNPointFeature()
            feature.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            feature.attributes = [
                "stationID": wx.stationID,
                "flightCategory": wx.flightCategory.rawValue
            ]
            return feature
        }
        let collection = MLNShapeCollectionFeature(shapes: features)
        weatherSource?.shape = collection
    }

    /// Build GeoJSON FeatureCollection from TFR array.
    func updateTFRs(_ tfrs: [TFR]) {
        let features: [MLNShape] = tfrs.compactMap { tfr in
            if let radiusNM = tfr.radiusNM, radiusNM > 0 {
                // Circular TFR - approximate as polygon
                let radiusMeters = radiusNM * 1852.0
                var coords = (0..<36).map { i -> CLLocationCoordinate2D in
                    let angle = Double(i) * (360.0 / 36.0) * .pi / 180.0
                    let lat = tfr.latitude + (radiusMeters / 111320.0) * cos(angle)
                    let lon = tfr.longitude + (radiusMeters / (111320.0 * cos(tfr.latitude * .pi / 180.0))) * sin(angle)
                    return CLLocationCoordinate2D(latitude: lat, longitude: lon)
                }
                let polygon = MLNPolygonFeature(coordinates: &coords, count: UInt(coords.count))
                polygon.attributes = [
                    "id": tfr.id,
                    "type": tfr.type.rawValue
                ]
                return polygon
            } else if !tfr.boundaries.isEmpty {
                // Polygon TFR
                var coords = tfr.boundaries.map {
                    CLLocationCoordinate2D(latitude: $0[0], longitude: $0[1])
                }
                guard coords.count >= 3 else { return nil }
                let polygon = MLNPolygonFeature(coordinates: &coords, count: UInt(coords.count))
                polygon.attributes = [
                    "id": tfr.id,
                    "type": tfr.type.rawValue
                ]
                return polygon
            }
            return nil
        }
        let collection = MLNShapeCollectionFeature(shapes: features)
        tfrSource?.shape = collection
    }

    // MARK: - Layer Visibility

    /// Toggle style layer visibility by MapLayer enum.
    func setLayerVisibility(_ layer: MapLayer, visible: Bool) {
        guard let style = mapView?.style else { return }
        let layerIDs = layerIdentifiers(for: layer)
        for id in layerIDs {
            style.layer(withIdentifier: id)?.isVisible = visible
        }
    }

    /// Map MapLayer enum to MapLibre style layer identifiers.
    private func layerIdentifiers(for layer: MapLayer) -> [String] {
        switch layer {
        case .airports: return ["airport-circles"]
        case .navaids: return ["navaid-circles"]
        case .airspace: return ["airspace-fill", "airspace-border", "airspace-labels"]
        case .weatherDots: return ["weather-circles"]
        case .tfrs: return ["tfr-fill", "tfr-border"]
        case .ownship: return ["ownship-symbol"]
        case .sectional: return ["sectional-overlay"]
        case .route: return []  // Route layer added in flight planning plan
        }
    }

    // MARK: - Sectional Opacity

    /// Update raster layer opacity for sectional overlay.
    func setSectionalOpacity(_ opacity: Double) {
        sectionalLayer?.rasterOpacity = NSExpression(forConstantValue: opacity)
    }

    // MARK: - Animation

    /// Animate map to a location with zoom level.
    func animateToLocation(_ coordinate: CLLocationCoordinate2D, zoom: Double) {
        mapView?.setCenter(coordinate, zoomLevel: zoom, direction: mapView?.direction ?? 0, animated: true)
    }

    // MARK: - Helpers

    /// Placeholder for weather dot coordinate lookup.
    /// In practice, coordinates come from joining weather station ID with airport database.
    /// Weather dots are populated by Plan 04 which passes coordinates directly.
    private func getStationLatitude(_ stationID: String) -> Double? { nil }
    private func getStationLongitude(_ stationID: String) -> Double? { nil }
}
