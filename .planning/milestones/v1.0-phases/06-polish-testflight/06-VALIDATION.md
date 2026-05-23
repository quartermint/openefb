---
phase: 6
slug: polish-testflight
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-21
---

# Phase 6 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (@Test, #expect) + XCTest |
| **Config file** | efb-212.xcodeproj scheme `efb-212` |
| **Quick run command** | `xcodebuild test -scheme efb-212 -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' -only-testing:efb-212Tests` |
| **Full suite command** | `xcodebuild test -scheme efb-212 -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)'` |
| **Estimated runtime** | ~45 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick run command (unit tests only)
- **After every plan wave:** Run full suite command
- **Before `/gsd:verify-work`:** Full suite must be green + successful archive build + privacy report generated
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 06-01-01 | 01 | 1 | INFRA-04 | unit | Verify PrivacyInfo.xcprivacy exists in built bundle resources | ❌ W0 | ⬜ pending |
| 06-01-02 | 01 | 1 | INFRA-04 | unit | Parse PrivacyInfo.xcprivacy plist and assert required keys present | ❌ W0 | ⬜ pending |
| 06-02-01 | 02 | 1 | INFRA-05 | smoke | `xcodebuild build -scheme efb-212 -configuration Release -destination generic/platform=iOS` | ❌ W0 | ⬜ pending |
| 06-02-02 | 02 | 1 | INFRA-05 | unit | Assert SettingsView renders with expected elements | ❌ W0 | ⬜ pending |
| 06-03-01 | 03 | 2 | INFRA-05 | manual-only | Onboarding appears on first launch, persists dismissal | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `efb-212Tests/PrivacyManifestTests.swift` — stubs for INFRA-04 (verify PrivacyInfo.xcprivacy bundled and contains required declarations)
- [ ] `efb-212Tests/ViewTests/SettingsViewTests.swift` — stubs for INFRA-05 (verify Settings tab content)
- [ ] Verify release build succeeds: `xcodebuild build -scheme efb-212 -configuration Release -destination generic/platform=iOS`

*Existing test infrastructure covers base framework. Wave 0 adds phase-specific test files.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Onboarding appears on first launch, persists dismissal | INFRA-05 | Cannot automate @AppStorage state in unit tests without UI test host | 1. Delete app from simulator 2. Launch fresh 3. Verify onboarding appears 4. Dismiss onboarding 5. Relaunch 6. Verify onboarding does not appear |
| TestFlight public link works | INFRA-05 | Requires Apple review and real device | 1. Upload to App Store Connect 2. Submit for beta review 3. Create public link 4. Install on test device |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
