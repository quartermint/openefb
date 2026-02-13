//
//  FlightCategoryDot.swift
//  efb-212
//
//  Small colored circle indicating VFR/MVFR/IFR/LIFR flight conditions.
//  Used on map weather dots and in airport info sheets.
//

import SwiftUI

struct FlightCategoryDot: View {
    let category: FlightCategory
    var size: CGFloat = 12

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .accessibilityLabel("\(category.rawValue.uppercased()) conditions")
    }

    /// Maps FlightCategory to SwiftUI Color using the colorName property.
    private var color: Color {
        switch category {
        case .vfr:  return .green
        case .mvfr: return .blue
        case .ifr:  return .red
        case .lifr: return Color(red: 0.8, green: 0.0, blue: 0.8) // magenta
        }
    }
}

#Preview {
    HStack(spacing: 12) {
        ForEach(FlightCategory.allCases, id: \.self) { cat in
            VStack {
                FlightCategoryDot(category: cat, size: 16)
                Text(cat.rawValue.uppercased())
                    .font(.caption2)
            }
        }
    }
    .padding()
}
