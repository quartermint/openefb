//
//  CurrencyService.swift
//  efb-212
//
//  Pure-function service for FAR currency computation.
//  FAR 61.23 (medical), FAR 61.56 (flight review), FAR 61.57 (night currency).
//
//  All methods are static -- no instance state, no actor isolation needed.
//  Thresholds: > 30 days remaining = .current, <= 30 days = .warning, past = .expired.
//

import Foundation

struct CurrencyService {

    // MARK: - Medical Currency (FAR 61.23)

    /// Compute medical certificate currency status.
    /// - Parameter expiryDate: Medical certificate expiry date (nil = no medical on file).
    /// - Returns: `.current` if > 30 days remaining, `.warning` if <= 30 days, `.expired` if past or nil.
    static func medicalStatus(expiryDate: Date?, now: Date = Date()) -> CurrencyStatus {
        guard let expiry = expiryDate else { return .expired }

        let calendar = Calendar.current
        guard let daysRemaining = calendar.dateComponents([.day], from: now, to: expiry).day else {
            return .expired
        }

        if daysRemaining < 0 {
            return .expired
        } else if daysRemaining <= 30 {
            return .warning
        } else {
            return .current
        }
    }

    // MARK: - Flight Review Currency (FAR 61.56)

    /// Compute flight review (BFR) currency status.
    /// Flight review expires 24 calendar months from the review date.
    /// - Parameter reviewDate: Date of most recent flight review (nil = no review on file).
    /// - Returns: Currency status based on time remaining until 24-month expiry.
    static func flightReviewStatus(reviewDate: Date?, now: Date = Date()) -> CurrencyStatus {
        guard let review = reviewDate else { return .expired }

        let calendar = Calendar.current
        guard let expiryDate = calendar.date(byAdding: .month, value: 24, to: review) else {
            return .expired
        }

        return medicalStatus(expiryDate: expiryDate, now: now)
    }

    // MARK: - Night Currency (FAR 61.57)

    /// Compute night passenger-carrying currency status.
    /// Requires 3 full-stop night landings within the preceding 90 days.
    /// - Parameter nightLandings: Array of (date, count) tuples for night landing entries.
    /// - Returns: `.current` if >= 3 landings in past 90 days, `.expired` otherwise.
    ///   Note: No `.warning` state for FAR 61.57 -- either current or expired.
    static func nightCurrencyStatus(nightLandings: [(date: Date, count: Int)], now: Date = Date()) -> CurrencyStatus {
        let calendar = Calendar.current
        guard let cutoff = calendar.date(byAdding: .day, value: -90, to: now) else {
            return .expired
        }

        let recentCount = nightLandings
            .filter { $0.date >= cutoff }
            .reduce(0) { $0 + $1.count }

        return recentCount >= 3 ? .current : .expired
    }

    // MARK: - Overall Currency

    /// Compute overall pilot currency from individual statuses.
    /// Returns the most restrictive status: .expired > .warning > .current.
    /// - Parameters:
    ///   - medical: Medical certificate status.
    ///   - flightReview: Flight review (BFR) status.
    ///   - night: Night currency status.
    /// - Returns: `.expired` if any is expired, `.warning` if any is warning, else `.current`.
    static func overallStatus(medical: CurrencyStatus, flightReview: CurrencyStatus, night: CurrencyStatus) -> CurrencyStatus {
        let statuses = [medical, flightReview, night]

        if statuses.contains(.expired) {
            return .expired
        } else if statuses.contains(.warning) {
            return .warning
        } else {
            return .current
        }
    }
}
