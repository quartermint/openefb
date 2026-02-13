//
//  EFBErrorTests.swift
//  efb-212Tests
//
//  Tests for the centralized EFBError type — descriptions, severity, identifiers.
//

import Testing
import Foundation
@testable import efb_212

@Suite("EFBError Tests")
struct EFBErrorTests {

    @Test func allErrorsHaveDescriptions() {
        let errors: [EFBError] = [
            .gpsUnavailable,
            .chartExpired(Date()),
            .chartDownloadFailed("San_Francisco"),
            .chartCorrupted("San_Francisco"),
            .weatherStale(3600),
            .weatherFetchFailed(underlying: NSError(domain: "test", code: 0)),
            .recordingFailed(underlying: NSError(domain: "test", code: 0)),
            .databaseCorrupted,
            .databaseMigrationFailed(underlying: NSError(domain: "test", code: 0)),
            .nasrImportFailed(underlying: NSError(domain: "test", code: 0)),
            .networkUnavailable,
            .airportNotFound("KXYZ"),
        ]

        for error in errors {
            #expect(error.errorDescription != nil, "Error \(error.id) should have a description")
            #expect(!error.errorDescription!.isEmpty, "Error \(error.id) description should not be empty")
        }
    }

    @Test func allErrorsHaveUniqueIDs() {
        let errors: [EFBError] = [
            .gpsUnavailable,
            .chartExpired(Date()),
            .chartDownloadFailed("test"),
            .chartCorrupted("test"),
            .weatherStale(3600),
            .weatherFetchFailed(underlying: NSError(domain: "test", code: 0)),
            .recordingFailed(underlying: NSError(domain: "test", code: 0)),
            .databaseCorrupted,
            .databaseMigrationFailed(underlying: NSError(domain: "test", code: 0)),
            .nasrImportFailed(underlying: NSError(domain: "test", code: 0)),
            .networkUnavailable,
            .airportNotFound("KXYZ"),
        ]

        for error in errors {
            #expect(!error.id.isEmpty, "Error should have a non-empty ID")
        }

        // Verify IDs are unique for distinct error cases
        let ids = errors.map(\.id)
        let uniqueIDs = Set(ids)
        #expect(uniqueIDs.count == ids.count, "All error IDs should be unique")
    }

    @Test func severityLevels() {
        // Critical severity
        #expect(EFBError.gpsUnavailable.severity == .critical)
        #expect(EFBError.databaseCorrupted.severity == .critical)
        #expect(EFBError.databaseMigrationFailed(underlying: NSError(domain: "", code: 0)).severity == .critical)

        // Warning severity
        #expect(EFBError.chartExpired(Date()).severity == .warning)
        #expect(EFBError.weatherStale(3600).severity == .warning)
        #expect(EFBError.networkUnavailable.severity == .warning)

        // Error severity
        #expect(EFBError.chartDownloadFailed("test").severity == .error)
        #expect(EFBError.chartCorrupted("test").severity == .error)
        #expect(EFBError.weatherFetchFailed(underlying: NSError(domain: "", code: 0)).severity == .error)
        #expect(EFBError.recordingFailed(underlying: NSError(domain: "", code: 0)).severity == .error)
        #expect(EFBError.nasrImportFailed(underlying: NSError(domain: "", code: 0)).severity == .error)

        // Info severity
        #expect(EFBError.airportNotFound("KXYZ").severity == .info)
    }

    @Test func errorDescriptionsContainContext() {
        // Chart expired should include date info
        let chartError = EFBError.chartExpired(Date())
        #expect(chartError.errorDescription?.contains("expired") == true)

        // Chart download should include region name
        let downloadError = EFBError.chartDownloadFailed("San_Francisco")
        #expect(downloadError.errorDescription?.contains("San_Francisco") == true)

        // Airport not found should include the ICAO code
        let airportError = EFBError.airportNotFound("KPAO")
        #expect(airportError.errorDescription?.contains("KPAO") == true)

        // Weather stale should include minutes
        let weatherError = EFBError.weatherStale(3600)
        #expect(weatherError.errorDescription?.contains("60") == true)
    }

    @Test func errorIDsIncludeAssociatedValues() {
        let chartError = EFBError.chartDownloadFailed("San_Francisco")
        #expect(chartError.id.contains("San_Francisco"))

        let airportError = EFBError.airportNotFound("KPAO")
        #expect(airportError.id.contains("KPAO"))
    }
}
