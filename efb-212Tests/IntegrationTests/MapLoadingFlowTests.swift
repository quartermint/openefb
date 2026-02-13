//
//  MapLoadingFlowTests.swift
//  efb-212Tests
//
//  Integration test: simulates the app launch → airport loading → map display flow.
//  Verifies that MapViewModel coordinates with DatabaseManager and MapService
//  to load airports for the default region on startup and respond to region changes.
//

import Testing
import Foundation
import CoreLocation
@testable import efb_212

@Suite("Map Loading Flow Integration Tests")
struct MapLoadingFlowTests {

    // MARK: - Test Airports

    static let bayAreaAirports: [Airport] = [
        Airport(
            icao: "KPAO", faaID: "PAO", name: "Palo Alto",
            latitude: 37.4611, longitude: -122.1150, elevation: 4,
            type: .airport, ownership: .publicOwned,
            ctafFrequency: 118.6, unicomFrequency: nil,
            artccID: nil, fssID: nil, magneticVariation: nil,
            patternAltitude: 800, fuelTypes: ["100LL"],
            hasBeaconLight: true, runways: [], frequencies: []
        ),
        Airport(
            icao: "KSQL", faaID: "SQL", name: "San Carlos",
            latitude: 37.5119, longitude: -122.2494, elevation: 5,
            type: .airport, ownership: .publicOwned,
            ctafFrequency: 119.0, unicomFrequency: nil,
            artccID: nil, fssID: nil, magneticVariation: nil,
            patternAltitude: 800, fuelTypes: ["100LL"],
            hasBeaconLight: true, runways: [], frequencies: []
        ),
        Airport(
            icao: "KOAK", faaID: "OAK", name: "Oakland Intl",
            latitude: 37.7213, longitude: -122.2208, elevation: 9,
            type: .airport, ownership: .publicOwned,
            ctafFrequency: nil, unicomFrequency: nil,
            artccID: nil, fssID: nil, magneticVariation: nil,
            patternAltitude: 1000, fuelTypes: ["100LL", "Jet-A"],
            hasBeaconLight: true, runways: [], frequencies: []
        ),
    ]

    // MARK: - Full Flow: App Launch → Load Airports → Query

    @Test func appLaunchAirportLoadingFlow() async {
        // Step 1: Set up mock database with seed airports (simulates app launch DB init)
        let db = MockDatabaseManager()
        db.airports = Self.bayAreaAirports

        // Step 2: Create MapService and MapViewModel (simulates app launch wiring)
        let mapService = MapService()
        let vm = MapViewModel(databaseManager: db, mapService: mapService)

        // Step 3: Load airports for the default region (simulates initial map display)
        // MapService defaults to KPAO area (lat 37.46, lon -122.12), zoom 10
        let defaultCenter = CLLocationCoordinate2D(latitude: 37.46, longitude: -122.12)
        let defaultRadius = vm.estimatedRadiusNM(for: 10.0)

        await vm.loadAirportsForRegion(center: defaultCenter, radiusNM: defaultRadius)

        // Step 4: Verify airports loaded
        #expect(!vm.visibleAirports.isEmpty, "Airports should be loaded after initial fetch")
        #expect(vm.lastError == nil, "No error should occur during initial load")
        #expect(!vm.isLoadingAirports, "Loading should be complete")
    }

    @Test func regionChangeTriggersAirportReload() async {
        let db = MockDatabaseManager()
        db.airports = Self.bayAreaAirports

        let mapService = MapService()
        let vm = MapViewModel(databaseManager: db, mapService: mapService)

        // Load initial region
        let center1 = CLLocationCoordinate2D(latitude: 37.46, longitude: -122.12)
        await vm.loadAirportsForRegion(center: center1, radiusNM: 20.0)
        let count1 = vm.visibleAirports.count
        #expect(count1 > 0, "Should have airports after initial load")

        // Simulate region change (user panned the map)
        let center2 = CLLocationCoordinate2D(latitude: 37.72, longitude: -122.22)
        await vm.loadAirportsForRegion(center: center2, radiusNM: 20.0)

        // Airports should be refreshed (mock returns same set, but the load happened)
        #expect(!vm.isLoadingAirports)
        #expect(vm.lastError == nil)
    }

    @Test func selectAirportFromMapAnnotation() async {
        let db = MockDatabaseManager()
        db.airports = Self.bayAreaAirports

        let mapService = MapService()
        let vm = MapViewModel(databaseManager: db, mapService: mapService)

        // Step 1: Load airports
        let center = CLLocationCoordinate2D(latitude: 37.46, longitude: -122.12)
        await vm.loadAirportsForRegion(center: center, radiusNM: 20.0)
        #expect(!vm.visibleAirports.isEmpty)

        // Step 2: Simulate airport tap via ICAO (as MapServiceDelegate would do)
        await vm.selectAirport(byICAO: "KPAO")

        // Step 3: Verify selection
        #expect(vm.selectedAirport != nil)
        #expect(vm.selectedAirport?.icao == "KPAO")
        #expect(vm.selectedAirport?.name == "Palo Alto")
    }

    @Test func selectAirportThenClearAndReselect() async {
        let db = MockDatabaseManager()
        db.airports = Self.bayAreaAirports

        let mapService = MapService()
        let vm = MapViewModel(databaseManager: db, mapService: mapService)

        // Select KPAO
        await vm.selectAirport(byICAO: "KPAO")
        #expect(vm.selectedAirport?.icao == "KPAO")

        // Clear selection
        vm.clearSelection()
        #expect(vm.selectedAirport == nil)

        // Select a different airport
        await vm.selectAirport(byICAO: "KSQL")
        #expect(vm.selectedAirport?.icao == "KSQL")
    }

    // MARK: - Full Flow: Plan → Weather → Map

    @Test func planThenWeatherThenMapFlow() async {
        // Step 1: Create flight plan
        let db = MockDatabaseManager()
        db.airports = Self.bayAreaAirports
        let planVM = FlightPlanViewModel(databaseManager: db)
        planVM.departureICAO = "KPAO"
        planVM.destinationICAO = "KSQL"
        await planVM.createFlightPlan()
        #expect(planVM.activePlan != nil)

        // Step 2: Fetch weather for route airports
        let ws = MockWeatherService()
        ws.mockWeather["KPAO"] = WeatherCache(stationID: "KPAO", flightCategory: .vfr, fetchedAt: Date())
        ws.mockWeather["KSQL"] = WeatherCache(stationID: "KSQL", flightCategory: .mvfr, fetchedAt: Date())
        let weatherVM = WeatherViewModel(weatherService: ws)
        await weatherVM.fetchWeatherForStations(["KPAO", "KSQL"])
        #expect(weatherVM.weatherData.count == 2)

        // Step 3: Load airports on map
        let mapService = MapService()
        let mapVM = MapViewModel(databaseManager: db, mapService: mapService)
        let center = CLLocationCoordinate2D(latitude: 37.48, longitude: -122.18)
        await mapVM.loadAirportsForRegion(center: center, radiusNM: 20.0)
        #expect(!mapVM.visibleAirports.isEmpty)

        // Step 4: Verify all pieces are consistent
        let depICAO = planVM.activePlan!.departure
        let destICAO = planVM.activePlan!.destination
        #expect(weatherVM.weatherData[depICAO] != nil, "Weather should exist for departure")
        #expect(weatherVM.weatherData[destICAO] != nil, "Weather should exist for destination")
        let depOnMap = mapVM.visibleAirports.contains(where: { $0.icao == depICAO })
        let destOnMap = mapVM.visibleAirports.contains(where: { $0.icao == destICAO })
        #expect(depOnMap, "Departure airport should be visible on map")
        #expect(destOnMap, "Destination airport should be visible on map")
    }

    // MARK: - Error Handling

    @Test func mapLoadWithEmptyDB() async {
        let db = MockDatabaseManager()
        db.airports = []

        let mapService = MapService()
        let vm = MapViewModel(databaseManager: db, mapService: mapService)

        let center = CLLocationCoordinate2D(latitude: 37.46, longitude: -122.12)
        await vm.loadAirportsForRegion(center: center, radiusNM: 20.0)

        #expect(vm.visibleAirports.isEmpty)
        #expect(vm.lastError == nil) // Empty results is not an error
    }

    @Test func selectNonExistentAirportShowsError() async {
        let db = MockDatabaseManager()
        db.airports = Self.bayAreaAirports

        let mapService = MapService()
        let vm = MapViewModel(databaseManager: db, mapService: mapService)

        await vm.selectAirport(byICAO: "KXYZ")

        #expect(vm.selectedAirport == nil)
        #expect(vm.lastError != nil)
    }

    // MARK: - Zoom Behavior

    @Test func lowZoomClampsSearchRadius() async {
        let db = MockDatabaseManager()
        db.airports = Self.bayAreaAirports

        let mapService = MapService()
        let vm = MapViewModel(databaseManager: db, mapService: mapService)

        // At zoom 0 (whole world), radius should be clamped to 100 NM
        let radiusAtZoom0 = vm.estimatedRadiusNM(for: 0.0)
        #expect(radiusAtZoom0 <= 100.0, "Low zoom radius should be clamped")

        // Loading at clamped radius should still work
        let center = CLLocationCoordinate2D(latitude: 37.46, longitude: -122.12)
        await vm.loadAirportsForRegion(center: center, radiusNM: radiusAtZoom0)
        #expect(vm.lastError == nil)
    }
}
