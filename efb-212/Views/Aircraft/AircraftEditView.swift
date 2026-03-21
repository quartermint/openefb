//
//  AircraftEditView.swift
//  efb-212
//
//  Form-based editor for aircraft profile fields.
//  Used for both creating new profiles and editing existing ones.
//

import SwiftUI
import SwiftData

struct AircraftEditView: View {
    @Environment(\.dismiss) private var dismiss

    /// Existing profile to edit (nil = creating new).
    let profile: SchemaV1.AircraftProfile?

    /// Called when saving edits to an existing profile.
    let onSave: () -> Void

    /// Called when creating a new profile -- passes the N-number.
    let onAddNew: (String) -> Void

    // MARK: - Form State

    @State private var nNumber: String = ""
    @State private var aircraftType: String = ""
    @State private var fuelCapacity: String = ""
    @State private var fuelBurn: String = ""
    @State private var cruiseSpeed: String = ""
    @State private var showVSpeeds: Bool = false
    @State private var vr: String = ""
    @State private var vx: String = ""
    @State private var vy: String = ""
    @State private var va: String = ""
    @State private var vne: String = ""
    @State private var vfe: String = ""
    @State private var vs0: String = ""
    @State private var vs1: String = ""
    @State private var annualDue: Date = Date()
    @State private var hasAnnualDue: Bool = false
    @State private var transponderDue: Date = Date()
    @State private var hasTransponderDue: Bool = false
    @State private var showValidationError: Bool = false

    private var isEditing: Bool { profile != nil }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Aircraft Info

                Section("Aircraft Info") {
                    TextField("N-number (e.g., N12345)", text: $nNumber)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()

                    if showValidationError && nNumber.trimmingCharacters(in: .whitespaces).isEmpty {
                        Text("N-number is required")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    TextField("Aircraft type (e.g., Cessna 172SP)", text: $aircraftType)
                        .autocorrectionDisabled()
                }

                // MARK: - Performance

                Section("Performance") {
                    TextField("Usable Fuel (gal)", text: $fuelCapacity)
                        .keyboardType(.decimalPad)

                    TextField("Fuel Burn (GPH)", text: $fuelBurn)
                        .keyboardType(.decimalPad)

                    TextField("Cruise Speed (kts)", text: $cruiseSpeed)
                        .keyboardType(.decimalPad)
                }

                // MARK: - V-Speeds (Optional)

                Section {
                    Toggle("Show V-Speeds", isOn: $showVSpeeds)

                    if showVSpeeds {
                        VSpeedField(label: "Vr (Rotation)", text: $vr)  // knots
                        VSpeedField(label: "Vx (Best Angle)", text: $vx)  // knots
                        VSpeedField(label: "Vy (Best Rate)", text: $vy)  // knots
                        VSpeedField(label: "Va (Maneuvering)", text: $va)  // knots
                        VSpeedField(label: "Vs0 (Stall Landing)", text: $vs0)  // knots
                        VSpeedField(label: "Vs1 (Stall Clean)", text: $vs1)  // knots
                        VSpeedField(label: "Vfe (Max Flap)", text: $vfe)  // knots
                        VSpeedField(label: "Vne (Never Exceed)", text: $vne)  // knots
                    }
                } header: {
                    Text("V-Speeds (Optional)")
                }

                // MARK: - Inspection Dates

                Section("Inspection Dates") {
                    Toggle("Annual Due", isOn: $hasAnnualDue)
                    if hasAnnualDue {
                        DatePicker("Annual Due", selection: $annualDue, displayedComponents: .date)
                    }

                    Toggle("Transponder Due", isOn: $hasTransponderDue)
                    if hasTransponderDue {
                        DatePicker("Transponder Due", selection: $transponderDue, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Aircraft" : "New Aircraft")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProfile()
                    }
                }
            }
            .onAppear {
                loadProfile()
            }
        }
    }

    // MARK: - Load Existing Profile

    private func loadProfile() {
        guard let profile else { return }

        nNumber = profile.nNumber
        aircraftType = profile.aircraftType
        fuelCapacity = profile.fuelCapacityGallons.map { String($0) } ?? ""
        fuelBurn = profile.fuelBurnGPH.map { String($0) } ?? ""
        cruiseSpeed = profile.cruiseSpeedKts.map { String($0) } ?? ""

        if let vSpeeds = profile.vSpeeds {
            showVSpeeds = true
            vr = vSpeeds.vr.map { String($0) } ?? ""
            vx = vSpeeds.vx.map { String($0) } ?? ""
            vy = vSpeeds.vy.map { String($0) } ?? ""
            va = vSpeeds.va.map { String($0) } ?? ""
            vne = vSpeeds.vne.map { String($0) } ?? ""
            vfe = vSpeeds.vfe.map { String($0) } ?? ""
            vs0 = vSpeeds.vs0.map { String($0) } ?? ""
            vs1 = vSpeeds.vs1.map { String($0) } ?? ""
        }

        if let annual = profile.annualDue {
            hasAnnualDue = true
            annualDue = annual
        }

        if let transponder = profile.transponderDue {
            hasTransponderDue = true
            transponderDue = transponder
        }
    }

    // MARK: - Save

    private func saveProfile() {
        let trimmedNNumber = nNumber.trimmingCharacters(in: .whitespaces)
        guard !trimmedNNumber.isEmpty else {
            showValidationError = true
            return
        }

        if let profile {
            // Editing existing
            profile.nNumber = trimmedNNumber.uppercased()
            profile.aircraftType = aircraftType
            profile.fuelCapacityGallons = Double(fuelCapacity)
            profile.fuelBurnGPH = Double(fuelBurn)
            profile.cruiseSpeedKts = Double(cruiseSpeed)
            profile.annualDue = hasAnnualDue ? annualDue : nil
            profile.transponderDue = hasTransponderDue ? transponderDue : nil

            if showVSpeeds {
                profile.vSpeeds = VSpeeds(
                    vr: Int(vr), vx: Int(vx), vy: Int(vy), va: Int(va),
                    vne: Int(vne), vfe: Int(vfe), vs0: Int(vs0), vs1: Int(vs1)
                )
            } else {
                profile.vSpeeds = nil
            }

            onSave()
        } else {
            // Creating new
            onAddNew(trimmedNNumber.uppercased())
        }
    }
}

// MARK: - VSpeedField

private struct VSpeedField: View {
    let label: String
    @Binding var text: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            TextField("kts", text: $text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
        }
    }
}

#Preview {
    AircraftEditView(
        profile: nil,
        onSave: {},
        onAddNew: { _ in }
    )
}
