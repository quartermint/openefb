//
//  InstrumentStripView.swift
//  efb-212
//
//  Full-width bottom bar showing GS, ALT, VS, TRK instrument cells.
//  DTG and ETE appear conditionally when a flight plan or direct-to is active.
//  GPS unavailable: shows "---" dashes with "No GPS" indicator.
//
//  Per UI-SPEC: .ultraThinMaterial background, 16pt corner radius,
//  16pt horizontal / 8pt vertical padding. Numeric values use .title3 monospaced
//  semibold. Labels use .caption2 medium secondary. Units use .caption2 secondary
//  with lastTextBaseline alignment. No animation on value changes (pilot SA).
//

import SwiftUI

struct InstrumentStripView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        HStack(spacing: 0) {
            InstrumentCell(label: "GS", value: gsValue, unit: "KT")
            Divider().frame(height: 30)
            InstrumentCell(label: "ALT", value: altValue, unit: "FT")
            Divider().frame(height: 30)
            InstrumentCell(label: "VS", value: vsValue, unit: "FPM")
            Divider().frame(height: 30)
            InstrumentCell(label: "TRK", value: trkValue, unit: "\u{00B0}")

            if appState.activeFlightPlan || appState.directToAirport != nil {
                Divider().frame(height: 30)
                InstrumentCell(label: "DTG", value: dtgValue, unit: "NM")
                Divider().frame(height: 30)
                InstrumentCell(label: "ETE", value: eteValue, unit: "")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(alignment: .topTrailing) {
            if !appState.gpsAvailable {
                Text("No GPS")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(4)
                    .transition(.opacity.animation(.easeIn(duration: 0.3)))
            }
        }
    }

    // MARK: - Computed Values

    /// Ground speed in knots, rounded to nearest 1 kt
    private var gsValue: String {
        guard appState.gpsAvailable else { return "---" }
        return "\(Int(appState.groundSpeed))"
    }

    /// Altitude in feet MSL, rounded to nearest 10 ft (aviation standard)
    private var altValue: String {
        guard appState.gpsAvailable else { return "---" }
        return "\(Int((appState.altitude / 10).rounded() * 10))"
    }

    /// Vertical speed in fpm with +/- prefix
    private var vsValue: String {
        guard appState.gpsAvailable else { return "---" }
        let vs = Int(appState.verticalSpeed)
        return vs >= 0 ? "+\(vs)" : "\(vs)"
    }

    /// Track in degrees true, 3-digit with leading zeros
    private var trkValue: String {
        guard appState.gpsAvailable else { return "---" }
        return String(format: "%03.0f", appState.track)
    }

    /// Distance to go in nautical miles
    private var dtgValue: String {
        guard let dtg = appState.distanceToNext else { return "---" }
        return String(format: "%.1f", dtg)
    }

    /// Estimated time enroute formatted as Xh XXm or Xm
    private var eteValue: String {
        guard let ete = appState.estimatedTimeEnroute else { return "---" }
        let minutes = Int(ete / 60)
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 { return "\(hours)h\(String(format: "%02d", mins))m" }
        return "\(mins)m"
    }
}

// MARK: - InstrumentCell

/// Single instrument readout cell per UI-SPEC component inventory:
/// .caption2 label, .title3.monospaced.semibold value, .caption2 unit,
/// 60pt min width, 4pt horizontal padding.
struct InstrumentCell: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(.title3, design: .monospaced))
                    .fontWeight(.semibold)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(minWidth: 60)
        .padding(.horizontal, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) \(value) \(unit)")
    }
}

#Preview("GPS Available") {
    let appState = AppState()

    InstrumentStripView()
        .environment({
            appState.gpsAvailable = true
            appState.groundSpeed = 115
            appState.altitude = 4520
            appState.verticalSpeed = -200
            appState.track = 245
            return appState
        }())
        .padding()
}

#Preview("No GPS") {
    InstrumentStripView()
        .environment(AppState())
        .padding()
}

#Preview("With Flight Plan") {
    let appState = AppState()

    InstrumentStripView()
        .environment({
            appState.gpsAvailable = true
            appState.groundSpeed = 105
            appState.altitude = 5500
            appState.verticalSpeed = 0
            appState.track = 180
            appState.activeFlightPlan = true
            appState.distanceToNext = 42.3
            appState.estimatedTimeEnroute = 1440  // 24 minutes
            return appState
        }())
        .padding()
}
