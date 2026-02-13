//
//  ContentView.swift
//  efb-212
//
//  Root view — TabView with 5 main app tabs.
//  Map tab shows the full moving map with instrument strip and layer controls.
//  Flights tab shows flight history with manual entry.
//  Logbook tab shows traditional pilot logbook format.
//  Aircraft tab shows pilot and aircraft profile management.
//  Settings tab shows app settings and chart management.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: AppTab = .map

    // Map dependencies — created once for the map tab
    @State private var mapService = MapService()
    @State private var mapViewModel: MapViewModel?

    // Flight planning
    @State private var flightPlanViewModel: FlightPlanViewModel?
    @State private var weatherViewModel: WeatherViewModel?
    @State private var showFlightPlan: Bool = false

    // Nearest airport (emergency feature)
    @State private var nearestAirportViewModel: NearestAirportViewModel?
    @State private var showNearestAirport: Bool = false

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(AppTab.map.title, systemImage: AppTab.map.systemImage, value: .map) {
                mapTab
            }

            Tab(AppTab.flights.title, systemImage: AppTab.flights.systemImage, value: .flights) {
                NavigationStack {
                    FlightListView()
                }
            }

            Tab(AppTab.logbook.title, systemImage: AppTab.logbook.systemImage, value: .logbook) {
                NavigationStack {
                    LogbookView()
                }
            }

            Tab(AppTab.aircraft.title, systemImage: AppTab.aircraft.systemImage, value: .aircraft) {
                aircraftTab
            }

            Tab(AppTab.settings.title, systemImage: AppTab.settings.systemImage, value: .settings) {
                NavigationStack {
                    SettingsView()
                }
            }
        }
        .onAppear {
            if mapViewModel == nil {
                mapViewModel = MapViewModel(
                    databaseManager: appState.databaseManager,
                    mapService: mapService,
                    locationManager: appState.locationManager
                )
            }
            if flightPlanViewModel == nil {
                flightPlanViewModel = FlightPlanViewModel(
                    databaseManager: appState.databaseManager
                )
            }
            if weatherViewModel == nil {
                weatherViewModel = WeatherViewModel(
                    weatherService: appState.weatherService
                )
            }
            if nearestAirportViewModel == nil {
                nearestAirportViewModel = NearestAirportViewModel(
                    databaseManager: appState.databaseManager,
                    locationManager: appState.locationManager
                )
            }
        }
        .sheet(isPresented: $appState.isPresentingAirportInfo) {
            if let airportID = appState.selectedAirportID,
               let airport = mapViewModel?.selectedAirport, airport.icao == airportID {
                let weather = weatherViewModel?.weatherData[airportID]
                AirportInfoSheet(airport: airport, weather: weather)
            }
        }
        .sheet(isPresented: $showFlightPlan) {
            if let fpvm = flightPlanViewModel, let wvm = weatherViewModel {
                FlightPlanView(viewModel: fpvm, weatherViewModel: wvm)
            }
        }
        .sheet(isPresented: $showNearestAirport) {
            if let navm = nearestAirportViewModel {
                NearestAirportView(viewModel: navm, weatherViewModel: weatherViewModel)
            }
        }
        .onChange(of: flightPlanViewModel?.activePlan) {
            // Sync flight plan to AppState for InstrumentStrip DTG/ETE
            appState.activeFlightPlan = flightPlanViewModel?.activePlan
            if let plan = flightPlanViewModel?.activePlan {
                appState.distanceToNext = plan.totalDistance
                appState.estimatedTimeEnroute = plan.estimatedTime
                // Render route line on map
                mapService.showRoute(waypoints: plan.waypoints)
            } else {
                appState.distanceToNext = nil
                appState.estimatedTimeEnroute = nil
                mapService.clearRoute()
            }
        }
    }

    // MARK: - Map Tab

    @ViewBuilder
    private var mapTab: some View {
        ZStack(alignment: .bottom) {
            // Map fills the entire space
            MapView(mapService: mapService)
                .ignoresSafeArea(edges: .top)

            // Floating controls
            VStack {
                HStack {
                    // Flight plan button (top-left)
                    Button {
                        showFlightPlan = true
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.title3)
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .padding(.leading, 16)
                    .padding(.top, 60)

                    // Nearest airport button — emergency/safety feature
                    Button {
                        showNearestAirport = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                            Text("NEAREST")
                                .font(.caption)
                                .fontWeight(.black)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(.red)
                        .clipShape(Capsule())
                    }
                    .padding(.top, 60)

                    Spacer()

                    // Layer controls (top-right)
                    LayerControlsView(mapService: mapService)
                        .padding(.trailing, 16)
                        .padding(.top, 60)
                }
                Spacer()
            }

            // Instrument strip at bottom
            InstrumentStripView()
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
        }
    }

    // MARK: - Aircraft Tab

    @ViewBuilder
    private var aircraftTab: some View {
        NavigationStack {
            List {
                NavigationLink("Aircraft Profiles") {
                    AircraftProfileView()
                }
                NavigationLink("Pilot Profile") {
                    PilotProfileView()
                }
            }
            .navigationTitle("Aircraft & Pilot")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(
            AppState(
                locationManager: PlaceholderLocationManager(),
                databaseManager: PlaceholderDatabaseManager(),
                weatherService: PlaceholderWeatherService()
            )
        )
}
