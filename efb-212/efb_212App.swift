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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
    }
}
