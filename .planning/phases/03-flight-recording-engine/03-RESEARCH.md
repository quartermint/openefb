# Phase 3: Flight Recording Engine - Research

**Researched:** 2026-03-21
**Domain:** iOS audio recording, GPS tracking, real-time speech transcription, flight phase detection
**Confidence:** HIGH

## Summary

This phase delivers the complete flight recording pipeline: simultaneous GPS track capture + cockpit audio recording, real-time speech-to-text with aviation vocabulary post-processing, automatic flight phase detection via state machine, auto-start on speed threshold, and robust interruption handling. The domain is well-understood thanks to the SFR reference implementation (~7K LOC) which provides proven algorithms, thresholds, and architectural patterns.

The critical technical challenge is the three-way concurrency between: (1) `AVAudioEngine` writing AAC audio to file while simultaneously tapping buffers for speech recognition, (2) iOS 26 `SpeechAnalyzer` (or fallback `SFSpeechRecognizer`) consuming those buffers for real-time transcription, and (3) `CLLocationUpdate.liveUpdates(.airborne)` providing GPS track data -- all running concurrently in the background. This is achievable because iOS supports `audio` + `location` background modes simultaneously, and the SFR codebase has proven this exact pattern works for 6+ hour flights.

iOS 26 introduces `SpeechAnalyzer` / `SpeechTranscriber` as the next-generation speech-to-text API. It is significantly faster and more accurate than `SFSpeechRecognizer`, fully on-device, and has no time limits. However, it requires iOS 26+ and language model assets to be downloaded. The project already targets iOS 26, so `SpeechAnalyzer` should be the primary transcription engine with `SFSpeechRecognizer` as a graceful fallback only if SpeechAnalyzer assets are unavailable.

**Primary recommendation:** Build a `RecordingCoordinator` actor that orchestrates three independent services -- `TrackRecorder`, `AudioRecorder`, and `SpeechAnalyzer` -- using the SFR-proven architecture but rewritten for iOS 26 APIs (`CLLocationUpdate` AsyncSequence, `SpeechAnalyzer`, `@Observable` state). Store track points and transcript segments to GRDB in append-only mode. Flight phase detection runs as a pure-function state machine consuming GPS data.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Record button is a prominent floating button on the map view (top-left), always accessible, one-tap start/stop, red color when recording
- Recording status shows a red dot + elapsed time in the top bar with pulse animation while recording
- Auto-start triggers when ground speed exceeds threshold (default 15 kts) with a 3-second countdown + cancel option
- Manual stop shows confirmation dialog ("End flight recording?"); auto-stop triggers after 5 minutes below speed threshold
- Two audio quality profiles: "Standard" (32kbps AAC, ~14MB/hr) and "High" (64kbps AAC, ~28MB/hr), default Standard
- Live transcription shown in a scrolling, collapsible panel displaying last 3-5 segments
- Aviation vocabulary post-processor corrects common Speech framework misrecognitions: "november" to "N", "niner" to "9", runway formats, altitudes, frequencies -- leverages SFR proven patterns
- Auto-resume recording after phone call / Siri / headphone disconnect interruption with gap marker in transcript
- Speed + altitude state machine with hysteresis (SFR-proven approach): preflight (<5kts), taxi (5-15kts), takeoff (>15kts + climbing), cruise (level flight >500ft AGL), approach (descending), landing (<15kts after descent), postflight (<5kts sustained)
- Phase transitions shown as subtle label update in recording status bar
- 30-second minimum hysteresis in each phase before transition allowed
- Phase markers stored in GRDB with timestamp and GPS coordinates
- SFR is the design spec, not importable code -- algorithms and thresholds transfer as design knowledge
- AVAudioEngine with simultaneous file write + Speech framework buffer tap (SFR proven pattern)
- Only isFinal == true transcript segments stored to GRDB (discard volatile/partial)
- .airborne CLLocationUpdate configuration for in-flight accuracy
- Background audio session category must coexist with background location

### Claude's Discretion
- Exact AVAudioEngine configuration and buffer sizes
- GPS track sampling rate optimization (1Hz vs adaptive)
- Speech framework locale and recognition task configuration
- Recording file naming convention and storage directory structure
- Background mode entitlement configuration details
- Memory management strategy for long recordings

### Deferred Ideas (OUT OF SCOPE)
- Radio coach AI training mode (future milestone)
- ADS-B integration for traffic awareness during recording (requires hardware)
- Video recording overlay (significant scope increase)
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REC-01 | Pilot can start/stop flight recording with one tap, capturing GPS track and cockpit audio simultaneously | RecordingCoordinator orchestrates TrackRecorder + AudioRecorder; one-tap start/stop via AppState.RecordingState; proven by SFR FlightManager pattern |
| REC-02 | Recording auto-starts when ground speed exceeds configurable threshold (default 15 kts) | LocationService already provides ground speed in AppState; RecordingCoordinator monitors AppState.groundSpeed; 3-second countdown before start per user decision |
| REC-03 | Audio engine records cockpit audio for 6+ hours with configurable quality profiles | AVAudioEngine + AVAudioFile write pattern (not AVAudioRecorder) enables simultaneous file write + buffer tap; two profiles: Standard (32kbps) and High (64kbps) AAC; SFR CockpitAudioEngine proves this works for 6+ hours |
| REC-04 | Real-time speech-to-text with aviation vocabulary post-processing | iOS 26 SpeechAnalyzer as primary engine (faster, more accurate, no time limit); SFR AviationVocabularyProcessor provides proven regex patterns for N-numbers, altitudes, headings, frequencies, runways; only isFinal segments stored to GRDB |
| REC-05 | Automatic flight phase detection: preflight, taxi, takeoff, departure, cruise, approach, landing, postflight | SFR FlightPhaseDetector provides proven state machine with configurable thresholds; smoothed GPS data (5-point rolling average) prevents flickering; 30-second hysteresis per user decision |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| AVFoundation (AVAudioEngine) | System | Audio capture + simultaneous file write and buffer tap | Enables dual-output: AAC file recording + PCM buffer streaming to Speech framework |
| Speech (SpeechAnalyzer) | iOS 26 | On-device real-time transcription | New in iOS 26: 2.2x faster than Whisper, fully on-device, no time limit, handles distant audio |
| Speech (SFSpeechRecognizer) | iOS 17+ | Fallback transcription engine | Proven API for when SpeechAnalyzer assets are not installed |
| CoreLocation (CLLocationUpdate) | iOS 17+ | GPS track via AsyncSequence | Already used by LocationService; .airborne config for aviation accuracy |
| GRDB.swift | 7.x | Track points + transcript segments storage | Already in project; WAL mode, DatabasePool for concurrent reads during recording |
| SwiftData | iOS 17+ | Flight record metadata (user data layer) | Already in project; pairs with GRDB for dual-database architecture |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Combine | System | Audio buffer publisher pipe, state change observation | Wire AVAudioEngine tap buffers to SpeechAnalyzer input stream |
| CoreMotion | System | Barometric altitude (optional) | Enhanced altitude data for phase detection accuracy |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| SpeechAnalyzer | SFSpeechRecognizer only | Works on iOS 17+ but has 1-minute server limit; on-device mode has no limit but lower accuracy than SpeechAnalyzer |
| AVAudioEngine file write | AVAudioRecorder | Simpler API but cannot simultaneously tap buffers for speech -- would require running both AVAudioRecorder AND AVAudioEngine on the same session (SFR does this but it is fragile) |
| GRDB for track points | SwiftData | SwiftData lacks spatial queries and has higher per-write overhead; GRDB append-only writes are ~10x faster |

**No new SPM dependencies required.** All libraries are already in the project or are system frameworks.

## Architecture Patterns

### Recommended Project Structure
```
efb-212/
├── Services/
│   ├── Recording/
│   │   ├── RecordingCoordinator.swift    # Actor: orchestrates all recording services
│   │   ├── AudioRecorder.swift           # AVAudioEngine file write + buffer tap
│   │   ├── TrackRecorder.swift           # CLLocationUpdate GPS capture to GRDB
│   │   ├── TranscriptionService.swift    # SpeechAnalyzer wrapper with SFSpeechRecognizer fallback
│   │   ├── FlightPhaseDetector.swift     # Speed+altitude state machine
│   │   └── AviationVocabulary.swift      # Post-processor (regex patterns from SFR)
│   └── ... (existing services)
├── Data/
│   ├── RecordingDatabase.swift           # GRDB tables: track_points, transcript_segments, flight_phases
│   └── Models/
│       └── FlightRecord.swift            # SwiftData @Model for flight metadata
├── ViewModels/
│   └── RecordingViewModel.swift          # @MainActor, observes RecordingCoordinator state
├── Views/
│   ├── Map/
│   │   └── RecordingOverlayView.swift    # Record button, status bar, transcript panel
│   └── ...
└── Core/
    └── AppState.swift                    # Add RecordingState properties
```

### Pattern 1: RecordingCoordinator as Central Orchestrator
**What:** A Swift actor that owns the lifecycle of all recording sub-services and exposes state via `@Observable` properties on MainActor.
**When to use:** Always -- this is the primary coordination pattern.
**Example:**
```swift
// Source: SFR FlightManager pattern, adapted for iOS 26 + @Observable
actor RecordingCoordinator {
    // State published to UI via @Observable wrapper on MainActor
    @MainActor @Observable
    final class State {
        var recordingStatus: RecordingStatus = .idle
        var elapsedTime: TimeInterval = 0
        var currentPhase: FlightPhaseType = .preflight
        var recentTranscripts: [TranscriptSegment] = []  // last 5 for live panel
        var audioLevel: Float = -160  // dBFS for level meter
    }

    let state = State()

    private var audioRecorder: AudioRecorder?
    private var trackRecorder: TrackRecorder?
    private var transcriptionService: TranscriptionService?
    private var phaseDetector: FlightPhaseDetector

    func startRecording(profile: AudioQualityProfile) async throws { ... }
    func stopRecording() async -> FlightRecordingSummary { ... }
}
```

### Pattern 2: AVAudioEngine Dual-Output (File Write + Buffer Tap)
**What:** AVAudioEngine with input node tap that simultaneously writes AAC to an AVAudioFile AND streams PCM buffers to SpeechAnalyzer.
**When to use:** For audio recording that needs real-time transcription.
**Example:**
```swift
// Source: SFR CockpitAudioEngine + createwithswift.com SpeechAnalyzer guide
let audioEngine = AVAudioEngine()
let inputNode = audioEngine.inputNode
let recordingFormat = inputNode.outputFormat(forBus: 0)

// Create AAC output file
let outputFile = try AVAudioFile(
    forWriting: outputURL,
    settings: [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: profile.sampleRate,
        AVNumberOfChannelsKey: 1,
        AVEncoderBitRateKey: profile.bitRate
    ]
)

// Install tap: write to file AND stream to SpeechAnalyzer
inputNode.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { buffer, time in
    // Write to AAC file
    try? outputFile.write(from: buffer)
    // Stream to SpeechAnalyzer via AsyncStream continuation
    inputContinuation.yield(AnalyzerInput(buffer: convertedBuffer))
}

audioEngine.prepare()
try audioEngine.start()
```

### Pattern 3: SpeechAnalyzer with Volatile/Final Distinction
**What:** Configure SpeechTranscriber with `.volatileResults` reporting; display volatile results in UI but only persist `isFinal` segments to GRDB.
**When to use:** Always for real-time transcription display.
**Example:**
```swift
// Source: Apple WWDC25 Session 277, createwithswift.com guide
let transcriber = SpeechTranscriber(
    locale: Locale(identifier: "en-US"),
    reportingOptions: [.volatileResults],
    attributeOptions: [.audioTimeRange]
)
let analyzer = SpeechAnalyzer(modules: [transcriber])
let analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(
    compatibleWith: [transcriber]
)

// Consume results
for try await result in transcriber.results {
    let text = String(result.text.characters)
    let processed = vocabularyProcessor.process(text)

    if result.isFinal {
        // Persist to GRDB
        try await recordingDB.insertTranscript(segment)
    } else {
        // Update volatile UI only
        await MainActor.run { state.volatileText = processed }
    }
}
```

### Pattern 4: Flight Phase State Machine with Hysteresis
**What:** Pure-function state machine consuming smoothed GPS data, with configurable thresholds and minimum 30-second hold time per phase.
**When to use:** Processes every GPS track point during recording.
**Example:**
```swift
// Source: SFR FlightPhaseDetector, adapted for OpenEFB thresholds
struct FlightPhaseDetector {
    var currentPhase: FlightPhaseType = .preflight
    var phases: [PhaseMarker] = []
    private var recentPoints: [TrackPointRecord] = []  // 5-point smoothing window
    private var phaseEnteredAt: Date = Date()
    private let hysteresisSeconds: TimeInterval = 30  // user decision: 30s minimum

    mutating func process(_ point: TrackPointRecord) -> FlightPhaseType {
        recentPoints.append(point)
        if recentPoints.count > 5 { recentPoints.removeFirst() }

        let smoothedSpeed = recentPoints.map(\.groundSpeedKnots).average()
        let smoothedAlt = recentPoints.map(\.altitudeFeet).average()
        let smoothedVSI = recentPoints.map(\.verticalSpeedFPM).average()

        let candidatePhase = detectPhase(speed: smoothedSpeed, alt: smoothedAlt, vsi: smoothedVSI)

        // Enforce 30-second hysteresis
        if candidatePhase != currentPhase {
            let elapsed = point.timestamp.timeIntervalSince(phaseEnteredAt)
            guard elapsed >= hysteresisSeconds else { return currentPhase }

            // Transition
            closeCurrentPhase(at: point)
            currentPhase = candidatePhase
            phaseEnteredAt = point.timestamp
            openNewPhase(candidatePhase, at: point)
        }
        return currentPhase
    }
}
```

### Pattern 5: GRDB Append-Only Recording Tables
**What:** Dedicated GRDB tables for high-frequency recording data (track points at 1Hz = 3,600 rows/hour, transcript segments), separate from the aviation database.
**When to use:** All recording data goes to GRDB for performance; SwiftData stores only the flight metadata record.
**Example:**
```swift
// Source: OpenEFB AviationDatabase pattern
// Recording database: separate from aviation.sqlite
// Located at: Application Support/efb-212/recordings/{flightID}.sqlite
struct TrackPointRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "track_points"
    let id: UUID
    let flightID: UUID
    let timestamp: Date
    let latitude: Double         // degrees
    let longitude: Double        // degrees
    let altitudeFeet: Double     // feet MSL
    let groundSpeedKnots: Double // knots
    let verticalSpeedFPM: Double // feet per minute
    let courseDegrees: Double    // degrees true
}

struct TranscriptSegmentRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "transcript_segments"
    let id: UUID
    let flightID: UUID
    let timestamp: Date
    let text: String
    let confidence: Double       // 0.0-1.0
    let audioStartTime: TimeInterval
    let audioEndTime: TimeInterval
    let flightPhase: String      // FlightPhaseType raw value
}

struct PhaseMarkerRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "phase_markers"
    let id: UUID
    let flightID: UUID
    let phase: String            // FlightPhaseType raw value
    let startTimestamp: Date
    let endTimestamp: Date?
    let latitude: Double
    let longitude: Double
}
```

### Anti-Patterns to Avoid
- **Running AVAudioRecorder + AVAudioEngine simultaneously on the same session:** Fragile, causes audio route conflicts. Use AVAudioEngine exclusively for both file write and buffer tap.
- **Storing volatile/partial transcript segments:** Only `isFinal == true` results should be persisted. Volatile results change rapidly and create database churn.
- **Using SwiftData for track points:** SwiftData's per-write overhead is too high for 1Hz GPS data (3,600+ rows/hour). GRDB with WAL mode handles this efficiently.
- **Modifying AppState directly from actor-isolated services:** Always hop to MainActor via `await MainActor.run { }` or use a `@MainActor @Observable` state object.
- **Holding CLBackgroundActivitySession as a local variable:** Must be stored as a property; deallocation invalidates the session and kills background location.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Aviation vocabulary correction | Custom NLP pipeline | SFR's AviationVocabularyProcessor regex patterns | 448 lines of battle-tested regex covering N-numbers, altitudes, headings, frequencies, runways, transponder codes, ATIS, approach types, waypoints |
| Audio format conversion for SpeechAnalyzer | Manual PCM conversion | BufferConverter class with AVAudioConverter | Sample rate mismatch between mic format and SpeechAnalyzer's preferred format is a common pitfall |
| Flight phase thresholds | Trial-and-error tuning | SFR's FlightPhaseDetector thresholds | Proven on real flights: taxi 5-30kts, takeoff >30kts + climbing, cruise >500ft AGL, approach VSI < -200fpm |
| Audio session interruption handling | Custom state tracking | AVAudioSession.interruptionNotification + routeChangeNotification pattern from SFR | Handles phone calls, Siri, headphone disconnect, media services reset, app lifecycle transitions |
| Background mode configuration | Manual plist editing | Xcode Capabilities UI for background modes | Need both "Audio, AirPlay, and Picture in Picture" AND "Location updates" background modes |

**Key insight:** The SFR codebase is a 7,000+ LOC reference implementation that has already solved every edge case in this domain. The algorithms, thresholds, and error handling patterns transfer directly -- only the API surface changes (CLLocationManager -> CLLocationUpdate, ObservableObject -> @Observable, Core Data -> GRDB/SwiftData).

## Common Pitfalls

### Pitfall 1: AVAudioEngine Buffer Format Mismatch with SpeechAnalyzer
**What goes wrong:** AVAudioEngine's input node output format (typically 48kHz stereo on iPad) does not match SpeechAnalyzer's preferred format. Passing unconverted buffers produces garbled transcription or crashes.
**Why it happens:** The mic hardware format and the speech model format are different sample rates/channel counts.
**How to avoid:** Use `SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith:)` to get the target format, then use `AVAudioConverter` to convert each buffer before yielding to the SpeechAnalyzer input stream.
**Warning signs:** Transcription produces nonsense text or crashes with "buffer format mismatch" errors.

### Pitfall 2: CLBackgroundActivitySession Deallocation
**What goes wrong:** Background location tracking silently stops when the app goes to background because the `CLBackgroundActivitySession` was deallocated.
**Why it happens:** Session was stored as a local variable or weak reference instead of a strong property.
**How to avoid:** Store as a strong property on the RecordingCoordinator actor. Only invalidate on explicit stop. The existing LocationService already does this correctly.
**Warning signs:** GPS track has gaps when user switches to ForeFlight mid-flight.

### Pitfall 3: SpeechAnalyzer Asset Not Installed
**What goes wrong:** App crashes or returns empty transcription because the on-device speech model hasn't been downloaded.
**Why it happens:** SpeechAnalyzer requires language model assets to be downloaded via `AssetInventory`. Unlike SFSpeechRecognizer, models are not pre-installed.
**How to avoid:** Check `SpeechTranscriber.installedLocales` before starting. If en-US is not installed, fall back to SFSpeechRecognizer with `requiresOnDeviceRecognition = true`. Prompt user to download in Settings.
**Warning signs:** `SpeechTranscriber.installedLocales` does not contain the desired locale.

### Pitfall 4: AVAudioSession Category Conflicts
**What goes wrong:** Recording audio kills background location updates, or location updates kill audio.
**Why it happens:** Wrong audio session category or missing background mode entitlements.
**How to avoid:** Use `.playAndRecord` category with `.mixWithOthers` option. Ensure Info.plist has BOTH `audio` and `location` in UIBackgroundModes. Currently only `location` is configured -- `audio` must be added.
**Warning signs:** Recording works in foreground but audio stops when app goes to background.

### Pitfall 5: SFSpeechRecognizer 1-Minute Timeout (Server Mode)
**What goes wrong:** Transcription silently stops after ~60 seconds.
**Why it happens:** Using server-based recognition (the default) which has a 1-minute limit.
**How to avoid:** Always set `requiresOnDeviceRecognition = true` on `SFSpeechAudioBufferRecognitionRequest`. On-device mode has no time limit. SpeechAnalyzer does not have this issue.
**Warning signs:** Transcription works for the first minute then goes silent.

### Pitfall 6: Memory Growth During 6-Hour Recording
**What goes wrong:** App runs out of memory during long flights because track points and transcript segments accumulate in arrays.
**Why it happens:** Storing all data in memory instead of writing through to database.
**How to avoid:** Write track points and transcript segments to GRDB immediately on receipt. Only keep the last 5 transcript segments in memory for the UI panel. Track point arrays should be write-through, not accumulated.
**Warning signs:** Memory warnings or crashes after 2-3 hours of recording.

### Pitfall 7: Audio Interruption Without End Notification
**What goes wrong:** Recording stays paused forever after a phone call because the end-interruption notification never arrives.
**Why it happens:** Apple documentation states: "there is no guarantee that a begin interruption will have a corresponding end interruption."
**How to avoid:** Also observe `UIApplication.didBecomeActiveNotification`. When the app returns to foreground and recording is paused, attempt to resume. SFR's CockpitAudioEngine handles this pattern.
**Warning signs:** User returns from phone call and recording is still paused with no auto-resume.

### Pitfall 8: AVAudioEngine inputNode Tap with Zero Channels
**What goes wrong:** Crash when installing tap on inputNode if no audio input is available.
**Why it happens:** Can happen on simulator or if all audio inputs are disconnected.
**How to avoid:** Guard `format.channelCount > 0` before installing tap. SFR checks this explicitly.
**Warning signs:** EXC_BAD_ACCESS in `installTap(onBus:)`.

## Code Examples

### AVAudioSession Configuration for Recording + Background
```swift
// Source: SFR CockpitAudioEngine.configureSession(), adapted for OpenEFB
func configureAudioSession(profile: AudioQualityProfile) throws {
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(
        .playAndRecord,
        mode: .voiceChat,  // Optimized for voice input
        options: [
            .allowBluetooth,       // Bluetooth headsets
            .allowBluetoothA2DP,   // AirPods
            .defaultToSpeaker,     // Built-in speaker for playback
            .mixWithOthers         // Critical: coexist with other apps (ForeFlight)
        ]
    )
    try session.setPreferredSampleRate(profile.sampleRate)
    try session.setPreferredIOBufferDuration(0.05)  // 50ms buffer
    try session.setPreferredInputNumberOfChannels(1) // Mono
    try session.setActive(true)
}
```

### Audio Quality Profiles (User Decision: 2 profiles)
```swift
// Source: SFR AudioQualityProfile, simplified per user decision (2 profiles instead of 3)
enum AudioQualityProfile: String, Codable, CaseIterable {
    case standard   // 16kHz, 32kbps AAC (~14 MB/hr)
    case high       // 22kHz, 64kbps AAC (~28 MB/hr)

    var sampleRate: Double {
        switch self {
        case .standard: return 16_000
        case .high: return 22_050
        }
    }

    var bitRate: Int {
        switch self {
        case .standard: return 32_000
        case .high: return 64_000
        }
    }

    var estimatedMBPerHour: Double {
        switch self {
        case .standard: return 14
        case .high: return 28
        }
    }
}
```

### Info.plist Background Modes (MUST ADD audio)
```xml
<!-- Current Info.plist only has location. Must add audio for recording. -->
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
    <string>audio</string>
</array>
<!-- Also need these usage descriptions -->
<key>NSMicrophoneUsageDescription</key>
<string>OpenEFB records cockpit audio during flights for transcription and debrief.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>OpenEFB transcribes cockpit audio in real-time to create flight transcripts.</string>
```

### Interruption Handling (SFR-Proven Pattern)
```swift
// Source: SFR CockpitAudioEngine.handleInterruption()
private func handleInterruption(_ notification: Notification) {
    guard let userInfo = notification.userInfo,
          let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
          let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

    switch type {
    case .began:
        // Phone call, Siri -- pause recording, insert gap marker
        pauseRecording()
        insertGapMarker(reason: .interruption)

    case .ended:
        // Auto-resume per user decision
        if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                resumeRecording()
            }
        }
        // Fallback: also resume on didBecomeActive if still paused

    @unknown default: break
    }
}
```

### SpeechAnalyzer Setup with Fallback
```swift
// Source: Apple WWDC25 Session 277 + createwithswift.com guide
func setupTranscription() async throws -> TranscriptionEngine {
    // Try SpeechAnalyzer first (iOS 26+)
    let locale = Locale(identifier: "en-US")

    if SpeechTranscriber.installedLocales.contains(locale) {
        let transcriber = SpeechTranscriber(
            locale: locale,
            reportingOptions: [.volatileResults],
            attributeOptions: [.audioTimeRange]
        )
        let analyzer = SpeechAnalyzer(modules: [transcriber])
        let format = await SpeechAnalyzer.bestAvailableAudioFormat(
            compatibleWith: [transcriber]
        )
        return .speechAnalyzer(analyzer: analyzer, transcriber: transcriber, format: format)
    }

    // Fallback to SFSpeechRecognizer
    guard let recognizer = SFSpeechRecognizer(locale: locale),
          recognizer.isAvailable else {
        throw EFBError.recordingFailed(underlying: TranscriptionError.recognizerUnavailable)
    }

    let request = SFSpeechAudioBufferRecognitionRequest()
    request.shouldReportPartialResults = true
    request.requiresOnDeviceRecognition = true  // No time limit
    request.contextualStrings = aviationContextualStrings
    if #available(iOS 17, *) { request.addsPunctuation = true }

    return .sfSpeechRecognizer(recognizer: recognizer, request: request)
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| CLLocationManager delegate | CLLocationUpdate.liveUpdates() AsyncSequence | iOS 17 (WWDC23) | Cleaner async code; existing LocationService already uses this |
| SFSpeechRecognizer (server) | SFSpeechRecognizer (on-device) | iOS 13 | Removes 1-minute limit; requires `requiresOnDeviceRecognition = true` |
| SFSpeechRecognizer | SpeechAnalyzer + SpeechTranscriber | iOS 26 (WWDC25) | 2.2x faster, better accuracy, handles distant audio, modular API |
| ObservableObject + @Published | @Observable macro | iOS 17 (WWDC23) | OpenEFB already uses @Observable for AppState |
| CLLocationManager activityType = .airborne | CLLocationUpdate.liveUpdates(.airborne) | iOS 17 | Same tuning, modern API; SFR uses old API, OpenEFB should use new |

**Deprecated/outdated:**
- `AVAudioRecorder` for simultaneous recording + buffer streaming: Use `AVAudioEngine` with `AVAudioFile` write instead
- `CLLocationManager` delegate pattern: Use `CLLocationUpdate.liveUpdates()` AsyncSequence
- Server-based speech recognition for long recordings: Always use on-device mode

## Open Questions

1. **SpeechAnalyzer Buffer Format Negotiation**
   - What we know: `SpeechAnalyzer.bestAvailableAudioFormat()` returns the preferred format; `AVAudioConverter` handles conversion
   - What's unclear: Exact latency cost of per-buffer format conversion at 1Hz GPS + continuous audio
   - Recommendation: Implement and measure; if conversion is costly, match the AVAudioEngine format to SpeechAnalyzer's preferred format at session setup time via `setPreferredSampleRate`

2. **SpeechAnalyzer Asset Download UX**
   - What we know: SpeechAnalyzer requires downloadable language model assets; `AssetInventory.assetInstallationRequest()` triggers download
   - What's unclear: How large the en-US model is, how long download takes, whether it can happen in background
   - Recommendation: Check asset availability in recording setup flow; show download prompt if missing; fall back to SFSpeechRecognizer immediately rather than blocking

3. **GRDB per-Flight Database vs Single Database**
   - What we know: SFR uses per-flight files; OpenEFB has a single aviation.sqlite
   - What's unclear: Whether per-flight GRDB databases (easier cleanup, no cross-flight queries) or a single recording.sqlite (simpler management) is better
   - Recommendation: Use a single `recording.sqlite` database with `flightID` foreign key on all tables. Simpler to manage and query. Delete flight = DELETE WHERE flightID = ?

4. **Adaptive vs Fixed GPS Sampling**
   - What we know: SFR uses adaptive (1s airborne, 5s ground); user decision says 1Hz
   - What's unclear: Whether fixed 1Hz is sufficient or adaptive saves meaningful battery
   - Recommendation: Start with fixed 1Hz (simpler). The existing LocationService already provides updates at ~1Hz. Add adaptive sampling as optimization if battery becomes an issue.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (Xcode built-in) |
| Config file | efb-212Tests/ directory, test host guard in efb_212App.swift |
| Quick run command | `xcodebuild test -scheme efb-212 -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' -only-testing:efb-212Tests` |
| Full suite command | `xcodebuild test -scheme efb-212 -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)'` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REC-01 | Start/stop recording captures GPS + audio | integration | `xcodebuild test ... -only-testing:efb-212Tests/RecordingCoordinatorTests` | Wave 0 |
| REC-02 | Auto-start at speed threshold with countdown | unit | `xcodebuild test ... -only-testing:efb-212Tests/AutoStartTests` | Wave 0 |
| REC-03 | 6+ hour audio at configurable quality | unit + manual | `xcodebuild test ... -only-testing:efb-212Tests/AudioRecorderTests` (unit); manual: 10-min recording stability test | Wave 0 |
| REC-04 | Real-time transcription with aviation vocab | unit | `xcodebuild test ... -only-testing:efb-212Tests/TranscriptionServiceTests` + `AviationVocabularyTests` | Wave 0 |
| REC-05 | Flight phase detection state machine | unit | `xcodebuild test ... -only-testing:efb-212Tests/FlightPhaseDetectorTests` | Wave 0 |

### Sampling Rate
- **Per task commit:** Quick unit tests for the specific service being implemented
- **Per wave merge:** Full test suite
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `efb-212Tests/ServiceTests/FlightPhaseDetectorTests.swift` -- covers REC-05 with synthetic GPS sequences
- [ ] `efb-212Tests/ServiceTests/AviationVocabularyTests.swift` -- covers REC-04 vocabulary processing
- [ ] `efb-212Tests/ServiceTests/AudioRecorderTests.swift` -- covers REC-03 session configuration and profile switching
- [ ] `efb-212Tests/ServiceTests/TranscriptionServiceTests.swift` -- covers REC-04 with mock speech results
- [ ] `efb-212Tests/ServiceTests/RecordingCoordinatorTests.swift` -- covers REC-01 orchestration with mocks
- [ ] `efb-212Tests/ServiceTests/AutoStartTests.swift` -- covers REC-02 threshold and countdown logic
- [ ] `efb-212Tests/Mocks/MockAudioRecorder.swift` -- mock for testing coordinator without real audio
- [ ] `efb-212Tests/Mocks/MockTranscriptionService.swift` -- mock for testing without Speech framework

*(Framework install: none needed -- XCTest is built-in. Test host guard already exists.)*

## Sources

### Primary (HIGH confidence)
- SFR Reference Codebase (`~/sovereign-flight-recorder/`) -- CockpitAudioEngine.swift (808 lines), CockpitTranscriptionEngine.swift (680 lines), FlightPhaseDetector.swift (335 lines), AviationVocabularyProcessor.swift (449 lines), FlightManager.swift (303 lines), TrackLogRecorder.swift (366 lines), Enums.swift (208 lines), Flight.swift (444 lines)
- [Apple WWDC25 Session 277: SpeechAnalyzer](https://developer.apple.com/videos/play/wwdc2025/277/) -- SpeechAnalyzer API architecture and live transcription setup
- [Apple CLLocationUpdate.liveUpdates documentation](https://developer.apple.com/documentation/corelocation/cllocationupdate/liveupdates(_:)) -- AsyncSequence API with .airborne configuration
- [Apple AVAudioSession interruption handling](https://developer.apple.com/documentation/avfaudio/avaudiosession/responding_to_audio_session_interruptions) -- Official interruption notification pattern

### Secondary (MEDIUM confidence)
- [createwithswift.com: Implementing advanced speech-to-text](https://www.createwithswift.com/implementing-advanced-speech-to-text-in-your-swiftui-app/) -- Complete SpeechAnalyzer + AVAudioEngine integration code with BufferConverter
- [DEV.to: WWDC 2025 SpeechAnalyzer evolution](https://dev.to/arshtechpro/wwdc-2025-the-next-evolution-of-speech-to-text-using-speechanalyzer-6lo) -- SpeechTranscriber configuration, volatile/final results, format negotiation
- [MacStories: SpeechAnalyzer vs Whisper benchmarks](https://www.macstories.net/stories/hands-on-how-apples-new-speech-apis-outpace-whisper-for-lightning-fast-transcription/) -- 2.2x speed advantage, real-world testing
- [Medium: Streamlined Location Updates with CLLocationUpdate](https://medium.com/simform-engineering/streamlined-location-updates-with-cllocationupdate-in-swift-wwdc23-2200ef71f845) -- CLBackgroundActivitySession usage, automatic pause behavior

### Tertiary (LOW confidence)
- [Apple Developer Forums: SFSpeechRecognizer timeout](https://developer.apple.com/forums/thread/82839) -- Confirms 1-minute server limit; on-device has no limit
- [Andy Ibanez: On-device speech recognition](https://www.andyibanez.com/posts/speech-recognition-sfspeechrecognizer/) -- On-device recognition removes time limits

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all system frameworks, no new dependencies, SFR proves the pattern works
- Architecture: HIGH -- SFR FlightManager + CockpitAudioEngine + CockpitTranscriptionEngine provide a proven blueprint; only API surface changes for iOS 26
- Pitfalls: HIGH -- SFR codebase explicitly handles every listed pitfall; code examples are directly from the reference implementation
- SpeechAnalyzer specifics: MEDIUM -- new iOS 26 API, some implementation details based on third-party guides rather than direct Apple docs; core pattern verified across multiple sources
- Background audio+location coexistence: HIGH -- SFR proves this works; requires both UIBackgroundModes entries (currently only `location` is configured)

**Research date:** 2026-03-21
**Valid until:** 2026-04-21 (stable domain, iOS 26 APIs are GA)
