//
//  PilotProfileView.swift
//  efb-212
//
//  View for managing pilot profile and currency tracking.
//  Most users have a single pilot profile. Displays certificate info,
//  medical class/expiry, flight review date, and total hours.
//  Provides currency warnings when medical or flight review is due soon.
//

import SwiftUI
import SwiftData

struct PilotProfileView: View {
    @Query private var profiles: [PilotProfileModel]
    @Environment(\.modelContext) private var modelContext
    @State private var isEditing = false

    /// The user's single pilot profile, creating one if needed.
    private var currentProfile: PilotProfileModel {
        if let existing = profiles.first {
            return existing
        }
        let newProfile = PilotProfileModel()
        modelContext.insert(newProfile)
        return newProfile
    }

    var body: some View {
        List {
            if profiles.isEmpty || isProfileEmpty(profiles.first) {
                Section {
                    ContentUnavailableView(
                        "No Pilot Profile",
                        systemImage: "person.badge.shield.checkmark",
                        description: Text("Tap Edit to set up your pilot profile for currency tracking.")
                    )
                }
            } else if let profile = profiles.first {
                // Certificate Information
                Section("Certificate") {
                    if let name = profile.name, !name.isEmpty {
                        LabeledContent("Name", value: name)
                    }

                    if let certNumber = profile.certificateNumber, !certNumber.isEmpty {
                        LabeledContent("Certificate Number", value: certNumber)
                    }

                    if let certTypeRaw = profile.certificateType,
                       let certType = CertificateType(rawValue: certTypeRaw) {
                        LabeledContent("Certificate Type", value: certType.displayName)
                    }
                }

                // Medical Information
                Section("Medical") {
                    if let medClassRaw = profile.medicalClass,
                       let medClass = MedicalClass(rawValue: medClassRaw) {
                        LabeledContent("Medical Class", value: medClass.displayName)
                    }

                    if let expiry = profile.medicalExpiry {
                        HStack {
                            Text("Medical Expiry")
                            Spacer()
                            Text(expiry, style: .date)
                                .foregroundStyle(expiryColor(for: expiry))
                        }
                        if currencyWarning(for: expiry, label: "Medical") != nil {
                            CurrencyWarningRow(
                                label: "Medical",
                                expiryDate: expiry
                            )
                        }
                    }
                }

                // Flight Review
                Section("Flight Review") {
                    if let reviewDate = profile.flightReviewDate {
                        HStack {
                            Text("Last Flight Review")
                            Spacer()
                            Text(reviewDate, style: .date)
                        }

                        // Flight review is valid for 24 calendar months
                        let reviewExpiry = flightReviewExpiry(from: reviewDate)
                        HStack {
                            Text("Review Valid Through")
                            Spacer()
                            Text(reviewExpiry, style: .date)
                                .foregroundStyle(expiryColor(for: reviewExpiry))
                        }
                        if currencyWarning(for: reviewExpiry, label: "Flight Review") != nil {
                            CurrencyWarningRow(
                                label: "Flight Review",
                                expiryDate: reviewExpiry
                            )
                        }
                    }
                }

                // Experience
                Section("Experience") {
                    if let hours = profile.totalHours {
                        LabeledContent("Total Hours", value: String(format: "%.1f", hours))
                    }
                }
            }
        }
        .navigationTitle("Pilot Profile")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    isEditing = true
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            NavigationStack {
                PilotEditView(profile: currentProfile)
            }
        }
    }

    // MARK: - Currency Helpers

    /// Flight review is valid for 24 calendar months from the date of the review.
    private func flightReviewExpiry(from reviewDate: Date) -> Date {
        Calendar.current.date(byAdding: .month, value: 24, to: reviewDate) ?? reviewDate
    }

    /// Returns the color for an expiry date based on proximity.
    private func expiryColor(for date: Date) -> Color {
        if date < Date() { return .red }
        let thirtyDaysOut = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        if date < thirtyDaysOut { return .orange }
        let ninetyDaysOut = Calendar.current.date(byAdding: .day, value: 90, to: Date()) ?? Date()
        if date < ninetyDaysOut { return .yellow }
        return .primary
    }

    /// Returns a warning string if the given date is within 90 days or expired.
    private func currencyWarning(for date: Date, label: String) -> String? {
        if date < Date() {
            return "\(label) is expired."
        }
        let ninetyDaysOut = Calendar.current.date(byAdding: .day, value: 90, to: Date()) ?? Date()
        if date < ninetyDaysOut {
            let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
            return "\(label) expires in \(days) days."
        }
        return nil
    }

    private func isProfileEmpty(_ profile: PilotProfileModel?) -> Bool {
        guard let profile else { return true }
        return profile.name == nil
            && profile.certificateNumber == nil
            && profile.certificateType == nil
            && profile.medicalClass == nil
            && profile.medicalExpiry == nil
            && profile.flightReviewDate == nil
            && profile.totalHours == nil
    }
}

// MARK: - Currency Warning Row

struct CurrencyWarningRow: View {
    let label: String
    let expiryDate: Date

    private var isExpired: Bool {
        expiryDate < Date()
    }

    private var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isExpired ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(isExpired ? .red : .orange)
            Text(isExpired ? "\(label) is expired" : "\(label) expires in \(daysRemaining) days")
                .font(.caption)
                .foregroundStyle(isExpired ? .red : .orange)
        }
    }
}

// MARK: - Pilot Edit View

struct PilotEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let profile: PilotProfileModel

    @State private var name: String = ""
    @State private var certificateNumber: String = ""
    @State private var selectedCertType: CertificateType = .privatePilot
    @State private var hasCertType: Bool = false
    @State private var selectedMedClass: MedicalClass = .third
    @State private var hasMedClass: Bool = false
    @State private var medicalExpiry: Date = Date()
    @State private var hasMedicalExpiry: Bool = false
    @State private var flightReviewDate: Date = Date()
    @State private var hasFlightReview: Bool = false
    @State private var totalHours: String = ""

    var body: some View {
        Form {
            Section("Personal") {
                TextField("Full Name", text: $name)
                TextField("Certificate Number", text: $certificateNumber)
                    .keyboardType(.numberPad)
            }

            Section("Certificate") {
                Toggle("Certificate Type", isOn: $hasCertType)
                if hasCertType {
                    Picker("Type", selection: $selectedCertType) {
                        ForEach(CertificateType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }
            }

            Section("Medical") {
                Toggle("Medical Class", isOn: $hasMedClass)
                if hasMedClass {
                    Picker("Class", selection: $selectedMedClass) {
                        ForEach(MedicalClass.allCases, id: \.self) { cls in
                            Text(cls.displayName).tag(cls)
                        }
                    }
                }

                Toggle("Medical Expiry Date", isOn: $hasMedicalExpiry)
                if hasMedicalExpiry {
                    DatePicker("Expires", selection: $medicalExpiry, displayedComponents: .date)
                }
            }

            Section("Flight Review") {
                Toggle("Flight Review Date", isOn: $hasFlightReview)
                if hasFlightReview {
                    DatePicker("Last Review", selection: $flightReviewDate, displayedComponents: .date)
                }
            }

            Section("Experience") {
                HStack {
                    TextField("Total Flight Hours", text: $totalHours)
                        .keyboardType(.decimalPad)
                    Text("hours")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Edit Profile")
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
            }
        }
        .onAppear {
            loadFromProfile()
        }
    }

    // MARK: - Data Binding

    private func loadFromProfile() {
        name = profile.name ?? ""
        certificateNumber = profile.certificateNumber ?? ""

        if let certRaw = profile.certificateType, let cert = CertificateType(rawValue: certRaw) {
            selectedCertType = cert
            hasCertType = true
        }

        if let medRaw = profile.medicalClass, let med = MedicalClass(rawValue: medRaw) {
            selectedMedClass = med
            hasMedClass = true
        }

        if let expiry = profile.medicalExpiry {
            medicalExpiry = expiry
            hasMedicalExpiry = true
        }

        if let review = profile.flightReviewDate {
            flightReviewDate = review
            hasFlightReview = true
        }

        totalHours = profile.totalHours.map { String(format: "%.1f", $0) } ?? ""
    }

    private func save() {
        profile.name = name.isEmpty ? nil : name
        profile.certificateNumber = certificateNumber.isEmpty ? nil : certificateNumber
        profile.certificateType = hasCertType ? selectedCertType.rawValue : nil
        profile.medicalClass = hasMedClass ? selectedMedClass.rawValue : nil
        profile.medicalExpiry = hasMedicalExpiry ? medicalExpiry : nil
        profile.flightReviewDate = hasFlightReview ? flightReviewDate : nil
        profile.totalHours = Double(totalHours)
    }
}

// MARK: - Display Name Extensions

extension CertificateType {
    var displayName: String {
        switch self {
        case .student: return "Student Pilot"
        case .sport: return "Sport Pilot"
        case .recreational: return "Recreational Pilot"
        case .privatePilot: return "Private Pilot"
        case .commercial: return "Commercial Pilot"
        case .atp: return "Airline Transport Pilot"
        }
    }
}

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

// MARK: - Previews

#Preview("Pilot Profile") {
    NavigationStack {
        PilotProfileView()
    }
    .modelContainer(for: PilotProfileModel.self, inMemory: true)
}
