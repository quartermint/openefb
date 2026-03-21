//
//  OpacitySlider.swift
//  efb-212
//
//  Slider for adjusting VFR sectional chart overlay opacity (0-100%).
//  Bound to AppState.sectionalOpacity.
//

import SwiftUI

struct OpacitySlider: View {
    @Binding var opacity: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Sectional Opacity")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(opacity * 100))%")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .monospacedDigit()
            }

            Slider(value: $opacity, in: 0.0...1.0)
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    OpacitySlider(opacity: .constant(0.70))
        .frame(width: 240)
        .padding()
}
