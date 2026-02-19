//
//  WeatherService.swift
//  efb-212
//
//  NOAA Aviation Weather API client with in-memory caching.
//  Fetches METAR and TAF data, parses JSON, determines flight categories.
//
//  Actor isolation: nonisolated actor (opted out of MainActor default).
//  Conforms to WeatherServiceProtocol (Sendable).
//

import Foundation

// MARK: - NOAA API Response Models

/// Top-level METAR JSON element from aviationweather.gov
/// Marked nonisolated to opt out of MainActor default — used inside nonisolated actor.
private nonisolated struct METARResponse: Decodable {
    let icaoId: String?
    let rawOb: String?
    let temp: Double?
    let dewp: Double?
    let wdir: IntOrString?
    let wspd: Int?
    let wgst: Int?
    let visib: VisibilityValue?
    let altim: Double?
    let clouds: [CloudLayer]?
    let obsTime: String?  // ISO 8601 observation time

    /// Cloud layer within a METAR
    struct CloudLayer: Decodable {
        let cover: String?  // "FEW", "SCT", "BKN", "OVC"
        let base: Int?      // feet AGL
    }

    /// Visibility can be a number or string like "10+" in NOAA JSON
    enum VisibilityValue: Decodable {
        case number(Double)
        case string(String)

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let doubleVal = try? container.decode(Double.self) {
                self = .number(doubleVal)
            } else if let stringVal = try? container.decode(String.self) {
                self = .string(stringVal)
            } else {
                self = .number(10.0) // default to 10 SM
            }
        }

        var doubleValue: Double {
            switch self {
            case .number(let val): return val
            case .string(let str):
                // Handle "10+", "P6SM", etc.
                let cleaned = str.replacingOccurrences(of: "+", with: "")
                    .replacingOccurrences(of: "P", with: "")
                    .replacingOccurrences(of: "SM", with: "")
                return Double(cleaned) ?? 10.0
            }
        }
    }

    /// Wind direction can be "VRB" (string) or an integer
    enum IntOrString: Decodable {
        case int(Int)
        case string(String)

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let intVal = try? container.decode(Int.self) {
                self = .int(intVal)
            } else if let stringVal = try? container.decode(String.self) {
                self = .string(stringVal)
            } else {
                self = .int(0)
            }
        }

        var intValue: Int {
            switch self {
            case .int(let val): return val
            case .string: return 0  // variable wind
            }
        }

        var isVariable: Bool {
            switch self {
            case .int: return false
            case .string(let str): return str.uppercased() == "VRB"
            }
        }
    }
}

/// Top-level TAF JSON element from aviationweather.gov
/// Marked nonisolated to opt out of MainActor default — used inside nonisolated actor.
private nonisolated struct TAFResponse: Decodable {
    let icaoId: String?
    let rawTAF: String?
}

// MARK: - WeatherService Actor

nonisolated actor WeatherService: WeatherServiceProtocol {

    // MARK: - Properties

    /// In-memory weather cache keyed by ICAO station ID.
    private var cache: [String: WeatherCache] = [:]

    /// Cache time-to-live — 15 minutes.
    private let cacheTTL: TimeInterval = 900  // seconds

    /// URLSession for API requests.
    private let session: URLSession

    /// Database manager for persistent weather cache (GRDB).
    private let databaseManager: (any DatabaseManagerProtocol)?

    /// Base URL for NOAA Aviation Weather API.
    private let baseURL = "https://aviationweather.gov/api/data"

    // MARK: - Init

    init(session: URLSession = .shared, databaseManager: (any DatabaseManagerProtocol)? = nil) {
        self.session = session
        self.databaseManager = databaseManager
    }

    // MARK: - WeatherServiceProtocol

    func fetchMETAR(for stationID: String) async throws -> WeatherCache {
        let id = stationID.uppercased()

        // Return in-memory cached data if fresh
        if let cached = cache[id], cached.age < cacheTTL {
            return cached
        }

        // Check GRDB persistent cache on in-memory miss
        if let dbCached = try? await databaseManager?.cachedWeather(for: id),
           dbCached.age < cacheTTL {
            cache[id] = dbCached
            return dbCached
        }

        let urlString = "\(baseURL)/metar?ids=\(id)&format=json"
        guard let url = URL(string: urlString) else {
            throw EFBError.weatherFetchFailed(underlying: URLError(.badURL))
        }

        do {
            let (data, _) = try await session.data(from: url)
            let responses = try JSONDecoder().decode([METARResponse].self, from: data)

            guard let metar = responses.first else {
                throw EFBError.weatherFetchFailed(
                    underlying: NSError(domain: "WeatherService", code: 404,
                                        userInfo: [NSLocalizedDescriptionKey: "No METAR data for \(id)"])
                )
            }

            var weather = parseMetarResponse(metar, stationID: id)

            // Preserve existing TAF if we have it cached
            if let existing = cache[id] {
                weather.taf = existing.taf
            }

            cache[id] = weather

            // Write through to GRDB persistent cache
            try? await databaseManager?.cacheWeather(weather)

            return weather
        } catch let error as EFBError {
            // Return cached data on error if available
            if let cached = cache[id] { return cached }
            throw error
        } catch {
            // Return cached data on network error
            if let cached = cache[id] { return cached }
            throw EFBError.weatherFetchFailed(underlying: error)
        }
    }

    func fetchTAF(for stationID: String) async throws -> String {
        let id = stationID.uppercased()

        let urlString = "\(baseURL)/taf?ids=\(id)&format=json"
        guard let url = URL(string: urlString) else {
            throw EFBError.weatherFetchFailed(underlying: URLError(.badURL))
        }

        do {
            let (data, _) = try await session.data(from: url)
            let responses = try JSONDecoder().decode([TAFResponse].self, from: data)

            guard let taf = responses.first, let rawTAF = taf.rawTAF else {
                throw EFBError.weatherFetchFailed(
                    underlying: NSError(domain: "WeatherService", code: 404,
                                        userInfo: [NSLocalizedDescriptionKey: "No TAF data for \(id)"])
                )
            }

            // Update in-memory cache with TAF
            if cache[id] != nil {
                cache[id]?.taf = rawTAF
                // Write through updated entry to GRDB
                if let updated = cache[id] {
                    try? await databaseManager?.cacheWeather(updated)
                }
            }

            return rawTAF
        } catch let error as EFBError {
            throw error
        } catch {
            throw EFBError.weatherFetchFailed(underlying: error)
        }
    }

    func fetchWeatherForStations(_ stationIDs: [String]) async throws -> [WeatherCache] {
        let ids = stationIDs.map { $0.uppercased() }
        guard !ids.isEmpty else { return [] }

        let joined = ids.joined(separator: ",")
        let urlString = "\(baseURL)/metar?ids=\(joined)&format=json"
        guard let url = URL(string: urlString) else {
            throw EFBError.weatherFetchFailed(underlying: URLError(.badURL))
        }

        do {
            let (data, _) = try await session.data(from: url)
            let responses = try JSONDecoder().decode([METARResponse].self, from: data)

            var results: [WeatherCache] = []
            for metar in responses {
                let stationID = metar.icaoId?.uppercased() ?? ""
                guard !stationID.isEmpty else { continue }

                var weather = parseMetarResponse(metar, stationID: stationID)

                // Preserve existing TAF
                if let existing = cache[stationID] {
                    weather.taf = existing.taf
                }

                cache[stationID] = weather
                results.append(weather)

                // Write through to GRDB persistent cache
                try? await databaseManager?.cacheWeather(weather)
            }

            return results
        } catch let error as EFBError {
            throw error
        } catch {
            throw EFBError.weatherFetchFailed(underlying: error)
        }
    }

    nonisolated func cachedWeather(for stationID: String) -> WeatherCache? {
        // This is a synchronous, nonisolated method per protocol.
        // Cannot safely access actor state synchronously — return nil.
        // Callers should use fetchMETAR for current data.
        return nil
    }

    // MARK: - Cache Maintenance

    /// Remove weather entries older than 1 hour from both in-memory and GRDB caches.
    func cleanupStaleCache() async {
        let staleThreshold: TimeInterval = 3600  // 1 hour

        // Clean in-memory cache
        let now = Date()
        cache = cache.filter { _, value in
            now.timeIntervalSince(value.fetchedAt) < staleThreshold
        }

        // Clean GRDB cache
        guard let databaseManager else { return }
        do {
            let staleIDs = try await databaseManager.staleWeatherStations(olderThan: staleThreshold)
            if !staleIDs.isEmpty {
                try await databaseManager.clearWeatherCache()
                // Re-persist only the fresh in-memory entries
                for (_, weather) in cache {
                    try await databaseManager.cacheWeather(weather)
                }
            }
        } catch {
            // Stale cleanup is best-effort — don't propagate errors
        }
    }

    // MARK: - Parsing

    /// Parse a NOAA METAR JSON response into a WeatherCache struct.
    private func parseMetarResponse(_ metar: METARResponse, stationID: String) -> WeatherCache {
        let visibility = metar.visib?.doubleValue  // statute miles
        let ceiling = determineCeiling(from: metar.clouds)
        let category = determineFlightCategory(ceiling: ceiling, visibility: visibility)

        let wind: WindInfo? = {
            guard let speed = metar.wspd else { return nil }
            let direction = metar.wdir?.intValue ?? 0
            let isVariable = metar.wdir?.isVariable ?? false
            return WindInfo(
                direction: direction,
                speed: speed,
                gusts: metar.wgst,
                isVariable: isVariable
            )
        }()

        let observationTime: Date? = {
            guard let obsTimeStr = metar.obsTime else { return nil }
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: obsTimeStr) { return date }
            // Try without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            return formatter.date(from: obsTimeStr)
        }()

        return WeatherCache(
            stationID: stationID,
            metar: metar.rawOb,
            flightCategory: category,
            temperature: metar.temp,
            dewpoint: metar.dewp,
            wind: wind,
            visibility: visibility,
            ceiling: ceiling,
            fetchedAt: Date(),
            observationTime: observationTime
        )
    }

    /// Determine ceiling from cloud layers.
    /// Ceiling is the lowest BKN or OVC layer.
    /// - Parameter clouds: Array of cloud layers from METAR JSON.
    /// - Returns: Ceiling in feet AGL, or nil if sky clear / no ceiling.
    private func determineCeiling(from clouds: [METARResponse.CloudLayer]?) -> Int? {
        guard let clouds else { return nil }

        let ceilingCovers: Set<String> = ["BKN", "OVC"]
        let ceilingLayers = clouds.filter { layer in
            guard let cover = layer.cover?.uppercased() else { return false }
            return ceilingCovers.contains(cover)
        }

        // Return the lowest ceiling layer base
        let bases = ceilingLayers.compactMap(\.base)
        return bases.min()
    }

    /// Determine flight category from ceiling and visibility.
    /// VFR:  ceiling > 3000 AND visibility > 5 SM
    /// MVFR: ceiling 1000-3000 OR visibility 3-5 SM
    /// IFR:  ceiling 500-999 OR visibility 1-3 SM
    /// LIFR: ceiling < 500 OR visibility < 1 SM
    private func determineFlightCategory(ceiling: Int?, visibility: Double?) -> FlightCategory {
        let ceil = ceiling ?? 99999  // no ceiling = clear sky, treat as high
        let vis = visibility ?? 10.0 // no visibility report = assume good

        // Check worst category first (LIFR)
        if ceil < 500 || vis < 1.0 {
            return .lifr
        }
        if ceil < 1000 || vis < 3.0 {
            return .ifr
        }
        if ceil <= 3000 || vis <= 5.0 {
            return .mvfr
        }
        return .vfr
    }
}
