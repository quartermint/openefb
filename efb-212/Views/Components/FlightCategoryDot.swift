//
//  FlightCategoryDot.swift
//  efb-212
//
//  Color-coded circle indicating FAA flight category.
//  Per UI-SPEC: 12pt default circle, FAA standard colors.
//  VFR=green, MVFR=blue, IFR=red, LIFR=magenta.
//

import SwiftUI

struct FlightCategoryDot: View {

    let category: FlightCategory
    var size: CGFloat = 12

    var color: Color {
        switch category {
        case .vfr: return .green
        case .mvfr: return .blue
        case .ifr: return .red
        case .lifr: return Color(red: 0.8, green: 0.0, blue: 0.8)
        }
    }

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .accessibilityLabel("\(category.rawValue.uppercased()) conditions")
    }
}

#Preview {
    HStack(spacing: 16) {
        FlightCategoryDot(category: .vfr)
        FlightCategoryDot(category: .mvfr)
        FlightCategoryDot(category: .ifr)
        FlightCategoryDot(category: .lifr)
    }
}
