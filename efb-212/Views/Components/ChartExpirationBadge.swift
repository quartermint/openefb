//
//  ChartExpirationBadge.swift
//  efb-212
//
//  Chart expiration warning badge with yellow (<7 days) and red (expired) states.
//  Per INFRA-03: warns pilot when VFR charts are within 7 days of their 56-day
//  FAA cycle expiration or already expired.
//

import SwiftUI

struct ChartExpirationBadge: View {
    let daysRemaining: Int?

    var body: some View {
        if let days = daysRemaining, days <= 7 {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                Text(days <= 0 ? "CHARTS EXPIRED" : "Charts expire in \(days)d")
            }
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundColor(days <= 0 ? .white : .black)
            .background(days <= 0 ? Color.red : Color.yellow)
            .clipShape(Capsule())
        }
    }
}

#Preview("Expired") {
    ChartExpirationBadge(daysRemaining: -2)
}

#Preview("Expiring Soon") {
    ChartExpirationBadge(daysRemaining: 3)
}

#Preview("Current") {
    ChartExpirationBadge(daysRemaining: 30)
}

#Preview("No Chart") {
    ChartExpirationBadge(daysRemaining: nil)
}
