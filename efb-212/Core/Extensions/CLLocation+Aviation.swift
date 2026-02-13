//
//  CLLocation+Aviation.swift
//  efb-212
//
//  Aviation-specific CLLocation extensions for distance, bearing, and unit conversions.
//

import CoreLocation

extension CLLocation {
    /// Distance in nautical miles to another location
    func distanceInNM(to other: CLLocation) -> Double {
        self.distance(from: other) / 1852.0  // meters to NM
    }

    /// Bearing in degrees true to another location
    func bearing(to other: CLLocation) -> Double {
        let lat1 = self.coordinate.latitude.degreesToRadians
        let lon1 = self.coordinate.longitude.degreesToRadians
        let lat2 = other.coordinate.latitude.degreesToRadians
        let lon2 = other.coordinate.longitude.degreesToRadians

        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let bearing = atan2(y, x).radiansToDegrees

        return (bearing + 360).truncatingRemainder(dividingBy: 360)
    }
}

extension CLLocationCoordinate2D {
    /// Distance in nautical miles to another coordinate
    func distanceInNM(to other: CLLocationCoordinate2D) -> Double {
        let loc1 = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let loc2 = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return loc1.distanceInNM(to: loc2)
    }
}

extension Double {
    var degreesToRadians: Double { self * .pi / 180.0 }
    var radiansToDegrees: Double { self * 180.0 / .pi }

    /// Convert nautical miles to meters
    var nmToMeters: Double { self * 1852.0 }

    /// Convert meters to nautical miles
    var metersToNM: Double { self / 1852.0 }

    /// Convert feet to meters
    var feetToMeters: Double { self * 0.3048 }

    /// Convert meters to feet
    var metersToFeet: Double { self / 0.3048 }
}
