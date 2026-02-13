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

    @Test func formattedETEAfterPlan() async {
        let db = Self.makeMockDB()
        let vm = FlightPlanViewModel(databaseManager: db)

        vm.departureICAO = "KPAO"
        vm.destinationICAO = "KSQL"
        await vm.createFlightPlan()

        // ETE should be formatted as minutes (short flight)
        #expect(vm.formattedETE != nil)
        #expect(vm.formattedETE?.contains("m") == true)
    }

    // MARK: - Fuel Calculation

    @Test func fuelIsNilWhenNoBurnRate() async {
        let db = Self.makeMockDB()
        let vm = FlightPlanViewModel(databaseManager: db)

        vm.departureICAO = "KPAO"
        vm.destinationICAO = "KSQL"
        await vm.createFlightPlan()

        // Default fuel burn rate is nil, so estimated fuel should be nil
        #expect(vm.activePlan?.estimatedFuel == nil)
        #expect(vm.formattedFuel == nil)
    }

    // MARK: - Speed and Altitude Formatting

    @Test func formattedSpeedAndAltitude() async {
        let db = Self.makeMockDB()
        let vm = FlightPlanViewModel(databaseManager: db)

        vm.departureICAO = "KPAO"
        vm.destinationICAO = "KSQL"
        await vm.createFlightPlan()

        #expect(vm.formattedSpeed != nil)
        #expect(vm.formattedSpeed?.contains("kts") == true)
        #expect(vm.formattedSpeed?.contains("TAS") == true)

        #expect(vm.formattedAltitude != nil)
        #expect(vm.formattedAltitude?.contains("ft MSL") == true)
    }

    @Test func formattedValuesNilBeforePlan() {
        let db = Self.makeMockDB()
        let vm = FlightPlanViewModel(databaseManager: db)

        #expect(vm.formattedDistance == nil)
        #expect(vm.formattedETE == nil)
        #expect(vm.formattedFuel == nil)
        #expect(vm.formattedAltitude == nil)
        #expect(vm.formattedSpeed == nil)
    }

    // MARK: - Airport Resolution

    @Test func departureAirportResolvedAfterPlan() async {
        let db = Self.makeMockDB()
        let vm = FlightPlanViewModel(databaseManager: db)

        vm.departureICAO = "KPAO"
        vm.destinationICAO = "KSQL"
        await vm.createFlightPlan()

        #expect(vm.departureAirport != nil)
        #expect(vm.departureAirport?.icao == "KPAO")
        #expect(vm.destinationAirport != nil)
        #expect(vm.destinationAirport?.icao == "KSQL")
    }

    @Test func airportsNilAfterClear() async {
        let db = Self.makeMockDB()
        let vm = FlightPlanViewModel(databaseManager: db)

        vm.departureICAO = "KPAO"
        vm.destinationICAO = "KSQL"
        await vm.createFlightPlan()
        #expect(vm.departureAirport != nil)

        vm.clearFlightPlan()

        #expect(vm.departureAirport == nil)
        #expect(vm.destinationAirport == nil)
    }

    // MARK: - Input Handling

    @Test func icaoInputIsUppercased() async {
        let db = Self.makeMockDB()
        let vm = FlightPlanViewModel(databaseManager: db)

        vm.departureICAO = "kpao"  // lowercase
        vm.destinationICAO = "ksql"

        await vm.createFlightPlan()

        // Flight plan departure should be uppercased
        #expect(vm.activePlan?.departure == "KPAO")
        #expect(vm.activePlan?.destination == "KSQL")
    }

    @Test func icaoInputIsTrimmed() async {
        let db = Self.makeMockDB()
        let vm = FlightPlanViewModel(databaseManager: db)

        vm.departureICAO = "  KPAO  "  // whitespace
        vm.destinationICAO = "  KSQL  "

        await vm.createFlightPlan()

        #expect(vm.activePlan?.departure == "KPAO")
        #expect(vm.activePlan?.destination == "KSQL")
    }

    // MARK: - Default Values

    @Test func defaultCruiseValues() async {
        let db = Self.makeMockDB()
        let vm = FlightPlanViewModel(databaseManager: db)

        vm.departureICAO = "KPAO"
        vm.destinationICAO = "KSQL"
        await vm.createFlightPlan()

        guard let plan = vm.activePlan else {
            #expect(Bool(false), "Plan should exist")
            return
        }

        // Default cruise speed is 100 knots
        #expect(plan.cruiseSpeed == 100.0)
        // Default cruise altitude is 3000 feet MSL
        #expect(plan.cruiseAltitude == 3000)
    }
}
