//
//  AviationVocabulary.swift
//  efb-212
//
//  Regex-based aviation vocabulary post-processor.
//  Corrects common speech recognition misrecognitions for N-numbers,
//  frequencies, altitudes, headings, runways, squawk codes, and ATIS letters.
//
//  Design source: SFR AviationVocabularyProcessor (448 lines of proven patterns).
//

import Foundation

struct AviationVocabularyProcessor: Sendable {

    // MARK: - Phonetic Digit Map

    /// Maps spoken digit words to numeric characters.
    /// Includes both standard and ICAO phonetic variants.
    private static let digitMap: [String: String] = [
        "zero": "0",
        "one": "1",
        "two": "2",
        "to": "2",
        "tree": "3",
        "three": "3",
        "four": "4",
        "fower": "4",
        "fife": "5",
        "five": "5",
        "six": "6",
        "seven": "7",
        "eight": "8",
        "niner": "9",
        "nine": "9",
    ]

    /// Maps phonetic alphabet words to single letters.
    private static let phoneticAlphabet: [String: String] = [
        "alfa": "A", "alpha": "A",
        "bravo": "B",
        "charlie": "C",
        "delta": "D",
        "echo": "E",
        "foxtrot": "F",
        "golf": "G",
        "hotel": "H",
        "india": "I",
        "juliet": "J",
        "kilo": "K",
        "lima": "L",
        "mike": "M",
        "november": "N",
        "oscar": "O",
        "papa": "P",
        "quebec": "Q",
        "romeo": "R",
        "sierra": "S",
        "tango": "T",
        "uniform": "U",
        "victor": "V",
        "whiskey": "W",
        "xray": "X", "x-ray": "X",
        "yankee": "Y",
        "zulu": "Z",
    ]

    /// Maps number words for compound numbers (thousands).
    private static let numberWords: [String: Int] = [
        "zero": 0, "one": 1, "two": 2, "three": 3, "four": 4,
        "five": 5, "six": 6, "seven": 7, "eight": 8, "nine": 9,
        "niner": 9, "ten": 10, "eleven": 11, "twelve": 12,
        "thirteen": 13, "fourteen": 14, "fifteen": 15, "sixteen": 16,
        "seventeen": 17, "eighteen": 18, "nineteen": 19,
        "twenty": 20, "thirty": 30, "forty": 40, "fifty": 50,
    ]

    // MARK: - Public API

    /// Process transcript text through aviation vocabulary corrections.
    /// Applies regex-based corrections in priority order.
    func process(_ text: String) -> String {
        var result = text.lowercased()
        result = processNNumbers(result)
        result = processFlightLevels(result)
        result = processFrequencies(result)
        result = processSquawkCodes(result)
        result = processRunways(result)
        result = processAltitudes(result)
        result = processHeadings(result)
        result = processATIS(result)
        return result
    }

    // MARK: - N-Number Processing

    /// Converts "november [phonetic/digit words]" to N-number format.
    /// e.g., "november seven three two papa" -> "N732P"
    private func processNNumbers(_ text: String) -> String {
        // Match "november" followed by 1-6 phonetic words (digits or letters)
        let pattern = #"november\s+((?:(?:zero|one|two|three|four|five|six|seven|eight|nine|niner|alfa|alpha|bravo|charlie|delta|echo|foxtrot|golf|hotel|india|juliet|kilo|lima|mike|oscar|papa|quebec|romeo|sierra|tango|uniform|victor|whiskey|xray|x-ray|yankee|zulu)\s*){1,6})"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return text
        }

        var result = text
        let range = NSRange(result.startIndex..., in: result)

        let matches = regex.matches(in: result, range: range)
        // Process in reverse to preserve indices
        for match in matches.reversed() {
            guard let tailRange = Range(match.range(at: 1), in: result) else { continue }
            let tail = String(result[tailRange])

            // Convert each word in the tail to its digit/letter
            let words = tail.split(separator: " ").map(String.init)
            var nNumber = "N"
            for word in words {
                let lower = word.lowercased().trimmingCharacters(in: .whitespaces)
                if let digit = Self.digitMap[lower] {
                    nNumber += digit
                } else if let letter = Self.phoneticAlphabet[lower] {
                    nNumber += letter
                }
            }

            guard let fullRange = Range(match.range, in: result) else { continue }
            result.replaceSubrange(fullRange, with: nNumber)
        }

        return result
    }

    // MARK: - Flight Level Processing

    /// Converts "flight level [digits]" to FL format.
    /// e.g., "flight level three five zero" -> "FL350"
    private func processFlightLevels(_ text: String) -> String {
        let digitWords = "zero|one|two|three|four|five|six|seven|eight|nine|niner"
        let pattern = #"flight\s+level\s+((?:(?:"# + digitWords + #")\s*){2,3})"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return text
        }

        var result = text
        let matches = regex.matches(in: result, range: NSRange(result.startIndex..., in: result))

        for match in matches.reversed() {
            guard let digitsRange = Range(match.range(at: 1), in: result) else { continue }
            let digitsText = String(result[digitsRange])

            let digits = digitsText.split(separator: " ")
                .compactMap { Self.digitMap[String($0).lowercased().trimmingCharacters(in: .whitespaces)] }
                .joined()

            guard let fullRange = Range(match.range, in: result) else { continue }
            result.replaceSubrange(fullRange, with: "FL\(digits)")
        }

        return result
    }

    // MARK: - Frequency Processing

    /// Converts spoken frequency to numeric format.
    /// e.g., "one two three point four five" -> "123.45"
    private func processFrequencies(_ text: String) -> String {
        let digitWords = "zero|one|two|three|four|five|six|seven|eight|nine|niner"
        let pattern = #"((?:(?:"# + digitWords + #")\s+){2,3})point\s+((?:(?:"# + digitWords + #")\s*){1,3})"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return text
        }

        var result = text
        let matches = regex.matches(in: result, range: NSRange(result.startIndex..., in: result))

        for match in matches.reversed() {
            guard let wholeRange = Range(match.range(at: 1), in: result),
                  let decimalRange = Range(match.range(at: 2), in: result) else { continue }

            let wholeText = String(result[wholeRange])
            let decimalText = String(result[decimalRange])

            let wholeDigits = wholeText.split(separator: " ")
                .compactMap { Self.digitMap[String($0).lowercased().trimmingCharacters(in: .whitespaces)] }
                .joined()

            let decimalDigits = decimalText.split(separator: " ")
                .compactMap { Self.digitMap[String($0).lowercased().trimmingCharacters(in: .whitespaces)] }
                .joined()

            guard let fullRange = Range(match.range, in: result) else { continue }
            result.replaceSubrange(fullRange, with: "\(wholeDigits).\(decimalDigits)")
        }

        return result
    }

    // MARK: - Squawk Code Processing

    /// Converts "squawk [four digits]" to numeric format.
    /// e.g., "squawk one two zero zero" -> "Squawk 1200"
    private func processSquawkCodes(_ text: String) -> String {
        let digitWords = "zero|one|two|three|four|five|six|seven|eight|nine|niner"
        let pattern = #"squawk\s+((?:(?:"# + digitWords + #")\s*){4})"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return text
        }

        var result = text
        let matches = regex.matches(in: result, range: NSRange(result.startIndex..., in: result))

        for match in matches.reversed() {
            guard let digitsRange = Range(match.range(at: 1), in: result) else { continue }
            let digitsText = String(result[digitsRange])

            let digits = digitsText.split(separator: " ")
                .compactMap { Self.digitMap[String($0).lowercased().trimmingCharacters(in: .whitespaces)] }
                .joined()

            guard let fullRange = Range(match.range, in: result) else { continue }
            result.replaceSubrange(fullRange, with: "Squawk \(digits)")
        }

        return result
    }

    // MARK: - Runway Processing

    /// Converts "runway [digits] [left/right/center]" to formatted runway.
    /// e.g., "runway two seven left" -> "Runway 27L"
    private func processRunways(_ text: String) -> String {
        let digitWords = "zero|one|two|three|four|five|six|seven|eight|nine|niner"
        let pattern = #"runway\s+((?:(?:"# + digitWords + #")\s*){1,2})\s*(left|right|center)?"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return text
        }

        var result = text
        let matches = regex.matches(in: result, range: NSRange(result.startIndex..., in: result))

        for match in matches.reversed() {
            guard let digitsRange = Range(match.range(at: 1), in: result) else { continue }
            let digitsText = String(result[digitsRange])

            let digits = digitsText.split(separator: " ")
                .compactMap { Self.digitMap[String($0).lowercased().trimmingCharacters(in: .whitespaces)] }
                .joined()

            var suffix = ""
            if match.range(at: 2).location != NSNotFound,
               let sideRange = Range(match.range(at: 2), in: result) {
                let side = String(result[sideRange]).lowercased()
                switch side {
                case "left": suffix = "L"
                case "right": suffix = "R"
                case "center": suffix = "C"
                default: break
                }
            }

            guard let fullRange = Range(match.range, in: result) else { continue }
            result.replaceSubrange(fullRange, with: "Runway \(digits)\(suffix)")
        }

        return result
    }

    // MARK: - Altitude Processing

    /// Converts spoken altitudes to numeric format with comma separators.
    /// e.g., "maintain four thousand five hundred" -> "maintain 4,500"
    private func processAltitudes(_ text: String) -> String {
        let pattern = #"(maintain|altitude|descend|climb|at)\s+((?:(?:zero|one|two|three|four|five|six|seven|eight|nine|niner|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|thirty|forty|fifty|hundred|thousand)\s*)+)"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return text
        }

        var result = text
        let matches = regex.matches(in: result, range: NSRange(result.startIndex..., in: result))

        for match in matches.reversed() {
            guard let prefixRange = Range(match.range(at: 1), in: result),
                  let numbersRange = Range(match.range(at: 2), in: result) else { continue }

            let prefix = String(result[prefixRange])
            let numbersText = String(result[numbersRange])
            let value = parseSpokenNumber(numbersText)

            if value > 0 {
                let formatted = formatAltitude(value)
                guard let fullRange = Range(match.range, in: result) else { continue }
                result.replaceSubrange(fullRange, with: "\(prefix) \(formatted)")
            }
        }

        return result
    }

    // MARK: - Heading Processing

    /// Converts "heading [digits]" to numeric format.
    /// e.g., "heading three six zero" -> "heading 360"
    private func processHeadings(_ text: String) -> String {
        let digitWords = "zero|one|two|three|four|five|six|seven|eight|nine|niner"
        let pattern = #"heading\s+((?:(?:"# + digitWords + #")\s*){2,3})"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return text
        }

        var result = text
        let matches = regex.matches(in: result, range: NSRange(result.startIndex..., in: result))

        for match in matches.reversed() {
            guard let digitsRange = Range(match.range(at: 1), in: result) else { continue }
            let digitsText = String(result[digitsRange])

            let digits = digitsText.split(separator: " ")
                .compactMap { Self.digitMap[String($0).lowercased().trimmingCharacters(in: .whitespaces)] }
                .joined()

            guard let fullRange = Range(match.range, in: result) else { continue }
            result.replaceSubrange(fullRange, with: "heading \(digits)")
        }

        return result
    }

    // MARK: - ATIS Processing

    /// Converts "atis information [phonetic letter]" to abbreviated format.
    /// e.g., "atis information bravo" -> "ATIS Information B"
    private func processATIS(_ text: String) -> String {
        let letters = Self.phoneticAlphabet.keys.joined(separator: "|")
        let pattern = #"(?:atis\s+)?information\s+("#  + letters + #")"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return text
        }

        var result = text
        let matches = regex.matches(in: result, range: NSRange(result.startIndex..., in: result))

        for match in matches.reversed() {
            guard let letterRange = Range(match.range(at: 1), in: result) else { continue }
            let letterWord = String(result[letterRange]).lowercased()

            if let letter = Self.phoneticAlphabet[letterWord] {
                guard let fullRange = Range(match.range, in: result) else { continue }
                result.replaceSubrange(fullRange, with: "ATIS Information \(letter)")
            }
        }

        return result
    }

    // MARK: - Number Parsing Helpers

    /// Parse spoken number words into an integer value.
    /// Handles compound numbers like "four thousand five hundred".
    private func parseSpokenNumber(_ text: String) -> Int {
        let words = text.lowercased().split(separator: " ").map { String($0).trimmingCharacters(in: .whitespaces) }
        var total = 0
        var current = 0

        for word in words {
            if word == "hundred" {
                current = (current == 0 ? 1 : current) * 100
            } else if word == "thousand" {
                current = (current == 0 ? 1 : current) * 1000
                total += current
                current = 0
            } else if let value = Self.numberWords[word] {
                current += value
            }
        }

        total += current
        return total
    }

    /// Format an altitude integer with comma separators.
    /// e.g., 4500 -> "4,500"
    private func formatAltitude(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
