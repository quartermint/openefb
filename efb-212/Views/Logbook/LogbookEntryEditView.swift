//
//  LogbookEntryEditView.swift
//  efb-212
//
//  Review/edit view for a logbook entry before confirming.
//  Confirmed entries open in read-only mode (locked banner, all fields disabled).
//  Unconfirmed entries are editable with Save and Confirm toolbar buttons.
//

import SwiftUI
import SwiftData

struct LogbookEntryEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let entry: SchemaV1.LogbookEntry
    let viewModel: LogbookViewModel
    let isReadOnly: Bool

    // MARK: - Editable State

    @State private var date: Date
    @State private var departureICAO: String
    @State private var arrivalICAO: String
    @State private var route: String
    @State private var durationHours: Double
    @State private var aircraftType: String
    @State private var nightLandingCount: Int
    @State private var dayLandingCount: Int
    @State private var notes: String

    // MARK: - Init

    init(entry: SchemaV1.LogbookEntry, viewModel: LogbookViewModel, isReadOnly: Bool) {
        self.entry = entry
        self.viewModel = viewModel
        self.isReadOnly = isReadOnly

        // Initialize @State from entry fields
        _date = State(initialValue: entry.date)
        _departureICAO = State(initialValue: entry.departureICAO ?? "")
        _arrivalICAO = State(initialValue: entry.arrivalICAO ?? "")
        _route = State(initialValue: entry.route ?? "")
        _durationHours = State(initialValue: entry.durationSeconds / 3600.0)
        _aircraftType = State(initialValue: entry.aircraftType ?? "")
        _nightLandingCount = State(initialValue: entry.nightLandingCount)
        _dayLandingCount = State(initialValue: entry.dayLandingCount)
        _notes = State(initialValue: entry.notes ?? "")
    }

    var body: some View {
        Form {
            if isReadOnly {
                Section {
                    Label("This entry has been confirmed and is locked.", systemImage: "lock.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            // MARK: - Flight Info

            Section("Flight Info") {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                    .disabled(isReadOnly)

                HStack {
                    Text("Departure")
                    Spacer()
                    TextField("ICAO", text: $departureICAO)
                        .textInputAutocapitalization(.characters)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 120)
                        .disabled(isReadOnly)
                }

                HStack {
                    Text("Arrival")
                    Spacer()
                    TextField("ICAO", text: $arrivalICAO)
                        .textInputAutocapitalization(.characters)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 120)
                        .disabled(isReadOnly)
                }

                HStack {
                    Text("Route")
                    Spacer()
                    TextField("Waypoints", text: $route)
                        .multilineTextAlignment(.trailing)
                        .disabled(isReadOnly)
                }
            }

            // MARK: - Duration

            Section("Duration") {
                HStack {
                    Text("Block Time")
                    Spacer()
                    TextField("0.0", value: $durationHours, format: .number.precision(.fractionLength(1)))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 80)
                        .disabled(isReadOnly)
                    Text("hrs")
                        .foregroundStyle(.secondary)
                }
            }

            // MARK: - Aircraft

            Section("Aircraft") {
                HStack {
                    Text("Aircraft Type")
                    Spacer()
                    TextField("e.g. C172", text: $aircraftType)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 120)
                        .disabled(isReadOnly)
                }
            }

            // MARK: - Landings

            Section("Landings") {
                Stepper("Day Landings: \(dayLandingCount)", value: $dayLandingCount, in: 0...99)
                    .disabled(isReadOnly)
                Stepper("Night Landings (61.57): \(nightLandingCount)", value: $nightLandingCount, in: 0...99)
                    .disabled(isReadOnly)
            }

            // MARK: - Notes

            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(minHeight: 80)
                    .disabled(isReadOnly)
            }

            // MARK: - Flight Summary (read-only)

            if isReadOnly {
                Section("Summary") {
                    LabeledContent("Duration", value: "\(LogbookViewModel.formatDurationDecimal(entry.durationSeconds))h (\(LogbookViewModel.formatDurationHM(entry.durationSeconds)))")

                    if let departureName = entry.departureName {
                        LabeledContent("Departure", value: departureName)
                    }
                    if let arrivalName = entry.arrivalName {
                        LabeledContent("Arrival", value: arrivalName)
                    }
                    if entry.hasDebrief {
                        Label("AI Debrief Available", systemImage: "brain")
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
        .navigationTitle(isReadOnly ? "Flight Details" : "Edit Entry")
        .toolbar {
            if !isReadOnly {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveEntry()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Confirm") {
                        saveEntry()
                        viewModel.confirmEntry(entry)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .tint(.green)
                }
            }
        }
    }

    // MARK: - Save Logic

    /// Copy local @State values back to the entry model.
    private func saveEntry() {
        entry.date = date
        entry.departureICAO = departureICAO.uppercased().isEmpty ? nil : departureICAO.uppercased()
        entry.arrivalICAO = arrivalICAO.uppercased().isEmpty ? nil : arrivalICAO.uppercased()
        entry.route = route.isEmpty ? nil : route
        entry.durationSeconds = durationHours * 3600
        entry.aircraftType = aircraftType.isEmpty ? nil : aircraftType
        entry.nightLandingCount = nightLandingCount
        entry.dayLandingCount = dayLandingCount
        entry.notes = notes.isEmpty ? nil : notes
    }
}

#Preview("Editable") {
    NavigationStack {
        LogbookEntryEditView(
            entry: {
                let e = SchemaV1.LogbookEntry()
                e.departureICAO = "KPAO"
                e.arrivalICAO = "KSQL"
                e.durationSeconds = 3600
                e.aircraftType = "C172"
                return e
            }(),
            viewModel: LogbookViewModel(),
            isReadOnly: false
        )
    }
    .modelContainer(for: SchemaV1.LogbookEntry.self)
}

#Preview("Read Only") {
    NavigationStack {
        LogbookEntryEditView(
            entry: {
                let e = SchemaV1.LogbookEntry()
                e.departureICAO = "KPAO"
                e.arrivalICAO = "KSQL"
                e.durationSeconds = 5400
                e.aircraftType = "PA-28"
                e.isConfirmed = true
                return e
            }(),
            viewModel: LogbookViewModel(),
            isReadOnly: true
        )
    }
    .modelContainer(for: SchemaV1.LogbookEntry.self)
}
