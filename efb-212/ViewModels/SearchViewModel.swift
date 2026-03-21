//
//  SearchViewModel.swift
//  efb-212
//
//  Airport search with FTS5 full-text search backend via DatabaseServiceProtocol.
//  Debounces queries by 300ms, requires minimum 2 characters.
//  Per UI-SPEC: empty search shows no results, search failures clear silently.
//

import Foundation

@Observable
@MainActor
final class SearchViewModel {

    // MARK: - Dependencies

    let databaseService: any DatabaseServiceProtocol

    // MARK: - State

    var query: String = ""
    var results: [Airport] = []
    var isSearching: Bool = false

    // MARK: - Private

    private var searchTask: Task<Void, Never>?

    // MARK: - Init

    init(databaseService: any DatabaseServiceProtocol) {
        self.databaseService = databaseService
    }

    // MARK: - Search

    /// Debounced airport search. Cancels previous search, waits 300ms,
    /// then queries FTS5 via DatabaseServiceProtocol.searchAirports.
    /// Minimum 2 characters required.
    func search() {
        searchTask?.cancel()

        // Clear results and return immediately if query too short
        if query.count < 2 {
            results = []
            isSearching = false
            return
        }

        searchTask = Task { [weak self] in
            // 300ms debounce
            do {
                try await Task.sleep(nanoseconds: 300_000_000)
            } catch {
                return  // Cancelled
            }

            guard let self, !Task.isCancelled else { return }

            isSearching = true

            do {
                let searchResults = try databaseService.searchAirports(query: query, limit: 20)
                guard !Task.isCancelled else { return }
                results = searchResults
            } catch {
                // Silent failure -- search results clear per UI-SPEC copywriting contract
                guard !Task.isCancelled else { return }
                results = []
            }

            isSearching = false
        }
    }

    /// Clear search state.
    func clear() {
        searchTask?.cancel()
        query = ""
        results = []
        isSearching = false
    }
}
