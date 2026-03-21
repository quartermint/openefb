//
//  AircraftProfileViewModel.swift
//  efb-212
//
//  ViewModel for aircraft profile management -- CRUD, active selection,
//  and AppState synchronization. Uses @Observable (iOS 26 pattern).
//

import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class AircraftProfileViewModel {

    // MARK: - Published State

    /// All aircraft profiles, sorted by creation date (newest first).
    var profiles: [SchemaV1.AircraftProfile] = []

    /// The currently selected active aircraft profile.
    var activeProfile: SchemaV1.AircraftProfile?

    /// Whether the editor sheet is showing.
    var isShowingEditor: Bool = false

    /// Profile being edited (nil = creating new).
    var editingProfile: SchemaV1.AircraftProfile?

    // MARK: - Dependencies

    private let modelContext: ModelContext
    private let appState: AppState

    // MARK: - Init

    init(modelContext: ModelContext, appState: AppState) {
        self.modelContext = modelContext
        self.appState = appState
    }

    // MARK: - CRUD Operations

    /// Fetch all AircraftProfile from modelContext, sorted by createdAt descending.
    /// Sets profiles array and finds active profile. Syncs to AppState.
    func loadProfiles() {
        let descriptor = FetchDescriptor<SchemaV1.AircraftProfile>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            profiles = try modelContext.fetch(descriptor)
            activeProfile = profiles.first(where: { $0.isActive })
            appState.activeAircraftProfileID = activeProfile?.id
        } catch {
            profiles = []
            activeProfile = nil
            appState.activeAircraftProfileID = nil
        }
    }

    /// Create a new aircraft profile with the given N-number.
    func addProfile(nNumber: String) {
        let profile = SchemaV1.AircraftProfile(nNumber: nNumber)
        modelContext.insert(profile)

        do {
            try modelContext.save()
        } catch {
            // Insert still pending -- will save on next successful save
        }

        loadProfiles()
    }

    /// Delete the specified aircraft profile.
    func deleteProfile(_ profile: SchemaV1.AircraftProfile) {
        let wasActive = profile.isActive

        modelContext.delete(profile)

        if wasActive {
            activeProfile = nil
            appState.activeAircraftProfileID = nil
        }

        do {
            try modelContext.save()
        } catch {
            // Deletion still pending
        }

        loadProfiles()
    }

    /// Set the specified profile as the active aircraft.
    /// Deactivates all other profiles first.
    func setActive(_ profile: SchemaV1.AircraftProfile) {
        // Deactivate all
        for p in profiles {
            p.isActive = false
        }

        // Activate selected
        profile.isActive = true

        do {
            try modelContext.save()
        } catch {
            // Changes still pending
        }

        loadProfiles()
    }

    /// Save any pending edits to the current editing profile.
    func saveEdits() {
        do {
            try modelContext.save()
        } catch {
            // Changes still pending
        }

        loadProfiles()
    }
}
