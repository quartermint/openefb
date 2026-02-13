//
//  FlightListView.swift
//  efb-212
//
//  Flight history list view. Uses SwiftData @Query to fetch FlightRecordModel
//  entries sorted by date descending. Each row shows date, departure → arrival,
//  duration, and distance. Supports navigation to detail and manual entry.
//

import SwiftUI
import SwiftData

struct FlightListView: View {
    @Query(sort: \FlightRecordModel.date, order: .reverse)
    private var flights: [FlightRecordModel]

    @Environment(\.modelContext) private var modelContext
    @State private var showingAddFlight = false

    var body: some View {
        NavigationStack {
            Group {
                if flights.isEmpty {
                    emptyState
                } else {
                    flightList
                }
            }
            .navigationTitle("Flights")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Flight", systemImage: "plus") {
                        showingAddFlight = true
                    }
                }
            }
            .sheet(isPresented: $showingAddFlight) {
                NavigationStack {
                    AddFlightView()
                }
            }
        }
    }

    // MARK: - Flight List

    private var flightList: some View {
        List {
            ForEach(flights, id: \.flightID) { flight in
                NavigationLink {
                    FlightDetailView(flight: flight)
                } label: {
                    FlightRow(flight: flight)
                }
            }
            .onDelete(perform: deleteFlights)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView(
            "No Flights Recorded Yet",
            systemImage: "airplane",
            description: Text("Your recorded flights will appear here. Tap + to add a flight manually.")
        )
    }

    // MARK: - Deletion

    private func deleteFlights(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(flights[index])
        }
    }
}

// MARK: - Flight Row

struct FlightRow: View {
    let flight: FlightRecordModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(flight.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(formatDurationHM(flight.duration))
                    .font(.subheadline)
                    .fontDesign(.monospaced)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 4) {
                Text(flight.departure)
                    .font(.headline)
                    .fontDesign(.monospaced)

                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(flight.arrival)
                    .font(.headline)
                    .fontDesign(.monospaced)

                Spacer()

                if let distance = flight.totalDistance {
                    Text("\(distance, specifier: "%.1f") NM")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let remarks = flight.remarks, !remarks.isEmpty {
                Text(remarks)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }

    /// Formats a duration in seconds as "Xh Ym"
    private func formatDurationHM(_ duration: TimeInterval) -> String {
        let totalMinutes = Int(duration) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return "\(hours)h \(minutes)m"
    }
}

// MARK: - Add Flight View (Manual Entry)

struct AddFlightView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var departure = ""
    @State private var arrival = ""
    @State private var date = Date()
    @State private var hours = ""
    @State private var minutes = ""
    @State private var distance = ""
    @State private var remarks = ""

    var body: some View {
        Form {
            Section("Route") {
                TextField("Departure (ICAO)", text: $departure)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                TextField("Arrival (ICAO)", text: $arrival)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                DatePicker("Date", selection: $date, displayedComponents: .date)
            }

            Section("Duration") {
                HStack {
                    TextField("Hours", text: $hours)
                        .keyboardType(.numberPad)
                    Text("h")
                        .foregroundStyle(.secondary)
                    TextField("Minutes", text: $minutes)
                        .keyboardType(.numberPad)
                    Text("m")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Distance (optional)") {
                HStack {
                    TextField("Distance", text: $distance)
                        .keyboardType(.decimalPad)
                    Text("NM")                                  // nautical miles
                        .foregroundStyle(.secondary)
                }
            }

            Section("Remarks (optional)") {
                TextField("Remarks", text: $remarks, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
        .navigationTitle("Add Flight")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveFlight()
                    dismiss()
                }
                .disabled(!isValid)
            }
        }
    }

    private var isValid: Bool {
        let dep = departure.trimmingCharacters(in: .whitespaces)
        let arr = arrival.trimmingCharacters(in: .whitespaces)
        return !dep.isEmpty && !arr.isEmpty
    }

    private func saveFlight() {
        let h = Int(hours) ?? 0
        let m = Int(minutes) ?? 0
        let totalSeconds = TimeInterval((h * 3600) + (m * 60))   // seconds

        let record = FlightRecordModel(
            date: date,
            departure: departure.trimmingCharacters(in: .whitespaces).uppercased(),
            arrival: arrival.trimmingCharacters(in: .whitespaces).uppercased(),
            duration: totalSeconds
        )

        if let dist = Double(distance) {
            record.totalDistance = dist                            // nautical miles
        }

        if !remarks.trimmingCharacters(in: .whitespaces).isEmpty {
            record.remarks = remarks.trimmingCharacters(in: .whitespaces)
        }

        modelContext.insert(record)
    }
}

// MARK: - Previews

#Preview("Flight List") {
    FlightListView()
        .modelContainer(for: FlightRecordModel.self, inMemory: true)
}
