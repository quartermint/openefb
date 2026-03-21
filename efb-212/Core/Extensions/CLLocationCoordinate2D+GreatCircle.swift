//
//  CLLocationCoordinate2D+GreatCircle.swift
//  efb-212
//
//  Great-circle intermediate point computation for route line rendering.
//  Uses spherical interpolation (slerp) to generate evenly spaced points
//  along the shortest path between two coordinates on the Earth's surface.
//

import CoreLocation

extension CLLocationCoordinate2D {

    /// Compute intermediate points along a great-circle path between two coordinates.
    /// Uses spherical interpolation (slerp) for accurate geodesic path rendering.
    ///
    /// - Parameters:
    ///   - start: Departure coordinate
    ///   - end: Destination coordinate
    ///   - count: Number of intermediate points (default 100)
    /// - Returns: Array of coordinates along the great-circle path, including start and end
    static func greatCirclePoints(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D,
        count: Int = 100
    ) -> [CLLocationCoordinate2D] {
        let lat1 = start.latitude.degreesToRadians   // radians
        let lon1 = start.longitude.degreesToRadians  // radians
        let lat2 = end.latitude.degreesToRadians     // radians
        let lon2 = end.longitude.degreesToRadians    // radians

        // Angular distance between points (Haversine)
        let d = 2 * asin(sqrt(
            pow(sin((lat1 - lat2) / 2), 2) +
            cos(lat1) * cos(lat2) * pow(sin((lon1 - lon2) / 2), 2)
        ))

        // Guard zero-distance (same point or very close)
        guard d > 1e-10 else {
            return [start]
        }

        let sinD = sin(d)

        return (0...count).map { i in
            let f = Double(i) / Double(count)
            let a = sin((1 - f) * d) / sinD
            let b = sin(f * d) / sinD

            let x = a * cos(lat1) * cos(lon1) + b * cos(lat2) * cos(lon2)
            let y = a * cos(lat1) * sin(lon1) + b * cos(lat2) * sin(lon2)
            let z = a * sin(lat1) + b * sin(lat2)

            let lat = atan2(z, sqrt(x * x + y * y))
            let lon = atan2(y, x)

            return CLLocationCoordinate2D(
                latitude: lat.radiansToDegrees,   // degrees
                longitude: lon.radiansToDegrees   // degrees
            )
        }
    }
}
