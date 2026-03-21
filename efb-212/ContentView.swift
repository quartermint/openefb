//
//  ContentView.swift
//  efb-212
//
//  Root view -- 5-tab TabView shell.
//  Each tab will be populated with real views in later plans.
//

import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState

        TabView(selection: $appState.selectedTab) {
            Tab(AppTab.map.title, systemImage: AppTab.map.systemImage, value: .map) {
                MapContainerView()
            }

            Tab(AppTab.flights.title, systemImage: AppTab.flights.systemImage, value: .flights) {
                Text("Flights Placeholder")
            }

            Tab(AppTab.logbook.title, systemImage: AppTab.logbook.systemImage, value: .logbook) {
                Text("Logbook Placeholder")
            }

            Tab(AppTab.aircraft.title, systemImage: AppTab.aircraft.systemImage, value: .aircraft) {
                Text("Aircraft Placeholder")
            }

            Tab(AppTab.settings.title, systemImage: AppTab.settings.systemImage, value: .settings) {
                Text("Settings Placeholder")
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}
