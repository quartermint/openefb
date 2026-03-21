//
//  PilotProfile.swift
//  efb-212
//
//  SwiftData model for pilot profiles.
//  Stored in SchemaV1 for versioned migration support.
//  CloudKit-ready foundation (not enabled for v1).
//

import Foundation
import SwiftData

// MARK: - PilotProfile

extension SchemaV1 {

    @Model
    final class PilotProfile {
        /// Unique identifier for this profile.
        var id: UUID = UUID()

        /// Pilot's display name.
        var name: String = ""

        /// FAA certificate number.
        var certificateNumber: String?

        /// Certificate type raw value (maps to CertificateType enum).
        var certificateType: String?

        /// Medical class raw value (maps to MedicalClass enum).
        var medicalClass: String?

        /// Medical certificate expiry date.
        var medicalExpiry: Date?

        /// Most recent flight review (BFR) completion date.
        var flightReviewDate: Date?

        /// Total flight hours (pilot-reported).
        var totalHours: Double?

        /// Whether this is the currently selected pilot.
        var isActive: Bool = false

        /// JSON-encoded array of NightLandingEntry for night currency tracking.
        var nightLandingEntriesData: Data?

        /// Date this profile was created.
        var createdAt: Date = Date()

        init() {}

        // MARK: - Computed Properties

        /// Night landing entries decoded from JSON storage (FAR 61.57).
        var nightLandingEntries: [NightLandingEntry] {
            get {
                guard let data = nightLandingEntriesData else { return [] }
                return (try? JSONDecoder().decode([NightLandingEntry].self, from: data)) ?? []
            }
            set {
                nightLandingEntriesData = try? JSONEncoder().encode(newValue)
            }
        }

        /// Typed medical class (get/set wrapper around raw string).
        var medicalClassEnum: MedicalClass? {
            get {
                guard let raw = medicalClass else { return nil }
                return MedicalClass(rawValue: raw)
            }
            set {
                medicalClass = newValue?.rawValue
            }
        }

        /// Typed certificate type (get/set wrapper around raw string).
        var certificateTypeEnum: CertificateType? {
            get {
                guard let raw = certificateType else { return nil }
                return CertificateType(rawValue: raw)
            }
            set {
                certificateType = newValue?.rawValue
            }
        }
    }

    // MARK: - NightLandingEntry

    /// A single night landing entry for FAR 61.57 currency tracking.
    struct NightLandingEntry: Codable, Equatable, Sendable {
        /// Date of the night landing(s).
        var date: Date

        /// Number of full-stop night landings on this date.
        var count: Int
    }
}
