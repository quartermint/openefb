//
//  AviationVocabularyTests.swift
//  efb-212Tests
//
//  Unit tests for AviationVocabularyProcessor.
//  Validates regex-based aviation vocabulary corrections
//  for N-numbers, frequencies, altitudes, headings, runways,
//  squawk codes, ATIS letters, and phonetic digits.
//

import Testing
import Foundation
@testable import efb_212

@Suite("AviationVocabulary Tests")
struct AviationVocabularyTests {

    let processor = AviationVocabularyProcessor()

    // MARK: - N-Number Conversion

    @Test func nNumberConversion() {
        let result = processor.process("november seven three two papa")
        #expect(result.contains("N732P"))
    }

    // MARK: - Phonetic Digit: Niner

    @Test func ninerToNine() {
        let result = processor.process("squawk one two zero niner")
        #expect(result.contains("1209"))
    }

    // MARK: - Frequency Format

    @Test func frequencyFormat() {
        let result = processor.process("one two three point four five")
        #expect(result.contains("123.45"))
    }

    // MARK: - Flight Level

    @Test func flightLevelFormat() {
        let result = processor.process("flight level three five zero")
        #expect(result.contains("FL350"))
    }

    // MARK: - Runway Format

    @Test func runwayFormat() {
        let result = processor.process("runway two seven left")
        #expect(result.contains("Runway 27L"))
    }

    // MARK: - Squawk Code

    @Test func squawkCode() {
        let result = processor.process("squawk one two zero zero")
        #expect(result.contains("1200"))
    }

    // MARK: - Altitude Format

    @Test func altitudeFormat() {
        let result = processor.process("maintain four thousand five hundred")
        let hasComma = result.contains("4,500")
        let hasPlain = result.contains("4500")
        #expect(hasComma || hasPlain)
    }

    // MARK: - Heading Format

    @Test func headingFormat() {
        let result = processor.process("heading three six zero")
        #expect(result.contains("360"))
    }

    // MARK: - ATIS Letter

    @Test func atisLetter() {
        let result = processor.process("atis information bravo")
        let hasB = result.contains("B")
        let hasBravo = result.contains("Bravo")
        #expect(hasB || hasBravo)
    }

    // MARK: - No Change for Normal Text

    @Test func noChangeForNormalText() {
        let result = processor.process("hello world")
        #expect(result == "hello world")
    }

    // MARK: - Multiple Corrections

    @Test func multipleCorrections() {
        let result = processor.process("november seven three two papa contact one two three point four five")
        #expect(result.contains("N732P"))
        #expect(result.contains("123.45"))
    }
}
