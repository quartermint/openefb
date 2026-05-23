---
status: partial
phase: 06-polish-testflight
source: [06-03-PLAN.md checkpoint]
started: 2026-03-24
updated: 2026-03-24
---

## Current Test

[awaiting human testing]

## Tests

### 1. Onboarding flow displays 3 swipeable pages
expected: Pages show "Navigate with GPS" (blue), "Your Moving Map" (green), "Record Every Flight" (red) with "Get Started" button
result: [pending]

### 2. Onboarding "Get Started" transitions to main TabView
expected: Tapping "Get Started" dismisses onboarding and shows ContentView with all tabs
result: [pending]

### 3. Beta banner appears after onboarding
expected: Blue dismissable banner at top: "Beta — Report issues via TestFlight feedback"
result: [pending]

### 4. Settings tab has real content
expected: App version/build, "Send Feedback" link, "Source Code" link, legal section
result: [pending]

### 5. Onboarding persistence
expected: Re-running app skips onboarding (goes straight to ContentView)
result: [pending]

### 6. Release build archives successfully
expected: Xcode archive succeeds with signed provisioning profile for quartermint.efb-212
result: [pending]

## Summary

total: 6
passed: 0
issues: 0
pending: 6
skipped: 0
blocked: 0

## Gaps
