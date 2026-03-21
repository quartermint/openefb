//
//  FlightDetailView.swift
//  efb-212
//
//  Flight recording detail view with AI Debrief button and availability check.
//  Uses shared RecordingDatabase from AppState (not per-view instance).
//  Prewarms LanguageModelSession on appear, discards on disappear.
//

import SwiftUI
import SwiftData

struct FlightDetailView: View {
    let flightRecord: SchemaV1.FlightRecord
    @Environment(AppState.self) private var appState
    @State private var debriefEngine = DebriefEngine()

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // MARK: - Flight Info Section
                flightInfoSection

                Divider()

                // MARK: - Recording Stats
                recordingStatsSection

                Divider()

                // MARK: - AI Debrief Section
                debriefSection
            }
            .padding()
        }
        .navigationTitle("Flight Details")
        .onAppear {
            debriefEngine.checkAvailability()
            if debriefEngine.availabilityStatus == .available {
                debriefEngine.prewarm()
            }
        }
        .onDisappear {
            debriefEngine.discard()
        }
    }

    // MARK: - Flight Info

    @ViewBuilder
    private var flightInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Flight Info", systemImage: "airplane")
                .font(.headline)

            LabeledContent("Date", value: Self.dateFormatter.string(from: flightRecord.startDate))

            HStack {
                VStack(alignment: .leading) {
                    Text("From")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(flightRecord.departureICAO ?? "---")
                        .font(.title3.bold())
                    if let name = flightRecord.departureName {
                        Text(name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)

                VStack(alignment: .leading) {
                    Text("To")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(flightRecord.arrivalICAO ?? "---")
                        .font(.title3.bold())
                    if let name = flightRecord.arrivalName {
                        Text(name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }

            LabeledContent("Duration", value: LogbookViewModel.formatDurationHM(flightRecord.durationSeconds))
        }
    }

    // MARK: - Recording Stats

    @ViewBuilder
    private var recordingStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Recording Data", systemImage: "waveform")
                .font(.headline)

            LabeledContent("Track Points", value: "\(flightRecord.trackPointCount)")
            LabeledContent("Transcript Segments", value: "\(flightRecord.transcriptSegmentCount)")
            LabeledContent("Audio Quality", value: flightRecord.audioQuality.capitalized)
        }
    }

    // MARK: - Debrief Section

    @ViewBuilder
    private var debriefSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("AI Debrief", systemImage: "brain.head.profile")
                .font(.headline)

            switch debriefEngine.availabilityStatus {
            case .available:
                if let recordingDB = appState.getOrCreateRecordingDatabase() {
                    let metadata = buildMetadata()

                    NavigationLink {
                        DebriefView(
                            debriefEngine: debriefEngine,
                            flightID: flightRecord.id,
                            recordingDB: recordingDB,
                            metadata: metadata
                        )
                    } label: {
                        HStack {
                            Image(systemName: flightRecord.hasDebrief ? "brain" : "sparkles")
                                .font(.title3)
                            Text(flightRecord.hasDebrief ? "View Debrief" : "Generate Debrief")
                                .font(.body.bold())
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(flightRecord.hasDebrief ? Color.blue.opacity(0.1) : Color.purple.opacity(0.1))
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    // RecordingDatabase initialization failed
                    Label("Recording database unavailable", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.secondary)
                }

            case .unavailable(let reason):
                unavailableContent(reason: reason)

            case .unknown:
                ProgressView("Checking AI availability...")
            }
        }
    }

    // MARK: - Unavailable Content

    @ViewBuilder
    private func unavailableContent(reason: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "apple.intelligence")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("AI Debrief requires Apple Intelligence.")
                .font(.headline)
            Text("You can still review your flight track, transcript, and logbook entry.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if reason.contains("not enabled") {
                Link("Open Settings", destination: URL(string: UIApplication.openSettingsURLString)!)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.quaternary)
        )
    }

    // MARK: - Helpers

    private func buildMetadata() -> FlightMetadata {
        FlightMetadata(
            aircraftType: nil,  // Could look up from profile if needed
            pilotName: nil,
            departureICAO: flightRecord.departureICAO,
            arrivalICAO: flightRecord.arrivalICAO,
            date: flightRecord.startDate,
            durationSeconds: flightRecord.durationSeconds
        )
    }
}
