//
//  WeatherBadge.swift
//  efb-212
//
//  Staleness indicator for weather data with progressive urgency coloring.
//  Per UI-SPEC: capsule shape, 8pt horizontal / 4pt vertical padding.
//  Per user decision: yellow when >30 minutes old, red when >60 minutes old.
//  Per UI-SPEC copywriting: "<1 min" / "15 min" / "1h 30m" format, "STALE" when >2h.
//

import SwiftUI

struct WeatherBadge: View {

    let observationTime: Date?

    private var minutesAgo: Int {
        guard let obs = observationTime else { return 0 }
        return Int(Date().timeIntervalSince(obs) / 60)
    }

    private var displayText: String {
        guard observationTime != nil else { return "N/A" }
        if minutesAgo >= 120 { return "STALE" }
        if minutesAgo < 1 { return "<1 min" }
        if minutesAgo < 60 { return "\(minutesAgo) min" }
        let hours = minutesAgo / 60
        let mins = minutesAgo % 60
        if mins == 0 { return "\(hours)h" }
        return "\(hours)h \(mins)m"
    }

    private var badgeColor: Color {
        if minutesAgo >= 120 { return .gray }      // STALE per UI-SPEC
        if minutesAgo > 60 { return .red }          // >60 min per user decision
        if minutesAgo > 30 { return .yellow }        // >30 min per user decision
        return .secondary                             // fresh
    }

    var body: some View {
        Text(displayText)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeColor.opacity(0.2))
            .foregroundColor(badgeColor)
            .clipShape(Capsule())
    }
}

#Preview("Fresh") {
    WeatherBadge(observationTime: Date())
}

#Preview("30+ min") {
    WeatherBadge(observationTime: Date().addingTimeInterval(-2100))
}

#Preview("60+ min") {
    WeatherBadge(observationTime: Date().addingTimeInterval(-4200))
}

#Preview("STALE") {
    WeatherBadge(observationTime: Date().addingTimeInterval(-7800))
}

#Preview("No data") {
    WeatherBadge(observationTime: nil)
}
