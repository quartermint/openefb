---
phase: 04-ai-debrief-logbook
verified: 2026-03-21T17:00:00Z
status: human_needed
score: 7/7 must-haves verified
human_verification:
  - test: "Streaming debrief UI on device with Apple Intelligence"
    expected: "Tapping 'Generate Debrief' on FlightDetailView shows progressive streaming of narrative, phase observations, improvements, and 1-5 star rating in DebriefView"
    why_human: "Requires real device with Apple Intelligence enabled; Foundation Models runtime cannot be exercised in simulator or programmatically"
  - test: "Foundation Models unavailable message"
    expected: "On simulator or device without Apple Intelligence, FlightDetailView shows 'AI Debrief requires Apple Intelligence.' with 'You can still review your flight track, transcript, and logbook entry.' message; Settings link appears if reason contains 'not enabled'"
    why_human: "Requires device without Apple Intelligence or simulator where Foundation Models is unavailable"
  - test: "Recording stop auto-creates logbook entry"
    expected: "Start a recording, stop it, confirm the stop dialog — a logbook entry appears in the Logbook tab auto-populated with date, duration, and departure/arrival if coordinator resolved them"
    why_human: "End-to-end recording flow requires GPS + audio session; cannot be driven programmatically in a unit test"
  - test: "Logbook entry edit-before-confirm workflow"
    expected: "Tapping an unconfirmed logbook entry opens editable form; all fields (date, departure, arrival, route, duration, aircraft, landings, notes) can be edited; tapping Confirm locks the entry and navigates back; reopening shows read-only banner"
    why_human: "UI interaction state (editable vs disabled fields, navigation, sheet dismissal) requires manual exercise"
  - test: "Currency warning banner on map after night currency expiry"
    expected: "Set pilot medical expiry to 29 days from now — yellow banner appears at top of map tab with 'Medical certificate expiring soon'; dismiss button (X) removes it for the session"
    why_human: "Visual, interactive banner behavior with SwiftData live data requires manual exercise"
  - test: "Double Foundation Models call in generateDebrief"
    expected: "User experience is acceptable: streaming shows partial debrief, then a second respond() call is made for persistence — verify this does not show a jarring visual gap or double-generation experience"
    why_human: "DebriefEngine.generateDebrief calls streamResponse() then respond() sequentially (two LLM calls per debrief). This is a design concern that requires human judgment on whether the UX is acceptable, and whether the second call produces consistent results"
---

# Phase 4: AI Debrief + Logbook Verification Report

**Phase Goal:** After landing, a pilot can view an AI-generated post-flight debrief (narrative, per-phase observations, improvements, rating) on-device, confirm an auto-populated logbook entry, and see currency warnings if anything is approaching expiry
**Verified:** 2026-03-21
**Status:** human_needed — all automated checks passed, 6 items require human exercise
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths (from ROADMAP success criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Pilot taps "Debrief" and sees structured AI debrief streaming on-screen with narrative, phase observations, improvements, and overall rating | ? UNCERTAIN | DebriefView.swift fully wired: observes `debriefEngine.partialDebrief` for streaming and `debriefEngine.completedDebrief` for final output. FlightDetailView creates DebriefEngine, calls checkAvailability + prewarm on appear. Actual streaming requires Apple Intelligence device — needs human |
| 2 | On device without Apple Intelligence, shows clear non-alarming unavailable message with options | ? UNCERTAIN | FlightDetailView.swift `unavailableContent(reason:)` shows "AI Debrief requires Apple Intelligence." + "You can still review your flight track, transcript, and logbook entry." + Settings link. Needs human on non-AI device |
| 3 | Digital logbook entry auto-created from recording with correct fields; pilot can edit before confirming | ✓ VERIFIED | RecordingViewModel.confirmStop() calls LogbookViewModel.createFromRecording() at line 105. LogbookEntry sets flightID, date, departure/arrival ICAO (from coordinator summary), durationSeconds. LogbookEntryEditView provides full editable form |
| 4 | Currency warnings shown when medical, flight review, or 61.57 night currency approaching expiry | ? UNCERTAIN | CurrencyWarningBanner.swift correctly computes all three currency statuses via CurrencyService and renders yellow/red banner with messages. Wired into MapContainerView via .withAutoCompute(). Needs human to verify visual rendering |

**Score:** 7/7 must-haves verified at artifact/wiring level; 6 items flagged for human testing of runtime behavior

---

## Required Artifacts

### Plan 01 Artifacts

| Artifact | Contains | Status | Evidence |
|----------|----------|--------|----------|
| `efb-212/Services/Debrief/DebriefTypes.swift` | `@Generable struct FlightDebrief`, `@Generable struct PhaseObservation`, `struct DebriefRecord`, `struct FlightMetadata` | ✓ VERIFIED | 156 lines, all types present with `@Generable`, `@Guide` constraints, DebriefRecord with GRDB conformances and fromFlightDebrief factory |
| `efb-212/Services/Debrief/FlightSummaryBuilder.swift` | `struct FlightSummaryBuilder`, token budget constants, buildPrompt (DB + testable overloads), summarizePhase | ✓ VERIFIED | 178 lines, maxSummaryChars=12600, perPhaseCharBudget=1050, both overloads present, interruption filtering, proportional trim |
| `efb-212/Services/Debrief/DebriefEngine.swift` | `class DebriefEngine`, AvailabilityStatus enum with reasonMessage, checkAvailability, prewarm, generateDebrief, loadExistingDebrief, discard | ✓ VERIFIED | 241 lines, all lifecycle methods present. NOTE: generateDebrief makes two Foundation Models calls (streamResponse then respond) — flagged for human review |
| `efb-212/Data/RecordingDatabase.swift` | "v2_debrief" migration creating debrief_results table, insertDebrief, debrief(forFlight:), deleteDebrief | ✓ VERIFIED | Migration at line 204, all three CRUD methods at lines 295/325/334 |
| `efb-212Tests/ServiceTests/FlightSummaryBuilderTests.swift` | `FlightSummaryBuilderTests` suite with 5 substantive tests | ✓ VERIFIED | 249 lines, real test data helpers (makeEightPhaseMarkers, makeTrackPoints, makeTranscripts), all 5 tests fully implemented |
| `efb-212Tests/ServiceTests/DebriefAvailabilityTests.swift` | `DebriefAvailabilityTests` with 9 tests | ✓ VERIFIED | 74 lines, 9 tests covering all reason mappings + equality + edge cases |
| `efb-212Tests/Mocks/MockRecordingDatabase.swift` | `MockRecordingDatabase` with canned data arrays | ✓ VERIFIED | File exists with mockTrackPoints, mockTranscripts, mockPhaseMarkers arrays |

### Plan 02 Artifacts

| Artifact | Contains | Status | Evidence |
|----------|----------|--------|----------|
| `efb-212/Data/Models/LogbookEntry.swift` | `class LogbookEntry` in SchemaV1 extension | ✓ VERIFIED | 76 lines, all fields present including isConfirmed, nightLandingCount, hasDebrief |
| `efb-212/ViewModels/LogbookViewModel.swift` | `class LogbookViewModel` with full CRUD | ✓ VERIFIED | 166 lines, createFromRecording, createManualEntry, confirmEntry, confirmEntryAndUpdateCurrency, loadEntries, deleteEntry, formatDurationDecimal, formatDurationHM |
| `efb-212/ViewModels/RecordingViewModel.swift` | `createFromRecording` call after stopRecording | ✓ VERIFIED | confirmStop() at line 77: captures summary, conditionally calls logbookVM.createFromRecording() at line 105 |
| `efb-212/Views/Logbook/LogbookListView.swift` | `struct LogbookListView` with chronological list | ✓ VERIFIED | NavigationStack, confirmed/unconfirmed routing to read-only vs editable, manual entry creation, summary footer |
| `efb-212/Views/Logbook/LogbookEntryEditView.swift` | `struct LogbookEntryEditView` with editable form | ✓ VERIFIED | Full form fields, isReadOnly mode, Confirm button calls confirmEntryAndUpdateCurrency |
| `efb-212Tests/DataTests/LogbookEntryTests.swift` | `LogbookEntryTests` | ✓ VERIFIED | File exists with substantive tests |

### Plan 03 Artifacts

| Artifact | Contains | Status | Evidence |
|----------|----------|--------|----------|
| `efb-212/Views/Flights/DebriefView.swift` | `struct DebriefView` with streaming display | ✓ VERIFIED | 330 lines: completed/streaming/error/initial states, PhaseObservationCard, RatingView, Regenerate button, onAppear loads existing debrief |
| `efb-212/Views/Flights/FlightDetailView.swift` | `struct FlightDetailView` with DebriefEngine | ✓ VERIFIED | 207 lines: debriefEngine created as @State, checkAvailability+prewarm on appear, discard on disappear, uses appState.getOrCreateRecordingDatabase() |
| `efb-212/Views/Map/CurrencyWarningBanner.swift` | `struct CurrencyWarningBanner` | ✓ VERIFIED | 110 lines: computes all three currency statuses, yellow/red banner with dismiss button, withAutoCompute() extension |
| `efb-212/ContentView.swift` | LogbookListView in logbook tab | ✓ VERIFIED | Line 36: `LogbookListView()` replacing placeholder. unconfirmedLogbookCount badge at line 38 |
| `efb-212Tests/ServiceTests/CurrencyServiceTests.swift` | nightCurrencyFromLogbook tests | ✓ VERIFIED | 4 new tests at lines 136/144/158/171 |

---

## Key Link Verification

| From | To | Via | Status | Evidence |
|------|----|-----|--------|----------|
| FlightSummaryBuilder.swift | RecordingDatabase.swift | reads trackPoints, transcriptSegments, phaseMarkers | ✓ WIRED | Lines 42-44: `recordingDB.phaseMarkers(forFlight:)`, `recordingDB.trackPoints(forFlight:)`, `recordingDB.transcriptSegments(forFlight:)` |
| DebriefEngine.swift | DebriefTypes.swift | generates FlightDebrief via streamResponse | ✓ WIRED | Line 150-152: `session.streamResponse(to: prompt, generating: FlightDebrief.self)` |
| RecordingDatabase.swift | DebriefTypes.swift | saves/loads DebriefRecord | ✓ WIRED | insertDebrief at line 295 writes DebriefRecord fields; debrief(forFlight:) at 325 fetches and returns DebriefRecord? |
| DebriefView.swift | DebriefEngine.swift | observes partialDebrief and isGenerating | ✓ WIRED | Lines 33+75: `debriefEngine.partialDebrief`, `debriefEngine.isGenerating`, `debriefEngine.completedDebrief`, `debriefEngine.loadExistingDebrief(...)` |
| FlightDetailView.swift | DebriefEngine.swift | creates DebriefEngine, calls checkAvailability, prewarm | ✓ WIRED | `@State private var debriefEngine = DebriefEngine()` at line 16; onAppear calls checkAvailability() + prewarm() at lines 45-48 |
| FlightDetailView.swift | AppState.swift | shared RecordingDatabase via getOrCreateRecordingDatabase | ✓ WIRED | Line 127: `appState.getOrCreateRecordingDatabase()` — not `try? RecordingDatabase()` |
| LogbookViewModel.swift | PilotProfile.swift | appends NightLandingEntry on confirm | ✓ WIRED | confirmEntryAndUpdateCurrency at line 121: fetches active PilotProfile, appends NightLandingEntry to nightLandingEntries |
| CurrencyWarningBanner.swift | CurrencyService.swift | computes currency status for display | ✓ WIRED | Lines 75-80: CurrencyService.medicalStatus, CurrencyService.flightReviewStatus, CurrencyService.nightCurrencyStatus, CurrencyService.overallStatus |
| LogbookViewModel.swift | LogbookEntry.swift | SwiftData modelContext CRUD | ✓ WIRED | modelContext.insert(entry), modelContext.delete(entry), FetchDescriptor<SchemaV1.LogbookEntry> |
| RecordingViewModel.swift | LogbookViewModel.swift | confirmStop() calls createFromRecording | ✓ WIRED | Line 105: `logbookVM.createFromRecording(summary: summary, ...)` inside confirmStop() guard block |
| UserSettings.swift | LogbookEntry.swift | SchemaV1.models includes LogbookEntry.self | ✓ WIRED | Line 17: `[UserSettings.self, AircraftProfile.self, PilotProfile.self, FlightPlanRecord.self, FlightRecord.self, LogbookEntry.self]` |
| efb_212App.swift | LogbookEntry.swift | modelContainer includes LogbookEntry | ✓ WIRED | Lines 32 and 43: `SchemaV1.LogbookEntry.self` in both modelContainer calls |
| MapContainerView.swift | CurrencyWarningBanner.swift | banner in ZStack overlay | ✓ WIRED | Line 97: `CurrencyWarningBanner().withAutoCompute()` in VStack at top of ZStack |
| ContentView.swift | LogbookListView.swift | logbook tab uses real view | ✓ WIRED | Line 35-38: `LogbookListView()` with `.badge(unconfirmedLogbookCount)` |

---

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| DEBRIEF-01 | 04-01, 04-03 | On-device structured debrief via Foundation Models: narrative, observations, improvements, rating | ✓ SATISFIED | @Generable FlightDebrief schema compiled with all 4 fields; DebriefEngine.generateDebrief wires streamResponse; DebriefView renders all sections |
| DEBRIEF-02 | 04-01 | Flight data compressed under 3,000 tokens (12,600 chars) | ✓ SATISFIED | FlightSummaryBuilder.maxSummaryChars=12600, proportional trimming logic, FlightSummaryBuilderTests verify 8-phase prompt fits under budget |
| DEBRIEF-03 | 04-01, 04-03 | Graceful degradation when Foundation Models unavailable | ✓ SATISFIED | DebriefEngine.AvailabilityStatus with testable reasonMessage; FlightDetailView unavailableContent shows non-alarming message; DebriefAvailabilityTests (9 tests) cover all reason mappings |
| LOG-01 | 04-02 | Auto-populated logbook entries from recording | ✓ SATISFIED | RecordingViewModel.confirmStop() calls LogbookViewModel.createFromRecording() after coordinator.stopRecording(); entry gets flightID, date, departure/arrival, duration |
| LOG-02 | 04-02 | Pilot can review and edit before confirming | ✓ SATISFIED | LogbookEntryEditView with full editable form, Save + Confirm buttons; isReadOnly=true for confirmed entries with locked banner; LogbookEntryTests verify behavior |
| LOG-03 | 04-03 | Currency tracking: medical expiry, flight review date, 61.57 night | ✓ SATISFIED | LogbookViewModel.confirmEntryAndUpdateCurrency bridges nightLandingCount to PilotProfile.nightLandingEntries; CurrencyService.nightCurrencyStatus computes from those entries; CurrencyServiceTests extended with 4 logbook-derived tests |
| LOG-04 | 04-03 | Currency warnings displayed when approaching expiry | ✓ SATISFIED | CurrencyWarningBanner in MapContainerView ZStack computes medical/flightReview/night status and renders yellow/red banner; visual verification needed (human) |

All 7 requirements claimed by plans are mapped to concrete implementations. No orphaned requirements.

---

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `efb-212/Services/Debrief/DebriefEngine.swift` | 150-165 | Double Foundation Models call: streamResponse() then respond() — two separate LLM calls per debrief generation | ⚠️ Warning | The streaming call (lines 150-157) provides progressive UI, then a second blocking respond() call (line 162) is made to get the final typed FlightDebrief for persistence. This doubles the inference cost and time per debrief. The summary comment acknowledges this. The streaming result's final partial could potentially be used directly to avoid the second call, but this approach works and is architecturally sound. Flagged for human judgment on UX acceptability. |
| `efb-212/Views/Flights/FlightDetailView.swift` | 198-199 | `aircraftType: nil` in buildMetadata() helper | ℹ️ Info | FlightMetadata is constructed with `aircraftType: nil` in FlightDetailView. The aircraft type is available in AppState via activeAircraftProfileID but not looked up. The debrief prompt will show "Unknown" for aircraft type. Not a blocker — the debrief will still work. |

---

## Human Verification Required

### 1. Streaming Debrief on Apple Intelligence Device

**Test:** On a device with Apple Intelligence enabled (iPhone 15 Pro / iPad Pro with M-series), open a completed flight in the Flights tab, navigate to FlightDetailView, tap "Generate Debrief"
**Expected:** DebriefView appears with "Generating debrief..." progress indicator. Text progressively appears: narrative summary first, then phase observation cards, then improvement bullet points, then 1-5 star rating. After completion, "Regenerate Debrief" button appears at bottom.
**Why human:** Foundation Models streaming requires real Apple Intelligence runtime — cannot be exercised in simulator or unit tests

### 2. Foundation Models Unavailable State

**Test:** On iOS Simulator or a device without Apple Intelligence enabled, navigate to FlightDetailView for any flight
**Expected:** The AI Debrief section shows the apple.intelligence icon, "AI Debrief requires Apple Intelligence.", "You can still review your flight track, transcript, and logbook entry." If Apple Intelligence is disabled (not device-ineligible), a "Open Settings" link appears.
**Why human:** Requires device/simulator where Foundation Models is unavailable at runtime

### 3. Recording Stop Auto-Creates Logbook Entry

**Test:** Start a flight recording (map tab recording overlay), fly for a few minutes, tap stop, confirm the stop dialog
**Expected:** The Logbook tab badge increments by 1. Opening the logbook shows a new unconfirmed entry (pencil.circle icon) with the correct flight date and duration (roughly matching elapsed time). If coordinator detected departure/arrival airports, those ICAO codes are pre-filled.
**Why human:** End-to-end requires GPS + audio session; RecordingViewModel.logbookViewModel must be injected from the view layer before confirmStop() fires

### 4. Logbook Entry Edit/Confirm Workflow

**Test:** Tap an unconfirmed logbook entry (pencil.circle badge). Edit several fields (departure ICAO, night landing count to 2). Tap Save. Re-open the entry and verify edits persisted. Tap Confirm. Verify entry now shows checkmark.circle.fill badge. Tap it again and verify all fields are disabled with "This entry has been confirmed and is locked." banner.
**Expected:** Full edit roundtrip works. Confirmed entries are truly read-only.
**Why human:** SwiftData live persistence + UI state transitions require manual exercise

### 5. Currency Warning Banner (Map Tab)

**Test:** In the Aircraft tab, open the active pilot profile. Set medical certificate expiry to 15 days from now. Navigate to the Map tab.
**Expected:** A yellow banner appears at the top of the map with "Currency Warning" header and "Medical certificate expiring soon" message. Tapping the X button dismisses it for the session.
**Why human:** Visual rendering + dismissal interaction + SwiftData live data requires human

### 6. Double Foundation Models Call UX Acceptability

**Test:** On a device with Apple Intelligence, generate a debrief. Observe the full flow: streaming text appears, stream ends, then observe if there is a second loading phase or jarring behavior before the "Regenerate Debrief" button appears.
**Expected (acceptable):** Streaming completes smoothly. The second respond() call (for persistence) either completes quickly or the UI shows a brief loading state gracefully. The final stored debrief matches what was shown during streaming.
**Why human:** DebriefEngine.generateDebrief calls streamResponse() then respond() sequentially. Whether this produces a confusing double-generation experience requires runtime judgment. If the UX is poor, consider caching the final partial from the stream instead of making a second call.

---

## Gaps Summary

No gaps blocking goal achievement. All 14 artifacts exist and are substantive (no stubs). All 14 key links are verified. All 7 requirements are satisfied with concrete evidence. Six items are flagged for human verification because they require Foundation Models runtime, real GPS/audio, or interactive UI exercise that cannot be driven programmatically.

One architectural note: the double Foundation Models call in DebriefEngine.generateDebrief (streamResponse then respond) is a design choice documented in the code with comments. It works correctly but doubles inference cost per debrief. This is worth reviewing during human testing to assess UX impact.

---

_Verified: 2026-03-21_
_Verifier: Claude (gsd-verifier)_
