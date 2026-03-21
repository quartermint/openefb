//
//  UserSettings.swift
//  efb-212
//
//  SwiftData VersionedSchema V1 for user settings.
//  CloudKit-ready foundation (not enabled for v1).
//

import Foundation
import SwiftData

// MARK: - Schema V1

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [UserSettings.self, AircraftProfile.self, PilotProfile.self, FlightPlanRecord.self, FlightRecord.self, LogbookEntry.self]
    }

    @Model
    final class UserSettings {
        /// Default map orientation mode ("northUp" or "trackUp").
        var defaultMapMode: String = "northUp"

        /// Default VFR sectional overlay opacity (0.0 to 1.0).
        var sectionalOpacity: Double = 0.70

        /// Weather auto-refresh interval in seconds (default: 15 minutes).
        var weatherRefreshInterval: Double = 900

        /// UUID string of active aircraft profile (persists across launches).
        var activeAircraftID: String?

        /// UUID string of active pilot profile (persists across launches).
        var activePilotID: String?

        /// UUID string of last used flight plan (for auto-load on launch).
        var lastFlightPlanID: String?

        /// Date this settings record was created.
        var createdAt: Date = Date()

        init() {}
    }
}

// MARK: - Migration Plan

enum EFBSchemaMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}
