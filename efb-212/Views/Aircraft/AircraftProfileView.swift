//
//  AircraftProfileView.swift
//  efb-212
//
//  View for managing aircraft profiles. Uses SwiftData @Query to fetch
//  AircraftProfileModel instances. Supports adding, editing, and deleting
//  aircraft with registration, performance, and inspection data.
//

import SwiftUI
import SwiftData

struct AircraftProfileView: View {
    @Query(sort: \AircraftProfileModel.createdAt, order: .reverse) private var profiles: [AircraftProfileModel]
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddSheet = false

    var body: some View {
        List {
            if profiles.isEmpty {
                ContentUnavailableView(
                    "No Aircraft",
                    systemImage: "airplane.circle",
                    description: Text("Add your first aircraft to get started with fuel planning and inspection tracking.")
                )
            } else {
                ForEach(profiles, id: \.nNumber) { profile in
                    NavigationLink {
                        AircraftEditView(profile: profile)
                    } label: {
                        AircraftRow(profile: profile)
                    }
                }
                .onDelete(perform: deleteProfiles)
            }
        }
        .navigationTitle("Aircraft")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add", systemImage: "plus") {
                    showingAddSheet = true
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            NavigationStack {
                AircraftEditView(profile: nil)
            }
        }
    }

    private func deleteProfiles(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(profiles[index])
        }
    }
}

// MARK: - Aircraft Row

struct AircraftRow: View {
    let profile: AircraftProfileModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(profile.nNumber)
                    .font(.headline)
                    .fontDesign(.monospaced)

                if let type = profile.aircraftType, !type.isEmpty {
                    Text(type)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 16) {
                if let fuel = profile.fuelCapacityGallons {
                    Label("\(fuel, specifier: "%.0f") gal", systemImage: "fuelpump")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let burn = profile.fuelBurnGPH {
                    Label("\(burn, specifier: "%.1f") GPH", systemImage: "flame")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let speed = profile.cruiseSpeedKts {
                    Label("\(speed, specifier: "%.0f") kts", systemImage: "gauge.with.dots.needle.33percent")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Inspection warnings
            if let annualDue = profile.annualDue {
                InspectionBadge(label: "Annual", dueDate: annualDue)
            }
            if let transponderDue = profile.transponderDue {
                InspectionBadge(label: "Transponder", dueDate: transponderDue)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Inspection Badge

struct InspectionBadge: View {
    let label: String
    let dueDate: Date

    /// Inspection is overdue
    private var isOverdue: Bool {
        dueDate < Date()
    }

    /// Inspection is due within 30 days
    private var isDueSoon: Bool {
        let thirtyDaysOut = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        return dueDate < thirtyDaysOut && !isOverdue
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isOverdue ? "exclamationmark.triangle.fill" : "calendar.badge.clock")
                .foregroundStyle(badgeColor)
            Text("\(label): \(dueDate, style: .date)")
                .font(.caption2)
                .foregroundStyle(badgeColor)
        }
    }

    private var badgeColor: Color {
        if isOverdue { return .red }
        if isDueSoon { return .orange }
        return .secondary
    }
}

// MARK: - Aircraft Edit View

struct AircraftEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let profile: AircraftProfileModel?

    // Form state
    @State private var nNumber: String = ""
    @State private var aircraftType: String = ""
    @State private var fuelCapacity: String = ""         // gallons
    @State private var fuelBurn: String = ""             // gallons per hour
    @State private var cruiseSpeed: String = ""          // knots TAS
    @State private var annualDue: Date = Date()
    @State private var hasAnnualDue: Bool = false
    @State private var transponderDue: Date = Date()
    @State private var hasTransponderDue: Bool = false

    private var isNewProfile: Bool { profile == nil }

    var body: some View {
        Form {
            Section("Registration") {
                TextField("N-Number (e.g., N4543A)", text: $nNumber)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .disabled(!isNewProfile)

                TextField("Aircraft Type (e.g., AA-5B Tiger)", text: $aircraftType)
                    .autocorrectionDisabled()
            }

            Section("Performance") {
                HStack {
                    TextField("Fuel Capacity", text: $fuelCapacity)
                        .keyboardType(.decimalPad)
                    Text("gallons")                      // gallons — usable fuel
                        .foregroundStyle(.secondary)
                }

                HStack {
                    TextField("Fuel Burn Rate", text: $fuelBurn)
                        .keyboardType(.decimalPad)
                    Text("GPH")                          // gallons per hour at cruise
                        .foregroundStyle(.secondary)
                }

                HStack {
                    TextField("Cruise Speed", text: $cruiseSpeed)
                        .keyboardType(.decimalPad)
                    Text("kts TAS")                      // knots true airspeed
                        .foregroundStyle(.secondary)
                }
            }

            Section("Inspections") {
                Toggle("Annual Inspection Due", isOn: $hasAnnualDue)
                if hasAnnualDue {
                    DatePicker("Annual Due Date", selection: $annualDue, displayedComponents: .date)
                }

                Toggle("Transponder Check Due", isOn: $hasTransponderDue)
                if hasTransponderDue {
                    DatePicker("Transponder Due Date", selection: $transponderDue, displayedComponents: .date)
                }
            }
        }
        .navigationTitle(isNewProfile ? "New Aircraft" : "Edit Aircraft")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                    dismiss()
                }
                .disabled(nNumber.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .onAppear {
            loadFromProfile()
        }
    }

    // MARK: - Data Binding

    private func loadFromProfile() {
        guard let profile else { return }
        nNumber = profile.nNumber
        aircraftType = profile.aircraftType ?? ""
        fuelCapacity = profile.fuelCapacityGallons.map { String(format: "%.0f", $0) } ?? ""
        fuelBurn = profile.fuelBurnGPH.map { String(format: "%.1f", $0) } ?? ""
        cruiseSpeed = profile.cruiseSpeedKts.map { String(format: "%.0f", $0) } ?? ""

        if let annual = profile.annualDue {
            annualDue = annual
            hasAnnualDue = true
        }
        if let transponder = profile.transponderDue {
            transponderDue = transponder
            hasTransponderDue = true
        }
    }

    private func save() {
        let trimmedN = nNumber.trimmingCharacters(in: .whitespaces).uppercased()
        guard !trimmedN.isEmpty else { return }

        let target: AircraftProfileModel
        if let existing = profile {
            target = existing
        } else {
            target = AircraftProfileModel(nNumber: trimmedN)
            modelContext.insert(target)
        }

        target.aircraftType = aircraftType.isEmpty ? nil : aircraftType
        target.fuelCapacityGallons = Double(fuelCapacity)       // gallons
        target.fuelBurnGPH = Double(fuelBurn)                   // gallons per hour
        target.cruiseSpeedKts = Double(cruiseSpeed)             // knots TAS
        target.annualDue = hasAnnualDue ? annualDue : nil
        target.transponderDue = hasTransponderDue ? transponderDue : nil
    }
}

// MARK: - Previews

#Preview("Aircraft List") {
    NavigationStack {
        AircraftProfileView()
    }
    .modelContainer(for: AircraftProfileModel.self, inMemory: true)
}
