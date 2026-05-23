---
phase: 02
slug: profiles-flight-planning
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-21
---

# Phase 02 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (already in use) |
| **Config file** | efb-212Tests/ directory, Xcode test target |
| **Quick run command** | `xcodebuild test -scheme efb-212 -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' -only-testing:efb-212Tests` |
| **Full suite command** | `xcodebuild test -scheme efb-212 -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)'` |
| **Estimated runtime** | ~45 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick test of affected test suite
- **After every plan wave:** Run full suite command
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 45 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 02-01-01 | 01 | 1 | PLAN-03, PLAN-04 | unit | `xcodebuild build -scheme efb-212 ...` | N/A (build) | ⬜ pending |
| 02-01-02 | 01 | 1 | PLAN-03, PLAN-04 | unit | `xcodebuild test ... -only-testing:efb-212Tests/CurrencyServiceTests -only-testing:efb-212Tests/ProfileModelTests` | Created by task | ⬜ pending |
| 02-02-01 | 02 | 2 | PLAN-03, PLAN-04 | unit + build | `xcodebuild test ... -only-testing:efb-212Tests/CurrencyServiceTests -only-testing:efb-212Tests/ProfileModelTests && xcodebuild build ...` | Via Plan 01 T2 | ⬜ pending |
| 02-02-02 | 02 | 2 | PLAN-03, PLAN-04 | build | `xcodebuild build -scheme efb-212 ...` | N/A (UI views) | ⬜ pending |
| 02-03-01 | 03 | 2 | PLAN-01, PLAN-02 | unit + build | `xcodebuild test ... -only-testing:efb-212Tests/FlightPlanViewModelTests && xcodebuild build ...` | Partial (existing) | ⬜ pending |
| 02-03-02 | 03 | 2 | PLAN-01, PLAN-02 | build | `xcodebuild build -scheme efb-212 ...` | N/A (UI views) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Plan 01 Task 2 creates the Wave 0 test infrastructure for this phase:

- [x] `efb-212Tests/ServiceTests/CurrencyServiceTests.swift` — CurrencyService unit tests for medical, flight review, night 61.57 (created by Plan 01 Task 2)
- [x] `efb-212Tests/DataTests/ProfileModelTests.swift` — SwiftData model creation, computed property round-trip, validation tests (created by Plan 01 Task 2)
- [ ] `efb-212Tests/ViewModelTests/FlightPlanViewModelTests.swift` — EXISTS but uses archive `DatabaseManagerProtocol`; needs rewrite for `DatabaseServiceProtocol` + `@Observable` (updated during Plan 03 Task 1 execution)
- [ ] Update `efb-212Tests/Mocks/MockDatabaseManager.swift` — currently conforms to archived `DatabaseManagerProtocol`, needs alignment with current `DatabaseServiceProtocol` (updated during Plan 03 Task 1 execution)

*Plan 01 Task 2 fills the Wave 0 role — it creates CurrencyServiceTests and ProfileModelTests BEFORE Plan 02/03 ViewModels are built, ensuring Nyquist compliance. The FlightPlanViewModelTests update happens during Plan 03 Task 1 read_first step.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Route drawn as magenta line on map | PLAN-01 | MapLibre visual rendering | Enter departure + destination, verify magenta great-circle line appears on map |
| Currency badges (green/yellow/red) visible | PLAN-04 | Color rendering in SwiftUI | Set medical expiry to >30 days (green), <=30 days (yellow), past (red) and verify badge color |
| Profile persists across launches | PLAN-03 | App lifecycle behavior | Create profile, force-quit app, relaunch, verify profile still exists |
| Currency badge on Aircraft tab icon | PLAN-04 | Tab badge visual | Set pilot with expired medical, verify Aircraft tab shows badge count |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (Plan 01 Task 2 creates CurrencyServiceTests + ProfileModelTests)
- [x] No watch-mode flags
- [x] Feedback latency < 45s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated
