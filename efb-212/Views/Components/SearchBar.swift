//
//  SearchBar.swift
//  efb-212
//
//  Reusable airport search bar that queries DatabaseManagerProtocol.searchAirports().
//  Supports debounced search by ICAO identifier, FAA LID, or airport name.
//

import SwiftUI

struct SearchBar: View {
    @Binding var searchText: String
    @Binding var searchResults: [Airport]
    let databaseManager: any DatabaseManagerProtocol

    /// Minimum character count before triggering a search
    private let minimumQueryLength = 2
    /// Debounce interval in seconds
    private let debounceInterval: TimeInterval = 0.3
    /// Maximum results returned per query
    private let searchLimit = 20

    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search airports (ICAO, name, city)", text: $searchText)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)

                if isSearching {
                    ProgressView()
                        .controlSize(.small)
                }

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        searchResults = []
                        cancelSearch()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(.regularMaterial)
            .cornerRadius(10)
        }
        .onChange(of: searchText) { _, newValue in
            debouncedSearch(newValue)
        }
    }

    // MARK: - Search Logic

    /// Cancels any in-flight search task and schedules a new debounced search.
    private func debouncedSearch(_ query: String) {
        cancelSearch()

        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= minimumQueryLength else {
            searchResults = []
            return
        }

        searchTask = Task {
            // Debounce — wait before executing
            try? await Task.sleep(for: .seconds(debounceInterval))
            guard !Task.isCancelled else { return }
            await performSearch(trimmed)
        }
    }

    /// Executes the airport search against the database.
    private func performSearch(_ query: String) async {
        isSearching = true
        defer { isSearching = false }

        do {
            let results = try await databaseManager.searchAirports(query: query, limit: searchLimit)
            guard !Task.isCancelled else { return }
            searchResults = results
        } catch {
            // Silently handle errors — search is non-critical
            guard !Task.isCancelled else { return }
            searchResults = []
        }
    }

    /// Cancels the current in-flight search task.
    private func cancelSearch() {
        searchTask?.cancel()
        searchTask = nil
    }
}
