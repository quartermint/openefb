//
//  RecordingOverlayView.swift
//  efb-212
//
//  Recording UI overlay on the map view:
//  - Record button (top-left, prominent, one-tap start/stop)
//  - Recording status bar (red dot + elapsed time + phase label)
//  - Live transcript panel (collapsible, last 5 segments)
//  - Auto-start countdown display (3-2-1 with cancel)
//  - Stop confirmation dialog
//
//  Per CONTEXT.md decisions:
//  - Record button: prominent floating, top-left, red when recording
//  - Status bar: red pulsing dot + elapsed time + flight phase
//  - Transcript panel: scrolling, collapsible, last 3-5 segments
//  - Manual stop: confirmation dialog "End flight recording?"
//

import SwiftUI

struct RecordingOverlayView: View {
    let viewModel: RecordingViewModel

    // Pulse animation state
    @State private var isPulsing = false

    var body: some View {
        @Bindable var vm = viewModel

        VStack {
            // MARK: - Top Area: Record Button + Status Bar

            HStack(alignment: .top) {
                // Record button (top-left)
                recordButton
                    .padding(.leading, 16)

                Spacer()

                // Status bar (top-center, visible when recording)
                if viewModel.isRecording {
                    recordingStatusBar
                }

                Spacer()
            }

            Spacer()

            // MARK: - Bottom Area: Transcript Panel (above instrument strip)

            if viewModel.isRecording || !viewModel.recentTranscripts.isEmpty {
                transcriptPanel
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
            }
        }

        // MARK: - Stop Confirmation Dialog

        .confirmationDialog(
            "End flight recording?",
            isPresented: $vm.showStopConfirmation,
            titleVisibility: .visible
        ) {
            Button("End Recording", role: .destructive) {
                Task { await viewModel.confirmStop() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will stop recording GPS track, audio, and transcription.")
        }
    }

    // MARK: - Record Button

    @ViewBuilder
    private var recordButton: some View {
        Button {
            Task {
                switch viewModel.recordingStatus {
                case .idle:
                    await viewModel.startRecording()
                case .recording:
                    viewModel.requestStop()
                case .countdown:
                    await viewModel.cancelCountdown()
                default:
                    break
                }
            }
        } label: {
            ZStack {
                if viewModel.isCountingDown {
                    // Countdown state: number with cancel option
                    Circle()
                        .fill(.orange)
                        .frame(width: 52, height: 52)
                    Text("\(viewModel.countdownRemaining)")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                } else if viewModel.isRecording {
                    // Recording state: red circle with stop icon
                    Circle()
                        .fill(.red)
                        .frame(width: 52, height: 52)
                        .overlay(
                            Circle()
                                .stroke(.red.opacity(0.5), lineWidth: 3)
                                .scaleEffect(isPulsing ? 1.4 : 1.0)
                                .opacity(isPulsing ? 0 : 1)
                                .animation(
                                    .easeOut(duration: 1.5).repeatForever(autoreverses: false),
                                    value: isPulsing
                                )
                        )
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white)
                        .frame(width: 18, height: 18)
                } else {
                    // Idle state: white circle with mic icon
                    Circle()
                        .fill(.white)
                        .frame(width: 52, height: 52)
                        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                    Image(systemName: "mic.fill")
                        .font(.title3)
                        .foregroundStyle(.red)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(recordButtonLabel)
        .onAppear { isPulsing = true }
    }

    private var recordButtonLabel: String {
        switch viewModel.recordingStatus {
        case .idle: return "Start recording"
        case .recording: return "Stop recording"
        case .countdown: return "Cancel countdown"
        case .paused: return "Resume recording"
        case .stopping: return "Stopping recording"
        }
    }

    // MARK: - Recording Status Bar

    @ViewBuilder
    private var recordingStatusBar: some View {
        HStack(spacing: 8) {
            // Red pulsing dot
            Circle()
                .fill(.red)
                .frame(width: 10, height: 10)
                .scaleEffect(isPulsing ? 1.2 : 0.8)
                .animation(
                    .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                    value: isPulsing
                )

            // Elapsed time
            Text(viewModel.formattedElapsedTime)
                .font(.subheadline.monospacedDigit().bold())
                .foregroundStyle(.primary)

            // Flight phase label
            Text(viewModel.currentPhase.rawValue.capitalized)
                .font(.caption)
                .foregroundStyle(.secondary)
                .transition(.opacity)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .padding(.trailing, 16)
    }

    // MARK: - Live Transcript Panel

    @ViewBuilder
    private var transcriptPanel: some View {
        VStack(spacing: 0) {
            // Toggle button (chevron to expand/collapse)
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.toggleTranscriptPanel()
                }
            } label: {
                HStack {
                    Image(systemName: "text.bubble")
                        .font(.caption)
                    Text("Transcription")
                        .font(.caption.bold())
                    Spacer()
                    Image(systemName: viewModel.isTranscriptPanelExpanded ? "chevron.down" : "chevron.up")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)

            // Expanded content: last 5 transcript segments
            if viewModel.isTranscriptPanelExpanded {
                Divider()

                if viewModel.recentTranscripts.isEmpty {
                    Text("Listening...")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.vertical, 12)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(viewModel.recentTranscripts.suffix(5)) { item in
                                TranscriptItemRow(item: item)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                    .frame(maxHeight: 120)
                }
            }
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Transcript Item Row

private struct TranscriptItemRow: View {
    let item: TranscriptDisplayItem

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            // Timestamp
            Text(item.timestamp, format: .dateTime.hour().minute().second())
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.tertiary)
                .frame(width: 55, alignment: .leading)

            // Transcript text -- volatile items shown lighter
            Text(item.text)
                .font(.caption)
                .foregroundStyle(item.isVolatile ? .secondary : .primary)
                .italic(item.isVolatile)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()
        // Preview requires real coordinator -- this is for layout only
        Text("Map placeholder")
    }
}
