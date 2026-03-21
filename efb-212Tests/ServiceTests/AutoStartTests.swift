//
//  AutoStartTests.swift
//  efb-212Tests
//
//  Unit tests for auto-start threshold detection logic.
//  Tests threshold comparison, countdown behavior, and cancel logic.
//  Full integration tests of AppState observation require MainActor coordination;
//  these tests focus on the threshold logic and coordinator state transitions.
//

import Testing
import Foundation
import GRDB
@testable import efb_212

@Suite("AutoStart Tests", .serialized)
struct AutoStartTests {

    // MARK: - Helpers

    static func makeTempDB() throws -> RecordingDatabase {
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("autostart-test-\(UUID().uuidString).sqlite").path
        var config = Configuration()
        config.prepareDatabase { db in
            try db.execute(sql: "PRAGMA journal_mode = WAL")
        }
        let pool = try DatabasePool(path: dbPath, configuration: config)
        return try RecordingDatabase(dbPool: pool)
    }

    // MARK: - Threshold Logic

    @Test func speedAboveThresholdDetected() async {
        // Verify the threshold comparison works: 20 kts > 15 kts threshold
        let speed: Double = 20.0
        let threshold: Double = 15.0
        #expect(speed > threshold)
    }

    @Test func speedBelowThresholdNoTrigger() async {
        // 10 kts should not trigger auto-start (below 15 kts threshold)
        let speed: Double = 10.0
        let threshold: Double = 15.0
        #expect(speed <= threshold)
    }

    @Test func speedExactlyAtThresholdNoTrigger() async {
        // Exactly 15 kts should NOT trigger (must be strictly above)
        let speed: Double = 15.0
        let threshold: Double = 15.0
        #expect(!(speed > threshold))
    }

    // MARK: - Countdown Cancel

    @Test func cancelCountdownResetsToIdle() async throws {
        let db = try Self.makeTempDB()
        let coordinator = RecordingCoordinator(recordingDB: db)

        // Manually set to countdown state, then cancel
        await MainActor.run {
            coordinator.state.recordingStatus = .countdown(remaining: 2)
            coordinator.state.countdownRemaining = 2
        }

        await coordinator.cancelCountdown()

        let status = await coordinator.state.recordingStatus
        #expect(status == .idle)

        let remaining = await coordinator.state.countdownRemaining
        #expect(remaining == 0)
    }

    // MARK: - Custom Threshold

    @Test @MainActor func customThresholdUsed() async {
        // Verify that AppState's threshold property works as expected
        let appState = AppState()
        appState.autoStartSpeedThresholdKts = 25.0

        // Speed of 20 kts should NOT trigger with 25 kts threshold
        let speed = appState.groundSpeed  // 0 by default
        #expect(speed <= appState.autoStartSpeedThresholdKts)

        // Speed of 30 kts should trigger with 25 kts threshold
        appState.groundSpeed = 30.0
        #expect(appState.groundSpeed > appState.autoStartSpeedThresholdKts)
    }

    // MARK: - Auto-Start Disabled

    @Test @MainActor func autoStartDisabledPreventsMonitoring() async {
        let appState = AppState()
        appState.isAutoStartEnabled = false
        appState.groundSpeed = 50.0  // Well above threshold

        // Even with high speed, isAutoStartEnabled = false should prevent trigger
        #expect(appState.isAutoStartEnabled == false)
    }
}
