//
//  TFRService.swift
//  efb-212
//
//  Provides active TFR (Temporary Flight Restriction) data for map display.
//  Currently uses realistic stub data; real FAA TFR API integration is Phase 2.
//
//  The FAA TFR API (tfr.faa.gov) and ADDS NOTAM API (aviationweather.gov)
//  have unreliable/hard-to-parse formats. This service returns hardcoded
//  sample TFRs with real-looking data (stadium, VIP, hazard, etc.) to
//  validate the full rendering pipeline. Replace with live API in Phase 2.
//
//  Actor isolation: nonisolated actor (opted out of MainActor default).
//  Conforms to TFRServiceProtocol (Sendable).
//

import Foundation
import CoreLocation

// MARK: - TFRService Actor

nonisolated actor TFRService: TFRServiceProtocol {

    // MARK: - Properties

    /// In-memory TFR cache.
    private var cache: [TFR] = []

    /// Cache time-to-live — 30 minutes.
    private let cacheTTL: TimeInterval = 1800  // seconds

    /// Timestamp of last cache refresh.
    private var lastFetchTime: Date?

    // MARK: - Init

    init() {}

    // MARK: - TFRServiceProtocol

    func fetchActiveTFRs(near coordinate: CLLocationCoordinate2D, radiusNM: Double) async throws -> [TFR] {
        // Return cached data if fresh
        if let lastFetch = lastFetchTime, Date().timeIntervalSince(lastFetch) < cacheTTL, !cache.isEmpty {
            return filterTFRs(cache, near: coordinate, radiusNM: radiusNM)
        }

        // Phase 1: Load realistic stub data
        // Phase 2: Replace with FAA TFR API fetch
        let tfrs = Self.sampleTFRs()
        cache = tfrs
        lastFetchTime = Date()

        return filterTFRs(tfrs, near: coordinate, radiusNM: radiusNM)
    }

    // MARK: - Filtering

    /// Filter TFRs to those within a radius of the given coordinate and currently active.
    /// - Parameters:
    ///   - tfrs: All known TFRs.
    ///   - coordinate: Center of the search area.
    ///   - radiusNM: Search radius in nautical miles.
    /// - Returns: Active TFRs within the search radius.
    private func filterTFRs(_ tfrs: [TFR], near coordinate: CLLocationCoordinate2D, radiusNM: Double) -> [TFR] {
        let centerLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let radiusMeters = radiusNM * 1852.0  // 1 NM = 1852 meters

        return tfrs.filter { tfr in
            guard tfr.isActive else { return false }
            let tfrLocation = CLLocation(latitude: tfr.latitude, longitude: tfr.longitude)
            let distance = centerLocation.distance(from: tfrLocation)
            // Include TFR if its center is within the search radius,
            // accounting for the TFR's own radius if circular
            let tfrRadiusMeters = (tfr.radiusNM ?? 0) * 1852.0
            return distance <= (radiusMeters + tfrRadiusMeters)
        }
    }

    // MARK: - Sample Data

    /// Realistic sample TFRs for Phase 1 development.
    /// Includes stadium TFRs, VIP TFRs, hazard TFRs, and security TFRs
    /// with real coordinates and plausible NOTAM numbers.
    ///
    /// Phase 2: Replace this method with actual FAA API parsing.
    private static func sampleTFRs() -> [TFR] {
        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3600)
        let sixHoursFromNow = now.addingTimeInterval(6 * 3600)
        let twentyFourHoursFromNow = now.addingTimeInterval(24 * 3600)
        let oneWeekFromNow = now.addingTimeInterval(7 * 24 * 3600)

        return [
            // Stadium TFR — Levi's Stadium, Santa Clara, CA (NFL game)
            // 3 NM radius, surface to 3000 ft AGL (typical stadium TFR)
            TFR(
                id: "FDC 4/0254",
                type: .stadium,
                description: "TEMPORARY FLIGHT RESTRICTIONS FOR SPORTING EVENT. LEVI'S STADIUM, SANTA CLARA, CA. EFFECTIVE 1 HOUR BEFORE UNTIL 1 HOUR AFTER EVENT.",
                effectiveDate: oneHourAgo,
                expirationDate: sixHoursFromNow,
                latitude: 37.4033,
                longitude: -121.9694,
                radiusNM: 3.0,
                floorAltitude: 0,       // surface
                ceilingAltitude: 3000   // feet AGL (treated as MSL for simplicity)
            ),

            // Stadium TFR — Oracle Park, San Francisco, CA (MLB game)
            TFR(
                id: "FDC 4/1187",
                type: .stadium,
                description: "TEMPORARY FLIGHT RESTRICTIONS FOR SPORTING EVENT. ORACLE PARK, SAN FRANCISCO, CA. EFFECTIVE 1 HOUR BEFORE UNTIL 1 HOUR AFTER EVENT.",
                effectiveDate: oneHourAgo,
                expirationDate: sixHoursFromNow,
                latitude: 37.7786,
                longitude: -122.3893,
                radiusNM: 3.0,
                floorAltitude: 0,
                ceilingAltitude: 3000
            ),

            // VIP TFR — Palo Alto / Stanford area (presidential visit)
            TFR(
                id: "FDC 4/2891",
                type: .vip,
                description: "TEMPORARY FLIGHT RESTRICTIONS VIP MOVEMENT. PALO ALTO, CA. NO AIRCRAFT OPERATIONS WITHIN DESIGNATED AREA EXCEPT THOSE AUTHORIZED BY ATC.",
                effectiveDate: oneHourAgo,
                expirationDate: twentyFourHoursFromNow,
                latitude: 37.4419,
                longitude: -122.1430,
                radiusNM: 10.0,
                floorAltitude: 0,
                ceilingAltitude: 18000  // feet MSL (FL180)
            ),

            // Hazard TFR — Firefighting near Big Basin, CA
            TFR(
                id: "FDC 4/3456",
                type: .hazard,
                description: "TEMPORARY FLIGHT RESTRICTIONS FOR WILDFIRE SUPPRESSION. BIG BASIN REDWOODS STATE PARK, CA. AERIAL FIREFIGHTING OPERATIONS IN PROGRESS.",
                effectiveDate: oneHourAgo,
                expirationDate: oneWeekFromNow,
                latitude: 37.1750,
                longitude: -122.2269,
                radiusNM: 5.0,
                floorAltitude: 0,
                ceilingAltitude: 8000
            ),

            // Security TFR — SFO area (security event)
            TFR(
                id: "FDC 4/5012",
                type: .security,
                description: "TEMPORARY FLIGHT RESTRICTIONS FOR NATIONAL SECURITY. SAN FRANCISCO INTERNATIONAL AIRPORT AREA. SPECIAL SECURITY PROCEDURES IN EFFECT.",
                effectiveDate: oneHourAgo,
                expirationDate: twentyFourHoursFromNow,
                latitude: 37.6213,
                longitude: -122.3790,
                radiusNM: 3.0,
                floorAltitude: 0,
                ceilingAltitude: 5000
            ),

            // Airshow TFR — Moffett Field, Mountain View, CA
            TFR(
                id: "FDC 4/6789",
                type: .airshow,
                description: "TEMPORARY FLIGHT RESTRICTIONS FOR AIR SHOW. MOFFETT FEDERAL AIRFIELD, MOUNTAIN VIEW, CA. AEROBATIC ACTIVITY.",
                effectiveDate: oneHourAgo,
                expirationDate: sixHoursFromNow,
                latitude: 37.4153,
                longitude: -122.0490,
                radiusNM: 5.0,
                floorAltitude: 0,
                ceilingAltitude: 15000
            ),
        ]
    }
}
