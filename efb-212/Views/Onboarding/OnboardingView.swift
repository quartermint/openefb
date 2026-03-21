//
//  OnboardingView.swift
//  efb-212
//
//  First-time user onboarding walkthrough: 3 swipeable pages introducing
//  GPS navigation, moving map features, and flight recording.
//  Completion persisted via @AppStorage so onboarding only shows once.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0

    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                OnboardingPage(
                    systemImage: "location.fill",
                    tint: .blue,
                    title: "Navigate with GPS",
                    description: "OpenEFB uses your location to show your position on VFR sectional charts in real time."
                )
                .tag(0)

                OnboardingPage(
                    systemImage: "map.fill",
                    tint: .green,
                    title: "Your Moving Map",
                    description: "Airports, weather, airspace, and TFRs at your fingertips. Works offline with downloaded charts."
                )
                .tag(1)

                VStack(spacing: 24) {
                    OnboardingPage(
                        systemImage: "record.circle",
                        tint: .red,
                        title: "Record Every Flight",
                        description: "One tap to capture GPS track and cockpit audio. Get an AI-powered debrief after landing."
                    )

                    Button("Get Started") {
                        hasSeenOnboarding = true
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: 280)
                    .padding(.vertical, 14)
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.bottom, 40)
                }
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Onboarding Page

private struct OnboardingPage: View {
    let systemImage: String
    let tint: Color
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: systemImage)
                .font(.system(size: 80))
                .foregroundStyle(tint)

            Text(title)
                .font(.title)
                .fontWeight(.bold)

            Text(description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
}
