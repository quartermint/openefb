//
//  WeatherBadge.swift
//  efb-212
//
//  Compact badge showing weather data age and staleness.
//  Color coded: green (<30 min), yellow (30-60 min), red (>60 min),
//  gray (>2 hours, shows "STALE").
//  MainActor by default (SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor).
//

import SwiftUI

struct WeatherBadge: View {

    let weather: WeatherCache

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(badgeColor)
                .frame(width: 6, height: 6)

            Text(ageText)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(badgeColor)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(badgeColor.opacity(0.12))
        )
    }

    // MARK: - Computed Properties

    /// Age of the weather data in minutes.
    private var ageMinutes: Int {
        Int(weather.age / 60)
    }

    /// Human-readable age text.
    private var ageText: String {
        if ageMinutes > 120 {
            return "STALE"
        } else if ageMinutes < 1 {
            return "<1 min"
        } else if ageMinutes < 60 {
            return "\(ageMinutes) min"
        } else {
            let hours = ageMinutes / 60
            let mins = ageMinutes % 60
            if mins == 0 {
                return "\(hours)h"
            }
            return "\(hours)h \(mins)m"
        }
    }

    /// Color based on weather data age.
    /// - Green: fresh (< 30 minutes)
    /// - Yellow: aging (30-60 minutes)
    /// - Red: old (> 60 minutes)
    /// - Gray: stale (> 2 hours)
    private var badgeColor: Color {
        if ageMinutes > 120 {
            return .gray
        } else if ageMinutes > 60 {
            return .red
        } else if ageMinutes > 30 {
            return .yellow
        } else {
            return .green
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        // Fresh weather
        WeatherBadge(weather: WeatherCache(
            stationID: "KPAO",
            metar: "KPAO 121435Z 31010KT 10SM CLR 22/11 A3002",
            flightCategory: .vfr,
            fetchedAt: Date()
        ))

        // 45 minutes old
        WeatherBadge(weather: WeatherCache(
            stationID: "KSFO",
            flightCategory: .mvfr,
            fetchedAt: Date().addingTimeInterval(-2700)
        ))

        // 90 minutes old
        WeatherBadge(weather: WeatherCache(
            stationID: "KOAK",
            flightCategory: .ifr,
            fetchedAt: Date().addingTimeInterval(-5400)
        ))

        // Stale (3 hours)
        WeatherBadge(weather: WeatherCache(
            stationID: "KSJC",
            flightCategory: .lifr,
            fetchedAt: Date().addingTimeInterval(-10800)
        ))
    }
    .padding()
}
