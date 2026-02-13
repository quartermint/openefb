//
//  CrossCountryFlowTests.swift
//  efb-212Tests
//
//  Integration tests simulating a cross-country flight planning flow.
//  Tests the interaction between FlightPlanViewModel, WeatherViewModel,
//  and MockDatabaseManager / MockWeatherService — no UI involved.
//
//  Flow: Create flight plan KPAO -> KSQL, fetch weather for both airports,
//  verify plan has correct distance/ETE, verify weather cached for both.
//

import Testing
import Foundation
import CoreLocation
@testable import efb_212

@Suite("Cross-Country Flow Integration Tests")
struct CrossCountryFlowTests {

    // MARK: - Shared Test Airports

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

    // MARK: - Service Factories

    static func makeMockDB() -> MockDatabaseManager {
        let db = MockDatabaseManager()
        db.airports = [kpao, ksql]
        return db
    }

    static func makeMockWeather() -> MockWeatherService {
        let ws = MockWeatherService()
        ws.mockWeather["KPAO"] = WeatherCache(
            stationID: "KPAO",
            metar: "KPAO 121855Z 31008KT 10SM FEW040 20/10 A3012",
            flightCategory: .vfr,
            temperature: 20.0,
            dewpoint: 10.0,
            wind: WindInfo(direction: 310, speed: 8, gusts: nil, isVariable: false),
            visibility: 10.0,
            ceiling: nil,
            fetchedAt: Date()
        )
        ws.mockWeather["KSQL"] = WeatherCache(
            stationID: "KSQL",
            metar: "KSQL 121855Z 28010G15KT 10SM SCT050 19/09 A3011",
            flightCategory: .vfr,
            temperature: 19.0,
            dewpoint: 9.0,
            wind: WindInfo(direction: 280, speed: 10, gusts: 15, isVariable: false),
            visibility: 10.0,
            ceiling: nil,
            fetchedAt: Date()
        )
        return ws
    }

    // MARK: - Full Cross-Country Flow

    @Test func crossCountryFlightPlanFlow() async {
        let db = Self.makeMockDB()
        let ws = Self.makeMockWeather()

        // Step 1: Create flight plan
        let planVM = FlightPlanViewModel(databaseManager: db)
        planVM.departureICAO = "KPAO"
        planVM.destinationICAO = "KSQL"

        await planVM.createFlightPlan()

        // Verify plan created successfully
        #expect(planVM.activePlan != nil, "Flight plan should be created")
        #expect(planVM.error == nil, "No error should occur")

        guard let plan = planVM.activePlan else { return }

        // Step 2: Verify distance is reasonable (KPAO -> KSQL ~5-7 NM)
        #expect(plan.totalDistance > 3.0, "Distance should be at least 3 NM")
        #expect(plan.totalDistance < 10.0, "Distance should be less than 10 NM")

        // Step 3: Verify ETE is reasonable for the distance
        #expect(plan.estimatedTime > 0, "ETE should be positive")
        let eteMinutes = plan.estimatedTime / 60.0
        #expect(eteMinutes < 10, "ETE for a 5 NM flight at 100 kts should be well under 10 minutes")

        // Step 4: Fetch weather for both airports
        let weatherVM = WeatherViewModel(weatherService: ws)

        await weatherVM.fetchWeather(for: "KPAO")
        await weatherVM.fetchWeather(for: "KSQL")

        // Step 5: Verify weather data cached for both stations
        #expect(weatherVM.weatherData["KPAO"] != nil, "KPAO weather should be cached")
        #expect(weatherVM.weatherData["KSQL"] != nil, "KSQL weather should be cached")

        // Step 6: Verify weather categories
        #expect(weatherVM.weatherData["KPAO"]?.flightCategory == .vfr)
        #expect(weatherVM.weatherData["KSQL"]?.flightCategory == .vfr)

        // Step 7: Verify fetchMETAR was called for each station
        #expect(ws.fetchMETARCallCount == 2, "Should have fetched METAR for both stations")
    }

    @Test func crossCountryWithWeatherError() async {
        let db = Self.makeMockDB()
        let ws = MockWeatherService()
        ws.shouldFail = true

        // Create plan (should succeed — doesn't need weather)
        let planVM = FlightPlanViewModel(databaseManager: db)
        planVM.departureICAO = "KPAO"
        planVM.destinationICAO = "KSQL"

        await planVM.createFlightPlan()
        #expect(planVM.activePlan != nil, "Plan should still be created even if weather fails")

        // Fetch weather (should fail gracefully)
        let weatherVM = WeatherViewModel(weatherService: ws)
        await weatherVM.fetchWeather(for: "KPAO")

        #expect(weatherVM.error != nil, "Weather error should be recorded")
        #expect(weatherVM.weatherData["KPAO"] == nil, "No weather should be cached on failure")
    }

    @Test func crossCountryPlanThenClear() async {
        let db = Self.makeMockDB()

        let planVM = FlightPlanViewModel(databaseManager: db)
        planVM.departureICAO = "KPAO"
        planVM.destinationICAO = "KSQL"

        await planVM.createFlightPlan()
        #expect(planVM.activePlan != nil)

        planVM.clearFlightPlan()

        #expect(planVM.activePlan == nil, "Plan should be cleared")
        #expect(planVM.departureICAO == "", "Departure should be reset")
        #expect(planVM.destinationICAO == "", "Destination should be reset")
    }

    @Test func weatherDataFreshness() async {
        let ws = Self.makeMockWeather()
        let weatherVM = WeatherViewModel(weatherService: ws)

        await weatherVM.fetchWeather(for: "KPAO")

        guard let weather = weatherVM.weatherData["KPAO"] else {
            #expect(Bool(false), "Weather should be available")
            return
        }

        // Weather was just fetched — should not be stale
        #expect(!weather.isStale, "Freshly fetched weather should not be stale")
        #expect(weather.age < 5, "Weather age should be very small (just fetched)")
    }

    @Test func multiStationWeatherFetch() async {
        let ws = Self.makeMockWeather()
        let weatherVM = WeatherViewModel(weatherService: ws)

        // Fetch for both stations at once
        await weatherVM.fetchWeatherForStations(["KPAO", "KSQL"])

        #expect(weatherVM.weatherData.count == 2, "Both stations should have weather")
        #expect(weatherVM.weatherData["KPAO"]?.temperature == 20.0)
        #expect(weatherVM.weatherData["KSQL"]?.temperature == 19.0)
        #expect(ws.fetchStationsCallCount == 1, "Should have made one batch call")
    }
}
