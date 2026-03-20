# Phase 5: Track Replay - Context

**Gathered:** 2026-03-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver GPS track replay with synchronized cockpit audio and scrolling transcript, plus a flight history browsing experience. A pilot can select any past flight, watch the route replay on the map, listen to cockpit audio, and read along with the transcript — all synchronized.

</domain>

<decisions>
## Implementation Decisions

### Replay Experience
- Playback speeds: 1x, 2x, 4x, 8x with speed selector — 1x for detailed review, 8x for quick overview of long flights
- Full map view with GPS track drawn as a colored line (by altitude or speed), moving position marker follows playback — reuses the navigation map in review mode
- Horizontal scrub bar at bottom with flight phase markers for visual navigation — like a video player, phase markers help navigate directly to takeoff, approach, etc.
- Replay launched from "Replay" button on flight detail view (same view that has Debrief and Logbook entry) — all post-flight review in one place

### Audio/Transcript Sync
- Full cockpit audio playback via AVAudioPlayer, synchronized to the map position marker — pilot hears exactly what happened at each geographic point
- Scrolling transcript panel alongside map with current segment highlighted and auto-scrolling with playback — read along while watching and listening
- Dragging the scrub bar moves map position, audio position, and transcript position simultaneously — single unified control for all three data streams
- Flight history displayed as chronological list on Flights tab with date, departure→arrival, duration, aircraft; tap opens detail view with Replay + Debrief + Logbook — unified post-flight experience

### Claude's Discretion
- Track line coloring algorithm (altitude gradient vs speed gradient vs solid)
- Position marker animation smoothing between GPS points
- Transcript panel size and collapse/expand behavior
- Audio playback rate adjustment for speed-up modes (pitch correction vs chipmunk)
- Map auto-follow vs free-pan during replay
- Replay state management architecture

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `FlightDetailView.swift` — Existing flight detail view (add Replay button here)
- `FlightListView.swift` — Existing flight list (becomes flight history)
- `MapView.swift` / `MapService.swift` — Map rendering infrastructure (reuse for replay mode)
- `InstrumentStripView.swift` — Could show replay-time values (speed, altitude at playback point)

### Established Patterns
- MapLibre MLNMapView for map rendering with GeoJSON sources
- AVAudioPlayer for audio playback (standard iOS)
- Combine for synchronizing multiple data streams
- GRDB for reading GPS track points and transcript segments

### Integration Points
- Phase 3 GRDB: GPS track points (lat, lon, alt, speed, timestamp), flight phase markers (type, timestamp, coordinates)
- Phase 3 GRDB: Finalized transcript segments (text, timestamp, duration)
- Phase 3: Audio file path from recording (stored in app's Documents directory)
- Phase 4: Debrief content and logbook entry on the same flight detail view
- Phase 1 MapService: Reuse map rendering for replay with additional track overlay layer

</code_context>

<specifics>
## Specific Ideas

- GPS track points at ~1Hz means a 2-hour flight has ~7,200 points — map should handle this smoothly with GeoJSON line source
- Synchronization key: all data streams share the same timestamp space (recording start = t=0)
- Phase markers on scrub bar enable quick navigation: "jump to takeoff", "jump to approach"
- Replay should work fully offline (all data is local: GPS, audio, transcript, debrief)

</specifics>

<deferred>
## Deferred Ideas

- Export flight track to GPX/KMZ format (v2)
- Share replay as video (screen recording + audio composite)
- Compare multiple flights on same route (side-by-side replay)
- 3D replay with altitude visualization

</deferred>

---
*Phase: 05-track-replay*
*Context gathered: 2026-03-20 via Smart Discuss (autonomous)*
