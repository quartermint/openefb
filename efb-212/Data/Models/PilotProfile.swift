//
//  PilotProfile.swift
//  efb-212
//
//  SwiftData model for pilot profile and currency tracking.
//  Stores certificate info, medical class/expiry, and flight review dates.
//  CloudKit-ready for future premium sync.
//

import SwiftData
import Foundation

@Model
final class PilotProfileModel {
    var name: String?
    var certificateNumber: String?
    var certificateType: String?             // Stored as raw string from CertificateType enum
    var medicalClass: String?                // Stored as raw string from MedicalClass enum
    var medicalExpiry: Date?
    var flightReviewDate: Date?
    var totalHours: Double?

    init() {}
}
