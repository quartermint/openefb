//
//  BetaBanner.swift
//  efb-212
//
//  Dismissable beta disclaimer banner shown on first launch.
//  Per CONTEXT.md: "Beta -- Report issues via TestFlight feedback"
//  Sets expectations without being annoying -- dismissed once and never shown again.
//  Uses @AppStorage("hasDismissedBetaBanner") for persistence across launches.
//  Declared in PrivacyInfo.xcprivacy UserDefaults reason CA92.1.
//

import SwiftUI

struct BetaBanner: View {
    @AppStorage("hasDismissedBetaBanner") private var dismissed = false

    var body: some View {
        if !dismissed {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundStyle(.blue)
                Text("Beta -- Report issues via TestFlight feedback")
                    .font(.caption)
                Spacer()
                Button {
                    dismissed = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 16)
        }
    }
}

#Preview("Visible") {
    BetaBanner()
}
