//
//  efb_212App.swift
//  efb-212
//
//  App entry point with dependency injection.
//  All types are @MainActor by default (SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor).
//

import SwiftUI
import SwiftData

@main
struct efb_212App: App {
    @State private var appState: AppState

    init() {
        // Production dependencies — placeholder implementations for now.
        // Real implementations will be created in later waves.
        let appState = AppState(
            locationManager: PlaceholderLocationManager(),
            databaseManager: PlaceholderDatabaseManager(),
            weatherService: PlaceholderWeatherService()
        )
        _appState = State(wrappedValue: appState)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}
