//
//  DebriefEngine.swift
//  efb-212
//
//  Manages LanguageModelSession lifecycle for on-device AI flight debrief generation.
//  Handles availability checking, session prewarm, streaming generation via
//  streamResponse(to:generating:), and debrief persistence to GRDB.
//
//  Lifecycle: checkAvailability -> prewarm (on view appear) -> generateDebrief -> discard (on view dismiss)
//
//  Memory note: Foundation Models loads ~1.2 GB into memory. Session is created only when
//  pilot taps "Debrief" and discarded immediately on view dismiss. Never kept alive globally.
//

import Foundation
import FoundationModels
import os

// MARK: - DebriefEngine

@Observable
@MainActor
final class DebriefEngine {

    // MARK: - Published State

    /// Streaming partial debrief output for progressive UI rendering.
    private(set) var partialDebrief: FlightDebrief.PartiallyGenerated?

    /// Final completed debrief after generation stream finishes.
    private(set) var completedDebrief: FlightDebrief?

    /// Whether generation is currently in progress.
    private(set) var isGenerating: Bool = false

    /// Error from last generation attempt, if any.
    private(set) var error: Error?

    /// Current availability status of Foundation Models on this device.
    private(set) var availabilityStatus: AvailabilityStatus = .unknown

    // MARK: - Availability Status

    /// Testable availability status enum with user-friendly reason mapping.
    /// The `reasonMessage(for:)` static method extracts reason-to-message mapping
    /// so it can be unit tested without requiring a real Foundation Models runtime.
    enum AvailabilityStatus: Equatable, Sendable {
        case unknown
        case available
        case unavailable(reason: String)

        /// Maps a Foundation Models unavailable reason description to a user-friendly string.
        /// Extracted as a static method so it can be unit tested without a real device.
        static func reasonMessage(for reasonDescription: String) -> String {
            if reasonDescription.contains("deviceNotEligible") || reasonDescription.contains("not eligible") {
                return "This device does not support Apple Intelligence."
            } else if reasonDescription.contains("appleIntelligenceNotEnabled") || reasonDescription.contains("not enabled") {
                return "Apple Intelligence is not enabled. You can enable it in Settings."
            } else if reasonDescription.contains("modelNotReady") || reasonDescription.contains("not ready") {
                return "Apple Intelligence is still setting up. Please try again later."
            } else {
                return "AI Debrief is currently unavailable."
            }
        }
    }

    // MARK: - Private Properties

    private var session: LanguageModelSession?
    private let logger = Logger(subsystem: "quartermint.efb-212", category: "DebriefEngine")

    /// System prompt for the debrief generation session.
    static let systemPrompt = """
        You are an experienced flight instructor reviewing a student pilot's VFR flight. \
        Provide constructive, specific feedback based on the flight data. \
        Focus on safety, decision-making, and technique. \
        Be encouraging but honest about areas for improvement.
        """

    // MARK: - Availability

    /// Check Foundation Models availability on this device.
    /// Updates `availabilityStatus` based on `SystemLanguageModel.default.availability`.
    func checkAvailability() {
        let model = SystemLanguageModel.default

        switch model.availability {
        case .available:
            availabilityStatus = .available
            logger.info("Foundation Models available")

        case .unavailable(let reason):
            let reasonStr = String(describing: reason)
            let message = AvailabilityStatus.reasonMessage(for: reasonStr)
            availabilityStatus = .unavailable(reason: message)
            logger.warning("Foundation Models unavailable: \(message)")

        @unknown default:
            availabilityStatus = .unavailable(reason: "AI Debrief is currently unavailable.")
            logger.warning("Foundation Models unknown availability state")
        }
    }

    // MARK: - Session Management

    /// Prewarm the language model session for faster first response.
    /// Call on FlightDetailView.onAppear to start model loading.
    func prewarm() {
        guard availabilityStatus == .available else {
            logger.info("Skipping prewarm: Foundation Models not available")
            return
        }

        session = LanguageModelSession(instructions: Self.systemPrompt)
        logger.info("DebriefEngine session created and prewarming")
    }

    /// Generate a debrief from the given prompt text.
    /// Streams partial results to `partialDebrief` for progressive UI rendering.
    /// On completion, saves the debrief to GRDB via `recordingDB.insertDebrief`.
    ///
    /// - Parameters:
    ///   - prompt: The token-budgeted flight summary prompt from FlightSummaryBuilder.
    ///   - recordingDB: The recording database for persisting the debrief result.
    ///   - flightID: The flight ID to associate the debrief with.
    func generateDebrief(
        prompt: String,
        recordingDB: RecordingDatabase,
        flightID: UUID
    ) async {
        // Create session if nil (fallback in case prewarm was not called)
        if session == nil {
            session = LanguageModelSession(instructions: Self.systemPrompt)
        }

        guard let session else {
            error = EFBError.debriefFailed(underlying: DebriefError.sessionUnavailable)
            return
        }

        isGenerating = true
        error = nil
        partialDebrief = nil
        completedDebrief = nil

        defer { isGenerating = false }

        do {
            // Stream partial results for progressive UI rendering
            let stream = session.streamResponse(
                to: prompt,
                generating: FlightDebrief.self
            )

            for try await partial in stream {
                self.partialDebrief = partial.content
            }

            // After streaming completes, use respond() for the final typed object.
            // This makes a second generation call but ensures we get a fully typed
            // FlightDebrief for persistence. The session transcript helps context.
            let response = try await session.respond(
                to: prompt,
                generating: FlightDebrief.self
            )
            let debrief = response.content

            completedDebrief = debrief

            // Persist to GRDB
            let record = DebriefRecord.fromFlightDebrief(
                debrief,
                flightID: flightID,
                promptTokensEstimate: nil,
                responseTokensEstimate: nil
            )
            try recordingDB.insertDebrief(record)
            logger.info("Debrief generated and saved for flight \(flightID.uuidString)")
        } catch {
            self.error = error
            logger.error("Debrief generation failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Load Existing

    /// Load an existing debrief from GRDB for display (no generation needed).
    /// Reconstructs FlightDebrief from DebriefRecord fields.
    func loadExistingDebrief(recordingDB: RecordingDatabase, flightID: UUID) {
        do {
            guard let record = try recordingDB.debrief(forFlight: flightID) else {
                logger.info("No existing debrief for flight \(flightID.uuidString)")
                return
            }

            // Reconstruct FlightDebrief from stored fields
            let phases = record.decodedPhaseObservations
            let improvements = record.decodedImprovements

            completedDebrief = FlightDebrief(
                narrativeSummary: record.narrativeSummary,
                phaseObservations: phases,
                improvements: improvements,
                overallRating: record.overallRating
            )
            logger.info("Loaded existing debrief for flight \(flightID.uuidString)")
        } catch {
            self.error = error
            logger.error("Failed to load existing debrief: \(error.localizedDescription)")
        }
    }

    // MARK: - Cleanup

    /// Discard the session and all debrief state.
    /// Call on FlightDetailView.onDisappear to free ~1.2 GB of model memory.
    func discard() {
        session = nil
        partialDebrief = nil
        completedDebrief = nil
        error = nil
        logger.info("DebriefEngine discarded")
    }
}

// MARK: - Debrief Errors

enum DebriefError: LocalizedError, Sendable {
    case sessionUnavailable
    case generationFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .sessionUnavailable:
            return "AI debrief session is not available. Please check Apple Intelligence settings."
        case .generationFailed(let error):
            return "Debrief generation failed: \(error.localizedDescription)"
        }
    }
}
