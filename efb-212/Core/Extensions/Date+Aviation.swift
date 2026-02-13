//
//  Date+Aviation.swift
//  efb-212
//
//  Aviation date formatting extensions for Zulu time and METAR parsing.
//

import Foundation

extension Date {
    /// Format as Zulu time (e.g., "1435Z")
    var zuluString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HHmm"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: self) + "Z"
    }

    /// Format as full Zulu datetime (e.g., "12 Feb 2026 1435Z")
    var fullZuluString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy HHmm"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: self) + "Z"
    }

    /// Format as METAR observation time (e.g., "121435Z" for 12th at 1435Z)
    var metarTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ddHHmm"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: self) + "Z"
    }

    /// Parse METAR observation time (e.g., "121435Z")
    static func fromMETARTime(_ string: String, referenceDate: Date = Date()) -> Date? {
        let cleaned = string.replacingOccurrences(of: "Z", with: "")
        guard cleaned.count == 6,
              let day = Int(cleaned.prefix(2)),
              let hour = Int(cleaned.dropFirst(2).prefix(2)),
              let minute = Int(cleaned.suffix(2)) else {
            return nil
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        var components = calendar.dateComponents([.year, .month], from: referenceDate)
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = 0

        return calendar.date(from: components)
    }

    /// Time ago description (e.g., "5 min ago", "2 hrs ago")
    var timeAgoShort: String {
        let interval = Date().timeIntervalSince(self)
        let minutes = Int(interval / 60)
        if minutes < 1 { return "just now" }
        if minutes < 60 { return "\(minutes) min ago" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours) hr\(hours == 1 ? "" : "s") ago" }
        let days = hours / 24
        return "\(days) day\(days == 1 ? "" : "s") ago"
    }
}
