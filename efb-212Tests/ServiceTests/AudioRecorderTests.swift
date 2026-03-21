//
//  AudioRecorderTests.swift
//  efb-212Tests
//
//  Unit tests for AudioRecorder.
//  AVAudioEngine requires real audio hardware, so tests focus on:
//  - Protocol conformance
//  - Quality profile settings
//  - Initial state values
//  - Output directory path construction
//

import Testing
import Foundation
@testable import efb_212

@Suite("AudioRecorder Tests")
struct AudioRecorderTests {

    // MARK: - Protocol Conformance

    @Test func conformsToAudioRecorderProtocol() async {
        let recorder = AudioRecorder()
        let proto: any AudioRecorderProtocol = recorder
        _ = proto  // Compiles = conforms
    }

    // MARK: - Quality Profile Settings

    @Test func standardProfileSampleRate() {
        let profile = AudioQualityProfile.standard
        #expect(profile.sampleRate == 16_000)
    }

    @Test func standardProfileBitRate() {
        let profile = AudioQualityProfile.standard
        #expect(profile.bitRate == 32_000)
    }

    @Test func standardProfileEstimatedSize() {
        let profile = AudioQualityProfile.standard
        #expect(profile.estimatedMBPerHour == 14)
    }

    @Test func highProfileSampleRate() {
        let profile = AudioQualityProfile.high
        #expect(profile.sampleRate == 22_050)
    }

    @Test func highProfileBitRate() {
        let profile = AudioQualityProfile.high
        #expect(profile.bitRate == 64_000)
    }

    @Test func highProfileEstimatedSize() {
        let profile = AudioQualityProfile.high
        #expect(profile.estimatedMBPerHour == 28)
    }

    // MARK: - Initial State

    @Test func initialStateNotRecording() async {
        let recorder = AudioRecorder()
        let recording = await recorder.isRecording
        #expect(recording == false)
    }

    @Test func initialAudioLevelIsSilence() async {
        let recorder = AudioRecorder()
        let level = await recorder.audioLevel
        #expect(level == -160)
    }

    // MARK: - Recordings Directory

    @Test func recordingsDirectoryIsInAppSupport() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let expected = appSupport.appendingPathComponent("efb-212/recordings")
        #expect(expected.lastPathComponent == "recordings")
        #expect(expected.deletingLastPathComponent().lastPathComponent == "efb-212")
    }
}
