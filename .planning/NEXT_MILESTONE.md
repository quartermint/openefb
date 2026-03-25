# Milestone Seed: OpenEFB Phase 2 — AI Flight Debrief

## Context
Sprints 1-3 complete (61 Swift files, 215+ tests, 3,700 airports seeded). Codebase mapped in `.planning/codebase/`. No GSD PROJECT.md exists yet — run `/gsd:new-project` or `/gsd:new-milestone` to initialize.

Phase 2 was blocked on: SFR package extraction for flight recording, Apple Foundation Models for AI debrief.

## Vision
On-device AI flight debrief that analyzes flight recordings and provides pilot feedback — fully private, no cloud required for base tier.

## Architecture: Two-Tier Debrief Engine

### Tier 1: Apple Foundation Models (Free/Offline — Default)
- On-device, iOS 26.0+ (26.3 shipping, SDK confirmed in Xcode 26.0.1)
- **Confirmed shipping APIs (from swiftinterface, module v1.0.49):**
  - `@Generable` macro: compile-time structured output schemas
  - `@Guide` macro: constrain properties (regex, ranges, enums, constant values)
  - `Tool` protocol: typed tool calling with `@Generable` Arguments + async `call()`
  - `LanguageModelSession`: multi-turn, Observable, streaming via `ResponseStream`
  - `PartiallyGenerated<T>`: streaming partial structured output snapshots
  - `Transcript`: Codable — persist and resume conversations across app launches
  - `Adapter` system: ship fine-tuned LoRAs via BackgroundAssets
  - `GenerationOptions`: temperature, sampling (greedy/top-k/nucleus), max tokens, seed
  - `prewarm(promptPrefix:)`: pre-load model for responsive generation
- **Limitations (confirmed):**
  - Context window size: no public constant, only `exceededContextWindowSize` error — test empirically
  - No multimodal: text-only prompts (no image/audio input)
  - No token counting API
  - No model selection (`.default` only, Apple decides what runs)
  - Rate limited + single concurrent request per session
  - No embeddings
- Reference implementations: Dimillian/FoundationChat, PallavAg/Apple-Intelligence-Chat

### Tier 2: Claude API (Premium/Opt-in)
- Deep aeronautical analysis, complex multi-factor reasoning
- Aviation knowledge base, weather pattern analysis, NOTAMs
- Long flight recordings exceeding Foundation Models context window
- Reuse SFR's `LLMProvider` protocol + `ClaudeProvider`

### Shared Pre-Processing Layer
Both tiers consume the same pre-processed flight summary (~3,500 tokens):
- GPS track → phase transitions, key metrics, altitude/speed profiles
- Audio → notable radio comms, frequency changes
- Events → go-arounds, course corrections, weather encounters

## Structured Output Schema (Foundation Models)
```swift
@Generable struct FlightDebrief {
    let summary: String
    let observations: [FlightObservation]
    let improvements: [String]
    let overallRating: FlightRating
}

@Generable struct FlightObservation {
    let phase: FlightPhase  // taxi, takeoff, climb, cruise, descent, approach, landing
    let observation: String
    let severity: Severity  // positive, neutral, advisory, caution
}
```

## Dependencies
- Apple Foundation Models: AVAILABLE NOW (iOS 26.0 SDK installed, iOS 26.3 shipping)
- SFR flight recording package extraction (or build native OpenEFB recorder)
- Fallback: mlx-swift-chat MLXLLM package if Foundation Models is too limited
  - Repo: https://github.com/preternatural-explore/mlx-swift-chat
  - 1-3B 4-bit model on iPhone 15 Pro, `increased-memory-limit` entitlement required

## Integration Pattern
- Fits existing MVVM + Combine + `@MainActor AppState` architecture
- `@Observable FlightDebriefEngine` with streaming partial results
- `@Generable` structured output eliminates JSON parsing
- `session.prewarm()` for responsive debrief generation

## Constraints
- iPad-first (OpenEFB is iPad VFR EFB) — iPad has more memory headroom than iPhone
- Privacy-first: on-device tier must work with zero network connectivity (in-flight)
- Aviation data sensitivity: flight paths, locations, radio comms are PII-adjacent
- iOS 26.3 is current — Foundation Models API is shipping and stable
