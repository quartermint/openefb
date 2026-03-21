//
//  efb_212App.swift
//  efb-212
//
//  App entry point with @Observable AppState injection and SwiftData container.
//

import SwiftUI
import SwiftData

@main
struct efb_212App: App {
    @State private var appState = AppState()

    /// Whether we are running inside a unit test host (XCTest bundle loaded).
    private var isRunningTests: Bool {
        NSClassFromString("XCTestCase") != nil
    }

    var body: some Scene {
        WindowGroup {
            if isRunningTests {
                // Minimal view for test runner -- avoids MapLibre initialization crash
                Text("Test Host")
                    .environment(appState)
                    .modelContainer(for: [
                        SchemaV1.UserSettings.self,
                        SchemaV1.AircraftProfile.self,
                        SchemaV1.PilotProfile.self,
                        SchemaV1.FlightPlanRecord.self,
                        SchemaV1.FlightRecord.self,
                        SchemaV1.LogbookEntry.self
                    ])
            } else {
                ContentView()
                    .environment(appState)
                    .modelContainer(for: [
                        SchemaV1.UserSettings.self,
                        SchemaV1.AircraftProfile.self,
                        SchemaV1.PilotProfile.self,
                        SchemaV1.FlightPlanRecord.self,
                        SchemaV1.FlightRecord.self,
                        SchemaV1.LogbookEntry.self
                    ])
            }
        }
    }
}
