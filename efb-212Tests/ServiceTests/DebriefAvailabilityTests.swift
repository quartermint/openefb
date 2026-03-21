//
//  DebriefAvailabilityTests.swift
//  efb-212Tests
//
//  Unit tests for DebriefEngine.AvailabilityStatus reason mapping.
//  Tests the static reasonMessage(for:) method which can be verified without
//  requiring a real Foundation Models runtime (no device with Apple Intelligence needed).
//

import Testing
import Foundation
@testable import efb_212

@Suite("Debrief Availability Tests")
struct DebriefAvailabilityTests {

    @Test("deviceNotEligible maps to device not supported message")
    func deviceNotEligibleReasonMessage() {
        let msg = DebriefEngine.AvailabilityStatus.reasonMessage(for: "deviceNotEligible")
        #expect(msg == "This device does not support Apple Intelligence.")
    }

    @Test("'not eligible' substring also maps to device not supported message")
    func notEligibleSubstringReasonMessage() {
        let msg = DebriefEngine.AvailabilityStatus.reasonMessage(for: "Device is not eligible for AI")
        #expect(msg == "This device does not support Apple Intelligence.")
    }

    @Test("appleIntelligenceNotEnabled maps to enable in Settings message")
    func appleIntelligenceNotEnabledReasonMessage() {
        let msg = DebriefEngine.AvailabilityStatus.reasonMessage(for: "appleIntelligenceNotEnabled")
        #expect(msg == "Apple Intelligence is not enabled. You can enable it in Settings.")
    }

    @Test("'not enabled' substring also maps to enable in Settings message")
    func notEnabledSubstringReasonMessage() {
        let msg = DebriefEngine.AvailabilityStatus.reasonMessage(for: "Apple Intelligence is not enabled on this device")
        #expect(msg == "Apple Intelligence is not enabled. You can enable it in Settings.")
    }

    @Test("modelNotReady maps to still setting up message")
    func modelNotReadyReasonMessage() {
        let msg = DebriefEngine.AvailabilityStatus.reasonMessage(for: "modelNotReady")
        #expect(msg == "Apple Intelligence is still setting up. Please try again later.")
    }

    @Test("'not ready' substring also maps to still setting up message")
    func notReadySubstringReasonMessage() {
        let msg = DebriefEngine.AvailabilityStatus.reasonMessage(for: "Model is not ready yet")
        #expect(msg == "Apple Intelligence is still setting up. Please try again later.")
    }

    @Test("Unknown reason returns generic unavailable message")
    func unknownReasonReturnsGenericMessage() {
        let msg = DebriefEngine.AvailabilityStatus.reasonMessage(for: "someUnknownReason")
        #expect(msg == "AI Debrief is currently unavailable.")
    }

    @Test("Empty reason string returns generic unavailable message")
    func emptyReasonReturnsGenericMessage() {
        let msg = DebriefEngine.AvailabilityStatus.reasonMessage(for: "")
        #expect(msg == "AI Debrief is currently unavailable.")
    }

    @Test("AvailabilityStatus enum equality checks")
    func availabilityStatusEquality() {
        #expect(DebriefEngine.AvailabilityStatus.unknown == .unknown)
        #expect(DebriefEngine.AvailabilityStatus.available == .available)
        #expect(DebriefEngine.AvailabilityStatus.unavailable(reason: "test") == .unavailable(reason: "test"))
        #expect(DebriefEngine.AvailabilityStatus.available != .unknown)
        #expect(DebriefEngine.AvailabilityStatus.unavailable(reason: "a") != .unavailable(reason: "b"))
    }
}
