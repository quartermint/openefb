//
//  FlightDetailView.swift
//  efb-212
//
//  Detail view for a single FlightRecordModel. Displays all flight fields
//  including date, route, duration, distance, and editable remarks.
//  Supports deletion with confirmation alert.
//

import SwiftUI
import SwiftData

struct FlightDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var flight: FlightRecordModel

    @State private var showingDeleteAlert = false
    @State private var editedRemarks: String = ""
    @State private var isEditingRemarks = false

    var body: some View {
        List {
            // MARK: - Route Section
            Section("Route") {
                LabeledContent("Departure") {
                    Text(flight.departure)
                        .fontDesign(.monospaced)
                }

                LabeledContent("Arrival") {
                    Text(flight.arrival)
                        .fontDesign(.monospaced)
                }

                if let route = flight.route, !route.isEmpty {
                    LabeledContent("Route") {
                        Text(route)
                            .fontDesign(.monospaced)
                            .font(.caption)
                    }
                }
            }

            // MARK: - Date & Time Section
            Section("Date & Duration") {
                LabeledContent("Date") {
                    Text(flight.date, style: .date)
                }

                LabeledContent("Duration") {
                    Text(formatDurationHM(flight.duration))
                        .fontDesign(.monospaced)
                }

                LabeledContent("Decimal Hours") {
                    Text(formatDurationDecimal(flight.duration))
                        .fontDesign(.monospaced)
                }
            }

            // MARK: - Distance Section
            if let distance = flight.totalDistance {
                Section("Distance") {
                    LabeledContent("Total Distance") {
                        Text("\(distance, specifier: "%.1f") NM")   // nautical miles
                            .fontDesign(.monospaced)
                    }
                }
            }

            // MARK: - Remarks Section
            Section("Remarks") {
                if isEditingRemarks {
                    TextField("Add remarks...", text: $editedRemarks, axis: .vertical)
                        .lineLimit(3...8)

                    HStack {
                        Button("Cancel") {
                            editedRemarks = flight.remarks ?? ""
                            isEditingRemarks = false
                        }

                        Spacer()

                        Button("Save") {
                            let trimmed = editedRemarks.trimmingCharacters(in: .whitespaces)
                            flight.remarks = trimmed.isEmpty ? nil : trimmed
                            isEditingRemarks = false
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    if let remarks = flight.remarks, !remarks.isEmpty {
                        Text(remarks)
                            .font(.body)
                    } else {
                        Text("No remarks")
                            .foregroundStyle(.secondary)
                            .italic()
                    }

                    Button("Edit Remarks") {
                        editedRemarks = flight.remarks ?? ""
                        isEditingRemarks = true
                    }
                }
            }

            // MARK: - Flight ID Section
            Section {
                LabeledContent("Flight ID") {
                    Text(flight.flightID.uuidString.prefix(8))
                        .font(.caption2)
                        .fontDesign(.monospaced)
                        .foregroundStyle(.secondary)
                }
            }

            // MARK: - Delete Section
            Section {
                Button("Delete Flight", role: .destructive) {
                    showingDeleteAlert = true
                }
            }
        }
        .navigationTitle("\(flight.departure) \u{2192} \(flight.arrival)")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Flight?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteFlight()
            }
        } message: {
            Text("This will permanently remove this flight record from your logbook.")
        }
    }

    // MARK: - Actions

    private func deleteFlight() {
        modelContext.delete(flight)
        dismiss()
    }

    // MARK: - Formatting Helpers

    /// Formats duration in seconds as "Xh Ym" (e.g., "2h 15m" or "0h 45m")
    private func formatDurationHM(_ duration: TimeInterval) -> String {
        let totalMinutes = Int(duration) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return "\(hours)h \(minutes)m"
    }

    /// Formats duration in seconds as decimal hours (e.g., "1.5")
    private func formatDurationDecimal(_ duration: TimeInterval) -> String {
        let hours = duration / 3600.0
        return String(format: "%.1f", hours)
    }
}

// MARK: - Previews

#Preview("Flight Detail") {
    NavigationStack {
        FlightDetailView(
            flight: {
                let record = FlightRecordModel(
                    date: Date(),
                    departure: "KPAO",
                    arrival: "KSQL",
                    duration: 8100                                  // 2h 15m in seconds
                )
                record.totalDistance = 12.3                          // nautical miles
                record.route = "KPAO V334 KSQL"
                record.remarks = "Smooth flight, light winds."
                return record
            }()
        )
    }
    .modelContainer(for: FlightRecordModel.self, inMemory: true)
}
