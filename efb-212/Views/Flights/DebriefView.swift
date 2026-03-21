//
//  DebriefView.swift
//  efb-212
//
//  Streaming AI debrief display with narrative summary, per-phase observations,
//  improvement suggestions, overall rating, and Regenerate button.
//  Observes DebriefEngine.partialDebrief/completedDebrief for progressive rendering.
//

import SwiftUI

struct DebriefView: View {
    let debriefEngine: DebriefEngine
    let flightID: UUID
    let recordingDB: RecordingDatabase
    let metadata: FlightMetadata

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let completed = debriefEngine.completedDebrief {
                    // MARK: - Completed Debrief Display
                    completedDebriefContent(completed)

                    Button {
                        regenerateDebrief()
                    } label: {
                        Label("Regenerate Debrief", systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(.bordered)
                    .padding(.top, 8)

                } else if debriefEngine.isGenerating, let partial = debriefEngine.partialDebrief {
                    // MARK: - Streaming Partial Debrief
                    streamingDebriefContent(partial)

                    ProgressView("Generating debrief...")
                        .padding(.top, 8)

                } else if let error = debriefEngine.error {
                    // MARK: - Error State
                    errorContent(error)

                } else {
                    // MARK: - Initial State
                    VStack(spacing: 16) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)

                        Text("Ready to analyze your flight")
                            .font(.headline)

                        Text("The AI will review your GPS track, transcript, and flight phases to provide personalized feedback.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Button {
                            generateDebrief()
                        } label: {
                            Label("Generate Debrief", systemImage: "sparkles")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .padding(.top, 32)
                }
            }
            .padding()
        }
        .navigationTitle("AI Debrief")
        .onAppear {
            debriefEngine.loadExistingDebrief(recordingDB: recordingDB, flightID: flightID)
        }
    }

    // MARK: - Completed Debrief Sections

    @ViewBuilder
    private func completedDebriefContent(_ debrief: FlightDebrief) -> some View {
        // Narrative Summary
        Section {
            Text(debrief.narrativeSummary)
                .font(.body)
        } header: {
            Label("Summary", systemImage: "doc.text")
                .font(.headline)
        }

        Divider()

        // Phase Observations
        Section {
            ForEach(Array(debrief.phaseObservations.enumerated()), id: \.offset) { _, observation in
                PhaseObservationCard(observation: observation)
            }
        } header: {
            Label("Phase Observations", systemImage: "list.bullet.clipboard")
                .font(.headline)
        }

        Divider()

        // Improvements
        if !debrief.improvements.isEmpty {
            Section {
                ForEach(Array(debrief.improvements.enumerated()), id: \.offset) { _, improvement in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.yellow)
                            .frame(width: 20)
                        Text(improvement)
                            .font(.body)
                    }
                }
            } header: {
                Label("Improvements", systemImage: "lightbulb")
                    .font(.headline)
            }

            Divider()
        }

        // Rating
        RatingView(rating: debrief.overallRating)
    }

    // MARK: - Streaming Partial Content

    @ViewBuilder
    private func streamingDebriefContent(_ partial: FlightDebrief.PartiallyGenerated) -> some View {
        if let summary = partial.narrativeSummary {
            Section {
                Text(summary)
                    .font(.body)
                    .contentTransition(.opacity)
            } header: {
                Label("Summary", systemImage: "doc.text")
                    .font(.headline)
            }

            Divider()
        }

        if let observations = partial.phaseObservations, !observations.isEmpty {
            Section {
                ForEach(Array(observations.enumerated()), id: \.offset) { _, observation in
                    streamingPhaseCard(observation)
                }
            } header: {
                Label("Phase Observations", systemImage: "list.bullet.clipboard")
                    .font(.headline)
            }

            Divider()
        }

        if let improvements = partial.improvements, !improvements.isEmpty {
            Section {
                ForEach(Array(improvements.enumerated()), id: \.offset) { _, improvement in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.yellow)
                            .frame(width: 20)
                        Text(improvement)
                            .font(.body)
                            .contentTransition(.opacity)
                    }
                }
            } header: {
                Label("Improvements", systemImage: "lightbulb")
                    .font(.headline)
            }

            Divider()
        }

        if let rating = partial.overallRating {
            RatingView(rating: rating)
        }
    }

    // MARK: - Streaming Phase Card

    @ViewBuilder
    private func streamingPhaseCard(_ partial: PhaseObservation.PartiallyGenerated) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let phase = partial.phase {
                HStack {
                    Text(phase.uppercased())
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let executedWell = partial.executedWell {
                        Image(systemName: executedWell ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(executedWell ? .green : .orange)
                    }
                }
            }

            if let observations = partial.observations {
                ForEach(Array(observations.enumerated()), id: \.offset) { _, text in
                    HStack(alignment: .top, spacing: 6) {
                        Text("\u{2022}")
                            .foregroundStyle(.secondary)
                        Text(text)
                            .font(.subheadline)
                            .contentTransition(.opacity)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.quaternary)
        )
    }

    // MARK: - Error Content

    @ViewBuilder
    private func errorContent(_ error: Error) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text("Debrief generation failed")
                .font(.headline)

            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                generateDebrief()
            } label: {
                Label("Try Again", systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.top, 32)
    }

    // MARK: - Actions

    private func generateDebrief() {
        Task {
            do {
                let prompt = try FlightSummaryBuilder.buildPrompt(
                    flightID: flightID,
                    recordingDB: recordingDB,
                    metadata: metadata
                )
                await debriefEngine.generateDebrief(
                    prompt: prompt,
                    recordingDB: recordingDB,
                    flightID: flightID
                )
            } catch {
                // FlightSummaryBuilder.buildPrompt can throw if DB read fails.
                // DebriefEngine will show error state.
            }
        }
    }

    private func regenerateDebrief() {
        // Clear existing debrief state before regenerating
        debriefEngine.discard()
        generateDebrief()
    }
}

// MARK: - PhaseObservationCard

private struct PhaseObservationCard: View {
    let observation: PhaseObservation

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(observation.phase.uppercased())
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: observation.executedWell ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(observation.executedWell ? .green : .orange)
            }

            ForEach(Array(observation.observations.enumerated()), id: \.offset) { _, text in
                HStack(alignment: .top, spacing: 6) {
                    Text("\u{2022}")
                        .foregroundStyle(.secondary)
                    Text(text)
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(observation.executedWell ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
        )
    }
}

// MARK: - RatingView

private struct RatingView: View {
    let rating: Int

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .foregroundStyle(star <= rating ? .yellow : .secondary)
                        .font(.title2)
                }
            }
            Text("Rating: \(rating)/5")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
