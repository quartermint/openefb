---
phase: 4
slug: ai-debrief-logbook
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-21
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (Xcode built-in) |
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
| 04-01-01 | 01 | 1 | DEBRIEF-01 | unit | FlightSummaryBuilderTests | ❌ W0 | ⬜ pending |
| 04-02-01 | 02 | 2 | DEBRIEF-02 | unit | DebriefEngineTests | ❌ W0 | ⬜ pending |
| 04-02-02 | 02 | 2 | DEBRIEF-03 | unit | DebriefAvailabilityTests | ❌ W0 | ⬜ pending |
| 04-03-01 | 03 | 1 | LOG-01, LOG-02 | unit | LogbookEntryTests | ❌ W0 | ⬜ pending |
| 04-03-02 | 03 | 1 | LOG-03 | unit | LogbookAutoPopulationTests | ❌ W0 | ⬜ pending |
| 04-04-01 | 04 | 1 | LOG-04 | unit | CurrencyWarningTests | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `efb-212Tests/FlightSummaryBuilderTests.swift` — stubs for DEBRIEF-01
- [ ] `efb-212Tests/DebriefEngineTests.swift` — stubs for DEBRIEF-02, DEBRIEF-03
- [ ] `efb-212Tests/LogbookEntryTests.swift` — stubs for LOG-01, LOG-02, LOG-03
- [ ] `efb-212Tests/CurrencyWarningTests.swift` — stubs for LOG-04

*Existing XCTest infrastructure covers framework requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Streaming debrief renders progressively on screen | DEBRIEF-02 | UI rendering + Apple FM availability | Run on device with Apple Intelligence enabled, observe streaming text |
| Graceful degradation message on non-AI device | DEBRIEF-03 | Requires device without Apple Intelligence | Run on simulator/old device, verify message shown |
| Logbook edit fields are editable before confirm | LOG-02 | UI interaction testing | Open auto-populated entry, edit each field, confirm save |
| Currency warning badges display correctly | LOG-04 | UI visual verification | Set medical expiry to 29 days, verify yellow badge |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 45s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
