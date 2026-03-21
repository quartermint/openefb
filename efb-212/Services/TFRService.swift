//
//  TFRService.swift
//  efb-212
//
//  Stub TFR service with sample data for Phase 1.
//  Per RESEARCH.md: no clean FAA JSON API for TFRs.
//  Ships with well-known sample TFRs (DC SFRA, stadium, etc.).
//  All sample data marked with isSample flag for UI disclaimer.
//

import Foundation
import CoreLocation

/// Constant flag for UI disclaimer banner when TFR data is sample-only.
let TFR_DATA_IS_SAMPLE = true

actor TFRService: TFRServiceProtocol {

    // MARK: - Sample TFR Data

    /// Well-known sample TFRs for Phase 1 demonstration.
    private let sampleTFRs: [TFR] = [
        // Washington DC SFRA (permanent)
        TFR(
            id: "FDC 1/0481",
            type: .security,
            description: "Washington DC Special Flight Rules Area (SFRA). All aircraft must comply with procedures in 14 CFR 93 Subpart V.",
            effectiveDate: Date.distantPast,
            expirationDate: Date.distantFuture,
            latitude: 38.8977,
            longitude: -77.0365,
            radiusNM: 30.0,
            floorAltitude: 0,    // feet MSL — surface
            ceilingAltitude: 18000  // feet MSL
        ),
        // Typical presidential TFR (example)
        TFR(
            id: "FDC 4/0254",
            type: .vip,
            description: "Temporary flight restrictions for VIP movement. No flight operations within designated area without ATC authorization.",
            effectiveDate: Date(),
            expirationDate: Date().addingTimeInterval(86400),  // 24 hours
            latitude: 33.9425,
            longitude: -118.4081,
            radiusNM: 10.0,
            floorAltitude: 0,    // feet MSL — surface
            ceilingAltitude: 18000  // feet MSL
        ),
        // Stadium TFR (typical Sunday NFL)
        TFR(
            id: "FDC 4/1001",
            type: .stadium,
            description: "Temporary flight restrictions for sporting event. SoFi Stadium, Inglewood, CA.",
            effectiveDate: Date(),
            expirationDate: Date().addingTimeInterval(21600),  // 6 hours
            latitude: 33.9535,
            longitude: -118.3392,
            radiusNM: 3.0,
            floorAltitude: 0,    // feet MSL — surface
            ceilingAltitude: 3000  // feet AGL (approximated as MSL for simplicity)
        ),
        // Space launch TFR (Cape Canaveral)
        TFR(
            id: "FDC 4/2050",
            type: .hazard,
            description: "Temporary flight restrictions for space launch operations. Cape Canaveral Space Force Station.",
            effectiveDate: Date(),
            expirationDate: Date().addingTimeInterval(43200),  // 12 hours
            latitude: 28.3922,
            longitude: -80.6077,
            radiusNM: 30.0,
            floorAltitude: 0,    // feet MSL — surface
            ceilingAltitude: 99999  // feet MSL — unlimited
        ),
        // Fire suppression TFR
        TFR(
            id: "FDC 4/3100",
            type: .hazard,
            description: "Temporary flight restrictions for wildfire suppression operations. No unauthorized aircraft within designated area.",
            effectiveDate: Date(),
            expirationDate: Date().addingTimeInterval(172800),  // 48 hours
            latitude: 34.2000,
            longitude: -118.1000,
            radiusNM: 5.0,
            floorAltitude: 0,    // feet MSL — surface
            ceilingAltitude: 8000  // feet MSL
        )
    ]

    // MARK: - TFRServiceProtocol

    func fetchTFRs(near coordinate: CLLocationCoordinate2D, radiusNM: Double) async throws -> [TFR] {
        // Filter sample TFRs by proximity to center coordinate
        return sampleTFRs.filter { tfr in
            let distance = haversineDistanceNM(
                from: coordinate,
                to: CLLocationCoordinate2D(latitude: tfr.latitude, longitude: tfr.longitude)
            )
            // Include TFRs whose center is within the search radius + their own radius
            let effectiveRadius = (tfr.radiusNM ?? 0) + radiusNM
            return distance <= effectiveRadius
        }
    }

    func activeTFRs() async throws -> [TFR] {
        // Return all sample TFRs (they're always "active" for demo purposes)
        return sampleTFRs
    }

    // MARK: - Distance Calculation

    /// Haversine great-circle distance in nautical miles.
    private func haversineDistanceNM(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D
    ) -> Double {
        let earthRadiusNM = 3440.065  // nautical miles
        let dLat = (to.latitude - from.latitude) * .pi / 180.0
        let dLon = (to.longitude - from.longitude) * .pi / 180.0
        let lat1 = from.latitude * .pi / 180.0
        let lat2 = to.latitude * .pi / 180.0

        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))

        return earthRadiusNM * c
    }
}
