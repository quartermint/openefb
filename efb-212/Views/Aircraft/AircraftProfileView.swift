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

    private var isOverdue: Bool { dueDate < Date() }
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
    @State private var fuelCapacity: String = ""
    @State private var fuelBurn: String = ""
    @State private var cruiseSpeed: String = ""
    @State private var annualDue: Date = Date()
    @State private var hasAnnualDue: Bool = false
    @State private var transponderDue: Date = Date()
    @State private var hasTransponderDue: Bool = false

    // FAA lookup state
    @State private var isLookingUp: Bool = false
    @State private var lookupError: String?
    @State private var lookupResult: FAALookupResult?

    // Defaults state
    @State private var defaults: AircraftPerformanceDefaults?
    @State private var useDefaults: Bool = true

    private var isNewProfile: Bool { profile == nil }
    private let faaService = FAALookupService()

    var body: some View {
        VStack(spacing: 0) {
            // Registration row
            registrationSection

            Divider().padding(.horizontal)

            // Aircraft identity (after lookup)
            if lookupResult != nil || !aircraftType.isEmpty {
                identitySection
                Divider().padding(.horizontal)
            }

            // Performance
            performanceSection

            Divider().padding(.horizontal)

            // Inspections
            inspectionsSection

            Spacer(minLength: 0)
        }
        .padding(.top, 8)
        .navigationTitle(isNewProfile ? "New Aircraft" : "Edit Aircraft")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                    dismiss()
                }
                .fontWeight(.semibold)
                .disabled(nNumber.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .onAppear { loadFromProfile() }
    }

    // MARK: - Registration Section

    @ViewBuilder
    private var registrationSection: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("N-NUMBER")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)

                TextField("N4543A", text: $nNumber)
                    .font(.system(.title2, design: .monospaced, weight: .bold))
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .disabled(!isNewProfile)
            }

            if isNewProfile {
                Button {
                    lookupNNumber()
                } label: {
                    if isLookingUp {
                        ProgressView()
                            .controlSize(.small)
                            .frame(width: 80, height: 36)
                    } else {
                        Label("Lookup", systemImage: "magnifyingglass")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(width: 80, height: 36)
                    }
                }
                .buttonStyle(.bordered)
                .tint(.blue)
                .disabled(nNumber.trimmingCharacters(in: .whitespaces).isEmpty || isLookingUp)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)

        if let lookupError {
            Label(lookupError, systemImage: "exclamationmark.triangle")
                .font(.caption)
                .foregroundStyle(.red)
                .padding(.horizontal)
                .padding(.bottom, 6)
        }
    }

    // MARK: - Identity Section (after lookup)

    @ViewBuilder
    private var identitySection: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                if isNewProfile && lookupResult == nil {
                    TextField("Aircraft Type", text: $aircraftType)
                        .font(.headline)
                        .autocorrectionDisabled()
                } else {
                    Text(aircraftType.isEmpty ? "Unknown" : aircraftType)
                        .font(.headline)
                }

                if let result = lookupResult {
                    HStack(spacing: 8) {
                        if let year = result.yearManufactured {
                            Text(year)
                        }
                        Text(result.manufacturer.trimmingCharacters(in: .whitespaces))
                        if let engine = result.engineManufacturer {
                            Text(engine.trimmingCharacters(in: .whitespaces))
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }
            }

            Spacer()

            if lookupResult != nil {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    // MARK: - Performance Section

    @ViewBuilder
    private var performanceSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("PERFORMANCE")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)

                Spacer()

                if defaults != nil {
                    Picker("", selection: $useDefaults) {
                        Text("Defaults").tag(true)
                        Text("Custom").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                    .onChange(of: useDefaults) { _, isDefault in
                        if isDefault, let defaults {
                            applyDefaults(defaults)
                        }
                    }
                }
            }

            HStack(spacing: 16) {
                PerfField(
                    label: "FUEL",
                    unit: "GAL",
                    text: $fuelCapacity,
                    isDefault: useDefaults && defaults != nil
                )

                PerfField(
                    label: "BURN",
                    unit: "GPH",
                    text: $fuelBurn,
                    isDefault: useDefaults && defaults != nil
                )

                PerfField(
                    label: "CRUISE",
                    unit: "KTS",
                    text: $cruiseSpeed,
                    isDefault: useDefaults && defaults != nil
                )
            }

            if let defaults, useDefaults {
                Text("Typical \(defaults.displayName) cruise performance")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .onChange(of: fuelCapacity) { checkCustomValues() }
        .onChange(of: fuelBurn) { checkCustomValues() }
        .onChange(of: cruiseSpeed) { checkCustomValues() }
    }

    // MARK: - Inspections Section

    @ViewBuilder
    private var inspectionsSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("INSPECTIONS")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Annual Due", isOn: $hasAnnualDue)
                        .font(.subheadline)
                    if hasAnnualDue {
                        DatePicker("", selection: $annualDue, displayedComponents: .date)
                            .labelsHidden()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Transponder Due", isOn: $hasTransponderDue)
                        .font(.subheadline)
                    if hasTransponderDue {
                        DatePicker("", selection: $transponderDue, displayedComponents: .date)
                            .labelsHidden()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    // MARK: - FAA Lookup

    private func lookupNNumber() {
        let trimmed = nNumber.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        isLookingUp = true
        lookupError = nil
        lookupResult = nil

        Task {
            do {
                let result = try await faaService.lookup(nNumber: trimmed)
                lookupResult = result

                // Auto-fill aircraft type
                if aircraftType.isEmpty {
                    aircraftType = result.displayType
                }

                // Look up default performance for this model
                if let perf = aircraftDefaults(forModel: result.model) {
                    defaults = perf
                    useDefaults = true
                    applyDefaults(perf)
                }
            } catch {
                lookupError = "Not found — check N-number and try again"
            }
            isLookingUp = false
        }
    }

    private func applyDefaults(_ perf: AircraftPerformanceDefaults) {
        fuelCapacity = String(format: "%.0f", perf.fuelCapacityGallons)
        fuelBurn = String(format: "%.1f", perf.fuelBurnGPH)
        cruiseSpeed = String(format: "%.0f", perf.cruiseSpeedKts)
    }

    /// If user manually edits a field and it differs from defaults, switch to Custom
    private func checkCustomValues() {
        guard let defaults, useDefaults else { return }
        let defaultFuel = String(format: "%.0f", defaults.fuelCapacityGallons)
        let defaultBurn = String(format: "%.1f", defaults.fuelBurnGPH)
        let defaultSpeed = String(format: "%.0f", defaults.cruiseSpeedKts)

        if fuelCapacity != defaultFuel || fuelBurn != defaultBurn || cruiseSpeed != defaultSpeed {
            useDefaults = false
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
        target.fuelCapacityGallons = Double(fuelCapacity)
        target.fuelBurnGPH = Double(fuelBurn)
        target.cruiseSpeedKts = Double(cruiseSpeed)
        target.annualDue = hasAnnualDue ? annualDue : nil
        target.transponderDue = hasTransponderDue ? transponderDue : nil
    }
}

// MARK: - Performance Field

private struct PerfField: View {
    let label: String
    let unit: String
    @Binding var text: String
    let isDefault: Bool

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)

            TextField("—", text: $text)
                .font(.system(.title3, design: .monospaced, weight: .semibold))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .foregroundStyle(isDefault ? .blue : .primary)

            Text(unit)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Previews

#Preview("Aircraft List") {
    NavigationStack {
        AircraftProfileView()
    }
    .modelContainer(for: AircraftProfileModel.self, inMemory: true)
}
