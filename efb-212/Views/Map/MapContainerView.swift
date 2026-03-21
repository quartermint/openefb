//
//  MapContainerView.swift
//  efb-212
//
//  Main map tab view composing map, right-edge controls, layer panel,
//  chart expiration warning overlay (INFRA-03), airport info sheet,
//  TFR disclaimer banner, and weather/TFR data integration.
//  Per UI-SPEC: map fills screen, controls on right edge, ZStack composition.
//

import SwiftUI

struct MapContainerView: View {
    @Environment(AppState.self) private var appState

    // Services created here and shared with child views
    @State private var mapService = MapService()
    @State private var mapViewModel: MapViewModel?

    // MARK: - Plan 04 Services (Weather, TFR, Proximity, Reachability)
    @State private var weatherService = WeatherService()
    @State private var tfrService = TFRService()
    @State private var proximityAlertService: ProximityAlertService?
    @State private var reachabilityService = ReachabilityService()

    var body: some View {
        @Bindable var appState = appState

        ZStack(alignment: .topTrailing) {
            // Full-screen map
            if let viewModel = mapViewModel {
                MapView(mapService: mapService, mapViewModel: viewModel)
                    .ignoresSafeArea(edges: .top)
            }

            // Right-edge controls stack (per user decision: right edge for iPad landscape)
            if let viewModel = mapViewModel {
                VStack(spacing: 16) {
                    MapControlsView(mapViewModel: viewModel)
                }
                .padding(.trailing, 16)
                .padding(.top, 60)
            }

            // Chart expiration warning overlay (INFRA-03)
            // Show at top-left when charts are expired or expiring within 7 days
            VStack {
                HStack {
                    if let viewModel = mapViewModel {
                        ChartExpirationBadge(daysRemaining: viewModel.chartDaysRemaining)
                            .padding(.leading, 16)
                            .padding(.top, 60)
                    }
                    Spacer()
                }
                Spacer()
            }

            // Layer controls popover
            if appState.isPresentingLayerControls, let viewModel = mapViewModel {
                VStack {
                    LayerControlsView(mapViewModel: viewModel)
                        .padding(.trailing, 16)
                        .padding(.top, 140)
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .transition(.opacity)
            }

            // MARK: - TFR Disclaimer Banner (Plan 04)
            // Non-dismissable red banner when TFR layer is visible
            if appState.visibleLayers.contains(.tfrs) {
                VStack {
                    Text("TFR DATA IS SAMPLE ONLY — NOT FOR NAVIGATION")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 16)
                        .background(Color.red)
                    Spacer()
                }
                .padding(.top, 44)
            }

            // MARK: - Offline / Cached Data Indicator (Plan 04)
            if !reachabilityService.isConnected {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "wifi.slash")
                        Text("Offline — using cached data")
                            .font(.caption)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.orange.opacity(0.9))
                    .clipShape(Capsule())
                    .padding(.bottom, 8)
                }
            }
        }
        .sheet(isPresented: $appState.isPresentingAirportInfo) {
            // MARK: - Airport Info Sheet (Plan 04)
            AirportInfoSheet(
                databaseService: mapViewModel?.databaseService ?? PlaceholderDatabaseService(),
                weatherService: weatherService
            )
        }
        .onAppear {
            if mapViewModel == nil {
                let databaseService: any DatabaseServiceProtocol
                if let dbManager = try? DatabaseManager() {
                    databaseService = dbManager
                } else {
                    databaseService = PlaceholderDatabaseService()
                }
                let vm = MapViewModel(
                    appState: appState,
                    mapService: mapService,
                    databaseService: databaseService
                )

                // Wire Plan 04 services to MapViewModel
                let proxService = ProximityAlertService(databaseService: databaseService)
                vm.weatherService = weatherService
                vm.tfrService = tfrService
                vm.proximityAlertService = proxService

                mapViewModel = vm
                proximityAlertService = proxService

                // Start reachability monitoring
                reachabilityService.start()
                appState.networkAvailable = reachabilityService.isConnected
            }
        }
        .onChange(of: reachabilityService.isConnected) { _, newValue in
            appState.networkAvailable = newValue
        }
    }
}

#Preview {
    MapContainerView()
        .environment(AppState())
}
