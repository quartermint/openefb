//
//  CurrencyBadge.swift
//  efb-212
//
//  Reusable traffic-light currency indicator badge.
//  Green (current), Yellow (warning), Red (expired).
//  Used in pilot profile view for medical, flight review, and night currency.
//

import SwiftUI

struct CurrencyBadge: View {
    let status: CurrencyStatus
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(statusText)
                .font(.caption)
                .foregroundStyle(statusColor)
                .fontWeight(.medium)
        }
    }

    private var statusColor: Color {
        switch status {
        case .current: return .green
        case .warning: return .yellow
        case .expired: return .red
        }
    }

    private var statusText: String {
        switch status {
        case .current: return "Current"
        case .warning: return "Expiring Soon"
        case .expired: return "Expired"
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        CurrencyBadge(status: .current, label: "Medical Certificate")
        CurrencyBadge(status: .warning, label: "Flight Review")
        CurrencyBadge(status: .expired, label: "Night Currency (61.57)")
    }
    .padding()
}
