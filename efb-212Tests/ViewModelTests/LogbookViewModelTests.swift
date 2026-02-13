//
//  LogbookViewModelTests.swift
//  efb-212Tests
//
//  Tests for LogbookViewModel: duration formatting (decimal and H:M)
//  and aggregate totals computation.
//

import Testing
import Foundation
@testable import efb_212

@Suite("LogbookViewModel Tests")
struct LogbookViewModelTests {

    // MARK: - Duration Formatting: Decimal Hours

    @Test func formatDurationDecimal1Hour() {
        let vm = LogbookViewModel()
        let result = vm.formatDurationDecimal(3600)
        #expect(result == "1.0")
    }

    @Test func formatDurationDecimal1Point5Hours() {
        let vm = LogbookViewModel()
        let result = vm.formatDurationDecimal(5400)
        #expect(result == "1.5")
    }

    @Test func formatDurationDecimal45Min() {
        let vm = LogbookViewModel()
        // 2700 seconds = 45 minutes = 0.75 hours
        let result = vm.formatDurationDecimal(2700)
        #expect(result == "0.8") // 0.75 rounds to 0.8 at one decimal
    }

    @Test func formatDurationDecimalZero() {
        let vm = LogbookViewModel()
        let result = vm.formatDurationDecimal(0)
        #expect(result == "0.0")
    }

    @Test func formatDurationDecimalLargeValue() {
        let vm = LogbookViewModel()
        // 10800 seconds = 3 hours
        let result = vm.formatDurationDecimal(10800)
        #expect(result == "3.0")
    }

    // MARK: - Duration Formatting: Hours and Minutes

    @Test func formatDurationHM1Hour() {
        let vm = LogbookViewModel()
        let result = vm.formatDurationHM(3600)
        #expect(result == "1h 0m")
    }

    @Test func formatDurationHM1Hour30Min() {
        let vm = LogbookViewModel()
        let result = vm.formatDurationHM(5400)
        #expect(result == "1h 30m")
    }

    @Test func formatDurationHM2Min30Sec() {
        let vm = LogbookViewModel()
        // 150 seconds = 2 minutes 30 seconds → rounds down to 2 full minutes
        let result = vm.formatDurationHM(150)
        #expect(result == "0h 2m")
    }

    @Test func formatDurationHMZero() {
        let vm = LogbookViewModel()
        let result = vm.formatDurationHM(0)
        #expect(result == "0h 0m")
    }

    @Test func formatDurationHMLargeValue() {
        let vm = LogbookViewModel()
        // 7200 seconds = 2 hours
        let result = vm.formatDurationHM(7200)
        #expect(result == "2h 0m")
    }

    // MARK: - Compute Totals

    @Test func computeTotalsEmpty() {
        let vm = LogbookViewModel()
        vm.computeTotals(from: [])
        #expect(vm.totalFlights == 0)
        #expect(vm.totalFlightTime == 0)
        #expect(vm.totalDistance == 0)
    }

    @Test func computeTotalsSingleFlight() {
        let vm = LogbookViewModel()
        let record = FlightRecordModel(
            date: Date(),
            departure: "KPAO",
            arrival: "KSQL",
            duration: 3600
        )
        record.totalDistance = 5.2

        vm.computeTotals(from: [record])

        #expect(vm.totalFlights == 1)
        #expect(vm.totalFlightTime == 3600)
        #expect(vm.totalDistance == 5.2)
    }

    @Test func computeTotalsMultipleFlights() {
        let vm = LogbookViewModel()
        let record1 = FlightRecordModel(
            date: Date(),
            departure: "KPAO",
            arrival: "KSQL",
            duration: 3600
        )
        record1.totalDistance = 5.0

        let record2 = FlightRecordModel(
            date: Date(),
            departure: "KSQL",
            arrival: "KPAO",
            duration: 5400
        )
        record2.totalDistance = 5.0

        let record3 = FlightRecordModel(
            date: Date(),
            departure: "KPAO",
            arrival: "KOAK",
            duration: 1800
        )
        // record3 has no distance (nil)

        vm.computeTotals(from: [record1, record2, record3])

        #expect(vm.totalFlights == 3)
        #expect(vm.totalFlightTime == 10800) // 3600 + 5400 + 1800
        #expect(vm.totalDistance == 10.0)     // 5.0 + 5.0 + 0
    }

    // MARK: - Flight Record Creation

    @Test func createFlightRecord() {
        let vm = LogbookViewModel()
        let record = vm.createFlightRecord(
            departure: "kpao",
            arrival: "ksql",
            duration: 3600,
            distance: 5.2,
            remarks: "Local flight"
        )

        #expect(record.departure == "KPAO")  // uppercased
        #expect(record.arrival == "KSQL")    // uppercased
        #expect(record.duration == 3600)
        #expect(record.totalDistance == 5.2)
        #expect(record.remarks == "Local flight")
    }
}
