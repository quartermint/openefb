//
//  FlightPlanViewModelTests.swift
//  efb-212Tests
//
//  Tests for FlightPlanViewModel: plan creation, distance calculation,
//  clearing, and error handling when airports are not found.
//

import Testing
import Foundation
import CoreLocation
@testable import efb_212

@Suite("FlightPlanViewModel Tests")
struct FlightPlanViewModelTests {

    // MARK: - Test Helpers

    static let kpao = Airport(
        icao: "KPAO", faaID: "PAO", name: "Palo Alto",
        latitude: 37.4611, longitude: -122.1150, elevation: 4,
        type: .airport, ownership: .publicOwned,
        ctafFrequency: 118.6, unicomFrequency: nil,
        artccID: nil, fssID: nil, magneticVariation: nil,
        patternAltitude: 800, fuelTypes: ["100LL"],
        hasBeaconLight: true, runways: [], frequencies: []
    )

    static let ksql = Airport(
        icao: "KSQL", faaID: "SQL", name: "San Carlos",
        latitude: 37.5119, longitude: -122.2494, elevation: 5,
        type: .airport, ownership: .publicOwned,
        ctafFrequency: 119.0, unicomFrequency: nil,
        artccID: nil, fssID: nil, magneticVariation: nil,
        patternAltitude: 800, fuelTypes: ["100LL"],
        hasBeaconLight: true, runways: [], frequencies: []
    )

    /// Create a mock database manager pre-loaded with test airports.
    static func makeMockDB() -> MockDatabaseManager {
        let db = MockDatabaseManager()
        db.airports = [kpao, ksql]
        return db
    }

    // MARK: - Flight Plan Creation

    @Test func createFlightPlanSuccess() async {
        let db = Self.makeMockDB()
        let vm = FlightPlanViewModel(databaseManager: db)

        vm.departureICAO = "KPAO"
        vm.destinationICAO = "KSQL"

        await vm.createFlightPlan()

        #expect(vm.activePlan != nil)
        #expect(vm.error == nil)
        #expect(vm.activePlan?.departure == "KPAO")
        #expect(vm.activePlan?.destination == "KSQL")
    }

    @Test func createFlightPlanDistance() async {
        let db = Self.makeMockDB()
        let vm = FlightPlanViewModel(databaseManager: db)

        vm.departureICAO = "KPAO"
        vm.destinationICAO = "KSQL"

        await vm.createFlightPlan()

        guard let plan = vm.activePlan else {
            #expect(Bool(false), "Flight plan should have been created")
            return
        }

        // KPAO to KSQL is approximately 5-7 NM
        let distance = plan.totalDistance
        #expect(distance > 3.0, "Distance should be at least 3 NM")
        #expect(distance < 10.0, "Distance should be less than 10 NM")
    }

    @Test func createFlightPlanETE() async {
        let db = Self.makeMockDB()
        let vm = FlightPlanViewModel(databaseManager: db)

        vm.departureICAO = "KPAO"
        vm.destinationICAO = "KSQL"

        await vm.createFlightPlan()

        guard let plan = vm.activePlan else {
            #expect(Bool(false), "Flight plan should have been created")
            return
        }

        // ETE = distance / speed * 3600
        // ~5 NM at 100 kts = ~3 minutes = ~180 seconds
        #expect(plan.estimatedTime > 60, "ETE should be at least 1 minute")
        #expect(plan.estimatedTime < 600, "ETE should be less than 10 minutes for this short flight")
    }

    @Test func createFlightPlanHasWaypoints() async {
        let db = Self.makeMockDB()
        let vm = FlightPlanViewModel(databaseManager: db)

        vm.departureICAO = "KPAO"
        vm.destinationICAO = "KSQL"

        await vm.createFlightPlan()

        guard let plan = vm.activePlan else {
            #expect(Bool(false), "Flight plan should have been created")
            return
        }

        // Should have 2 waypoints (departure + destination)
        #expect(plan.waypoints.count == 2)
        #expect(plan.waypoints.first?.identifier == "KPAO")
        #expect(plan.waypoints.last?.identifier == "KSQL")
    }

    // MARK: - Clear Flight Plan

    @Test func clearFlightPlan() async {
        let db = Self.makeMockDB()
        let vm = FlightPlanViewModel(databaseManager: db)

        vm.departureICAO = "KPAO"
        vm.destinationICAO = "KSQL"
        await vm.createFlightPlan()
        #expect(vm.activePlan != nil)

        vm.clearFlightPlan()

        #expect(vm.activePlan == nil)
        #expect(vm.departureICAO == "")
        #expect(vm.destinationICAO == "")
        #expect(vm.error == nil)
    }

    // MARK: - Error Cases

    @Test func errorWhenDepartureNotFound() async {
        let db = Self.makeMockDB()
        let vm = FlightPlanViewModel(databaseManager: db)

        vm.departureICAO = "KXYZ"  // Does not exist in mock DB
        vm.destinationICAO = "KSQL"

        await vm.createFlightPlan()

        #expect(vm.activePlan == nil)
        #expect(vm.error != nil)
    }

    @Test func errorWhenDestinationNotFound() async {
        let db = Self.makeMockDB()
        let vm = FlightPlanViewModel(databaseManager: db)

        vm.departureICAO = "KPAO"
        vm.destinationICAO = "KXYZ"  // Does not exist in mock DB

        await vm.createFlightPlan()

        #expect(vm.activePlan == nil)
        #expect(vm.error != nil)
    }

    @Test func errorWhenBothFieldsEmpty() async {
        let db = Self.makeMockDB()
        let vm = FlightPlanViewModel(databaseManager: db)

        vm.departureICAO = ""
        vm.destinationICAO = ""

        await vm.createFlightPlan()

        #expect(vm.activePlan == nil)
        #expect(vm.error != nil)
    }

    // MARK: - Formatted Helpers

    @Test func formattedDistanceNil() {
        let db = Self.makeMockDB()
        let vm = FlightPlanViewModel(databaseManager: db)

        // No active plan = nil formatted values
        #expect(vm.formattedDistance == nil)
        #expect(vm.formattedETE == nil)
    }

    @Test func formattedDistanceAfterPlan() async {
        let db = Self.makeMockDB()
        let vm = FlightPlanViewModel(databaseManager: db)

        vm.departureICAO = "KPAO"
        vm.destinationICAO = "KSQL"
        await vm.createFlightPlan()

        #expect(vm.formattedDistance != nil)
        #expect(vm.formattedDistance?.contains("NM") == true)
    }
}
