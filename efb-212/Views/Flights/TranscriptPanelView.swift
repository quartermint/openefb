//
//  TranscriptPanelView.swift
//  efb-212
//
//  Scrolling transcript panel with active segment highlight and auto-scroll.
//  Used in the replay view right panel -- shows all transcript segments
//  with the current segment highlighted and centered.
//
//  REPLAY-02: Transcript scrolls to matching segment as position marker moves.
//

import SwiftUI

struct TranscriptPanelView: View {
    let segments: [TranscriptSegmentRecord]
    let activeIndex: Int?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "text.bubble")
                    .font(.caption)
                Text("Transcript")
                    .font(.caption.bold())
                Spacer()
                Text("\(segments.count) segments")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Content
            if segments.isEmpty {
                emptyState
            } else {
                scrollableTranscript
            }
        }
        .background(.regularMaterial)
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "text.bubble")
                .font(.title2)
                .foregroundStyle(.tertiary)
            Text("No transcript available")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Scrollable Transcript

    @ViewBuilder
    private var scrollableTranscript: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                        TranscriptSegmentRow(
                            segment: segment,
                            isActive: index == activeIndex,
                            formattedTime: formatTime(segment.audioStartTime)
                        )
                        .id(index)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .onChange(of: activeIndex) { _, newIndex in
                guard let newIndex = newIndex else { return }
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
    }

    // MARK: - Time Formatting

    /// Format seconds as MM:SS (or HH:MM:SS for >= 1 hour).
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

// MARK: - Segment Row

private struct TranscriptSegmentRow: View {
    let segment: TranscriptSegmentRecord
    let isActive: Bool
    let formattedTime: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Timestamp
            Text(formattedTime)
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.tertiary)
                .frame(width: 48, alignment: .trailing)

            // Segment text
            VStack(alignment: .leading, spacing: 2) {
                Text(segment.text)
                    .font(isActive ? .caption.bold() : .caption)
                    .foregroundStyle(isActive ? .primary : .secondary)

                // Flight phase badge
                Text(segment.flightPhase.capitalized)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isActive ? Color.blue.opacity(0.15) : Color.clear)
        )
        .animation(.easeInOut(duration: 0.2), value: isActive)
    }
}
