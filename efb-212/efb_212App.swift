//
//  efb_212App.swift
//  efb-212
//
//  App entry point with dependency injection and SwiftData model container.
//  All types are @MainActor by default (SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor).
//

import SwiftUI
import SwiftData

@main
struct efb_212App: App {
    @State private var appState: AppState

    init() {
        // Production dependencies — real service implementations.
        let locationManager = LocationManager()
        let databaseManager = DatabaseManager()
        let weatherService = WeatherService()

        let appState = AppState(
            locationManager: locationManager,
            databaseManager: databaseManager,
            weatherService: weatherService
        )
        _appState = State(wrappedValue: appState)

        // Request location authorization on launch
        locationManager.requestAuthorization()
        locationManager.startUpdating()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .modelContainer(for: [
                    AircraftProfileModel.self,
                    FlightRecordModel.self,
                    PilotProfileModel.self
                ])
        }
    }
}
