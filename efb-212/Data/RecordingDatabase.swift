//
//  RecordingDatabase.swift
//  efb-212
//
//  GRDB-backed recording database for high-frequency flight data.
//  Stores track points (1Hz GPS), transcript segments, and phase markers.
//  Separate from aviation.sqlite -- located at Application Support/efb-212/recording.sqlite.
//
//  Uses DatabasePool with WAL mode for concurrent reads during recording.
//  Marked @unchecked Sendable because DatabasePool is inherently thread-safe.
//

import Foundation
import GRDB

// MARK: - Track Point Record

struct TrackPointRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    static let databaseTableName = "track_points"

    let id: UUID
    let flightID: UUID
    let timestamp: Date
    let latitude: Double          // degrees
    let longitude: Double         // degrees
    let altitudeFeet: Double      // feet MSL
    let groundSpeedKnots: Double  // knots
    let verticalSpeedFPM: Double  // feet per minute
    let courseDegrees: Double     // degrees true

    nonisolated init(
        id: UUID = UUID(),
        flightID: UUID,
        timestamp: Date = Date(),
        latitude: Double,
        longitude: Double,
        altitudeFeet: Double,
        groundSpeedKnots: Double,
        verticalSpeedFPM: Double,
        courseDegrees: Double
    ) {
        self.id = id
        self.flightID = flightID
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.altitudeFeet = altitudeFeet
        self.groundSpeedKnots = groundSpeedKnots
        self.verticalSpeedFPM = verticalSpeedFPM
        self.courseDegrees = courseDegrees
    }
}

// MARK: - Transcript Segment Record

struct TranscriptSegmentRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    static let databaseTableName = "transcript_segments"

    let id: UUID
    let flightID: UUID
    let timestamp: Date
    let text: String
    let confidence: Double         // 0.0-1.0
    let audioStartTime: TimeInterval
    let audioEndTime: TimeInterval
    let flightPhase: String        // FlightPhaseType raw value

    nonisolated init(
        id: UUID = UUID(),
        flightID: UUID,
        timestamp: Date = Date(),
        text: String,
        confidence: Double,
        audioStartTime: TimeInterval,
        audioEndTime: TimeInterval,
        flightPhase: String
    ) {
        self.id = id
        self.flightID = flightID
        self.timestamp = timestamp
        self.text = text
        self.confidence = confidence
        self.audioStartTime = audioStartTime
        self.audioEndTime = audioEndTime
        self.flightPhase = flightPhase
    }
}

// MARK: - Phase Marker Record

struct PhaseMarkerRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    static let databaseTableName = "phase_markers"

    let id: UUID
    let flightID: UUID
    let phase: String              // FlightPhaseType raw value
    let startTimestamp: Date
    var endTimestamp: Date?
    let latitude: Double           // degrees
    let longitude: Double          // degrees

    nonisolated init(
        id: UUID = UUID(),
        flightID: UUID,
        phase: String,
        startTimestamp: Date = Date(),
        endTimestamp: Date? = nil,
        latitude: Double,
        longitude: Double
    ) {
        self.id = id
        self.flightID = flightID
        self.phase = phase
        self.startTimestamp = startTimestamp
        self.endTimestamp = endTimestamp
        self.latitude = latitude
        self.longitude = longitude
    }
}

// MARK: - Recording Database

final class RecordingDatabase: @unchecked Sendable {

    let dbPool: DatabasePool

    // MARK: - Production Initialization

    /// Initialize with the default recording database location.
    /// Database file: Application Support/efb-212/recording.sqlite
    nonisolated init() throws {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dbDir = appSupport.appendingPathComponent("efb-212", isDirectory: true)
        let dbPath = dbDir.appendingPathComponent("recording.sqlite")

        if !fileManager.fileExists(atPath: dbDir.path) {
            try fileManager.createDirectory(at: dbDir, withIntermediateDirectories: true)
        }

        var config = Configuration()
        config.prepareDatabase { db in
            try db.execute(sql: "PRAGMA journal_mode = WAL")
        }
        let pool = try DatabasePool(path: dbPath.path, configuration: config)
        self.dbPool = pool
        try Self.migrate(dbPool: pool)
    }

    /// Initialize with a specific database pool (for testing).
    nonisolated init(dbPool: DatabasePool) throws {
        self.dbPool = dbPool
        try Self.migrate(dbPool: dbPool)
    }

    // MARK: - Migration

    private nonisolated static func migrate(dbPool: DatabasePool) throws {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1") { db in
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS track_points (
                    id TEXT PRIMARY KEY,
                    flightID TEXT NOT NULL,
                    timestamp REAL NOT NULL,
                    latitude REAL NOT NULL,
                    longitude REAL NOT NULL,
                    altitudeFeet REAL NOT NULL,
                    groundSpeedKnots REAL NOT NULL,
                    verticalSpeedFPM REAL NOT NULL,
                    courseDegrees REAL NOT NULL
                )
                """)
            try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_track_points_flight ON track_points(flightID)")

            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS transcript_segments (
                    id TEXT PRIMARY KEY,
                    flightID TEXT NOT NULL,
                    timestamp REAL NOT NULL,
                    text TEXT NOT NULL,
                    confidence REAL NOT NULL,
                    audioStartTime REAL NOT NULL,
                    audioEndTime REAL NOT NULL,
                    flightPhase TEXT NOT NULL
                )
                """)
            try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_transcript_segments_flight ON transcript_segments(flightID)")

            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS phase_markers (
                    id TEXT PRIMARY KEY,
                    flightID TEXT NOT NULL,
                    phase TEXT NOT NULL,
                    startTimestamp REAL NOT NULL,
                    endTimestamp REAL,
                    latitude REAL NOT NULL,
                    longitude REAL NOT NULL
                )
                """)
            try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_phase_markers_flight ON phase_markers(flightID)")
        }
        try migrator.migrate(dbPool)
    }

    // MARK: - Track Point CRUD

    /// Insert a single track point (1Hz GPS data).
    nonisolated func insertTrackPoint(_ point: TrackPointRecord) throws {
        try dbPool.write { db in
            try point.insert(db)
        }
    }

    /// Retrieve all track points for a flight, ordered by timestamp.
    nonisolated func trackPoints(forFlight flightID: UUID) throws -> [TrackPointRecord] {
        try dbPool.read { db in
            try TrackPointRecord
                .filter(Column("flightID") == flightID.uuidString)
                .order(Column("timestamp"))
                .fetchAll(db)
        }
    }

    // MARK: - Transcript Segment CRUD

    /// Insert a single transcript segment (only isFinal segments).
    nonisolated func insertTranscript(_ segment: TranscriptSegmentRecord) throws {
        try dbPool.write { db in
            try segment.insert(db)
        }
    }

    /// Retrieve all transcript segments for a flight, ordered by timestamp.
    nonisolated func transcriptSegments(forFlight flightID: UUID) throws -> [TranscriptSegmentRecord] {
        try dbPool.read { db in
            try TranscriptSegmentRecord
                .filter(Column("flightID") == flightID.uuidString)
                .order(Column("timestamp"))
                .fetchAll(db)
        }
    }

    // MARK: - Phase Marker CRUD

    /// Insert a new phase marker when a flight phase transition occurs.
    nonisolated func insertPhaseMarker(_ marker: PhaseMarkerRecord) throws {
        try dbPool.write { db in
            try marker.insert(db)
        }
    }

    /// Close the current phase marker by setting its end timestamp.
    nonisolated func updatePhaseMarkerEnd(id: UUID, endTimestamp: Date) throws {
        try dbPool.write { db in
            try db.execute(
                sql: "UPDATE phase_markers SET endTimestamp = ? WHERE id = ?",
                arguments: [endTimestamp.timeIntervalSinceReferenceDate, id.uuidString]
            )
        }
    }

    /// Retrieve all phase markers for a flight, ordered by start timestamp.
    nonisolated func phaseMarkers(forFlight flightID: UUID) throws -> [PhaseMarkerRecord] {
        try dbPool.read { db in
            try PhaseMarkerRecord
                .filter(Column("flightID") == flightID.uuidString)
                .order(Column("startTimestamp"))
                .fetchAll(db)
        }
    }

    // MARK: - Deletion

    /// Delete all recording data for a specific flight (track points, transcripts, phase markers).
    nonisolated func deleteFlightData(flightID: UUID) throws {
        try dbPool.write { db in
            try db.execute(sql: "DELETE FROM track_points WHERE flightID = ?", arguments: [flightID.uuidString])
            try db.execute(sql: "DELETE FROM transcript_segments WHERE flightID = ?", arguments: [flightID.uuidString])
            try db.execute(sql: "DELETE FROM phase_markers WHERE flightID = ?", arguments: [flightID.uuidString])
        }
    }
}
