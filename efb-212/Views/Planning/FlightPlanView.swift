//
//  FlightPlanView.swift
//  efb-212
//
//  Flights tab content: create and manage flight plans.
//  Top section for plan creation with airport search,
//  bottom section for saved plans list.
//
//  Uses concrete AviationDatabase fallback if the Map tab
//  hasn't loaded yet (sharedDatabaseService is nil).
//

import SwiftUI
import SwiftData

struct FlightPlanView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: FlightPlanViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    flightPlanContent(viewModel: viewModel)
                } else {
                    ProgressView("Loading...")
                }
            }
            .navigationTitle("Flight Plans")
        }
        .onAppear {
            initializeViewModel()
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private func flightPlanContent(viewModel: FlightPlanViewModel) -> some View {
        VStack(spacing: 0) {
            // MARK: Plan Creator Section
            planCreatorSection(viewModel: viewModel)

            Divider()
                .padding(.vertical, 8)

            // MARK: Saved Plans Section
            savedPlansSection(viewModel: viewModel)
        }
    }

    // MARK: - Plan Creator

    @ViewBuilder
    private func planCreatorSection(viewModel: FlightPlanViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Departure airport search
            VStack(alignment: .leading, spacing: 4) {
                Text("Departure")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("Search airport (ICAO, name, city)", text: Binding(
                    get: { viewModel.departureQuery },
                    set: { viewModel.departureQuery = $0 }
                ))
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)
                .onChange(of: viewModel.departureQuery) { _, _ in
                    viewModel.searchDeparture()
                }

                // Departure search results dropdown
                if !viewModel.departureResults.isEmpty {
                    airportResultsList(
                        results: viewModel.departureResults,
                        onSelect: { viewModel.selectDeparture($0) }
                    )
                }
            }

            // Destination airport search
            VStack(alignment: .leading, spacing: 4) {
                Text("Destination")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("Search airport (ICAO, name, city)", text: Binding(
                    get: { viewModel.destinationQuery },
                    set: { viewModel.destinationQuery = $0 }
                ))
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)
                .onChange(of: viewModel.destinationQuery) { _, _ in
                    viewModel.searchDestination()
                }

                // Destination search results dropdown
                if !viewModel.destinationResults.isEmpty {
                    airportResultsList(
                        results: viewModel.destinationResults,
                        onSelect: { viewModel.selectDestination($0) }
                    )
                }
            }

            // Summary card (shown when both airports selected)
            if viewModel.selectedDeparture != nil && viewModel.selectedDestination != nil {
                FlightPlanSummaryCard(
                    distanceNM: viewModel.distanceNM,
                    ete: viewModel.formattedETE,
                    fuelGallons: viewModel.estimatedFuelGallons,
                    departure: viewModel.selectedDeparture?.icao ?? "",
                    destination: viewModel.selectedDestination?.icao ?? ""
                )

                // Action buttons
                HStack(spacing: 12) {
                    Button {
                        viewModel.savePlan()
                    } label: {
                        Label("Save Plan", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.borderedProminent)

                    Button(role: .destructive) {
                        viewModel.clearPlan()
                    } label: {
                        Label("Clear", systemImage: "xmark.circle")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
    }

    // MARK: - Saved Plans List

    @ViewBuilder
    private func savedPlansSection(viewModel: FlightPlanViewModel) -> some View {
        if viewModel.savedPlans.isEmpty {
            ContentUnavailableView(
                "No Saved Plans",
                systemImage: "airplane.circle",
                description: Text("Create a flight plan above to get started.")
            )
        } else {
            List {
                ForEach(viewModel.savedPlans, id: \.id) { record in
                    Button {
                        viewModel.loadPlan(record)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 4) {
                                    Text(record.departureICAO)
                                        .font(.headline)
                                    Image(systemName: "arrow.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(record.destinationICAO)
                                        .font(.headline)
                                }

                                HStack(spacing: 8) {
                                    Text(String(format: "%.1f nm", record.totalDistanceNM))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(record.lastUsedAt, style: .relative)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }

                            Spacer()

                            if record.id == viewModel.activePlanID {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        viewModel.deletePlan(viewModel.savedPlans[index])
                    }
                }
            }
            .listStyle(.plain)
        }
    }

    // MARK: - Airport Results Helper

    @ViewBuilder
    private func airportResultsList(results: [Airport], onSelect: @escaping (Airport) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(results) { airport in
                Button {
                    onSelect(airport)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(airport.icao)
                            .font(.subheadline.bold())
                        Text(airport.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                if airport.id != results.last?.id {
                    Divider()
                }
            }
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - ViewModel Initialization

    /// Initialize the FlightPlanViewModel with database service.
    /// Uses AppState.sharedDatabaseService if available (Map tab loaded first),
    /// otherwise creates a concrete AviationDatabase as fallback.
    private func initializeViewModel() {
        guard viewModel == nil else { return }

        let dbService: any DatabaseServiceProtocol
        if let shared = appState.sharedDatabaseService {
            dbService = shared
        } else {
            // Initialize AviationDatabase directly when Map tab hasn't loaded yet.
            // AviationDatabase opens the bundled SQLite read-only -- safe to have multiple instances.
            if let aviationDB = try? DatabaseManager() {
                dbService = aviationDB
                // Also set as shared so other tabs can use it
                appState.sharedDatabaseService = aviationDB
            } else {
                dbService = PlaceholderDatabaseService()
            }
        }

        let vm = FlightPlanViewModel(databaseService: dbService, appState: appState)
        vm.configure(mapService: appState.sharedMapService, modelContext: modelContext)
        viewModel = vm
    }
}

#Preview {
    FlightPlanView()
        .environment(AppState())
        .modelContainer(for: [
            SchemaV1.FlightPlanRecord.self,
            SchemaV1.AircraftProfile.self
        ])
}
