//
//  PrivacyManifestTests.swift
//  efb-212Tests
//
//  Validates that PrivacyInfo.xcprivacy contains all required Apple privacy
//  declarations for App Store Connect / TestFlight submission.
//  Reads the manifest from the project source directory via #filePath.
//

import Testing
import Foundation

@Suite("Privacy Manifest Validation")
struct PrivacyManifestTests {

    // MARK: - Test Helpers

    /// Load and parse PrivacyInfo.xcprivacy from the project source directory.
    /// Uses #filePath to derive the project root, then reads efb-212/PrivacyInfo.xcprivacy.
    private func loadPrivacyManifest() throws -> [String: Any] {
        // #filePath gives: .../efb-212Tests/PrivacyManifestTests.swift
        // Navigate up to project root: efb-212Tests/ -> project root
        let testFilePath = URL(fileURLWithPath: #filePath)
        let projectRoot = testFilePath
            .deletingLastPathComponent()  // Remove PrivacyManifestTests.swift
            .deletingLastPathComponent()  // Remove efb-212Tests/
        let manifestPath = projectRoot
            .appendingPathComponent("efb-212")
            .appendingPathComponent("PrivacyInfo.xcprivacy")

        let data = try Data(contentsOf: manifestPath)
        let plist = try PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: nil
        )
        guard let dict = plist as? [String: Any] else {
            throw ManifestError.invalidFormat
        }
        return dict
    }

    private enum ManifestError: Error {
        case invalidFormat
    }

    // MARK: - Tests

    @Test("PrivacyInfo.xcprivacy file exists in project directory")
    func privacyManifestFileExists() throws {
        let testFilePath = URL(fileURLWithPath: #filePath)
        let projectRoot = testFilePath
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let manifestPath = projectRoot
            .appendingPathComponent("efb-212")
            .appendingPathComponent("PrivacyInfo.xcprivacy")

        #expect(FileManager.default.fileExists(atPath: manifestPath.path))
    }

    @Test("NSPrivacyTracking is set to false")
    func noTracking() throws {
        let manifest = try loadPrivacyManifest()

        guard let tracking = manifest["NSPrivacyTracking"] as? Bool else {
            Issue.record("NSPrivacyTracking key missing or not a boolean")
            return
        }
        #expect(tracking == false)
    }

    @Test("NSPrivacyTrackingDomains is present and empty")
    func emptyTrackingDomains() throws {
        let manifest = try loadPrivacyManifest()

        guard let domains = manifest["NSPrivacyTrackingDomains"] as? [Any] else {
            Issue.record("NSPrivacyTrackingDomains key missing or not an array")
            return
        }
        #expect(domains.isEmpty, "Tracking domains should be empty (no tracking)")
    }

    @Test("Collected data types include PreciseLocation and AudioData")
    func collectedDataTypes() throws {
        let manifest = try loadPrivacyManifest()

        guard let collectedTypes = manifest["NSPrivacyCollectedDataTypes"] as? [[String: Any]] else {
            Issue.record("NSPrivacyCollectedDataTypes missing or not an array of dicts")
            return
        }

        #expect(collectedTypes.count == 2, "Should declare exactly 2 collected data types")

        let dataTypeNames = collectedTypes.compactMap {
            $0["NSPrivacyCollectedDataType"] as? String
        }
        #expect(dataTypeNames.contains("NSPrivacyCollectedDataTypePreciseLocation"),
                "Must declare precise location collection")
        #expect(dataTypeNames.contains("NSPrivacyCollectedDataTypeAudioData"),
                "Must declare audio data collection")

        // Verify neither is used for tracking
        for entry in collectedTypes {
            let isTracking = entry["NSPrivacyCollectedDataTypeTracking"] as? Bool
            #expect(isTracking == false,
                    "Collected data type should not be used for tracking")

            let isLinked = entry["NSPrivacyCollectedDataTypeLinked"] as? Bool
            #expect(isLinked == false,
                    "Collected data type should not be linked to identity")

            guard let purposes = entry["NSPrivacyCollectedDataTypePurposes"] as? [String] else {
                Issue.record("Missing purposes array for collected data type")
                continue
            }
            #expect(purposes.contains("NSPrivacyCollectedDataTypePurposeAppFunctionality"),
                    "Purpose should be app functionality")
        }
    }

    @Test("Accessed API types include UserDefaults with CA92.1 reason")
    func accessedAPITypes() throws {
        let manifest = try loadPrivacyManifest()

        guard let apiTypes = manifest["NSPrivacyAccessedAPITypes"] as? [[String: Any]] else {
            Issue.record("NSPrivacyAccessedAPITypes missing or not an array of dicts")
            return
        }

        #expect(apiTypes.count == 1, "Should declare exactly 1 accessed API type")

        guard let firstAPI = apiTypes.first else {
            Issue.record("No API type entries found")
            return
        }

        let apiType = firstAPI["NSPrivacyAccessedAPIType"] as? String
        #expect(apiType == "NSPrivacyAccessedAPICategoryUserDefaults",
                "Must declare UserDefaults API access")

        guard let reasons = firstAPI["NSPrivacyAccessedAPITypeReasons"] as? [String] else {
            Issue.record("Missing reasons array for UserDefaults API")
            return
        }
        #expect(reasons.contains("CA92.1"),
                "UserDefaults reason must include CA92.1 (app's own defaults)")
    }
}
