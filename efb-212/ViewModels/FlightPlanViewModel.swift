//
//  FlightPlanViewModel.swift
//  efb-212
//
//  Manages flight plan creation and editing state.
//  Looks up airports, calculates distance/ETE, builds FlightPlan.
//  MainActor by default (SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor).
//

import Foundation
import Combine
import CoreLocation

final class FlightPlanViewModel: ObservableObject {

    // MARK: - Published State

    /// Departure airport ICAO code entered by the user.
    @Published var departureICAO: String = ""

    /// Destination airport ICAO code entered by the user.
    @Published var destinationICAO: String = ""

    /// The active flight plan, if one has been created.
    @Published var activePlan: FlightPlan?

    /// Resolved departure airport model.
    @Published var departureAirport: Airport?

    /// Resolved destination airport model.
    @Published var destinationAirport: Airport?

    /// Whether a flight plan is currently being created.
    @Published var isCreatingPlan: Bool = false

    /// Last error encountered.
    @Published var error: EFBError?

    // MARK: - Aircraft Configuration

    /// Cruise speed used for ETE calculations — knots TAS.
    /// Defaults to 100 kts when no aircraft profile is selected.
    @Published var cruiseSpeed: Double = 100.0

    /// Fuel burn rate — gallons per hour. Nil when no aircraft profile is configured.
    @Published var fuelBurnRate: Double?

    /// Fuel capacity — gallons. Nil when no aircraft profile is configured.
    @Published var fuelCapacity: Double?

    /// Display name of the selected aircraft, if any.
    @Published var selectedAircraftName: String?

    /// Default cruise altitude — feet MSL.
    private let defaultCruiseAltitude: Int = 3000

    /// Whether an aircraft profile is providing performance data.
    var hasAircraftProfile: Bool { selectedAircraftName != nil }

    /// Whether estimated fuel exceeds aircraft fuel capacity.
    var fuelInsufficient: Bool {
        guard let fuel = activePlan?.estimatedFuel,
              let capacity = fuelCapacity else { return false }
        return fuel > capacity
    }

    // MARK: - Dependencies

    private let databaseManager: any DatabaseManagerProtocol

    // MARK: - Init

    init(databaseManager: any DatabaseManagerProtocol) {
        self.databaseManager = databaseManager
    }

    // MARK: - Aircraft Configuration

    /// Configure flight plan calculations from an aircraft profile.
    /// - Parameters:
    ///   - name: Aircraft display name (e.g., "N4543A - AA-5B Tiger").
    ///   - cruiseSpeed: Cruise speed in knots TAS. Nil keeps the current value.
    ///   - fuelBurn: Fuel burn rate in GPH. Nil clears fuel estimates.
    ///   - fuelCapacity: Fuel capacity in gallons. Nil clears fuel sufficiency check.
    func configureFromAircraftProfile(
        name: String,
        cruiseSpeed: Double?,
        fuelBurn: Double?,
        fuelCapacity: Double?
    ) {
        self.selectedAircraftName = name
        if let speed = cruiseSpeed, speed > 0 {
            self.cruiseSpeed = speed
        }
        self.fuelBurnRate = fuelBurn
        self.fuelCapacity = fuelCapacity
    }

    /// Clear aircraft profile, reverting to defaults.
    func clearAircraftProfile() {
        selectedAircraftName = nil
        cruiseSpeed = 100.0
        fuelBurnRate = nil
        fuelCapacity = nil
    }

    // MARK: - Flight Plan Creation

    /// Create a flight plan from the current departure and destination ICAO codes.
    /// Looks up airports in the database, calculates distance and ETE,
    /// and builds a FlightPlan with departure and destination waypoints.
    func createFlightPlan() async {
        let depID = departureICAO.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let destID = destinationICAO.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)

        guard !depID.isEmpty, !destID.isEmpty else {
            error = .airportNotFound("Please enter both departure and destination")
            return
        }

        isCreatingPlan = true
        error = nil
        defer { isCreatingPlan = false }

        // Look up departure airport
        do {
            guard let depAirport = try await databaseManager.airport(byICAO: depID) else {
                error = .airportNotFound(depID)
                return
            }
            departureAirport = depAirport

            // Look up destination airport
            guard let destAirport = try await databaseManager.airport(byICAO: destID) else {
                error = .airportNotFound(destID)
                return
            }
            destinationAirport = destAirport

            // Calculate distance using CLLocation
            let depLocation = CLLocation(latitude: depAirport.latitude, longitude: depAirport.longitude)
            let destLocation = CLLocation(latitude: destAirport.latitude, longitude: destAirport.longitude)
            let distanceMeters = depLocation.distance(from: destLocation)
            let distanceNM = distanceMeters.metersToNM  // Uses CLLocation+Aviation extension

            // Calculate ETE from cruise speed
            let speed = cruiseSpeed  // knots TAS (from aircraft profile or default 100)
            let eteSeconds: TimeInterval = distanceNM > 0 ? (distanceNM / speed) * 3600 : 0

            // Calculate fuel if burn rate is available
            let estimatedFuel: Double? = {
                guard let burnRate = fuelBurnRate else { return nil }
                let hours = eteSeconds / 3600.0
                return burnRate * hours  // gallons
            }()

            // Build waypoints
            let departureWaypoint = Waypoint(
                identifier: depAirport.icao,
                name: depAirport.name,
                latitude: depAirport.latitude,
                longitude: depAirport.longitude,
                altitude: Int(depAirport.elevation),
                type: .airport
            )

            let destinationWaypoint = Waypoint(
                identifier: destAirport.icao,
                name: destAirport.name,
                latitude: destAirport.latitude,
                longitude: destAirport.longitude,
                altitude: Int(destAirport.elevation),
                type: .airport
            )

            // Build flight plan
            let plan = FlightPlan(
                name: "\(depID) to \(destID)",
                departure: depID,
                destination: destID,
                waypoints: [departureWaypoint, destinationWaypoint],
                cruiseAltitude: defaultCruiseAltitude,
                cruiseSpeed: speed,
                fuelBurnRate: fuelBurnRate,
                totalDistance: distanceNM,
                estimatedTime: eteSeconds,
                estimatedFuel: estimatedFuel
            )

            activePlan = plan
        } catch {
            self.error = .airportNotFound(depID)
        }
    }

    /// Clear the active flight plan and reset form fields.
    func clearFlightPlan() {
        activePlan = nil
        departureAirport = nil
        destinationAirport = nil
        departureICAO = ""
        destinationICAO = ""
        error = nil
    }

    // MARK: - Computed Helpers

    /// Formatted total distance string (e.g., "45.2 NM").
    var formattedDistance: String? {
        guard let plan = activePlan else { return nil }
        return String(format: "%.1f NM", plan.totalDistance)
    }

    /// Formatted ETE string (e.g., "0h 27m").
    var formattedETE: String? {
        guard let plan = activePlan else { return nil }
        let totalMinutes = Int(plan.estimatedTime / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    /// Formatted estimated fuel string (e.g., "4.5 gal"), or nil if unknown.
    var formattedFuel: String? {
        guard let fuel = activePlan?.estimatedFuel else { return nil }
        return String(format: "%.1f gal", fuel)
    }

    /// Formatted cruise altitude (e.g., "3,000 ft MSL").
    var formattedAltitude: String? {
        guard let plan = activePlan else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let formatted = formatter.string(from: NSNumber(value: plan.cruiseAltitude)) ?? "\(plan.cruiseAltitude)"
        return "\(formatted) ft MSL"
    }

    /// Formatted cruise speed (e.g., "100 kts TAS").
    var formattedSpeed: String? {
        guard let plan = activePlan else { return nil }
        return "\(Int(plan.cruiseSpeed)) kts TAS"
    }
}
