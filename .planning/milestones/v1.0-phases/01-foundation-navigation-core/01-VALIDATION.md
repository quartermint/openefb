---
phase: 1
slug: foundation-navigation-core
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-20
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (built-in iOS testing) |
| **Config file** | efb-212.xcodeproj (test target) |
| **Quick run command** | `xcodebuild test -scheme efb-212 -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' -only-testing:efb-212Tests` |
| **Full suite command** | `xcodebuild test -scheme efb-212 -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)'` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick test command
- **After every plan wave:** Run full suite command
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 01-01-01 | 01 | 1 | INFRA-01 | build | `xcodebuild build -scheme efb-212` | ❌ W0 | ⬜ pending |
| 01-02-01 | 02 | 1 | DATA-01 | unit | `xcodebuild test -only-testing:efb-212Tests/AviationDatabaseTests` | ❌ W0 | ⬜ pending |
| 01-02-02 | 02 | 1 | DATA-02 | unit | `xcodebuild test -only-testing:efb-212Tests/SpatialQueryTests` | ❌ W0 | ⬜ pending |
| 01-03-01 | 03 | 2 | NAV-01 | integration | Manual — simulator GPS | N/A | ⬜ pending |
| 01-03-02 | 03 | 2 | NAV-02 | integration | Manual — chart overlay | N/A | ⬜ pending |
| 01-04-01 | 04 | 3 | WX-01 | unit | `xcodebuild test -only-testing:efb-212Tests/WeatherServiceTests` | ❌ W0 | ⬜ pending |
| 01-05-01 | 05 | 3 | NAV-05 | unit | `xcodebuild test -only-testing:efb-212Tests/InstrumentStripTests` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Test target exists in efb-212.xcodeproj
- [ ] `efb-212Tests/AviationDatabaseTests.swift` — stubs for DATA-01 through DATA-06
- [ ] `efb-212Tests/WeatherServiceTests.swift` — stubs for WX-01 through WX-03
- [ ] `efb-212Tests/LocationServiceTests.swift` — stubs for NAV-01, NAV-05

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| GPS position on map | NAV-01 | Requires simulator/device GPS | Set simulator location → verify blue dot moves |
| VFR chart overlay | NAV-02 | Visual rendering verification | Load map → verify sectional tiles render with opacity slider |
| Airport tap info | NAV-03, DATA-01 | UI interaction | Tap airport → verify popup shows runways, frequencies, weather |
| Airspace boundaries | NAV-04 | Visual rendering | Toggle layers → verify Class B/C/D boundaries render |
| Background location | NAV-06 | Device behavior | Lock screen → verify location continues updating |
| Offline mode | INFRA-03 | Network state | Enable airplane mode → verify map/data still works |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
