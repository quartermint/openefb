//
//  ReplayView.swift
//  efb-212
//
//  Full-screen track replay experience -- map + transcript panel + scrub bar + playback controls.
//  iPad landscape optimized. Driven by ReplayEngine from Plan 01.
//  REPLAY-01: Position marker follows recorded GPS track at controllable playback speed.
//  REPLAY-02: Audio, transcript, and map position synchronized through scrub bar.
//

import SwiftUI

struct ReplayView: View {
    let flightRecord: SchemaV1.FlightRecord

    @Environment(AppState.self) private var appState
    @State private var viewModel = ReplayViewModel()

    var body: some View {
        Group {
            if appState.recordingStatus != .idle {
                recordingActiveGuard
            } else if viewModel.isLoading {
                loadingState
            } else if let error = viewModel.loadError {
                errorState(error)
            } else {
                replayContent
            }
        }
        .navigationTitle(navigationTitleText)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if appState.recordingStatus == .idle {
                viewModel.loadFlight(flightRecord: flightRecord, appState: appState)
            }
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }

    // MARK: - Navigation Title

    private var navigationTitleText: String {
        let dep = flightRecord.departureICAO ?? ""
        let arr = flightRecord.arrivalICAO ?? ""
        if dep.isEmpty && arr.isEmpty {
            return "Flight Replay"
        }
        return "\(dep) to \(arr)"
    }

    // MARK: - Main Replay Content

    @ViewBuilder
    private var replayContent: some View {
        ZStack {
            // Main content: map + optional transcript panel
            HStack(spacing: 0) {
                // Left: Replay map (takes remaining space)
                ReplayMapView(
                    replayEngine: viewModel.replayEngine,
                    autoFollow: $viewModel.autoFollow
                )

                // Right: Transcript panel (~300pt, collapsible)
                if viewModel.isTranscriptPanelExpanded {
                    TranscriptPanelView(
                        segments: viewModel.replayEngine.transcriptSegments,
                        activeIndex: viewModel.replayEngine.currentTranscriptIndex
                    )
                    .frame(width: 300)
                    .transition(.move(edge: .trailing))
                }
            }

            // Overlay controls
            VStack {
                HStack(alignment: .top) {
                    // Top-left: Playback controls
                    playbackControlsOverlay
                        .padding(.leading, 16)
                        .padding(.top, 8)

                    Spacer()

                    // Top-right: Instrument readouts + transcript toggle
                    VStack(alignment: .trailing, spacing: 8) {
                        instrumentReadoutsOverlay
                        transcriptToggleButton
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 8)
                }

                Spacer()

                // Audio muted indicator
                if viewModel.replayEngine.audioMuted {
                    audioMutedIndicator
                        .padding(.bottom, 4)
                }

                // Collapsed transcript card (when panel is collapsed, show current segment)
                if !viewModel.isTranscriptPanelExpanded,
                   let index = viewModel.replayEngine.currentTranscriptIndex,
                   index < viewModel.replayEngine.transcriptSegments.count {
                    collapsedTranscriptCard(
                        segment: viewModel.replayEngine.transcriptSegments[index]
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
                }

                // Bottom: Timeline scrub bar (full width)
                TimelineScrubBar(
                    currentPosition: Binding(
                        get: { viewModel.replayEngine.currentPosition },
                        set: { viewModel.replayEngine.seekTo($0) }
                    ),
                    totalDuration: viewModel.replayEngine.totalDuration,
                    phaseMarkerFractions: viewModel.replayEngine.phaseMarkerFractions,
                    isPlaying: viewModel.replayEngine.isPlaying,
                    onSeek: { position in
                        viewModel.replayEngine.seekTo(position)
                    }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }

    // MARK: - Playback Controls Overlay

    @ViewBuilder
    private var playbackControlsOverlay: some View {
        HStack(spacing: 12) {
            // Play/Pause button
            Button {
                viewModel.togglePlayPause()
            } label: {
                Image(systemName: viewModel.replayEngine.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(.blue))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(viewModel.replayEngine.isPlaying ? "Pause" : "Play")

            // Speed selector
            Button {
                viewModel.showSpeedPicker.toggle()
            } label: {
                Text("\(viewModel.replayEngine.playbackSpeed, specifier: "%.0f")x")
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(.black.opacity(0.6)))
            }
            .buttonStyle(.plain)
            .popover(isPresented: $viewModel.showSpeedPicker) {
                speedPickerContent
            }

            // Re-center button (visible when auto-follow is off)
            if !viewModel.autoFollow {
                Button {
                    viewModel.recenter()
                } label: {
                    Image(systemName: "location.fill")
                        .font(.body)
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(.orange))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Re-center map")
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Speed Picker

    @ViewBuilder
    private var speedPickerContent: some View {
        VStack(spacing: 4) {
            ForEach(ReplayViewModel.availableSpeeds, id: \.self) { speed in
                Button {
                    viewModel.selectSpeed(speed)
                } label: {
                    HStack {
                        Text("\(speed, specifier: "%.0f")x")
                            .font(.body.monospacedDigit())
                        if speed == viewModel.replayEngine.playbackSpeed {
                            Image(systemName: "checkmark")
                                .font(.caption)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
        .presentationCompactAdaptation(.popover)
    }

    // MARK: - Instrument Readouts Overlay

    @ViewBuilder
    private var instrumentReadoutsOverlay: some View {
        HStack(spacing: 16) {
            // Ground speed -- knots
            VStack(spacing: 2) {
                Text("GS")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(Int(viewModel.replayEngine.currentSpeed))")
                    .font(.subheadline.bold().monospacedDigit())
            }

            // Altitude -- feet MSL
            VStack(spacing: 2) {
                Text("ALT")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(Int(viewModel.replayEngine.currentAltitude))")
                    .font(.subheadline.bold().monospacedDigit())
            }

            // Heading -- degrees true
            VStack(spacing: 2) {
                Text("HDG")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(Int(viewModel.replayEngine.currentHeading))\u{00B0}")
                    .font(.subheadline.bold().monospacedDigit())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Transcript Toggle Button

    @ViewBuilder
    private var transcriptToggleButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                viewModel.isTranscriptPanelExpanded.toggle()
            }
        } label: {
            Image(systemName: viewModel.isTranscriptPanelExpanded ? "sidebar.trailing" : "text.bubble")
                .font(.body)
                .foregroundStyle(.primary)
                .frame(width: 36, height: 36)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(viewModel.isTranscriptPanelExpanded ? "Hide transcript" : "Show transcript")
    }

    // MARK: - Audio Muted Indicator

    @ViewBuilder
    private var audioMutedIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "speaker.slash.fill")
                .font(.caption2)
            Text("Audio muted at \(viewModel.replayEngine.playbackSpeed, specifier: "%.0f")x")
                .font(.caption2)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    // MARK: - Collapsed Transcript Card

    @ViewBuilder
    private func collapsedTranscriptCard(segment: TranscriptSegmentRecord) -> some View {
        HStack {
            Image(systemName: "text.bubble.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(segment.text)
                .font(.caption)
                .lineLimit(2)
            Spacer()
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Recording Active Guard

    @ViewBuilder
    private var recordingActiveGuard: some View {
        VStack(spacing: 16) {
            Image(systemName: "record.circle")
                .font(.largeTitle)
                .foregroundStyle(.red)
            Text("Stop recording before replaying a flight.")
                .font(.headline)
                .multilineTextAlignment(.center)
            Text("An active flight recording is in progress. End the recording from the Map tab to enable replay.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }

    // MARK: - Loading State

    @ViewBuilder
    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)
            Text("Loading flight data...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Error State

    @ViewBuilder
    private func errorState(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text("Could not load flight")
                .font(.headline)
            Text(error)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                viewModel.loadFlight(flightRecord: flightRecord, appState: appState)
            }
            .buttonStyle(.bordered)
        }
        .padding(32)
    }
}
