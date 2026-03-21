//
//  PilotProfileViewModel.swift
//  efb-212
//
//  ViewModel for pilot profile management -- CRUD, active selection,
//  currency computation via CurrencyService, and night landing entry.
//  Uses @Observable (iOS 26 pattern).
//

import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class PilotProfileViewModel {

    // MARK: - Published State

    /// All pilot profiles, sorted by creation date (newest first).
    var profiles: [SchemaV1.PilotProfile] = []

    /// The currently selected active pilot profile.
    var activeProfile: SchemaV1.PilotProfile?

    /// Currency status computed from active profile's dates.
    var medicalCurrency: CurrencyStatus = .expired
    var flightReviewCurrency: CurrencyStatus = .expired
    var nightCurrency: CurrencyStatus = .expired
    var overallCurrency: CurrencyStatus = .expired

    /// Whether the editor sheet is showing.
    var isShowingEditor: Bool = false

    /// Profile being edited (nil = creating new).
    var editingProfile: SchemaV1.PilotProfile?

    /// Whether the night landing entry sheet is showing.
    var isShowingNightLandingEntry: Bool = false

    // MARK: - Dependencies

    private let modelContext: ModelContext
    private let appState: AppState

    // MARK: - Init

    init(modelContext: ModelContext, appState: AppState) {
        self.modelContext = modelContext
        self.appState = appState
    }

    // MARK: - CRUD Operations

    /// Fetch all PilotProfile from modelContext, sorted by createdAt descending.
    /// Sets profiles array, finds active profile, syncs to AppState, computes currency.
    func loadProfiles() {
        let descriptor = FetchDescriptor<SchemaV1.PilotProfile>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            profiles = try modelContext.fetch(descriptor)
            activeProfile = profiles.first(where: { $0.isActive })
            appState.activePilotProfileID = activeProfile?.id
        } catch {
            profiles = []
            activeProfile = nil
            appState.activePilotProfileID = nil
        }

        computeCurrency()
    }

    /// Compute currency status from the active profile's dates and night landings.
    /// Uses CurrencyService static methods (FAR 61.23, 61.56, 61.57).
    func computeCurrency() {
        guard let profile = activeProfile else {
            medicalCurrency = .expired
            flightReviewCurrency = .expired
            nightCurrency = .expired
            overallCurrency = .expired
            return
        }

        medicalCurrency = CurrencyService.medicalStatus(expiryDate: profile.medicalExpiry)
        flightReviewCurrency = CurrencyService.flightReviewStatus(reviewDate: profile.flightReviewDate)

        let nightLandings = profile.nightLandingEntries.map { (date: $0.date, count: $0.count) }
        nightCurrency = CurrencyService.nightCurrencyStatus(nightLandings: nightLandings)

        overallCurrency = CurrencyService.overallStatus(
            medical: medicalCurrency,
            flightReview: flightReviewCurrency,
            night: nightCurrency
        )
    }

    /// Create a new empty pilot profile.
    func addProfile() {
        let profile = SchemaV1.PilotProfile()
        modelContext.insert(profile)

        do {
            try modelContext.save()
        } catch {
            // Insert still pending
        }

        loadProfiles()
    }

    /// Delete the specified pilot profile.
    func deleteProfile(_ profile: SchemaV1.PilotProfile) {
        let wasActive = profile.isActive

        modelContext.delete(profile)

        if wasActive {
            activeProfile = nil
            appState.activePilotProfileID = nil
        }

        do {
            try modelContext.save()
        } catch {
            // Deletion still pending
        }

        loadProfiles()
    }

    /// Set the specified profile as the active pilot.
    /// Deactivates all other profiles first.
    func setActive(_ profile: SchemaV1.PilotProfile) {
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

    /// Add a night landing entry to the active pilot profile.
    /// - Parameters:
    ///   - date: Date of the night landing(s).
    ///   - count: Number of full-stop night landings.
    func addNightLandings(date: Date, count: Int) {
        guard let profile = activeProfile else { return }

        var entries = profile.nightLandingEntries
        entries.append(SchemaV1.NightLandingEntry(date: date, count: count))
        profile.nightLandingEntries = entries

        do {
            try modelContext.save()
        } catch {
            // Changes still pending
        }

        computeCurrency()
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
