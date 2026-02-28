//
//  FAALookupService.swift
//  efb-212
//
//  Fetches aircraft registration data from the FAA N-number registry.
//  Parses the HTML response to extract manufacturer, model, year, and engine info.
//

import Foundation

// MARK: - FAA Lookup Error

struct FAALookupError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

// MARK: - FAA Lookup Result

struct FAALookupResult {
    let manufacturer: String        // e.g., "GRUMMAN AMERICAN AVN. CORP."
    let model: String               // e.g., "AA-5B"
    let yearManufactured: String?   // e.g., "1979"
    let serialNumber: String?       // e.g., "AA5B1302"
    let aircraftType: String?       // e.g., "Fixed Wing Single-Engine"
    let engineManufacturer: String? // e.g., "LYCOMING"
    let engineModel: String?        // e.g., "O&VO-360 SER"
    let engineType: String?         // e.g., "Reciprocating"

    /// Formatted display string: "AA-5B Tiger" style
    var displayType: String {
        let mfr = manufacturer.trimmingCharacters(in: .whitespaces)
        let mdl = model.trimmingCharacters(in: .whitespaces)

        // Use just model if manufacturer is verbose
        if mdl.isEmpty { return mfr }
        return mdl
    }
}

// MARK: - FAA Lookup Service

final class FAALookupService {

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Look up an aircraft by N-number from the FAA registry.
    /// - Parameter nNumber: N-number with or without "N" prefix (e.g., "N4543A" or "4543A").
    /// - Returns: Parsed registration data.
    func lookup(nNumber: String) async throws -> FAALookupResult {
        // Strip "N" prefix for the FAA query parameter
        let stripped = nNumber.uppercased().hasPrefix("N")
            ? String(nNumber.uppercased().dropFirst())
            : nNumber.uppercased()

        guard !stripped.isEmpty else {
            throw FAALookupError(message:"Empty N-number")
        }

        guard let url = URL(string: "https://registry.faa.gov/AircraftInquiry/Search/NNumberResult?NNumberTxt=\(stripped)") else {
            throw FAALookupError(message:"Invalid URL for N-number lookup")
        }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw FAALookupError(message:"FAA registry returned an error")
        }

        guard let html = String(data: data, encoding: .utf8) else {
            throw FAALookupError(message:"Could not decode FAA response")
        }

        return try parse(html: html)
    }

    // MARK: - HTML Parsing

    /// Parse FAA registry HTML to extract aircraft data.
    /// Fields are in `<td data-label="Field Name">value</td>` format.
    private func parse(html: String) throws -> FAALookupResult {
        let manufacturer = extractField("Manufacturer Name", from: html)
        let model = extractField("Model", from: html)

        guard let manufacturer, let model else {
            throw FAALookupError(message:"Aircraft not found in FAA registry")
        }

        return FAALookupResult(
            manufacturer: manufacturer,
            model: model,
            yearManufactured: extractField("Mfr Year", from: html),
            serialNumber: extractField("Serial Number", from: html),
            aircraftType: extractField("Aircraft Type", from: html),
            engineManufacturer: extractField("Engine Manufacturer", from: html),
            engineModel: extractField("Engine Model", from: html),
            engineType: extractField("Engine Type", from: html)
        )
    }

    /// Extract a field value from the FAA HTML using the data-label attribute.
    /// Matches: `<td data-label="Field Name">value</td>`
    private func extractField(_ label: String, from html: String) -> String? {
        // Pattern: data-label="Label">VALUE</td>
        let pattern = "data-label=\"\(NSRegularExpression.escapedPattern(for: label))\">([^<]+)</td>"

        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }

        let range = NSRange(html.startIndex..., in: html)
        guard let match = regex.firstMatch(in: html, range: range),
              let valueRange = Range(match.range(at: 1), in: html) else {
            return nil
        }

        let value = String(html[valueRange]).trimmingCharacters(in: .whitespacesAndNewlines)

        // FAA sometimes pads values with spaces and returns "None" for empty fields
        if value.isEmpty || value == "None" { return nil }
        return value
    }
}
