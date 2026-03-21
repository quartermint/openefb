# Phase 5: Track Replay - Research

**Researched:** 2026-03-21
**Domain:** AVFoundation audio playback, MapLibre track animation, multi-stream synchronization
**Confidence:** HIGH

## Summary

Phase 5 delivers GPS track replay with synchronized cockpit audio and scrolling transcript, plus a flight history browsing experience. The technical challenge is three-fold: (1) rendering a polyline track on the existing MapLibre map with a moving position marker, (2) playing back recorded audio with variable speed, and (3) synchronizing all three data streams (map position, audio playback, transcript scroll) through a single time-based coordination model.

The existing codebase provides strong foundations: RecordingDatabase already has all the CRUD methods needed (trackPoints, transcriptSegments, phaseMarkers for a given flightID), MapService already manages GeoJSON sources/layers on MLNMapView, FlightDetailView exists as the entry point, and audio files are stored as .m4a in Application Support. The primary new work is a ReplayEngine that coordinates time-based synchronization and new UI for the scrub bar, transcript panel, and replay map overlay.

**Primary recommendation:** Build a `@MainActor @Observable ReplayEngine` that owns a `TimeInterval` playback position as its single source of truth. Map marker, audio player, and transcript highlight all derive their state from this position. Use a high-frequency Timer (10-20 Hz) for smooth animation, with AVAudioPlayer for audio playback (rate-limited to 2x max; mute audio at 4x/8x speeds).

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Playback speeds: 1x, 2x, 4x, 8x with speed selector -- 1x for detailed review, 8x for quick overview of long flights
- Full map view with GPS track drawn as a colored line (by altitude or speed), moving position marker follows playback -- reuses the navigation map in review mode
- Horizontal scrub bar at bottom with flight phase markers for visual navigation -- like a video player, phase markers help navigate directly to takeoff, approach, etc.
- Replay launched from "Replay" button on flight detail view (same view that has Debrief and Logbook entry) -- all post-flight review in one place
- Full cockpit audio playback via AVAudioPlayer, synchronized to the map position marker -- pilot hears exactly what happened at each geographic point
- Scrolling transcript panel alongside map with current segment highlighted and auto-scrolling with playback -- read along while watching and listening
- Dragging the scrub bar moves map position, audio position, and transcript position simultaneously -- single unified control for all three data streams
- Flight history displayed as chronological list on Flights tab with date, departure-to-arrival, duration, aircraft; tap opens detail view with Replay + Debrief + Logbook -- unified post-flight experience

### Claude's Discretion
- Track line coloring algorithm (altitude gradient vs speed gradient vs solid)
- Position marker animation smoothing between GPS points
- Transcript panel size and collapse/expand behavior
- Audio playback rate adjustment for speed-up modes (pitch correction vs chipmunk)
- Map auto-follow vs free-pan during replay
- Replay state management architecture

### Deferred Ideas (OUT OF SCOPE)
- Export flight track to GPX/KMZ format (v2)
- Share replay as video (screen recording + audio composite)
- Compare multiple flights on same route (side-by-side replay)
- 3D replay with altitude visualization
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REPLAY-01 | Pilot can replay recorded flight on the map with position marker following the GPS track | ReplayEngine time model + MapService track overlay + position marker GeoJSON source; track points from RecordingDatabase.trackPoints(forFlight:) |
| REPLAY-02 | Track replay synchronizes with cockpit audio playback and scrolling transcript timeline | AVAudioPlayer.currentTime bidirectional sync with ReplayEngine.currentPosition; transcript segments matched by audioStartTime/audioEndTime to current playback time |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| AVFoundation (AVAudioPlayer) | iOS 26 system | Audio file playback with seek and rate control | User decision specifies AVAudioPlayer; built-in, no dependencies, supports .m4a |
| MapLibre Native iOS | Already in project | Map rendering with GeoJSON polyline + point sources for track and marker | Already the project's map engine; MLNPolylineFeature for track line, MLNPointFeature for marker |
| GRDB.swift | Already in project | Read track points, transcript segments, phase markers from recording.sqlite | Already the project's recording database; all needed CRUD methods exist |
| SwiftData | Already in project | Read FlightRecord metadata for flight list | Already stores flight metadata in SchemaV1.FlightRecord |
| Combine / Timer | iOS 26 system | High-frequency playback position updates (10-20 Hz tick) for smooth animation | Standard iOS approach; TimelineView is an alternative but Timer provides more control over tick rate |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| SwiftUI Slider | iOS 26 system | Scrub bar for timeline control | Built-in, customizable with overlay for phase markers |
| ScrollViewReader | iOS 26 system | Programmatic scroll to active transcript segment | Built-in, enables auto-scroll with scrollTo |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| AVAudioPlayer | AVAudioEngine | Engine supports rate > 2x but already used for recording; two simultaneous engines can conflict on audio session. AVAudioPlayer is simpler for pure playback |
| Timer for tick | TimelineView | TimelineView is SwiftUI-native but has scheduling limitations; Timer gives precise Hz control |
| SwiftUI Slider | Custom UIKit scrub bar | More control over touch tracking, but project convention is SwiftUI-first |

**Installation:**
No new dependencies needed. All libraries are already in the project or system frameworks.

## Architecture Patterns

### Recommended Project Structure
```
efb-212/
├── Services/
│   └── Replay/
│       └── ReplayEngine.swift         # @Observable playback coordinator
├── ViewModels/
│   ├── ReplayViewModel.swift          # UI state for replay view
│   └── FlightHistoryViewModel.swift   # Flight list + detail navigation
├── Views/
│   └── Flights/
│       ├── FlightDetailView.swift     # MODIFY: add Replay button
│       ├── FlightHistoryListView.swift # New: chronological flight list
│       ├── ReplayView.swift           # New: map + transcript + scrub bar
│       ├── ReplayMapView.swift        # New: MapView variant for replay mode
│       ├── TranscriptPanelView.swift  # New: scrolling transcript with highlight
│       └── TimelineScrubBar.swift     # New: scrub bar with phase markers
```

### Pattern 1: Single Source of Truth Time Model

**What:** ReplayEngine owns a single `currentPosition: TimeInterval` (seconds from recording start). All consumers (map marker, audio player, transcript highlight) derive their state from this value. When the user drags the scrub bar, it writes to `currentPosition`; the engine then seeks audio and recomputes map/transcript positions.

**When to use:** Any multi-stream synchronized playback system.

**Why:** Avoids drift between streams. Audio currentTime, GPS timestamp offsets, and transcript audioStartTime all convert to/from the same time base.

**Example:**
```swift
@Observable
@MainActor
final class ReplayEngine {
    // Single source of truth
    var currentPosition: TimeInterval = 0  // seconds from recording start
    var isPlaying: Bool = false
    var playbackSpeed: Float = 1.0  // 1x, 2x, 4x, 8x

    // Derived state
    var currentTrackPointIndex: Int = 0
    var currentTranscriptIndex: Int? = nil
    var currentCoordinate: CLLocationCoordinate2D = .init()
    var currentAltitude: Double = 0
    var currentSpeed: Double = 0

    // Data
    private var trackPoints: [TrackPointRecord] = []
    private var transcriptSegments: [TranscriptSegmentRecord] = []
    private var phaseMarkers: [PhaseMarkerRecord] = []
    private var audioPlayer: AVAudioPlayer?
    private var playbackTimer: Timer?
    private var recordingStartTime: Date = Date()

    // Total duration derived from track points
    var totalDuration: TimeInterval {
        guard let first = trackPoints.first, let last = trackPoints.last else { return 0 }
        return last.timestamp.timeIntervalSince(first.timestamp)
    }

    func loadFlight(flightID: UUID, recordingDB: RecordingDatabase, audioURL: URL?) throws {
        trackPoints = try recordingDB.trackPoints(forFlight: flightID)
        transcriptSegments = try recordingDB.transcriptSegments(forFlight: flightID)
        phaseMarkers = try recordingDB.phaseMarkers(forFlight: flightID)

        if let first = trackPoints.first {
            recordingStartTime = first.timestamp
        }

        if let url = audioURL, FileManager.default.fileExists(atPath: url.path) {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.enableRate = true
            audioPlayer?.prepareToPlay()
        }

        updateDerivedState()
    }

    func play() {
        isPlaying = true
        syncAudioToPosition()
        audioPlayer?.play()
        startTimer()
    }

    func pause() {
        isPlaying = false
        audioPlayer?.pause()
        playbackTimer?.invalidate()
    }

    func seekTo(_ position: TimeInterval) {
        currentPosition = max(0, min(position, totalDuration))
        syncAudioToPosition()
        updateDerivedState()
    }

    func setSpeed(_ speed: Float) {
        playbackSpeed = speed
        if speed <= 2.0 {
            audioPlayer?.rate = speed
        } else {
            // AVAudioPlayer max rate is 2.0; mute audio at 4x/8x
            audioPlayer?.volume = 0
            audioPlayer?.rate = 2.0  // keep audio advancing at 2x
        }
    }

    private func startTimer() {
        playbackTimer?.invalidate()
        // 20 Hz for smooth marker animation
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
    }

    private func tick() {
        guard isPlaying else { return }
        currentPosition += 0.05 * Double(playbackSpeed)

        if currentPosition >= totalDuration {
            currentPosition = totalDuration
            pause()
        }

        updateDerivedState()
    }

    private func syncAudioToPosition() {
        audioPlayer?.currentTime = currentPosition
    }

    private func updateDerivedState() {
        // Binary search for nearest track point
        let targetTime = recordingStartTime.addingTimeInterval(currentPosition)
        currentTrackPointIndex = findNearestTrackPointIndex(for: targetTime)

        if let tp = trackPoints[safe: currentTrackPointIndex] {
            currentCoordinate = CLLocationCoordinate2D(latitude: tp.latitude, longitude: tp.longitude)
            currentAltitude = tp.altitudeFeet
            currentSpeed = tp.groundSpeedKnots
        }

        // Find active transcript segment
        currentTranscriptIndex = transcriptSegments.firstIndex(where: {
            currentPosition >= $0.audioStartTime && currentPosition < $0.audioEndTime
        })
    }
}
```

### Pattern 2: Track Overlay on Existing MapService

**What:** Add replay-specific GeoJSON sources to MapService -- a polyline source for the full track and a point source for the moving position marker. These exist alongside (not replacing) the existing navigation sources.

**When to use:** Replay mode on the existing map.

**Example:**
```swift
// In MapService -- new replay layer methods
func addReplayTrackLayer(to style: MLNStyle) {
    let source = MLNShapeSource(
        identifier: "replay-track",
        shape: MLNShapeCollectionFeature(shapes: []),
        options: [MLNShapeSourceOption.lineDistanceMetrics: true]
    )
    style.addSource(source)

    let lineLayer = MLNLineStyleLayer(identifier: "replay-track-line", source: source)
    lineLayer.lineColor = NSExpression(forConstantValue: UIColor.systemOrange)
    lineLayer.lineWidth = NSExpression(forConstantValue: 3.0)
    lineLayer.lineCap = NSExpression(forConstantValue: "round")
    lineLayer.lineJoin = NSExpression(forConstantValue: "round")
    style.addLayer(lineLayer)
}

func addReplayMarkerLayer(to style: MLNStyle) {
    let point = MLNPointFeature()
    point.coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)

    let source = MLNShapeSource(identifier: "replay-marker", shape: point, options: nil)
    style.addSource(source)

    // Reuse ownship chevron or create a distinct marker
    let layer = MLNSymbolStyleLayer(identifier: "replay-marker-symbol", source: source)
    layer.iconImageName = NSExpression(forConstantValue: "replay-marker")
    layer.iconRotation = NSExpression(forKeyPath: "heading")
    layer.iconAllowsOverlap = NSExpression(forConstantValue: true)
    style.addLayer(layer)
}

func updateReplayTrack(_ trackPoints: [TrackPointRecord]) {
    var coords = trackPoints.map {
        CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
    }
    let polyline = MLNPolylineFeature(coordinates: &coords, count: UInt(coords.count))
    replayTrackSource?.shape = polyline
}

func updateReplayMarker(coordinate: CLLocationCoordinate2D, heading: Double) {
    let point = MLNPointFeature()
    point.coordinate = coordinate
    point.attributes = ["heading": heading]
    replayMarkerSource?.shape = point
}
```

### Pattern 3: Interpolated Position Between GPS Points

**What:** GPS data is at ~1Hz. At 20 Hz animation tick rate, interpolate latitude/longitude/heading between the two nearest track points for smooth marker movement.

**When to use:** Any time the playback tick rate exceeds the GPS sample rate.

**Example:**
```swift
func interpolatedPosition(at time: TimeInterval) -> (CLLocationCoordinate2D, Double) {
    let targetTime = recordingStartTime.addingTimeInterval(time)

    // Find bracketing track points
    guard let afterIndex = trackPoints.firstIndex(where: { $0.timestamp >= targetTime }),
          afterIndex > 0 else {
        let tp = trackPoints.last ?? trackPoints[0]
        return (CLLocationCoordinate2D(latitude: tp.latitude, longitude: tp.longitude), tp.courseDegrees)
    }

    let before = trackPoints[afterIndex - 1]
    let after = trackPoints[afterIndex]

    let totalInterval = after.timestamp.timeIntervalSince(before.timestamp)
    guard totalInterval > 0 else {
        return (CLLocationCoordinate2D(latitude: before.latitude, longitude: before.longitude), before.courseDegrees)
    }

    let fraction = targetTime.timeIntervalSince(before.timestamp) / totalInterval
    let lat = before.latitude + (after.latitude - before.latitude) * fraction
    let lon = before.longitude + (after.longitude - before.longitude) * fraction
    let heading = before.courseDegrees + (after.courseDegrees - before.courseDegrees) * fraction

    return (CLLocationCoordinate2D(latitude: lat, longitude: lon), heading)
}
```

### Anti-Patterns to Avoid
- **Using audio currentTime as source of truth:** Audio playback can drift, buffer, or stall. The timer-driven position is the authority; audio syncs to it, not the other way around.
- **Rebuilding GeoJSON polyline on every tick:** Build the full track polyline once on load. Only update the marker point on each tick.
- **Creating a new MapView for replay:** Reuse the existing MapView/MapService infrastructure. Add replay layers alongside existing layers, and hide navigation-only layers during replay mode.
- **Storing entire track in memory as CLLocation objects:** TrackPointRecord is already lightweight (8 doubles). 7,200 points for a 2-hour flight is ~460 KB -- fine in memory.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Audio playback | Custom AVAudioEngine playback pipeline | AVAudioPlayer | Already records with AVAudioEngine; playback is a separate concern, AVAudioPlayer is designed for file playback with seek/rate |
| Time interpolation | Complex spline/bezier path interpolation | Linear interpolation between consecutive 1Hz GPS points | At 1Hz sampling, linear interpolation is visually indistinguishable from higher-order interpolation |
| GeoJSON polyline | Manual coordinate string building | MLNPolylineFeature(coordinates:count:) | MapLibre's built-in GeoJSON type handles coordinate arrays correctly |
| Scrub bar phase markers | Custom drawing code | SwiftUI Slider + .overlay with positioned phase marker views | Slider handles touch interaction; overlays add visual markers |
| Transcript auto-scroll | Custom scroll position tracking | ScrollViewReader + scrollTo with anchor | Built-in SwiftUI mechanism for programmatic scrolling |

**Key insight:** The complexity here is in synchronization logic, not in any individual component. Each piece (audio playback, map rendering, transcript display) uses standard iOS APIs. The engineering challenge is keeping them in lockstep through a clean time model.

## Common Pitfalls

### Pitfall 1: AVAudioPlayer Rate Limit of 2.0x
**What goes wrong:** Setting AVAudioPlayer.rate to 4.0 or 8.0 is silently clamped or causes unexpected behavior. Apple documentation specifies the valid range as 0.5 to 2.0.
**Why it happens:** User decisions specify 4x and 8x playback speeds, but AVAudioPlayer cannot deliver them.
**How to avoid:** At 1x and 2x, play audio at the matching rate. At 4x and 8x, mute audio (or keep it at 2x with a disclaimer). The map marker and transcript should still advance at the correct accelerated rate via the timer.
**Warning signs:** Audio pitch becomes severely distorted or playback stops advancing.

### Pitfall 2: Audio-Timer Drift Over Long Flights
**What goes wrong:** Timer-based position and AVAudioPlayer.currentTime diverge over a 2+ hour flight, leading to visible desynchronization.
**Why it happens:** Timer fires are not perfectly periodic (RunLoop scheduling), and audio playback has its own clock.
**How to avoid:** Periodically (every 5 seconds) read AVAudioPlayer.currentTime and correct the timer-driven position if drift exceeds a threshold (e.g., 0.2 seconds). At 4x/8x where audio is muted, drift doesn't matter.
**Warning signs:** Transcript highlight and audio become out of sync by more than half a second.

### Pitfall 3: GeoJSON Performance with 7,200+ Points
**What goes wrong:** Updating the full track polyline GeoJSON on every tick causes janky map performance.
**Why it happens:** Serializing and deserializing 7,200 coordinates at 20 Hz overwhelms the main thread.
**How to avoid:** Build the full track polyline GeoJSON ONCE when the flight loads. Only update the position marker point feature (1 coordinate) on each tick. The polyline is static -- it never changes during playback.
**Warning signs:** Map frame drops below 30fps during replay.

### Pitfall 4: Audio Session Conflict with Recording
**What goes wrong:** If the user navigates to replay while a recording is active (unlikely but possible), the audio session category may conflict.
**Why it happens:** Recording uses `.playAndRecord` category; playback also needs audio session access.
**How to avoid:** Disable the Replay button when `appState.recordingStatus != .idle`. Show a clear message: "Stop recording before replaying a flight."
**Warning signs:** Audio playback fails to start or recording audio cuts out.

### Pitfall 5: Track Point Timestamp Base Mismatch
**What goes wrong:** Track point timestamps are absolute Dates, but audio positions are relative TimeIntervals from recording start. Mixing them causes offset errors.
**Why it happens:** RecordingDatabase stores Date timestamps for track points but TimeInterval offsets for transcript audioStartTime/audioEndTime.
**How to avoid:** Compute `recordingStartTime = trackPoints.first!.timestamp`. Convert all absolute timestamps to relative offsets: `offset = point.timestamp.timeIntervalSince(recordingStartTime)`. This puts everything in the same time base as the audio.
**Warning signs:** Map position and transcript are offset by hours (the epoch offset).

### Pitfall 6: Missing Audio File
**What goes wrong:** The audio file for a flight may not exist (recording failed, file deleted, or placeholder was used).
**Why it happens:** AudioRecorder is best-effort; GPS recording continues even if audio fails (per Phase 3 decision).
**How to avoid:** ReplayEngine must handle nil audioPlayer gracefully. Track replay and transcript still work without audio. Show "Audio unavailable" in the scrub bar area.
**Warning signs:** Crash on force-unwrapping audioPlayer.

## Code Examples

### Loading Flight Data for Replay
```swift
// Source: existing RecordingDatabase API
func loadFlightForReplay(flightID: UUID) throws -> (
    trackPoints: [TrackPointRecord],
    transcripts: [TranscriptSegmentRecord],
    phaseMarkers: [PhaseMarkerRecord]
) {
    guard let recordingDB = appState.getOrCreateRecordingDatabase() else {
        throw EFBError.databaseCorrupted
    }

    let trackPoints = try recordingDB.trackPoints(forFlight: flightID)
    let transcripts = try recordingDB.transcriptSegments(forFlight: flightID)
    let phaseMarkers = try recordingDB.phaseMarkers(forFlight: flightID)

    return (trackPoints, transcripts, phaseMarkers)
}
```

### Resolving Audio File URL from FlightRecord
```swift
// Audio files stored at: Application Support/efb-212/recordings/{flightID}.m4a
// FlightRecord.audioFileURL stores relative path
func resolveAudioURL(for flightRecord: SchemaV1.FlightRecord) -> URL? {
    guard let relativePath = flightRecord.audioFileURL else { return nil }
    let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    let url = appSupport.appendingPathComponent(relativePath)
    return FileManager.default.fileExists(atPath: url.path) ? url : nil
}
```

### AVAudioPlayer Setup with Rate Enabled
```swift
// Source: Apple AVAudioPlayer documentation
func setupAudioPlayer(url: URL) throws -> AVAudioPlayer {
    let player = try AVAudioPlayer(contentsOf: url)
    player.enableRate = true   // MUST set before changing rate
    player.prepareToPlay()     // Preload audio buffer
    return player
}
```

### Phase Marker Positions for Scrub Bar
```swift
// Convert phase markers to fractional positions on the scrub bar
func phaseMarkerPositions(markers: [PhaseMarkerRecord], totalDuration: TimeInterval, recordingStart: Date) -> [(phase: String, fraction: Double)] {
    guard totalDuration > 0 else { return [] }
    return markers.map { marker in
        let offset = marker.startTimestamp.timeIntervalSince(recordingStart)
        let fraction = offset / totalDuration
        return (phase: marker.phase, fraction: max(0, min(1, fraction)))
    }
}
```

### Transcript Auto-Scroll with ScrollViewReader
```swift
// Source: SwiftUI ScrollViewReader API
struct TranscriptPanelView: View {
    let segments: [TranscriptSegmentRecord]
    let activeIndex: Int?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                        TranscriptSegmentRow(
                            segment: segment,
                            isActive: index == activeIndex
                        )
                        .id(index)
                    }
                }
            }
            .onChange(of: activeIndex) { _, newIndex in
                if let index = newIndex {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(index, anchor: .center)
                    }
                }
            }
        }
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| AVAudioPlayer only (max 2x rate) | AVAudioPlayer for 1-2x, mute at 4-8x | Long-standing iOS limitation | Audio only available at 1x/2x; visual replay works at all speeds |
| ObservableObject + @Published | @Observable macro | iOS 17 / Swift 5.9 | Simpler observation, automatic dependency tracking -- project already uses this pattern |
| Combine Timer publisher | Timer.scheduledTimer with Task hop | Project pattern | Consistent with existing RecordingViewModel sync loop approach |

**Deprecated/outdated:**
- AVAudioPlayer `numberOfLoops` for replay looping -- not applicable here (single playback with scrub)
- CADisplayLink for animation -- SwiftUI's @Observable + Timer is sufficient; no CALayer animation needed

## Discretion Recommendations

### Track Line Coloring: Altitude Gradient (RECOMMENDED)
**Recommendation:** Use altitude-based coloring with a simple segmented approach. Rather than MapLibre's `lineGradient` (which only supports `$lineProgress` interpolation, not feature attributes), draw the track as multiple short line segments with colors assigned based on altitude.

**Implementation:** Divide track points into groups by altitude range. Create separate MLNPolylineFeature segments for each altitude band, each styled with a different color via separate line layers or a data-driven `lineColor` expression on a single layer using a feature property.

**Altitude color scale:** Low (green, < 3000 ft) -> Medium (yellow, 3000-8000 ft) -> High (orange, > 8000 ft). This provides meaningful visual information for VFR pilot review.

**Alternative (simpler):** Use a single solid color (systemOrange) for the full track and defer gradient coloring. This significantly reduces complexity for Plan 01.

### Position Marker Smoothing: Linear Interpolation
**Recommendation:** Linear interpolation between consecutive GPS points (see Pattern 3 above). At 1Hz GPS sampling and 20Hz tick rate, this produces visually smooth movement with negligible computational cost.

### Transcript Panel: Collapsible Side Panel
**Recommendation:** On iPad landscape, show the transcript as a right-side panel (~300pt wide) that can collapse to a narrow handle. When collapsed, only show the current segment as a floating card. The map occupies the remaining space.

### Audio at 4x/8x: Mute with Visual Indicator
**Recommendation:** Mute audio at speeds above 2x and show a clear "Audio muted at [speed]x" indicator. The pilot's mental model at 8x speed is "scanning the route," not "listening to communications." AVAudioPlayer rate maxes at 2.0; attempting higher rates produces distorted or silent output.

### Map Auto-Follow: Follow with Manual Override
**Recommendation:** Map auto-centers on the position marker during playback (auto-follow mode). If the user pans the map manually, auto-follow disables and a "Re-center" button appears. Tapping re-center re-enables auto-follow. This matches the existing ownship tracking pattern.

### Replay State Architecture: @Observable ReplayEngine
**Recommendation:** `@MainActor @Observable ReplayEngine` as a standalone service, not embedded in a ViewModel. The engine manages the time model and audio player. A separate `ReplayViewModel` holds UI state (panel expanded, speed selector visible, etc.) and references the engine. This separates playback logic from UI concerns and makes the engine independently testable.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (via `import Testing`) |
| Config file | Xcode project target `efb-212Tests` |
| Quick run command | `xcodebuild test -scheme efb-212 -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' -only-testing:efb-212Tests` |
| Full suite command | `xcodebuild test -scheme efb-212 -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)'` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REPLAY-01 | Track points loaded from GRDB, polyline built, position marker advances through coordinates | unit | `xcodebuild test -scheme efb-212 -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' -only-testing:efb-212Tests/ReplayEngineTests` | Wave 0 |
| REPLAY-01 | Interpolated position between GPS points is computed correctly | unit | same as above | Wave 0 |
| REPLAY-01 | Playback speed changes (1x/2x/4x/8x) advance position at correct rate | unit | same as above | Wave 0 |
| REPLAY-02 | Audio player currentTime syncs to engine position on seek | unit | same as above | Wave 0 |
| REPLAY-02 | Active transcript segment index matches current playback position | unit | same as above | Wave 0 |
| REPLAY-02 | Phase marker fractional positions computed correctly from timestamps | unit | same as above | Wave 0 |

### Sampling Rate
- **Per task commit:** Quick run command (ReplayEngineTests only)
- **Per wave merge:** Full test suite
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `efb-212Tests/ReplayEngineTests.swift` -- covers REPLAY-01, REPLAY-02 (unit tests for time model, interpolation, seek, speed, transcript matching)
- [ ] Test helper: factory function to create test RecordingDatabase with sample track points and transcript segments (GRDB temp file pattern from Phase 4)

*(Test infrastructure exists: Swift Testing framework, Xcode test target. Only new test files needed.)*

## Open Questions

1. **FlightRecord.audioFileURL format**
   - What we know: The audioFileURL stores a relative path, and audio files are written to `Application Support/efb-212/recordings/{flightID}.m4a` by RecordingCoordinator
   - What's unclear: Whether audioFileURL is set as the full absolute path or a relative path component
   - Recommendation: Check actual stored values; resolve with the same base path used by RecordingCoordinator. Handle both formats defensively.

2. **Flights Tab Content**
   - What we know: The Flights tab currently shows FlightPlanView (flight plan creation). The user decision says flight history should be a chronological list on the Flights tab.
   - What's unclear: Whether to replace FlightPlanView with a combined view or add a segmented control
   - Recommendation: Add a segmented control or section to the Flights tab: "Plans" (existing) and "History" (new FlightRecord list). Or navigate from FlightPlanView to history. Planner decides layout.

3. **Replay Map vs Navigation Map**
   - What we know: User decided replay "reuses the navigation map in review mode"
   - What's unclear: Whether to present replay as a full-screen modal over the map tab or as an embedded map within the Flights tab navigation stack
   - Recommendation: Present as a full-screen view (NavigationLink destination from FlightDetailView) with its own MapView instance configured in replay mode. This avoids disrupting the live navigation map state.

## Sources

### Primary (HIGH confidence)
- Apple AVAudioPlayer documentation -- currentTime, rate, enableRate, duration properties
- MapLibre Native iOS API -- MGLLineStyleLayer, MGLShapeSource, MLNPolylineFeature, lineGradient
- Existing codebase: RecordingDatabase.swift, MapService.swift, FlightDetailView.swift, AudioRecorder.swift, RecordingCoordinator.swift, AppState.swift, Types.swift

### Secondary (MEDIUM confidence)
- [AVAudioPlayer playback progress pattern](https://agarmash.com/posts/avaudioplayer-playback-progress/) -- Timer-based UI sync approach
- [SwiftUI + Combine AVPlayer sync](https://gist.github.com/AKosmachyov/2b9327545d4b538ec50ca3f3757c6cc7) -- Slider binding pattern
- [MapLibre line gradient spec](https://maplibre.org/maplibre-style-spec/layers/) -- lineGradient requires lineDistanceMetrics
- [MGLLineStyleLayer reference](https://maplibre.org/maplibre-native/ios/api/Classes/MGLLineStyleLayer.html) -- lineGradient only supports $lineProgress, not feature attributes

### Tertiary (LOW confidence)
- AVAudioPlayer rate range (0.5-2.0) -- confirmed by multiple sources but Apple's official doc page requires JavaScript to render; treat as HIGH based on consistent reporting

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all components are existing project dependencies or system frameworks; no new libraries needed
- Architecture: HIGH -- patterns follow existing codebase conventions (@Observable, MapService GeoJSON, GRDB reads); synchronization model is well-understood
- Pitfalls: HIGH -- identified from direct API investigation (AVAudioPlayer rate limit, GeoJSON performance, timestamp base conversion)

**Research date:** 2026-03-21
**Valid until:** 2026-04-21 (stable -- no API changes expected; AVFoundation and MapLibre Native are mature)
