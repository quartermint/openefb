//
//  CurrencyWarningBanner.swift
//  efb-212
//
//  Non-blocking currency warning banner for the map tab.
//  Displays yellow (warning) or red (expired) banner when any pilot currency
//  (medical, flight review, night) is approaching or past expiry.
//  Pilot can dismiss the banner for the current session.
//

import SwiftUI
import SwiftData

struct CurrencyWarningBanner: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @State private var overallStatus: CurrencyStatus = .current
    @State private var warningMessages: [String] = []
    @State private var isDismissed: Bool = false

    var body: some View {
        if !isDismissed && !appState.currencyWarningDismissed && overallStatus != .current {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(overallStatus == .expired ? .red : .yellow)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Currency Warning")
                        .font(.caption.bold())
                    ForEach(Array(warningMessages.enumerated()), id: \.offset) { _, message in
                        Text(message)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button {
                    withAnimation {
                        isDismissed = true
                        appState.currencyWarningDismissed = true
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - Currency Computation

    /// Fetch active pilot profile and compute currency warnings.
    /// Same pattern as ContentView.updateCurrencyBadge for consistency.
    func computeCurrency() {
        let descriptor = FetchDescriptor<SchemaV1.PilotProfile>(
            predicate: #Predicate<SchemaV1.PilotProfile> { $0.isActive == true }
        )

        guard let activeProfiles = try? modelContext.fetch(descriptor),
              let profile = activeProfiles.first else {
            overallStatus = .current
            warningMessages = []
            return
        }

        let medical = CurrencyService.medicalStatus(expiryDate: profile.medicalExpiry)
        let flightReview = CurrencyService.flightReviewStatus(reviewDate: profile.flightReviewDate)
        let nightLandings = profile.nightLandingEntries.map { (date: $0.date, count: $0.count) }
        let night = CurrencyService.nightCurrencyStatus(nightLandings: nightLandings)

        overallStatus = CurrencyService.overallStatus(medical: medical, flightReview: flightReview, night: night)

        var messages: [String] = []
        switch medical {
        case .warning: messages.append("Medical certificate expiring soon")
        case .expired: messages.append("Medical certificate expired")
        case .current: break
        }
        switch flightReview {
        case .warning: messages.append("Flight review expiring soon")
        case .expired: messages.append("Flight review expired")
        case .current: break
        }
        switch night {
        case .expired: messages.append("Night currency expired (61.57)")
        default: break  // Night has no .warning state per FAR 61.57
        }
        warningMessages = messages
    }
}

// MARK: - View Extension for onAppear hook

extension CurrencyWarningBanner {
    /// Wrapper that triggers currency computation on appear.
    func withAutoCompute() -> some View {
        self.onAppear {
            computeCurrency()
        }
    }
}
