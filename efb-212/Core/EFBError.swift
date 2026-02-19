//
//  EFBError.swift
//  efb-212
//
//  Centralized error types with user-facing messages.
//  Conforms to LocalizedError for SwiftUI alert integration
//  and Identifiable for .alert(item:) usage.
//

import Foundation

enum EFBError: LocalizedError, Identifiable {

    // GPS / Location
    case gpsUnavailable

    // Charts
    case chartExpired(Date)
    case chartDownloadFailed(String)
    case chartCorrupted(String)

    // Weather
    case weatherStale(TimeInterval)
    case weatherFetchFailed(underlying: Error)

    // Recording
    case recordingFailed(underlying: Error)

    // Database
    case databaseCorrupted
    case databaseMigrationFailed(underlying: Error)

    // NASR Import
    case nasrImportFailed(underlying: Error)

    // TFR
    case tfrFetchFailed(underlying: Error)

    // Network
    case networkUnavailable

    // Aviation Data
    case airportNotFound(String)

    // MARK: - Identifiable

    var id: String {
        switch self {
        case .gpsUnavailable:
            return "gpsUnavailable"
        case .chartExpired(let date):
            return "chartExpired-\(date.timeIntervalSince1970)"
        case .chartDownloadFailed(let region):
            return "chartDownloadFailed-\(region)"
        case .chartCorrupted(let region):
            return "chartCorrupted-\(region)"
        case .weatherStale(let age):
            return "weatherStale-\(age)"
        case .weatherFetchFailed:
            return "weatherFetchFailed"
        case .recordingFailed:
            return "recordingFailed"
        case .databaseCorrupted:
            return "databaseCorrupted"
        case .databaseMigrationFailed:
            return "databaseMigrationFailed"
        case .nasrImportFailed:
            return "nasrImportFailed"
        case .tfrFetchFailed:
            return "tfrFetchFailed"
        case .networkUnavailable:
            return "networkUnavailable"
        case .airportNotFound(let icao):
            return "airportNotFound-\(icao)"
        }
    }

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .gpsUnavailable:
            return "GPS is unavailable. Ensure Location Services are enabled for this app."

        case .chartExpired(let date):
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "Chart expired on \(formatter.string(from: date)). Download the latest chart for current navigation data."

        case .chartDownloadFailed(let region):
            return "Failed to download chart for \(region). Check your network connection and try again."

        case .chartCorrupted(let region):
            return "Chart data for \(region) is corrupted. Delete and re-download the chart."

        case .weatherStale(let age):
            let minutes = Int(age / 60)
            return "Weather data is \(minutes) minutes old and may be unreliable. Refresh when possible."

        case .weatherFetchFailed(let underlying):
            return "Unable to fetch weather: \(underlying.localizedDescription)"

        case .recordingFailed(let underlying):
            return "Flight recording error: \(underlying.localizedDescription)"

        case .databaseCorrupted:
            return "Aviation database is corrupted. Re-import NASR data from Settings."

        case .databaseMigrationFailed(let underlying):
            return "Database migration failed: \(underlying.localizedDescription). Please reinstall the app or contact support."

        case .nasrImportFailed(let underlying):
            return "NASR data import failed: \(underlying.localizedDescription). Try again or download a fresh data set."

        case .tfrFetchFailed(let underlying):
            return "Unable to fetch TFR data: \(underlying.localizedDescription)"

        case .networkUnavailable:
            return "No network connection. Weather and chart downloads are unavailable."

        case .airportNotFound(let icao):
            return "Airport \"\(icao)\" not found in the database. Verify the identifier or update your aviation data."
        }
    }

    // MARK: - Severity

    var severity: ErrorSeverity {
        switch self {
        case .gpsUnavailable:
            return .critical
        case .chartExpired:
            return .warning
        case .chartDownloadFailed:
            return .error
        case .chartCorrupted:
            return .error
        case .weatherStale:
            return .warning
        case .weatherFetchFailed:
            return .error
        case .recordingFailed:
            return .error
        case .databaseCorrupted:
            return .critical
        case .databaseMigrationFailed:
            return .critical
        case .nasrImportFailed:
            return .error
        case .tfrFetchFailed:
            return .warning
        case .networkUnavailable:
            return .warning
        case .airportNotFound:
            return .info
        }
    }
}
