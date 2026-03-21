//
//  AircraftProfile.swift
//  efb-212
//
//  SwiftData model for aircraft profiles.
//  Stored in SchemaV1 for versioned migration support.
//  CloudKit-ready foundation (not enabled for v1).
//

import Foundation
import SwiftData

// MARK: - AircraftProfile

extension SchemaV1 {

    @Model
    final class AircraftProfile {
        /// Unique identifier for this profile.
        var id: UUID = UUID()

        /// FAA registration number (e.g., "N4543A").
        var nNumber: String = ""

        /// Aircraft type/model (free text, e.g., "Cessna 172SP").
        var aircraftType: String = ""

        /// Usable fuel capacity -- gallons.
        var fuelCapacityGallons: Double?

        /// Cruise fuel burn rate -- gallons per hour.
        var fuelBurnGPH: Double?

        /// Cruise true airspeed -- knots.
        var cruiseSpeedKts: Double?

        /// JSON-encoded VSpeeds struct (optional).
        var vSpeedsData: Data?

        /// Whether this is the currently selected aircraft.
        var isActive: Bool = false

        /// Annual inspection due date.
        var annualDue: Date?

        /// Transponder inspection due date.
        var transponderDue: Date?

        /// Date this profile was created.
        var createdAt: Date = Date()

        init(nNumber: String) {
            self.nNumber = nNumber
        }

        // MARK: - Computed Properties

        /// V-speeds decoded from JSON storage.
        var vSpeeds: VSpeeds? {
            get {
                guard let data = vSpeedsData else { return nil }
                return try? JSONDecoder().decode(VSpeeds.self, from: data)
            }
            set {
                vSpeedsData = try? JSONEncoder().encode(newValue)
            }
        }

        /// Whether this profile has minimum required data (non-empty N-number).
        var isValid: Bool {
            !nNumber.isEmpty
        }
    }
}
