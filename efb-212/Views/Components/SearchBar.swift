//
//  SearchBar.swift
//  efb-212
//
//  Search input for airport lookup by ICAO, name, or city.
//  Per UI-SPEC: .regularMaterial background, 8pt corner radius,
//  8pt internal padding, magnifying glass + clear button (SF Symbols).
//

import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    let onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .accessibilityHidden(true)  // decorative per UI-SPEC accessibility

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.subheadline)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)  // ICAO IDs are uppercase
                .onSubmit(onSubmit)

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(8)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    SearchBar(
        text: .constant("KPAO"),
        placeholder: "Search airports (ICAO, name, city)",
        onSubmit: {}
    )
    .padding()
}
