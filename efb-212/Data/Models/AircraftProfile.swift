//
//  AircraftProfile.swift
//  efb-212
//
//  SwiftData model for user aircraft profiles.
//  Stores aircraft registration, performance data, and inspection dates.
//  CloudKit-ready for future premium sync.
//

import SwiftData
import Foundation

@Model
final class AircraftProfileModel {
    var nNumber: String                      // FAA registration (e.g., "N4543A")
    var aircraftType: String?                // e.g., "AA-5B Tiger"
    var fuelCapacityGallons: Double?         // gallons
    var fuelBurnGPH: Double?                 // gallons per hour
    var cruiseSpeedKts: Double?              // knots TAS
    var annualDue: Date?                     // Annual inspection due date
    var transponderDue: Date?                // Transponder check due date
    var createdAt: Date

    init(nNumber: String) {
        self.nNumber = nNumber
        self.createdAt = Date()
    }
}
