# Phase 4: AI Debrief + Logbook - Research

**Researched:** 2026-03-21
**Domain:** Apple Foundation Models (on-device LLM), SwiftData logbook modeling, FAR currency computation
**Confidence:** HIGH

## Summary

Phase 4 integrates Apple's Foundation Models framework (iOS 26) for on-device AI flight debrief generation, builds a digital logbook with auto-populated entries from recording data, and wires currency warnings into the logbook confirmation flow. The core technical challenge is the 4,096-token context window constraint -- compressing potentially hours of GPS track data and cockpit transcript into under 3,000 tokens while preserving per-phase fidelity for meaningful debrief generation.

The Foundation Models framework provides `LanguageModelSession` with `streamResponse(to:generating:)` for structured streaming output, the `@Generable` macro for compile-time schema definition with constrained decoding (guaranteeing structural correctness), and `@Guide` for natural-language field descriptions and value constraints. The `PartiallyGenerated` wrapper enables progressive UI updates as the model generates each field. Availability checking via `SystemLanguageModel.default.availability` handles graceful degradation on unsupported devices.

The logbook builds on existing SwiftData patterns (SchemaV1) and the existing `FlightRecord` model already has `hasDebrief`, `departureICAO`, `arrivalICAO`, and `aircraftProfileID` fields. A new `LogbookEntry` model captures confirmed pilot-reviewed logbook data separate from the raw recording metadata. Currency integration leverages the existing `CurrencyService` (static pure functions) and `PilotProfileViewModel` pattern.

**Primary recommendation:** Build FlightSummaryBuilder as a pure-function service that reads from RecordingDatabase (GRDB) and compresses flight data per-phase into a token-budgeted prompt. DebriefEngine wraps LanguageModelSession lifecycle with prewarm-on-appear / discard-on-dismiss pattern. LogbookEntry as a new SwiftData @Model auto-populated from FlightRecordingSummary with R-tree reverse lookup for airports. Currency recomputation triggered on logbook entry confirmation.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Debrief triggered by pilot via "Debrief" button on flight detail view after recording ends, with streaming output -- pilot initiates when ready, sees results build in real time
- Output structured as 4 sections: Narrative Summary, Per-Phase Observations (grouped by detected flight phase), Improvement Suggestions, Overall Rating (1-5 scale)
- Generated debrief saved to GRDB alongside flight record with "Regenerate" button available -- pilot can revisit anytime and re-run if unsatisfied
- When Foundation Models unavailable: friendly message "AI Debrief requires Apple Intelligence. You can still review your flight track, transcript, and logbook entry." with link to device Settings -- non-alarming, highlights what IS still available
- Auto-create logbook entry when recording stops: date, departure (R-tree nearest airport at recording start), arrival (R-tree nearest at end), route, block time, aircraft from active profile -- zero pilot effort required
- Logbook list view is chronological with date, departure->arrival, duration, aircraft type -- scannable like a traditional paper logbook
- All fields editable before pilot taps "Confirm" which locks the entry -- review step catches auto-detection errors (e.g., wrong airport)
- Manual logbook entry creation supported for flights not recorded with the app -- pilots need complete logbooks
- After confirming a logbook entry, currency calculations update immediately and show any newly triggered warnings inline -- immediate feedback loop
- 61.57 night passenger-carrying automatically calculated from confirmed logbook entries (night landing count) in last 90 days -- closes the manual-entry gap from Phase 2
- Warning thresholds: green (>30 days from expiry), yellow (1-30 days), red (expired) -- consistent with Phase 2 profile design
- Non-blocking warning banner at top of map view on app launch if any currency is yellow or red -- pilot sees it without being blocked from using the app

### Claude's Discretion
- @Generable FlightDebrief schema field names and constraints
- FlightSummaryBuilder token compression algorithm details (must stay under ~3,000 tokens for 4,096 context window)
- LanguageModelSession lifecycle management (prewarm timing, session reuse vs discard)
- Exact logbook entry SwiftData model fields beyond the specified ones
- Debrief streaming UI animation and layout details
- Rating scale criteria (what constitutes a 1 vs 5)

### Deferred Ideas (OUT OF SCOPE)
- Claude API premium debrief tier for complex/long flights (v2 -- validate on-device quality first)
- Debrief comparison across flights (trend analysis over multiple debriefs)
- Logbook export to ForeFlight CSV format (v2)
- CloudKit sync for logbook entries (v2)
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DEBRIEF-01 | After flight, app generates structured debrief on-device via Apple Foundation Models: narrative summary, per-phase observations, improvements, overall rating | Foundation Models framework with @Generable FlightDebrief schema, LanguageModelSession.streamResponse, PartiallyGenerated streaming |
| DEBRIEF-02 | Flight data is compressed into a summary under 3,000 tokens before debrief generation (4,096 context window constraint) | FlightSummaryBuilder with per-phase chunking strategy, ~4.2 chars/token ratio, token counting via SystemLanguageModel.tokenUsage |
| DEBRIEF-03 | App gracefully degrades when Foundation Models is unavailable (unsupported device, Apple Intelligence disabled) with clear user messaging | SystemLanguageModel.default.availability switch with .unavailable reason handling |
| LOG-01 | App maintains a digital logbook with entries auto-populated from recording: date, departure, arrival, route, duration, aircraft | LogbookEntry SwiftData @Model, auto-population from FlightRecordingSummary + R-tree reverse lookup |
| LOG-02 | Pilot can review and edit auto-populated logbook entries before confirming | Editable form with "Confirm" action that sets isConfirmed flag, locks entry |
| LOG-03 | App tracks pilot currency: medical expiry, flight review date, 61.57 night passenger-carrying (3 T/O + landings in 90 days) | Existing CurrencyService extended with logbook-derived night landing aggregation |
| LOG-04 | App displays currency warnings when medical, flight review, or 61.57 requirements are approaching expiry | CurrencyBadge (existing), non-blocking map banner, inline post-confirmation warnings |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| FoundationModels | iOS 26+ | On-device LLM for structured debrief generation | Apple first-party; only option for on-device Foundation Models |
| SwiftData | iOS 26+ | LogbookEntry @Model persistence | Already used for all user data (SchemaV1) |
| GRDB.swift | 7.x (already in project) | Debrief storage alongside flight recording data | Already powers RecordingDatabase; debrief content stored with flight data |
| Observation | iOS 26+ | @Observable ViewModels | Already used project-wide (@Observable pattern, not ObservableObject) |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| SwiftUI | iOS 26+ | Debrief streaming UI, logbook views, currency warnings | All view layer |
| os.Logger | iOS 26+ | Structured logging for debrief/logbook operations | Debug and diagnostic logging |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Foundation Models | Claude API | Cloud-dependent, requires account, costs money -- deferred to v2 PREMIUM-01 |
| SwiftData for LogbookEntry | GRDB for logbook | SwiftData aligns with existing user data pattern; GRDB reserved for high-frequency aviation/recording data |
| Separate debrief DB | Debrief in RecordingDatabase | RecordingDatabase already has flight-keyed tables; add debrief_results table via migration v2 |

**Installation:** No new dependencies. Foundation Models is a system framework (`import FoundationModels`). GRDB and SwiftData already in project.

## Architecture Patterns

### Recommended Project Structure
```
efb-212/
├── Services/
│   ├── Debrief/
│   │   ├── FlightSummaryBuilder.swift      # Compresses flight data to token-budgeted prompt
│   │   └── DebriefEngine.swift             # LanguageModelSession lifecycle + generation
│   └── Recording/                           # Existing recording services
├── Data/
│   ├── Models/
│   │   └── LogbookEntry.swift              # New SwiftData @Model
│   └── RecordingDatabase.swift             # Extended with debrief_results table (migration v2)
├── ViewModels/
│   ├── DebriefViewModel.swift              # Streaming debrief UI state
│   └── LogbookViewModel.swift              # Logbook CRUD, auto-population, currency wiring
├── Views/
│   ├── Flights/
│   │   └── DebriefView.swift               # Streaming debrief display
│   ├── Logbook/
│   │   ├── LogbookListView.swift           # Chronological logbook list
│   │   ├── LogbookEntryEditView.swift      # Review/edit before confirm
│   │   └── LogbookEntryDetailView.swift    # Confirmed entry detail
│   ├── Map/
│   │   └── CurrencyWarningBanner.swift     # Non-blocking map banner
│   └── Components/
│       └── CurrencyBadge.swift             # Existing -- reused
└── Core/
    └── Types.swift                          # Extended with debrief-related types
```

### Pattern 1: @Generable FlightDebrief Schema
**What:** Compile-time schema for structured debrief output with constrained decoding
**When to use:** Debrief generation -- guarantees the model outputs valid structured data
**Example:**
```swift
// Source: Apple Foundation Models framework documentation + WWDC25 code-along
import FoundationModels

@Generable
struct FlightDebrief {
    @Guide(description: "A concise narrative summary of the entire flight in 2-3 sentences.")
    let narrativeSummary: String

    @Guide(description: "Observations grouped by detected flight phase.")
    let phaseObservations: [PhaseObservation]

    @Guide(description: "Specific, actionable improvement suggestions for the pilot.")
    let improvements: [String]

    @Guide(description: "Overall flight rating.", .range(1...5))
    let overallRating: Int
}

@Generable
struct PhaseObservation {
    @Guide(description: "Flight phase name: preflight, taxi, takeoff, departure, cruise, approach, landing, or postflight.")
    let phase: String

    @Guide(description: "Key observations during this phase.")
    let observations: [String]

    @Guide(description: "Whether this phase was executed well.")
    let executedWell: Bool
}
```

### Pattern 2: LanguageModelSession Lifecycle (Prewarm / Stream / Discard)
**What:** Session creation on view appear, prewarm for fast first response, discard on dismiss
**When to use:** DebriefEngine manages session lifecycle tied to view lifecycle
**Example:**
```swift
// Source: Apple Developer code-along + blog pattern
@Observable
@MainActor
final class DebriefViewModel {
    private(set) var debrief: FlightDebrief.PartiallyGenerated?
    private(set) var isGenerating: Bool = false
    var error: Error?

    private var session: LanguageModelSession?

    func prewarm(instructions: String) {
        session = LanguageModelSession(instructions: instructions)
        session?.prewarm()
    }

    func generate(prompt: Prompt) async {
        guard let session else { return }
        isGenerating = true
        defer { isGenerating = false }

        do {
            let stream = session.streamResponse(
                to: prompt,
                generating: FlightDebrief.self
            )
            for try await partial in stream {
                self.debrief = partial.content
            }
        } catch {
            self.error = error
        }
    }

    func discard() {
        session = nil
        debrief = nil
    }
}
```

### Pattern 3: Availability Checking with Graceful Degradation
**What:** Check device capability before showing debrief UI
**When to use:** FlightDetailView decides whether to show "Debrief" button or unavailable message
**Example:**
```swift
// Source: Apple Developer Documentation
let model = SystemLanguageModel.default

switch model.availability {
case .available:
    // Show "Debrief" button
    DebriefButton(flightID: flightID)

case .unavailable(let reason):
    // Show friendly unavailable message
    VStack(spacing: 12) {
        Image(systemName: "apple.intelligence.badge.xmark")
            .font(.largeTitle)
            .foregroundStyle(.secondary)

        Text("AI Debrief requires Apple Intelligence.")
            .font(.headline)

        Text("You can still review your flight track, transcript, and logbook entry.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)

        if case .appleIntelligenceNotEnabled = reason {
            Link("Open Settings", destination: URL(string: UIApplication.openSettingsURLString)!)
        }
    }
}
```

### Pattern 4: Token-Budgeted Flight Summary Compression
**What:** Compress hours of GPS + transcript data into ~3,000 tokens for the 4,096 context window
**When to use:** FlightSummaryBuilder processes raw GRDB data before debrief prompt construction
**Strategy:**
```
Total budget: 4,096 tokens
- Instructions/schema: ~200 tokens (system prompt + @Generable schema overhead)
- Flight context: ~300 tokens (aircraft, pilot, departure, arrival, duration, date)
- Per-phase summaries: ~2,000 tokens (8 phases x 250 tokens each, variable)
- Response headroom: ~1,500 tokens (for the generated debrief)
- Safety margin: ~96 tokens

Compression approach:
1. Group track points by phase (from phase_markers table)
2. Per phase: compute summary stats (avg altitude, avg speed, duration, distance)
3. Per phase: select top 3 transcript segments by confidence score
4. Per phase: note any anomalies (sharp altitude changes, speed deviations)
5. Combine into structured prompt text, ~250 tokens per phase
6. Token estimation: ~4.2 characters per token (English text average)
```

### Pattern 5: LogbookEntry Auto-Population from Recording
**What:** Create a pre-filled logbook entry when recording stops
**When to use:** RecordingCoordinator.stopRecording() produces FlightRecordingSummary; caller resolves airports via R-tree and creates LogbookEntry
**Example:**
```swift
// After recording stops, in the ViewModel layer:
let summary = await coordinator.stopRecording()
guard let summary else { return }

// Resolve departure/arrival via R-tree nearest airport
let startPoints = try recordingDB.trackPoints(forFlight: summary.flightID)
if let firstPoint = startPoints.first {
    let coord = CLLocationCoordinate2D(latitude: firstPoint.latitude, longitude: firstPoint.longitude)
    let nearest = try databaseService.nearestAirports(to: coord, count: 1)
    departureICAO = nearest.first?.icao
}
// Same for arrival using last track point

// Create LogbookEntry in SwiftData
let entry = SchemaV1.LogbookEntry()
entry.flightID = summary.flightID
entry.date = summary.startDate
entry.departureICAO = departureICAO
entry.arrivalICAO = arrivalICAO
entry.durationSeconds = summary.endDate.timeIntervalSince(summary.startDate)
entry.aircraftProfileID = appState.activeAircraftProfileID?.uuidString
entry.isConfirmed = false  // Pilot must review and confirm
modelContext.insert(entry)
```

### Anti-Patterns to Avoid
- **Loading full transcript into prompt:** A 2-hour flight could have 1000+ transcript segments. Always summarize per-phase, never dump raw text.
- **Reusing LanguageModelSession across flights:** Each debrief is independent. Create a fresh session per generation to avoid transcript accumulation consuming context.
- **Blocking UI during debrief generation:** Always use `streamResponse` with `PartiallyGenerated` for progressive rendering. Never use `respond` (waits for complete output).
- **Coupling logbook confirmation to debrief generation:** These are independent actions. A pilot can confirm a logbook entry without generating a debrief, and vice versa.
- **Storing debrief in SwiftData:** Debrief content is flight-specific high-volume data (like track points); it belongs in GRDB alongside the recording data, not in SwiftData.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| On-device LLM inference | Custom ML model loading/inference | `LanguageModelSession` from FoundationModels | Apple manages model loading, memory, Neural Engine scheduling |
| Structured output parsing | JSON parsing from raw LLM text | `@Generable` macro + constrained decoding | Compile-time guarantees; no malformed output possible |
| Token counting | Character-counting heuristic | `SystemLanguageModel.tokenUsage(for:)` (iOS 26.4+) | Exact count; fallback to ~4.2 chars/token estimation for iOS 26.0-26.3 |
| Streaming structured output | Manual partial JSON parsing | `PartiallyGenerated<T>` from `streamResponse` | Framework handles incremental field population |
| Flight phase grouping | Manual timestamp bucketing | `RecordingDatabase.phaseMarkers(forFlight:)` | Already computed and stored by FlightPhaseDetector during recording |
| Airport reverse lookup | Distance calculation from coordinates | `AviationDatabase.nearestAirports(to:count:)` | R-tree spatial index already operational |
| Currency computation | Manual date arithmetic | `CurrencyService` static methods | Already tested (13 passing tests), handles all FAR edge cases |

**Key insight:** The Foundation Models framework does the heavy lifting for LLM interaction -- the custom work is data compression (FlightSummaryBuilder) and lifecycle management (DebriefEngine). Everything else uses existing infrastructure.

## Common Pitfalls

### Pitfall 1: Exceeding the 4,096-Token Context Window
**What goes wrong:** Long flights (2+ hours) with dense transcripts blow past the context limit, causing `GenerationError.exceededContextWindowSize`
**Why it happens:** Raw flight data for a 2-hour flight can be 50K+ characters. System instructions + @Generable schema consume ~200 tokens overhead.
**How to avoid:** FlightSummaryBuilder MUST compress aggressively. Budget: ~300 tokens for flight metadata, ~2,000 for per-phase summaries, ~1,500 for response. Use `SystemLanguageModel.tokenUsage(for:)` (iOS 26.4+) or estimate at 4.2 chars/token. Cap per-phase summary at 250 tokens (~1,050 chars).
**Warning signs:** Test with long flights (3+ hours). If generation fails silently or throws, check token budget.

### Pitfall 2: Model Not Ready / Apple Intelligence Disabled
**What goes wrong:** App crashes or shows blank screen when Foundation Models unavailable
**Why it happens:** Not all iPads support Apple Intelligence. Users may disable it in Settings. The model may be downloading/updating.
**How to avoid:** Always check `SystemLanguageModel.default.availability` BEFORE creating a session. Handle all three `.unavailable` reasons: `.deviceNotEligible`, `.appleIntelligenceNotEnabled`, `.modelNotReady`. Show the decided friendly message with Settings link.
**Warning signs:** Test on older iPad simulator. Check `.modelNotReady` case -- may need a retry mechanism.

### Pitfall 3: LanguageModelSession Memory Pressure (~1.2 GB)
**What goes wrong:** Model loads into memory (~1.2 GB), competing with MapLibre and audio recording resources
**Why it happens:** Foundation Models requires significant RAM. iPad Air (4 GB) vs iPad Pro (8-16 GB) have different headroom.
**How to avoid:** Create session only when pilot taps "Debrief", discard immediately on view dismiss. Never keep a session alive when not actively generating. Use `prewarm()` only on FlightDetailView.onAppear, not globally.
**Warning signs:** Memory warnings during debrief generation on lower-end iPads.

### Pitfall 4: GRDB Migration Ordering with RecordingDatabase
**What goes wrong:** Adding a debrief_results table to RecordingDatabase requires a new migration that runs after the existing v1 migration
**Why it happens:** GRDB migrations are named and ordered. A new migration "v2" must be registered after "v1".
**How to avoid:** Register migration "v2_debrief" after "v1" in RecordingDatabase.migrate(). The new table has a foreign key-like reference to flightID (TEXT, not enforced FK for GRDB simplicity). Include all debrief fields as columns.
**Warning signs:** Migration runs on first launch after upgrade. Test with existing recording.sqlite that has flight data.

### Pitfall 5: SwiftData Schema Version Not Bumped for LogbookEntry
**What goes wrong:** Adding a new @Model to SchemaV1 without adding it to the container causes crashes
**Why it happens:** `modelContainer(for:)` in efb_212App.swift lists models explicitly. Missing a model = silent data loss or crash.
**How to avoid:** Add `SchemaV1.LogbookEntry.self` to the `models` array in `SchemaV1.models`, to `modelContainer(for:)` in `efb_212App.swift`, and to `SchemaV1.versionIdentifier` if needed. SwiftData handles lightweight migration for additive changes (new model) within the same schema version.
**Warning signs:** "Failed to find matching model" crash on launch after adding LogbookEntry.

### Pitfall 6: Night Landing Auto-Calculation from Logbook Entries
**What goes wrong:** CurrencyService expects `[(date: Date, count: Int)]` tuples from PilotProfile.nightLandingEntries. Logbook entries don't automatically feed into this.
**Why it happens:** Phase 2 built manual night landing entry. Phase 4 needs to bridge confirmed logbook entries (which may include night landings) into the currency computation pipeline.
**How to avoid:** When a logbook entry is confirmed with night landing count > 0, automatically append a NightLandingEntry to the active PilotProfile. CurrencyService already handles the rest. This is the "closes the manual-entry gap" decision from CONTEXT.md.
**Warning signs:** Currency stays expired even after confirming a flight with night landings.

### Pitfall 7: R-Tree Reverse Lookup Returns Wrong Airport
**What goes wrong:** Auto-detected departure/arrival is the nearest airport by distance, which may not be where the pilot actually flew from/to
**Why it happens:** GPS position at recording start may be at a nearby FBO, parking lot, or the wrong side of a paired airport (e.g., KSFO vs KOAK across the bay)
**How to avoid:** This is WHY the "review before confirm" step exists. Show the detected airport clearly with a search/picker to change it. The editable field is the design solution, not a technical fix.
**Warning signs:** Test with flights near closely-spaced airports.

## Code Examples

### GRDB Migration v2: Debrief Results Table
```swift
// Source: Existing RecordingDatabase.swift migration pattern
// Add to RecordingDatabase.migrate() after "v1" migration

migrator.registerMigration("v2_debrief") { db in
    try db.execute(sql: """
        CREATE TABLE IF NOT EXISTS debrief_results (
            id TEXT PRIMARY KEY,
            flightID TEXT NOT NULL,
            narrativeSummary TEXT NOT NULL,
            phaseObservationsJSON TEXT NOT NULL,
            improvementsJSON TEXT NOT NULL,
            overallRating INTEGER NOT NULL,
            generatedAt REAL NOT NULL,
            promptTokensEstimate INTEGER,
            responseTokensEstimate INTEGER
        )
        """)
    try db.execute(sql: "CREATE INDEX IF NOT EXISTS idx_debrief_results_flight ON debrief_results(flightID)")
}
```

### DebriefRecord GRDB Model
```swift
// Source: Existing TrackPointRecord/TranscriptSegmentRecord pattern
struct DebriefRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    static let databaseTableName = "debrief_results"

    let id: UUID
    let flightID: UUID
    let narrativeSummary: String
    let phaseObservationsJSON: String  // JSON-encoded [PhaseObservation]
    let improvementsJSON: String       // JSON-encoded [String]
    let overallRating: Int             // 1-5
    let generatedAt: Date
    let promptTokensEstimate: Int?
    let responseTokensEstimate: Int?
}
```

### LogbookEntry SwiftData Model
```swift
// Source: Existing SchemaV1 pattern from FlightRecord.swift
extension SchemaV1 {
    @Model
    final class LogbookEntry {
        var id: UUID = UUID()
        var flightID: UUID?              // Links to RecordingDatabase flight (nil for manual entries)
        var date: Date = Date()
        var departureICAO: String?
        var departureName: String?
        var arrivalICAO: String?
        var arrivalName: String?
        var route: String?               // Route string (waypoints)
        var durationSeconds: Double = 0  // Block time -- seconds
        var aircraftProfileID: String?   // UUID string of aircraft used
        var aircraftType: String?        // Denormalized for display without profile lookup
        var pilotProfileID: String?      // UUID string of pilot
        var nightLandingCount: Int = 0   // For 61.57 currency auto-calculation
        var dayLandingCount: Int = 0     // Total day landings
        var notes: String?               // Pilot remarks
        var isConfirmed: Bool = false    // Locked after pilot review
        var hasDebrief: Bool = false     // Whether AI debrief has been generated
        var createdAt: Date = Date()

        init() {}
    }
}
```

### FlightSummaryBuilder Token Compression
```swift
// Source: Project-specific implementation guided by Apple token management patterns
struct FlightSummaryBuilder {

    /// Maximum characters for the combined flight summary (targeting ~3,000 tokens at 4.2 chars/token).
    static let maxSummaryChars = 12_600  // ~3,000 tokens
    static let perPhaseCharBudget = 1_050 // ~250 tokens per phase

    /// Build a token-budgeted prompt from flight recording data.
    static func buildPrompt(
        flightID: UUID,
        recordingDB: RecordingDatabase,
        flightMetadata: FlightMetadata
    ) throws -> Prompt {
        let phases = try recordingDB.phaseMarkers(forFlight: flightID)
        let trackPoints = try recordingDB.trackPoints(forFlight: flightID)
        let transcripts = try recordingDB.transcriptSegments(forFlight: flightID)

        var phaseSummaries: [String] = []

        for phase in phases {
            let phasePoints = trackPoints.filter { point in
                point.timestamp >= phase.startTimestamp &&
                (phase.endTimestamp == nil || point.timestamp <= phase.endTimestamp!)
            }
            let phaseTranscripts = transcripts.filter { seg in
                seg.flightPhase == phase.phase
            }

            let summary = summarizePhase(
                phase: phase,
                trackPoints: phasePoints,
                transcripts: phaseTranscripts
            )
            phaseSummaries.append(summary)
        }

        return Prompt {
            """
            Analyze this flight and provide a structured debrief.

            Flight: \(flightMetadata.description)

            \(phaseSummaries.joined(separator: "\n\n"))
            """
        }
    }

    /// Summarize a single flight phase within the per-phase character budget.
    private static func summarizePhase(
        phase: PhaseMarkerRecord,
        trackPoints: [TrackPointRecord],
        transcripts: [TranscriptSegmentRecord]
    ) -> String {
        // Compute stats
        let avgAlt = trackPoints.isEmpty ? 0 : trackPoints.map(\.altitudeFeet).reduce(0, +) / Double(trackPoints.count)
        let avgSpeed = trackPoints.isEmpty ? 0 : trackPoints.map(\.groundSpeedKnots).reduce(0, +) / Double(trackPoints.count)
        let duration = phase.endTimestamp.map { $0.timeIntervalSince(phase.startTimestamp) } ?? 0

        // Top 3 transcripts by confidence
        let topTranscripts = transcripts
            .filter { !$0.text.hasPrefix("[INTERRUPTION:") }
            .sorted { $0.confidence > $1.confidence }
            .prefix(3)
            .map { $0.text }

        var summary = "[\(phase.phase.uppercased())] Duration: \(Int(duration))s, Avg Alt: \(Int(avgAlt))ft, Avg GS: \(Int(avgSpeed))kts"

        if !topTranscripts.isEmpty {
            summary += "\nComms: " + topTranscripts.joined(separator: " | ")
        }

        // Truncate to budget
        if summary.count > perPhaseCharBudget {
            summary = String(summary.prefix(perPhaseCharBudget - 3)) + "..."
        }

        return summary
    }
}
```

### PartiallyGenerated Streaming UI
```swift
// Source: Apple WWDC25 code-along pattern
struct DebriefView: View {
    let viewModel: DebriefViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let debrief = viewModel.debrief {
                    // Narrative summary
                    if let narrative = debrief.narrativeSummary {
                        Text(narrative)
                            .font(.body)
                            .contentTransition(.opacity)
                    }

                    // Per-phase observations
                    if let phases = debrief.phaseObservations {
                        ForEach(phases, id: \.phase) { phase in
                            PhaseObservationCard(observation: phase)
                        }
                    }

                    // Improvements
                    if let improvements = debrief.improvements {
                        Section("Improvements") {
                            ForEach(improvements, id: \.self) { item in
                                Label(item, systemImage: "lightbulb")
                            }
                        }
                    }

                    // Rating
                    if let rating = debrief.overallRating {
                        RatingView(rating: rating)
                    }
                }

                if viewModel.isGenerating {
                    ProgressView("Generating debrief...")
                }
            }
            .padding()
        }
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Cloud LLM APIs for on-device AI | Apple Foundation Models (on-device, no API key) | iOS 26 / WWDC 2025 | Zero cloud dependency, full privacy, offline capable |
| Raw text LLM output + manual parsing | @Generable + constrained decoding | iOS 26 / WWDC 2025 | Guaranteed structural correctness, no parsing errors |
| ObservableObject + @Published | @Observable macro | iOS 17+ (project already uses) | Cleaner syntax, better performance |
| Core Data | SwiftData | iOS 17+ (project already uses) | Swift-native, simpler API, CloudKit-ready |

**Deprecated/outdated:**
- `ObservableObject` / `@Published`: Project uses `@Observable` macro exclusively (Phase 1 decision)
- Manual JSON parsing of LLM output: `@Generable` eliminates this entirely
- Token counting by character estimation only: `SystemLanguageModel.tokenUsage(for:)` available in iOS 26.4+

## Open Questions

1. **Token usage API availability timing**
   - What we know: `SystemLanguageModel.tokenUsage(for:)` and `contextSize` are available in iOS 26.4+ with `@backDeployed`
   - What's unclear: Whether the app targets iOS 26.0 or 26.4 minimum -- affects whether we can use exact token counting or must rely on estimation
   - Recommendation: Use estimation (4.2 chars/token) as primary strategy, add exact counting as enhancement if targeting iOS 26.4+. The estimation is conservative enough to be safe.

2. **Foundation Models on iPad Air (4 GB RAM)**
   - What we know: Model requires ~1.2 GB RAM. iPad Air 2022 has 8 GB, but older iPads may have 4 GB
   - What's unclear: Whether Apple restricts Foundation Models to 8 GB+ devices or handles memory pressure gracefully
   - Recommendation: The `SystemLanguageModel.default.availability` check handles this -- `.deviceNotEligible` will be returned for unsupported hardware. No special handling needed beyond the availability check.

3. **Debrief regeneration behavior**
   - What we know: User decision says "Regenerate" button available, debrief saved to GRDB
   - What's unclear: Whether regeneration overwrites the previous debrief or stores history
   - Recommendation: Overwrite (INSERT OR REPLACE on flightID). Single debrief per flight keeps it simple. v2 could store history if desired.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (already in use, `@Suite`, `@Test`, `#expect`) |
| Config file | Xcode scheme test configuration |
| Quick run command | `xcodebuild test -scheme efb-212 -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' -only-testing:efb-212Tests/FlightSummaryBuilderTests` |
| Full suite command | `xcodebuild test -scheme efb-212 -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)'` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DEBRIEF-01 | @Generable FlightDebrief schema compiles and generates valid instances | unit | `xcodebuild test ... -only-testing:efb-212Tests/DebriefSchemaTests` | Wave 0 |
| DEBRIEF-02 | FlightSummaryBuilder compresses flight data within token budget | unit | `xcodebuild test ... -only-testing:efb-212Tests/FlightSummaryBuilderTests` | Wave 0 |
| DEBRIEF-03 | Availability check returns correct states for all .unavailable reasons | unit | `xcodebuild test ... -only-testing:efb-212Tests/DebriefAvailabilityTests` | Wave 0 |
| LOG-01 | LogbookEntry auto-populates from FlightRecordingSummary | unit | `xcodebuild test ... -only-testing:efb-212Tests/LogbookAutoPopulationTests` | Wave 0 |
| LOG-02 | LogbookEntry fields are editable before confirmation, locked after | unit | `xcodebuild test ... -only-testing:efb-212Tests/LogbookEntryTests` | Wave 0 |
| LOG-03 | CurrencyService computes 61.57 from confirmed logbook entries | unit | `xcodebuild test ... -only-testing:efb-212Tests/CurrencyServiceTests` (extend existing) | Partial (existing tests cover medical/BFR/night, need logbook-derived night) |
| LOG-04 | Currency warning banners display for warning/expired states | manual-only | Visual verification on simulator | N/A -- UI test |

### Sampling Rate
- **Per task commit:** Quick run for affected test suite
- **Per wave merge:** Full suite: `xcodebuild test -scheme efb-212 -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)'`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `efb-212Tests/ServiceTests/FlightSummaryBuilderTests.swift` -- covers DEBRIEF-02
- [ ] `efb-212Tests/ServiceTests/DebriefSchemaTests.swift` -- covers DEBRIEF-01 (schema compilation)
- [ ] `efb-212Tests/ServiceTests/DebriefAvailabilityTests.swift` -- covers DEBRIEF-03
- [ ] `efb-212Tests/DataTests/LogbookEntryTests.swift` -- covers LOG-01, LOG-02
- [ ] `efb-212Tests/ViewModelTests/LogbookViewModelTests.swift` -- re-enable and update disabled tests
- [ ] `efb-212Tests/Mocks/MockRecordingDatabase.swift` -- mock for FlightSummaryBuilder tests

Note: DebriefEngine actual generation cannot be unit tested without a real Foundation Models runtime (requires device with Apple Intelligence). Test the FlightSummaryBuilder (pure data compression) and schema definition (compilation) instead. DebriefEngine integration is manual/device testing.

## Sources

### Primary (HIGH confidence)
- [Apple Foundation Models Documentation](https://developer.apple.com/documentation/FoundationModels) - Framework overview, API surface
- [Apple LanguageModelSession Documentation](https://developer.apple.com/documentation/foundationmodels/languagemodelsession) - Session API, respond/streamResponse
- [Apple TN3193: Managing Context Window](https://developer.apple.com/documentation/technotes/tn3193-managing-the-on-device-foundation-model-s-context-window) - Token limits, context management
- [WWDC25 Code-Along: Foundation Models](https://developer.apple.com/events/resources/code-along-205/) - Complete code patterns for @Generable, streaming, tools
- [WWDC25: Meet the Foundation Models framework](https://developer.apple.com/videos/play/wwdc2025/286/) - Framework introduction
- [WWDC25: Deep dive into Foundation Models](https://developer.apple.com/videos/play/wwdc2025/301/) - Advanced patterns

### Secondary (MEDIUM confidence)
- [Artem Novichkov: Getting Started with Foundation Models](https://artemnovichkov.com/blog/getting-started-with-apple-foundation-models) - Verified code patterns for session, availability, tools
- [Artem Novichkov: Tracking Token Usage](https://artemnovichkov.com/blog/tracking-token-usage-in-foundation-models) - tokenUsage API, contextSize property
- [CreateWithSwift: Exploring Foundation Models](https://www.createwithswift.com/exploring-the-foundation-models-framework/) - @Generable types, @Guide constraints, streaming
- [AzamSharp: Ultimate Guide to Foundation Models](https://azamsharp.com/2025/06/18/the-ultimate-guide-to-the-foundation-models-framework.html) - Structured output, tool patterns
- [Zats.io: Context Window Management](https://zats.io/blog/making-the-most-of-apple-foundation-models-context-window/) - Compression strategies, summarization

### Tertiary (LOW confidence)
- Token-to-character ratio (~4.2 chars/token) -- empirical observation from multiple sources, not officially documented by Apple

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Apple first-party framework, no alternatives needed, existing GRDB/SwiftData patterns established in project
- Architecture: HIGH - @Generable and streaming patterns well-documented from WWDC25 and multiple verified sources
- Pitfalls: HIGH - Token budget constraint is well-understood (4,096 limit documented in TN3193); GRDB migration pattern established in existing code
- Token compression: MEDIUM - The per-phase chunking strategy is sound in principle but untested against real flight data; actual token counts may vary

**Research date:** 2026-03-21
**Valid until:** 2026-04-21 (30 days -- Foundation Models API is stable post-iOS 26 release)
