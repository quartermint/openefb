//
//  FlightSummaryBuilder.swift
//  efb-212
//
//  Token-budgeted flight data compression for Foundation Models debrief generation.
//  Compresses GPS track points, transcript segments, and phase markers into a
//  structured prompt under 3,000 tokens (~12,600 characters at 4.2 chars/token).
//
//  Compression strategy:
//  - Group data by flight phase (from phase_markers table)
//  - Per phase: compute summary stats (avg altitude, avg speed, duration)
//  - Per phase: select top 3 transcript segments by confidence (excluding interruptions)
//  - Cap each phase summary at ~250 tokens (1,050 characters)
//  - Flight metadata header capped at ~300 tokens (1,260 characters)
//

import Foundation

struct FlightSummaryBuilder {

    // MARK: - Token Budget Constants

    /// Maximum characters for the combined flight summary (~3,000 tokens at 4.2 chars/token).
    static let maxSummaryChars = 12_600

    /// Maximum characters per phase summary (~250 tokens).
    static let perPhaseCharBudget = 1_050

    /// Maximum characters for flight metadata header (~300 tokens).
    static let metadataCharBudget = 1_260

    // MARK: - Build Prompt (Database-backed)

    /// Build a token-budgeted prompt from flight recording data stored in RecordingDatabase.
    /// Fetches track points, transcripts, and phase markers from GRDB and delegates to the
    /// data-backed overload for compression.
    static func buildPrompt(
        flightID: UUID,
        recordingDB: RecordingDatabase,
        metadata: FlightMetadata
    ) throws -> String {
        let phaseMarkers = try recordingDB.phaseMarkers(forFlight: flightID)
        let trackPoints = try recordingDB.trackPoints(forFlight: flightID)
        let transcripts = try recordingDB.transcriptSegments(forFlight: flightID)

        return buildPrompt(
            trackPoints: trackPoints,
            transcriptSegments: transcripts,
            phaseMarkers: phaseMarkers,
            metadata: metadata
        )
    }

    // MARK: - Build Prompt (Data-backed, testable)

    /// Build a token-budgeted prompt from flight data arrays.
    /// Testable overload that accepts data directly without database dependency.
    static func buildPrompt(
        trackPoints: [TrackPointRecord],
        transcriptSegments: [TranscriptSegmentRecord],
        phaseMarkers: [PhaseMarkerRecord],
        metadata: FlightMetadata
    ) -> String {
        // Build metadata header, truncate to budget
        var metadataHeader = metadata.description
        if metadataHeader.count > metadataCharBudget {
            metadataHeader = String(metadataHeader.prefix(metadataCharBudget - 3)) + "..."
        }

        // Build per-phase summaries
        var phaseSummaries: [String] = []
        for phase in phaseMarkers {
            let phasePoints = trackPoints.filter { point in
                point.timestamp >= phase.startTimestamp &&
                (phase.endTimestamp == nil || point.timestamp <= phase.endTimestamp!)
            }
            let phaseTranscripts = transcriptSegments.filter { seg in
                seg.flightPhase == phase.phase
            }

            let summary = summarizePhase(
                phase: phase,
                trackPoints: phasePoints,
                transcripts: phaseTranscripts
            )
            phaseSummaries.append(summary)
        }

        // Combine into prompt
        var prompt = "Analyze this flight and provide a structured debrief.\n\nFlight: \(metadataHeader)\n\n\(phaseSummaries.joined(separator: "\n\n"))"

        // If total exceeds budget, proportionally trim phase summaries
        if prompt.count > maxSummaryChars {
            let overhead = prompt.count - maxSummaryChars
            let trimPerPhase = phaseSummaries.isEmpty ? 0 : (overhead / phaseSummaries.count) + 1
            let newBudget = max(100, perPhaseCharBudget - trimPerPhase)

            phaseSummaries = phaseMarkers.enumerated().map { index, phase in
                let phasePoints = trackPoints.filter { point in
                    point.timestamp >= phase.startTimestamp &&
                    (phase.endTimestamp == nil || point.timestamp <= phase.endTimestamp!)
                }
                let phaseTranscripts = transcriptSegments.filter { seg in
                    seg.flightPhase == phase.phase
                }

                var summary = summarizePhaseRaw(
                    phase: phase,
                    trackPoints: phasePoints,
                    transcripts: phaseTranscripts
                )
                if summary.count > newBudget {
                    summary = String(summary.prefix(newBudget - 3)) + "..."
                }
                return summary
            }

            prompt = "Analyze this flight and provide a structured debrief.\n\nFlight: \(metadataHeader)\n\n\(phaseSummaries.joined(separator: "\n\n"))"
        }

        return prompt
    }

    // MARK: - Phase Summary

    /// Summarize a single flight phase within the per-phase character budget.
    /// Computes average altitude, speed, duration. Selects top 3 transcripts by confidence.
    /// Excludes interruption gap markers from transcript selection.
    static func summarizePhase(
        phase: PhaseMarkerRecord,
        trackPoints: [TrackPointRecord],
        transcripts: [TranscriptSegmentRecord]
    ) -> String {
        var summary = summarizePhaseRaw(
            phase: phase,
            trackPoints: trackPoints,
            transcripts: transcripts
        )

        // Truncate to budget
        if summary.count > perPhaseCharBudget {
            summary = String(summary.prefix(perPhaseCharBudget - 3)) + "..."
        }

        return summary
    }

    // MARK: - Private

    /// Build phase summary without truncation (for proportional trimming in buildPrompt).
    private static func summarizePhaseRaw(
        phase: PhaseMarkerRecord,
        trackPoints: [TrackPointRecord],
        transcripts: [TranscriptSegmentRecord]
    ) -> String {
        // Compute summary statistics
        let avgAlt = trackPoints.isEmpty ? 0.0 :
            trackPoints.map(\.altitudeFeet).reduce(0, +) / Double(trackPoints.count)
        let avgSpeed = trackPoints.isEmpty ? 0.0 :
            trackPoints.map(\.groundSpeedKnots).reduce(0, +) / Double(trackPoints.count)
        let duration = phase.endTimestamp.map { $0.timeIntervalSince(phase.startTimestamp) } ?? 0

        // Select top 3 transcript segments by confidence, excluding interruption markers
        let topTranscripts = transcripts
            .filter { !$0.text.hasPrefix("[INTERRUPTION:") }
            .sorted { $0.confidence > $1.confidence }
            .prefix(3)
            .map(\.text)

        var summary = "[\(phase.phase.uppercased())] Duration: \(Int(duration))s, Avg Alt: \(Int(avgAlt))ft, Avg GS: \(Int(avgSpeed))kts"

        if !topTranscripts.isEmpty {
            summary += "\nComms: " + topTranscripts.joined(separator: " | ")
        }

        return summary
    }
}
