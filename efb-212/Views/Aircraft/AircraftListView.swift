//
//  AircraftListView.swift
//  efb-212
//
//  Aircraft tab main view -- list of aircraft profiles with add/edit/delete,
//  active selection, and navigation to pilot profile section.
//

import SwiftUI
import SwiftData

struct AircraftListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @State private var viewModel: AircraftProfileViewModel?

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Aircraft Profiles Section

                Section {
                    if let vm = viewModel {
                        if vm.profiles.isEmpty {
                            Text("No aircraft profiles yet")
                                .foregroundStyle(.secondary)
                                .italic()
                        } else {
                            ForEach(vm.profiles, id: \.id) { profile in
                                AircraftRow(
                                    profile: profile,
                                    isActive: profile.isActive,
                                    onTap: { vm.setActive(profile) },
                                    onEdit: {
                                        vm.editingProfile = profile
                                        vm.isShowingEditor = true
                                    }
                                )
                            }
                            .onDelete { indexSet in
                                for index in indexSet {
                                    vm.deleteProfile(vm.profiles[index])
                                }
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("Aircraft Profiles")
                        Spacer()
                        if let count = viewModel?.profiles.count, count > 0 {
                            Text("\(count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // MARK: - Pilot Profile Section

                Section {
                    NavigationLink {
                        PilotProfileView()
                    } label: {
                        Label("Pilot Profile", systemImage: "person.circle")
                    }
                } header: {
                    Text("Pilot")
                }
            }
            .navigationTitle("Aircraft")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel?.editingProfile = nil
                        viewModel?.isShowingEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add aircraft")
                }
            }
            .sheet(isPresented: Binding(
                get: { viewModel?.isShowingEditor ?? false },
                set: { viewModel?.isShowingEditor = $0 }
            )) {
                if let vm = viewModel {
                    AircraftEditView(
                        profile: vm.editingProfile,
                        onSave: {
                            vm.saveEdits()
                            vm.isShowingEditor = false
                        },
                        onAddNew: { nNumber in
                            vm.addProfile(nNumber: nNumber)
                            vm.isShowingEditor = false
                        }
                    )
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = AircraftProfileViewModel(
                        modelContext: modelContext,
                        appState: appState
                    )
                }
                viewModel?.loadProfiles()
            }
        }
    }
}

// MARK: - AircraftRow

private struct AircraftRow: View {
    let profile: SchemaV1.AircraftProfile
    let isActive: Bool
    let onTap: () -> Void
    let onEdit: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.nNumber)
                        .font(.headline)
                    if !profile.aircraftType.isEmpty {
                        Text(profile.aircraftType)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    if let fuel = profile.fuelCapacityGallons, let burn = profile.fuelBurnGPH {
                        Text("\(Int(fuel)) gal / \(String(format: "%.1f", burn)) GPH")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()

                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.title3)
                }
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing) {
            Button("Edit", systemImage: "pencil") {
                onEdit()
            }
            .tint(.blue)
        }
    }
}

#Preview {
    AircraftListView()
        .environment(AppState())
        .modelContainer(for: [
            SchemaV1.AircraftProfile.self,
            SchemaV1.PilotProfile.self,
            SchemaV1.UserSettings.self,
            SchemaV1.FlightPlanRecord.self
        ])
}
