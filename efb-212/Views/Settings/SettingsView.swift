//
//  SettingsView.swift
//  efb-212
//
//  Real Settings tab replacing placeholder.
//  Shows app version, build number, feedback link, chart info, and legal section.
//  Per CONTEXT.md: in-app "Send Feedback" link in Settings for TestFlight users.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                // Section 1: About
                Section("About") {
                    LabeledContent("Version", value: appVersion)
                    LabeledContent("Build", value: buildNumber)
                }

                // Section 2: Feedback
                Section("Feedback") {
                    Link("Send Feedback", destination: feedbackURL)
                    Text("You can also take a screenshot in TestFlight to send feedback directly to the developer.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Section 3: Charts
                Section("Charts") {
                    Text("Chart downloads managed automatically. VFR sectional charts follow the FAA 56-day cycle.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Section 4: Legal
                Section("Legal") {
                    LabeledContent("License", value: "MPL-2.0")
                    Link("Source Code", destination: URL(string: "https://github.com/quartermint/openefb")!)
                }
            }
            .navigationTitle("Settings")
        }
    }

    // MARK: - Computed Properties

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    private var feedbackURL: URL {
        URL(string: "mailto:feedback@quartermint.com?subject=OpenEFB%20Beta%20Feedback")!
    }
}

#Preview {
    SettingsView()
}
