//
//  CurrencyServiceTests.swift
//  efb-212Tests
//
//  Unit tests for CurrencyService FAR currency computation.
//  FAR 61.23 (medical), FAR 61.56 (flight review), FAR 61.57 (night currency).
//

import Testing
import Foundation
@testable import efb_212

@Suite("CurrencyService Tests")
struct CurrencyServiceTests {

    // MARK: - Medical Status (FAR 61.23)

    @Test func medicalCurrentWhenMoreThan30Days() {
        let expiry = Calendar.current.date(byAdding: .day, value: 60, to: Date())!
        let status = CurrencyService.medicalStatus(expiryDate: expiry)
        #expect(status == .current)
    }

    @Test func medicalWarningWhenWithin30Days() {
        let expiry = Calendar.current.date(byAdding: .day, value: 15, to: Date())!
        let status = CurrencyService.medicalStatus(expiryDate: expiry)
        #expect(status == .warning)
    }

    @Test func medicalExpiredWhenPastDate() {
        let expiry = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let status = CurrencyService.medicalStatus(expiryDate: expiry)
        #expect(status == .expired)
    }

    @Test func medicalExpiredWhenNil() {
        let status = CurrencyService.medicalStatus(expiryDate: nil)
        #expect(status == .expired)
    }

    @Test func medicalWarningAtExactly30Days() {
        let expiry = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        let status = CurrencyService.medicalStatus(expiryDate: expiry)
        #expect(status == .warning)
    }

    // MARK: - Flight Review Status (FAR 61.56)

    @Test func flightReviewCurrentWhenRecent() {
        // 12 months ago -> 12 months remaining of 24 -> current
        let reviewDate = Calendar.current.date(byAdding: .month, value: -12, to: Date())!
        let status = CurrencyService.flightReviewStatus(reviewDate: reviewDate)
        #expect(status == .current)
    }

    @Test func flightReviewWarningWhenApproaching() {
        // 23 months ago -> ~1 month remaining -> warning
        let reviewDate = Calendar.current.date(byAdding: .month, value: -23, to: Date())!
        let status = CurrencyService.flightReviewStatus(reviewDate: reviewDate)
        #expect(status == .warning)
    }

    @Test func flightReviewExpiredWhenPast24Months() {
        // 25 months ago -> expired
        let reviewDate = Calendar.current.date(byAdding: .month, value: -25, to: Date())!
        let status = CurrencyService.flightReviewStatus(reviewDate: reviewDate)
        #expect(status == .expired)
    }

    @Test func flightReviewExpiredWhenNil() {
        let status = CurrencyService.flightReviewStatus(reviewDate: nil)
        #expect(status == .expired)
    }

    // MARK: - Night Currency Status (FAR 61.57)

    @Test func nightCurrentWith3Landings() {
        // 3 landings 30 days ago -> within 90-day window -> current
        let date = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let status = CurrencyService.nightCurrencyStatus(nightLandings: [(date: date, count: 3)])
        #expect(status == .current)
    }

    @Test func nightExpiredWith2Landings() {
        // 2 landings 30 days ago -> not enough (need 3) -> expired
        let date = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let status = CurrencyService.nightCurrencyStatus(nightLandings: [(date: date, count: 2)])
        #expect(status == .expired)
    }

    @Test func nightExpiredWhenOutside90Days() {
        // 5 landings 100 days ago -> outside 90-day window -> expired
        let date = Calendar.current.date(byAdding: .day, value: -100, to: Date())!
        let status = CurrencyService.nightCurrencyStatus(nightLandings: [(date: date, count: 5)])
        #expect(status == .expired)
    }

    @Test func nightExpiredWhenEmpty() {
        let status = CurrencyService.nightCurrencyStatus(nightLandings: [])
        #expect(status == .expired)
    }

    @Test func nightCurrentWithMultipleEntries() {
        // Entries across multiple dates summing to 3 within 90 days
        let date1 = Calendar.current.date(byAdding: .day, value: -45, to: Date())!
        let date2 = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let date3 = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let landings: [(date: Date, count: Int)] = [
            (date: date1, count: 1),
            (date: date2, count: 1),
            (date: date3, count: 1)
        ]
        let status = CurrencyService.nightCurrencyStatus(nightLandings: landings)
        #expect(status == .current)
    }

    // MARK: - Overall Status

    @Test func overallCurrentWhenAllCurrent() {
        let status = CurrencyService.overallStatus(medical: .current, flightReview: .current, night: .current)
        #expect(status == .current)
    }

    @Test func overallWarningWhenOneWarning() {
        let status = CurrencyService.overallStatus(medical: .warning, flightReview: .current, night: .current)
        #expect(status == .warning)
    }

    @Test func overallExpiredWhenOneExpired() {
        let status = CurrencyService.overallStatus(medical: .current, flightReview: .current, night: .expired)
        #expect(status == .expired)
    }

    // MARK: - Logbook-Derived Night Currency (LOG-03 bridge)

    @Test func nightCurrencyFromLogbookSingleConfirmedEntry() {
        // Simulates: pilot confirms logbook entry with 3 night landings 10 days ago
        let date = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let landings: [(date: Date, count: Int)] = [(date: date, count: 3)]
        let status = CurrencyService.nightCurrencyStatus(nightLandings: landings)
        #expect(status == .current)
    }

    @Test func nightCurrencyFromLogbookMultipleConfirmedEntries() {
        // Simulates: 3 separate flights each with 1 night landing within 90 days
        let date1 = Calendar.current.date(byAdding: .day, value: -80, to: Date())!
        let date2 = Calendar.current.date(byAdding: .day, value: -50, to: Date())!
        let date3 = Calendar.current.date(byAdding: .day, value: -20, to: Date())!
        let landings: [(date: Date, count: Int)] = [
            (date: date1, count: 1),
            (date: date2, count: 1),
            (date: date3, count: 1)
        ]
        let status = CurrencyService.nightCurrencyStatus(nightLandings: landings)
        #expect(status == .current)
    }

    @Test func nightCurrencyFromLogbookMixedOldAndNew() {
        // Simulates: 2 flights with night landings, one outside 90 days, one inside
        // Only 1 landing in window (need 3) -- should be expired
        let oldDate = Calendar.current.date(byAdding: .day, value: -100, to: Date())!
        let newDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let landings: [(date: Date, count: Int)] = [
            (date: oldDate, count: 5),
            (date: newDate, count: 1)
        ]
        let status = CurrencyService.nightCurrencyStatus(nightLandings: landings)
        #expect(status == .expired)
    }

    @Test func nightCurrencyFromLogbookExactlyAt90Days() {
        // Simulates: 3 landings exactly 90 days ago -- boundary test
        // Use a fixed 'now' to avoid millisecond drift between Date() calls
        let now = Date()
        let date = Calendar.current.date(byAdding: .day, value: -90, to: now)!
        let landings: [(date: Date, count: Int)] = [(date: date, count: 3)]
        let status = CurrencyService.nightCurrencyStatus(nightLandings: landings, now: now)
        // At exactly 90 days, should still be current (within window)
        #expect(status == .current)
    }
}
