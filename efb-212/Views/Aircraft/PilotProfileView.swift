//
//  PilotProfileView.swift
//  efb-212
//
//  Displays the active pilot profile with currency badges, night landing entry,
//  and profile management (list, active selection, create/edit/delete).
//

import SwiftUI
import SwiftData

struct PilotProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @State private var viewModel: PilotProfileViewModel?

    // Night landing entry form state
    @State private var nightLandingDate: Date = Date()
    @State private var nightLandingCount: Int = 3

    var body: some View {
        List {
            if let vm = viewModel {
                if vm.profiles.isEmpty {
                    // No profiles -- show create button
                    Section {
                        Button {
                            vm.addProfile()
                            vm.editingProfile = vm.profiles.first
                            vm.isShowingEditor = true
                        } label: {
                            Label("Create Pilot Profile", systemImage: "person.badge.plus")
                        }
                    }
                } else {
                    // MARK: - Pilot Profiles List (if multiple)

                    if vm.profiles.count > 1 {
                        Section("Pilot Profiles") {
                            ForEach(vm.profiles, id: \.id) { profile in
                                PilotRow(
                                    profile: profile,
                                    isActive: profile.isActive,
                                    onTap: { vm.setActive(profile) }
                                )
                            }
                            .onDelete { indexSet in
                                for index in indexSet {
                                    vm.deleteProfile(vm.profiles[index])
                                }
                            }
                        }
                    }

                    // MARK: - Active Pilot Info

                    if let active = vm.activeProfile {
                        Section {
                            LabeledContent("Name", value: active.name.isEmpty ? "Not set" : active.name)

                            if let certNumber = active.certificateNumber, !certNumber.isEmpty {
                                LabeledContent("Certificate #", value: certNumber)
                            }

                            if let certType = active.certificateTypeEnum {
                                LabeledContent("Certificate Type", value: certType.displayName)
                            }

                            if let totalHours = active.totalHours {
                                LabeledContent("Total Hours", value: String(format: "%.1f", totalHours))
                            }

                            Button {
                                vm.editingProfile = active
                                vm.isShowingEditor = true
                            } label: {
                                Label("Edit Profile", systemImage: "pencil")
                            }
                        } header: {
                            Text("Pilot Info")
                        }

                        // MARK: - Currency Status

                        Section("Currency Status") {
                            CurrencyBadge(status: vm.medicalCurrency, label: "Medical Certificate")
                            CurrencyBadge(status: vm.flightReviewCurrency, label: "Flight Review")
                            CurrencyBadge(status: vm.nightCurrency, label: "Night Currency (61.57)")
                        }

                        // MARK: - Night Landings

                        Section {
                            Button {
                                vm.isShowingNightLandingEntry = true
                            } label: {
                                Label("Log Night Landings", systemImage: "moon.fill")
                            }

                            // Recent entries (last 10)
                            let recentEntries = Array(active.nightLandingEntries
                                .sorted(by: { $0.date > $1.date })
                                .prefix(10))

                            if !recentEntries.isEmpty {
                                ForEach(recentEntries, id: \.date) { entry in
                                    HStack {
                                        Text(entry.date, format: .dateTime.month().day().year())
                                            .font(.subheadline)
                                        Spacer()
                                        Text("\(entry.count) landing\(entry.count == 1 ? "" : "s")")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        } header: {
                            Text("Night Landings")
                        }
                    }

                    // MARK: - Add Another Profile

                    Section {
                        Button {
                            vm.addProfile()
                        } label: {
                            Label("Add Pilot Profile", systemImage: "person.badge.plus")
                        }
                    }
                }
            }
        }
        .navigationTitle("Pilot Profile")
        .toolbar {
            if let vm = viewModel, vm.profiles.count <= 1, vm.activeProfile == nil {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        vm.addProfile()
                        vm.editingProfile = vm.profiles.first
                        vm.isShowingEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { viewModel?.isShowingEditor ?? false },
            set: { viewModel?.isShowingEditor = $0 }
        )) {
            if let vm = viewModel {
                PilotEditView(
                    profile: vm.editingProfile,
                    onSave: {
                        vm.saveEdits()
                        vm.isShowingEditor = false
                    }
                )
            }
        }
        .sheet(isPresented: Binding(
            get: { viewModel?.isShowingNightLandingEntry ?? false },
            set: { viewModel?.isShowingNightLandingEntry = $0 }
        )) {
            NightLandingEntrySheet(
                date: $nightLandingDate,
                count: $nightLandingCount,
                onSave: {
                    viewModel?.addNightLandings(date: nightLandingDate, count: nightLandingCount)
                    viewModel?.isShowingNightLandingEntry = false
                    // Reset for next entry
                    nightLandingDate = Date()
                    nightLandingCount = 3
                }
            )
        }
        .onAppear {
            if viewModel == nil {
                viewModel = PilotProfileViewModel(
                    modelContext: modelContext,
                    appState: appState
                )
            }
            viewModel?.loadProfiles()
        }
    }
}

// MARK: - PilotRow

private struct PilotRow: View {
    let profile: SchemaV1.PilotProfile
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.name.isEmpty ? "Unnamed Pilot" : profile.name)
                        .font(.headline)
                    if let certType = profile.certificateTypeEnum {
                        Text(certType.displayName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
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
    }
}

// MARK: - NightLandingEntrySheet

private struct NightLandingEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var date: Date
    @Binding var count: Int
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Night Landing Entry") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)

                    Stepper("Landings: \(count)", value: $count, in: 1...10)
                }

                Section {
                    Text("Log full-stop night landings for FAR 61.57 currency tracking. Requires 3 landings within 90 days for night passenger-carrying currency.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Log Night Landings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                    }
                }
            }
        }
    }
}

// MARK: - CertificateType Display Names

extension CertificateType {
    var displayName: String {
        switch self {
        case .student: return "Student Pilot"
        case .sport: return "Sport Pilot"
        case .recreational: return "Recreational Pilot"
        case .privatePilot: return "Private Pilot"
        case .commercial: return "Commercial Pilot"
        case .atp: return "ATP"
        }
    }
}

// MARK: - MedicalClass Display Names

extension MedicalClass {
    var displayName: String {
        switch self {
        case .first: return "First Class"
        case .second: return "Second Class"
        case .third: return "Third Class"
        case .basicMed: return "BasicMed"
        }
    }
}

#Preview {
    NavigationStack {
        PilotProfileView()
    }
    .environment(AppState())
    .modelContainer(for: [
        SchemaV1.AircraftProfile.self,
        SchemaV1.PilotProfile.self,
        SchemaV1.UserSettings.self,
        SchemaV1.FlightPlanRecord.self
    ])
}
