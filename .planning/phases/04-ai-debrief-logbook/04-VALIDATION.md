---
phase: 4
slug: ai-debrief-logbook
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-03-21
updated: 2026-03-21
---

# Phase 4 — Validation Strategy

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
| 04-01-00 | 01 | 1 | DEBRIEF-01, DEBRIEF-02, DEBRIEF-03 | stub | FlightSummaryBuilderTests, DebriefSchemaTests, DebriefAvailabilityTests (Wave 0 stubs) | W0 task creates | pending |
| 04-01-01 | 01 | 1 | DEBRIEF-01, DEBRIEF-02 | unit | FlightSummaryBuilderTests, DebriefSchemaTests | created in W0 | pending |
| 04-01-02 | 01 | 1 | DEBRIEF-03 | unit | DebriefAvailabilityTests | created in W0 | pending |
| 04-02-01 | 02 | 1 | LOG-01, LOG-02 | unit | LogbookEntryTests | W0 (pre-existing) | pending |
| 04-02-02 | 02 | 1 | LOG-01 | build | BUILD SUCCEEDED (UI + RecordingViewModel wiring) | N/A | pending |
| 04-03-01 | 03 | 2 | DEBRIEF-01 | build | BUILD SUCCEEDED (DebriefView + FlightDetailView) | N/A | pending |
| 04-03-02 | 03 | 2 | LOG-03, LOG-04 | unit | CurrencyServiceTests (extended) | existing + extended | pending |

*Status: pending -- green -- red -- flaky*

---

## Wave 0 Requirements

Plan 04-01 Task 0 creates all Wave 0 stub test files:
- [ ] `efb-212Tests/ServiceTests/FlightSummaryBuilderTests.swift` — stubs for DEBRIEF-02
- [ ] `efb-212Tests/ServiceTests/DebriefSchemaTests.swift` — stubs for DEBRIEF-01
- [ ] `efb-212Tests/ServiceTests/DebriefAvailabilityTests.swift` — stubs for DEBRIEF-03
- [ ] `efb-212Tests/Mocks/MockRecordingDatabase.swift` — mock for FlightSummaryBuilder tests

Pre-existing test files extended in later tasks:
- [ ] `efb-212Tests/DataTests/LogbookEntryTests.swift` — covers LOG-01, LOG-02 (Plan 02)
- [ ] `efb-212Tests/ServiceTests/CurrencyServiceTests.swift` — extended for LOG-03 (Plan 03)

---

## Requirement Coverage

| Req ID | Description | Plan(s) | Test Coverage |
|--------|-------------|---------|---------------|
| DEBRIEF-01 | On-device structured debrief via Foundation Models | 01, 03 | DebriefSchemaTests (schema compilation), DebriefView build (UI) |
| DEBRIEF-02 | Flight data compressed under 3,000 tokens | 01 | FlightSummaryBuilderTests (token budget compliance) |
| DEBRIEF-03 | Graceful degradation when Foundation Models unavailable | 01 | DebriefAvailabilityTests (reason mapping) |
| LOG-01 | Auto-populated logbook entries from recording | 02 | LogbookEntryTests (auto-population), RecordingViewModel wiring (build) |
| LOG-02 | Editable logbook entries before confirm | 02 | LogbookEntryTests (confirm lock), LogbookEntryEditView build |
| LOG-03 | Currency tracking: medical, flight review, 61.57 night | 03 | CurrencyServiceTests (extended with logbook-derived night) |
| LOG-04 | Currency warning display | 03 | CurrencyWarningBanner build, manual visual verification |

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Streaming debrief renders progressively on screen | DEBRIEF-01 | UI rendering + Apple FM availability | Run on device with Apple Intelligence enabled, observe streaming text |
| Graceful degradation message on non-AI device | DEBRIEF-03 | Requires device without Apple Intelligence | Run on simulator/old device, verify message shown |
| Logbook edit fields are editable before confirm | LOG-02 | UI interaction testing | Open auto-populated entry, edit each field, confirm save |
| Confirmed entries open in read-only mode | LOG-02 | UI state verification | Confirm entry, tap to reopen, verify all fields disabled |
| Currency warning banner on map | LOG-04 | UI visual verification | Set medical expiry to 29 days, verify yellow banner on map tab |
| Recording stop auto-creates logbook entry | LOG-01 | End-to-end recording flow | Start recording, stop, verify logbook entry appears |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (Task 0 in Plan 01)
- [x] No watch-mode flags
- [x] Feedback latency < 45s
- [ ] `nyquist_compliant: true` set in frontmatter (set, pending execution)

**Approval:** pending execution
