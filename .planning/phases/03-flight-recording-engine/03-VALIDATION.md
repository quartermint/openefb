---
phase: 03
slug: flight-recording-engine
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-21
---

# Phase 03 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (Xcode built-in) |
| **Config file** | efb-212Tests/ directory, test host guard in efb_212App.swift |
| **Quick run command** | `xcodebuild test -scheme efb-212 -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' -only-testing:efb-212Tests` |
| **Full suite command** | `xcodebuild test -scheme efb-212 -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)'` |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick unit tests for the specific service being implemented
- **After every plan wave:** Run full suite command
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | REC-01, REC-02, REC-05 | unit + integration | `xcodebuild test ... -only-testing:efb-212Tests/RecordingCoordinatorTests -only-testing:efb-212Tests/FlightPhaseDetectorTests -only-testing:efb-212Tests/AutoStartTests` | Created by plan | ⬜ pending |
| 03-01-02 | 01 | 1 | REC-01, REC-05 | unit | `xcodebuild test ... -only-testing:efb-212Tests/FlightPhaseDetectorTests` | Created by plan | ⬜ pending |
| 03-02-01 | 02 | 2 | REC-03 | unit | `xcodebuild test ... -only-testing:efb-212Tests/AudioRecorderTests` | Created by plan | ⬜ pending |
| 03-02-02 | 02 | 2 | REC-03 | manual | 10-min recording stability test | N/A | ⬜ pending |
| 03-03-01 | 03 | 2 | REC-04 | unit | `xcodebuild test ... -only-testing:efb-212Tests/TranscriptionServiceTests -only-testing:efb-212Tests/AviationVocabularyTests` | Created by plan | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Plan 01 Task 2 creates the Wave 0 test infrastructure:

- [x] `efb-212Tests/ServiceTests/FlightPhaseDetectorTests.swift` — REC-05 with synthetic GPS sequences
- [x] `efb-212Tests/ServiceTests/RecordingCoordinatorTests.swift` — REC-01 orchestration with mocks
- [x] `efb-212Tests/ServiceTests/AutoStartTests.swift` — REC-02 threshold and countdown logic
- [x] `efb-212Tests/Mocks/MockAudioRecorder.swift` — mock for coordinator testing without real audio
- [x] `efb-212Tests/Mocks/MockTranscriptionService.swift` — mock for testing without Speech framework

Plan 02/03 create their own test files during execution:

- [ ] `efb-212Tests/ServiceTests/AudioRecorderTests.swift` — REC-03 session configuration
- [ ] `efb-212Tests/ServiceTests/TranscriptionServiceTests.swift` — REC-04 mock speech results
- [ ] `efb-212Tests/ServiceTests/AviationVocabularyTests.swift` — REC-04 vocabulary processing

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Simultaneous GPS + audio capture | REC-01 | Requires real device with GPS + mic | Start recording, walk outside, verify track points and audio file |
| Auto-start at speed threshold | REC-02 | Requires simulated movement | Use Xcode location simulation at >15kts, verify recording auto-starts |
| 6+ hour continuous recording | REC-03 | Duration test | Run 10-min extended test, verify no memory growth or audio gaps |
| Phone call interruption recovery | REC-03 | Requires real phone call | Simulate phone call during recording, verify audio resumes |
| Real speech recognition accuracy | REC-04 | Requires actual speech input | Play ATC audio, verify N-numbers and altitudes recognized |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated
