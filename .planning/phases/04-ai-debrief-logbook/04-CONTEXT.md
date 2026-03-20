# Phase 4: AI Debrief + Logbook - Context

**Gathered:** 2026-03-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver on-device AI post-flight debrief via Apple Foundation Models, digital logbook with auto-populated entries from recording data, and currency warning integration. After landing, a pilot reviews an AI-generated debrief, confirms a logbook entry, and sees currency warnings if anything is approaching expiry.

</domain>

<decisions>
## Implementation Decisions

### AI Debrief Experience
- Debrief triggered by pilot via "Debrief" button on flight detail view after recording ends, with streaming output — pilot initiates when ready, sees results build in real time
- Output structured as 4 sections: Narrative Summary, Per-Phase Observations (grouped by detected flight phase), Improvement Suggestions, Overall Rating (1-5 scale)
- Generated debrief saved to GRDB alongside flight record with "Regenerate" button available — pilot can revisit anytime and re-run if unsatisfied
- When Foundation Models unavailable: friendly message "AI Debrief requires Apple Intelligence. You can still review your flight track, transcript, and logbook entry." with link to device Settings — non-alarming, highlights what IS still available

### Logbook
- Auto-create logbook entry when recording stops: date, departure (R-tree nearest airport at recording start), arrival (R-tree nearest at end), route, block time, aircraft from active profile — zero pilot effort required
- Logbook list view is chronological with date, departure→arrival, duration, aircraft type — scannable like a traditional paper logbook
- All fields editable before pilot taps "Confirm" which locks the entry — review step catches auto-detection errors (e.g., wrong airport)
- Manual logbook entry creation supported for flights not recorded with the app — pilots need complete logbooks

### Currency Warnings Integration
- After confirming a logbook entry, currency calculations update immediately and show any newly triggered warnings inline — immediate feedback loop
- 61.57 night passenger-carrying automatically calculated from confirmed logbook entries (night landing count) in last 90 days — closes the manual-entry gap from Phase 2
- Warning thresholds: green (>30 days from expiry), yellow (1-30 days), red (expired) — consistent with Phase 2 profile design
- Non-blocking warning banner at top of map view on app launch if any currency is yellow or red — pilot sees it without being blocked from using the app

### Claude's Discretion
- @Generable FlightDebrief schema field names and constraints
- FlightSummaryBuilder token compression algorithm details (must stay under ~3,000 tokens for 4,096 context window)
- LanguageModelSession lifecycle management (prewarm timing, session reuse vs discard)
- Exact logbook entry SwiftData model fields beyond the specified ones
- Debrief streaming UI animation and layout details
- Rating scale criteria (what constitutes a 1 vs 5)

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `FlightRecord.swift` — SwiftData @Model (reference for logbook entry model)
- `FlightDetailView.swift` — Existing flight detail UI (reference for debrief display layout)
- `FlightListView.swift` — Existing flight list view (reference for logbook list)
- `LogbookView.swift` + `LogbookViewModel.swift` — Existing logbook implementation (reference)
- Currency computation patterns from Phase 2 PilotProfile

### Established Patterns
- SwiftData @Model for user data (logbook entries)
- GRDB for flight data (GPS track, transcript, debrief content)
- ViewModel pattern with @Published properties

### Integration Points
- Phase 3 RecordingCoordinator provides: completed GPS track (GRDB), finalized transcript segments (GRDB), flight phase markers (GRDB)
- Phase 2 PilotProfile and AircraftProfile for logbook association
- Phase 1 AviationDatabase for departure/arrival airport reverse lookup via R-tree
- Phase 2 currency tracking computation layer
- Apple Foundation Models: LanguageModelSession, @Generable, @Guide macros (iOS 26)

</code_context>

<specifics>
## Specific Ideas

- FlightSummaryBuilder must compress full flight data (potentially hours of GPS + transcript) into under 3,000 tokens for Foundation Models' 4,096 context window
- Per-phase chunking strategy: summarize each flight phase independently, then combine
- session.prewarm() called when FlightDetailView appears, session discarded on dismiss
- PartiallyGenerated<FlightDebrief> for streaming structured output to the UI
- Transcript from GRDB persisted separately for the Codable session transcript resumption

</specifics>

<deferred>
## Deferred Ideas

- Claude API premium debrief tier for complex/long flights (v2 — validate on-device quality first)
- Debrief comparison across flights (trend analysis over multiple debriefs)
- Logbook export to ForeFlight CSV format (v2)
- CloudKit sync for logbook entries (v2)

</deferred>

---
*Phase: 04-ai-debrief-logbook*
*Context gathered: 2026-03-20 via Smart Discuss (autonomous)*
