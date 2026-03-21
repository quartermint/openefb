---
phase: 02
slug: profiles-flight-planning
status: draft
nyquist_compliant: false
wave_0_complete: false
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
| 02-01-01 | 01 | 1 | PLAN-03 | unit + integration | `xcodebuild test ... -only-testing:efb-212Tests/AircraftProfileTests` | ❌ W0 | ⬜ pending |
| 02-01-02 | 01 | 1 | PLAN-04 | unit + integration | `xcodebuild test ... -only-testing:efb-212Tests/ProfileModelTests` | ❌ W0 | ⬜ pending |
| 02-02-01 | 02 | 2 | PLAN-01 | unit | `xcodebuild test ... -only-testing:efb-212Tests/FlightPlanViewModelTests` | Partial | ⬜ pending |
| 02-02-02 | 02 | 2 | PLAN-02 | unit | `xcodebuild test ... -only-testing:efb-212Tests/FlightPlanViewModelTests` | Partial | ⬜ pending |
| 02-03-01 | 03 | 2 | PLAN-04 | unit | `xcodebuild test ... -only-testing:efb-212Tests/CurrencyServiceTests` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `efb-212Tests/ServiceTests/CurrencyServiceTests.swift` — stubs for PLAN-04 currency computation (medical, flight review, night 61.57)
- [ ] `efb-212Tests/DataTests/ProfileModelTests.swift` — stubs for PLAN-03, PLAN-04 SwiftData model creation, persistence, field validation
- [ ] `efb-212Tests/ViewModelTests/FlightPlanViewModelTests.swift` — EXISTS but uses archive `DatabaseManagerProtocol`; needs rewrite for `DatabaseServiceProtocol` + `@Observable`
- [ ] Update `efb-212Tests/Mocks/MockDatabaseManager.swift` — currently conforms to archived `DatabaseManagerProtocol`, needs alignment with current `DatabaseServiceProtocol`

*Existing infrastructure covers Phase 1 tests; Wave 0 adds stubs for Phase 2 requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Route drawn as magenta line on map | PLAN-01 | MapLibre visual rendering | Enter departure + destination, verify magenta great-circle line appears on map |
| Currency badges (green/yellow/red) visible | PLAN-04 | Color rendering in SwiftUI | Set medical expiry to >30 days (green), <=30 days (yellow), past (red) and verify badge color |
| Profile persists across launches | PLAN-03 | App lifecycle behavior | Create profile, force-quit app, relaunch, verify profile still exists |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 45s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
