//
//  LogbookListView.swift
//  efb-212
//
//  Chronological logbook list with confirmed/unconfirmed indicators,
//  manual entry creation, and summary footer.
//  Confirmed entries navigate to read-only detail; unconfirmed to editable view.
//

import SwiftUI
import SwiftData

struct LogbookListView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: LogbookViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    if vm.entries.isEmpty {
                        ContentUnavailableView {
                            Label("No Flights Yet", systemImage: "book.closed")
                        } description: {
                            Text("Your flights will appear here after recording. You can also add entries manually.")
                        }
                    } else {
                        logbookList(vm: vm)
                    }
                } else {
                    ProgressView("Loading...")
                }
            }
            .navigationTitle("Logbook")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        addManualEntry()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: Binding(
                get: { viewModel?.isShowingManualEntry ?? false },
                set: { viewModel?.isShowingManualEntry = $0 }
            )) {
                if let vm = viewModel, let entry = vm.selectedEntry {
                    NavigationStack {
                        LogbookEntryEditView(entry: entry, viewModel: vm, isReadOnly: false)
                            .navigationTitle("New Entry")
                    }
                }
            }
        }
        .onAppear {
            initializeViewModel()
        }
    }

    // MARK: - Logbook List

    @ViewBuilder
    private func logbookList(vm: LogbookViewModel) -> some View {
        List {
            ForEach(vm.entries, id: \.id) { entry in
                NavigationLink {
                    LogbookEntryEditView(
                        entry: entry,
                        viewModel: vm,
                        isReadOnly: entry.isConfirmed
                    )
                } label: {
                    LogbookEntryRow(entry: entry)
                }
            }
            .onDelete { indexSet in
                deleteEntries(at: indexSet, vm: vm)
            }

            // Summary footer
            Section {
                HStack {
                    Text("Total")
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(vm.totalFlights) flights")
                    Text("  ")
                    Text("\(LogbookViewModel.formatDurationDecimal(vm.totalFlightTimeSeconds))h")
                        .fontWeight(.medium)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Entry Row

    private struct LogbookEntryRow: View {
        let entry: SchemaV1.LogbookEntry

        private static let dateFormatter: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "MMM d, yyyy"
            return f
        }()

        var body: some View {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Self.dateFormatter.string(from: entry.date))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(entry.departureICAO ?? "---") -> \(entry.arrivalICAO ?? "---")")
                        .font(.body)
                        .fontWeight(.medium)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(LogbookViewModel.formatDurationDecimal(entry.durationSeconds))h")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(entry.aircraftType ?? "Unknown")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if entry.isConfirmed {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .padding(.leading, 4)
                } else {
                    Image(systemName: "pencil.circle")
                        .foregroundStyle(.orange)
                        .padding(.leading, 4)
                }
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: - Actions

    private func initializeViewModel() {
        if viewModel == nil {
            let vm = LogbookViewModel()
            vm.loadEntries(modelContext: modelContext)
            viewModel = vm
        } else {
            viewModel?.loadEntries(modelContext: modelContext)
        }
    }

    private func addManualEntry() {
        guard let vm = viewModel else { return }
        let entry = vm.createManualEntry(modelContext: modelContext)
        vm.selectedEntry = entry
        vm.isShowingManualEntry = true
    }

    private func deleteEntries(at offsets: IndexSet, vm: LogbookViewModel) {
        for index in offsets {
            let entry = vm.entries[index]
            // Only allow deleting unconfirmed entries
            guard !entry.isConfirmed else { continue }
            vm.deleteEntry(entry, modelContext: modelContext)
        }
        vm.loadEntries(modelContext: modelContext)
    }
}

#Preview {
    LogbookListView()
        .environment(AppState())
        .modelContainer(for: [
            SchemaV1.LogbookEntry.self,
            SchemaV1.UserSettings.self
        ])
}
