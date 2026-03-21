//
//  TimelineScrubBar.swift
//  efb-212
//
//  Horizontal scrub bar with flight phase markers and time display.
//  Used at the bottom of ReplayView for timeline navigation.
//  Phase markers positioned as vertical ticks at their fractional positions.
//
//  REPLAY-02: Scrubbing the timeline moves map position, audio, and transcript simultaneously.
//

import SwiftUI

struct TimelineScrubBar: View {
    @Binding var currentPosition: TimeInterval
    let totalDuration: TimeInterval
    let phaseMarkerFractions: [PhaseMarkerFraction]
    let isPlaying: Bool
    let onSeek: (TimeInterval) -> Void

    var body: some View {
        VStack(spacing: 4) {
            // Slider with phase marker overlay
            ZStack(alignment: .leading) {
                // Phase marker overlay (behind the slider visually)
                phaseMarkerOverlay

                // Scrub slider
                Slider(
                    value: $currentPosition,
                    in: 0...max(totalDuration, 0.001),
                    onEditingChanged: { editing in
                        if !editing {
                            onSeek(currentPosition)
                        }
                    }
                )
                .tint(.orange)
            }

            // Time labels: elapsed (left) and remaining (right)
            HStack {
                Text(formatTime(currentPosition))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)

                Spacer()

                Text("-\(formatTime(max(0, totalDuration - currentPosition)))")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Phase Marker Overlay

    @ViewBuilder
    private var phaseMarkerOverlay: some View {
        GeometryReader { geometry in
            let sliderWidth = geometry.size.width
            let sliderHeight = geometry.size.height

            ForEach(Array(phaseMarkerFractions.enumerated()), id: \.offset) { _, marker in
                let xPosition = marker.fraction * sliderWidth

                VStack(spacing: 1) {
                    // Vertical tick mark
                    Rectangle()
                        .fill(Color.secondary.opacity(0.6))
                        .frame(width: 2, height: 12)

                    // Phase abbreviation label
                    Text(phaseAbbreviation(marker.phase))
                        .font(.system(size: 8))
                        .foregroundStyle(.tertiary)
                }
                .position(x: xPosition, y: sliderHeight / 2)
            }
        }
        .allowsHitTesting(false)  // Phase markers don't intercept touches
    }

    // MARK: - Phase Abbreviation

    /// Abbreviate flight phase names for compact display on the scrub bar.
    private func phaseAbbreviation(_ phase: String) -> String {
        switch phase.lowercased() {
        case "preflight": return "PRE"
        case "taxi": return "TXI"
        case "takeoff": return "T/O"
        case "departure": return "DEP"
        case "cruise": return "CRZ"
        case "approach": return "APR"
        case "landing": return "LND"
        case "postflight": return "PST"
        default: return String(phase.prefix(3)).uppercased()
        }
    }

    // MARK: - Time Formatting

    /// Format time interval as HH:MM:SS (>= 1 hour) or MM:SS.
    private func formatTime(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(max(0, interval))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}
