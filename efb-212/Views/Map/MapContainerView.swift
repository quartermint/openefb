//
//  MapContainerView.swift
//  efb-212
//
//  Main map tab view composing map, right-edge controls, layer panel,
//  chart expiration warning overlay (INFRA-03), and airport info sheet.
//  Per UI-SPEC: map fills screen, controls on right edge, ZStack composition.
//

import SwiftUI

struct MapContainerView: View {
    @Environment(AppState.self) private var appState

    // Services created here and shared with child views
    @State private var mapService = MapService()
    @State private var mapViewModel: MapViewModel?

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
        }
        .sheet(isPresented: $appState.isPresentingAirportInfo) {
            // AirportInfoSheet (added in Plan 04)
            Text("Airport Info Placeholder")
                .presentationDetents([.medium])
        }
        .onAppear {
            if mapViewModel == nil {
                let databaseService: any DatabaseServiceProtocol
                if let dbManager = try? DatabaseManager() {
                    databaseService = dbManager
                } else {
                    databaseService = PlaceholderDatabaseService()
                }
                mapViewModel = MapViewModel(
                    appState: appState,
                    mapService: mapService,
                    databaseService: databaseService
                )
            }
        }
    }
}

#Preview {
    MapContainerView()
        .environment(AppState())
}
