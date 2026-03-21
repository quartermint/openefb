//
//  ContentView.swift
//  efb-212
//
//  Root view -- 5-tab TabView shell.
//  Aircraft tab shows real profile management views.
//  Currency warning badge on Aircraft tab icon when any currency is warning/expired.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    /// Number of non-current currency statuses for tab badge display.
    @State private var currencyBadgeCount: Int = 0

    /// Number of unconfirmed logbook entries for tab badge display.
    @State private var unconfirmedLogbookCount: Int = 0

    var body: some View {
        @Bindable var appState = appState

        VStack(spacing: 0) {
            BetaBanner()

            TabView(selection: $appState.selectedTab) {
                Tab(AppTab.map.title, systemImage: AppTab.map.systemImage, value: .map) {
                    MapContainerView()
                }

                Tab(AppTab.flights.title, systemImage: AppTab.flights.systemImage, value: .flights) {
                    FlightsTabView()
                }

                Tab(AppTab.logbook.title, systemImage: AppTab.logbook.systemImage, value: .logbook) {
                    LogbookListView()
                }
                .badge(unconfirmedLogbookCount)

                Tab(AppTab.aircraft.title, systemImage: AppTab.aircraft.systemImage, value: .aircraft) {
                    AircraftListView()
                }
                .badge(currencyBadgeCount)

                Tab(AppTab.settings.title, systemImage: AppTab.settings.systemImage, value: .settings) {
                    SettingsView()
                }
            }
            .onAppear {
                updateCurrencyBadge()
                updateLogbookBadge()
            }
            .onChange(of: appState.activePilotProfileID) { _, _ in
                updateCurrencyBadge()
            }
            .onChange(of: appState.selectedTab) { _, _ in
                updateLogbookBadge()
                updateCurrencyBadge()
            }
        }
    }

    // MARK: - Currency Badge Computation

    /// Fetch active pilot profile and compute how many currency statuses are non-current.
    /// Badge count shows on Aircraft tab icon (hidden when 0).
    private func updateCurrencyBadge() {
        let descriptor = FetchDescriptor<SchemaV1.PilotProfile>(
            predicate: #Predicate<SchemaV1.PilotProfile> { $0.isActive == true }
        )

        guard let activeProfiles = try? modelContext.fetch(descriptor),
              let profile = activeProfiles.first else {
            currencyBadgeCount = 0
            return
        }

        let medical = CurrencyService.medicalStatus(expiryDate: profile.medicalExpiry)
        let flightReview = CurrencyService.flightReviewStatus(reviewDate: profile.flightReviewDate)
        let nightLandings = profile.nightLandingEntries.map { (date: $0.date, count: $0.count) }
        let night = CurrencyService.nightCurrencyStatus(nightLandings: nightLandings)

        var count = 0
        if medical != .current { count += 1 }
        if flightReview != .current { count += 1 }
        if night != .current { count += 1 }

        currencyBadgeCount = count
    }

    // MARK: - Logbook Badge Computation

    /// Count unconfirmed logbook entries for tab badge display.
    private func updateLogbookBadge() {
        let descriptor = FetchDescriptor<SchemaV1.LogbookEntry>(
            predicate: #Predicate<SchemaV1.LogbookEntry> { $0.isConfirmed == false }
        )
        unconfirmedLogbookCount = (try? modelContext.fetchCount(descriptor)) ?? 0
    }
}

// MARK: - Flights Tab View

/// Flights tab with segmented control for Plans and History.
/// Defaults to History (pilots come here most often to review flights).
struct FlightsTabView: View {

    enum FlightsSection: String, CaseIterable {
        case history = "History"
        case plans = "Plans"
    }

    @State private var selectedSection: FlightsSection = .history

    var body: some View {
        VStack(spacing: 0) {
            // Segmented control at top
            Picker("", selection: $selectedSection) {
                ForEach(FlightsSection.allCases, id: \.self) { section in
                    Text(section.rawValue).tag(section)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
            .padding(.vertical, 8)

            // Content
            switch selectedSection {
            case .plans:
                FlightPlanView()
            case .history:
                NavigationStack {
                    FlightHistoryListView()
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AppState())
        .modelContainer(for: [
            SchemaV1.AircraftProfile.self,
            SchemaV1.PilotProfile.self,
            SchemaV1.UserSettings.self,
            SchemaV1.FlightPlanRecord.self,
            SchemaV1.LogbookEntry.self
        ])
}
