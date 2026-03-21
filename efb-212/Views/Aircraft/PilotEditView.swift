//
//  PilotEditView.swift
//  efb-212
//
//  Form-based editor for pilot profile fields.
//  Handles name, certificate info, medical class/expiry, flight review, total hours.
//

import SwiftUI
import SwiftData

struct PilotEditView: View {
    @Environment(\.dismiss) private var dismiss

    /// Profile to edit (must be non-nil -- created before presenting this view).
    let profile: SchemaV1.PilotProfile?
    let onSave: () -> Void

    // MARK: - Form State

    @State private var name: String = ""
    @State private var certificateNumber: String = ""
    @State private var certificateType: CertificateType? = nil
    @State private var medicalClass: MedicalClass? = nil
    @State private var medicalExpiry: Date = Date()
    @State private var hasMedicalExpiry: Bool = false
    @State private var flightReviewDate: Date = Date()
    @State private var hasFlightReview: Bool = false
    @State private var totalHours: String = ""

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Personal

                Section("Personal") {
                    TextField("Name", text: $name)
                        .textContentType(.name)

                    TextField("Certificate Number", text: $certificateNumber)
                        .autocorrectionDisabled()
                }

                // MARK: - Certificate

                Section("Certificate") {
                    Picker("Certificate Type", selection: $certificateType) {
                        Text("None").tag(nil as CertificateType?)
                        ForEach(CertificateType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type as CertificateType?)
                        }
                    }

                    Picker("Medical Class", selection: $medicalClass) {
                        Text("None").tag(nil as MedicalClass?)
                        ForEach(MedicalClass.allCases, id: \.self) { cls in
                            Text(cls.displayName).tag(cls as MedicalClass?)
                        }
                    }
                }

                // MARK: - Dates

                Section("Dates") {
                    Toggle("Medical Expiry", isOn: $hasMedicalExpiry)
                    if hasMedicalExpiry {
                        DatePicker("Medical Expiry", selection: $medicalExpiry, displayedComponents: .date)
                    }

                    Toggle("Flight Review Date", isOn: $hasFlightReview)
                    if hasFlightReview {
                        DatePicker("Flight Review Date", selection: $flightReviewDate, displayedComponents: .date)
                    }
                }

                // MARK: - Experience

                Section("Experience") {
                    TextField("Total Hours", text: $totalHours)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Edit Pilot")
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

        name = profile.name
        certificateNumber = profile.certificateNumber ?? ""
        certificateType = profile.certificateTypeEnum
        medicalClass = profile.medicalClassEnum

        if let expiry = profile.medicalExpiry {
            hasMedicalExpiry = true
            medicalExpiry = expiry
        }

        if let review = profile.flightReviewDate {
            hasFlightReview = true
            flightReviewDate = review
        }

        totalHours = profile.totalHours.map { String($0) } ?? ""
    }

    // MARK: - Save

    private func saveProfile() {
        guard let profile else { return }

        profile.name = name
        profile.certificateNumber = certificateNumber.isEmpty ? nil : certificateNumber
        profile.certificateTypeEnum = certificateType
        profile.medicalClassEnum = medicalClass
        profile.medicalExpiry = hasMedicalExpiry ? medicalExpiry : nil
        profile.flightReviewDate = hasFlightReview ? flightReviewDate : nil
        profile.totalHours = Double(totalHours)

        onSave()
    }
}

#Preview {
    PilotEditView(
        profile: nil,
        onSave: {}
    )
}
