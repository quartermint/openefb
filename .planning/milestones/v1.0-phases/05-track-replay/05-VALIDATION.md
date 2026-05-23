---
phase: 5
slug: track-replay
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-21
---

# Phase 5 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (`@Suite`, `@Test`, `#expect`) |
| **Config file** | efb-212.xcodeproj test scheme |
| **Quick run command** | `xcodebuild test -scheme efb-212 -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' -only-testing:efb-212Tests` |
| **Full suite command** | `xcodebuild test -scheme efb-212 -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)'` |
| **Estimated runtime** | ~45 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick test command
- **After every plan wave:** Run full suite command
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 45 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 05-01-00 | 01 | 1 | REPLAY-01, REPLAY-02 | stub | ReplayEngineTests (Wave 0 stubs) | W0 task creates | pending |
| 05-01-01 | 01 | 1 | REPLAY-01 | unit | ReplayEngineTests | created in W0 | pending |
| 05-01-02 | 01 | 1 | REPLAY-02 | unit | ReplayEngineTests (sync tests) | created in W0 | pending |
| 05-02-01 | 02 | 2 | REPLAY-01, REPLAY-02 | build | BUILD SUCCEEDED (FlightHistoryListView, ReplayMapView) | N/A | pending |
| 05-02-02 | 02 | 2 | REPLAY-01 | build | BUILD SUCCEEDED (Flights tab wiring) | N/A | pending |

*Status: pending -- green -- red -- flaky*

---

## Wave 0 Requirements

Plan 05-01 Task 0 creates all Wave 0 stub test files:
- [ ] `efb-212Tests/ServiceTests/ReplayEngineTests.swift` — stubs for REPLAY-01, REPLAY-02

*Existing XCTest infrastructure covers framework requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Position marker follows GPS track on map at controllable speed | REPLAY-01 | MapLibre rendering + animation | Open past flight, tap Play, observe marker moving along track |
| Audio plays in sync with map position | REPLAY-02 | AVAudioPlayer + timer sync | During replay, verify audio matches position on track |
| Scrubbing timeline moves map + transcript | REPLAY-02 | UI interaction + tri-sync | Drag scrubber, verify map marker jumps and transcript scrolls |
| Transcript scrolls to matching segment | REPLAY-02 | ScrollViewReader + timing | During replay, verify transcript highlights current segment |
| Speed control (1x, 2x, 4x, 8x) | REPLAY-01 | AVAudioPlayer rate limits | Change speed during replay, verify marker accelerates |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 45s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
