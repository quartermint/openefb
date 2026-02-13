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

    // MARK: - Configuration

    /// Default cruise speed — knots TAS.
    private let defaultCruiseSpeed: Double = 100.0

    /// Default cruise altitude — feet MSL.
    private let defaultCruiseAltitude: Int = 3000

    /// Default fuel burn rate — gallons per hour (nil if unknown).
    private let defaultFuelBurnRate: Double? = nil

    // MARK: - Dependencies

    private let databaseManager: any DatabaseManagerProtocol

    // MARK: - Init

    init(databaseManager: any DatabaseManagerProtocol) {
        self.databaseManager = databaseManager
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
            let cruiseSpeed = defaultCruiseSpeed  // knots TAS
            let eteSeconds: TimeInterval = distanceNM > 0 ? (distanceNM / cruiseSpeed) * 3600 : 0

            // Calculate fuel if burn rate is available
            let estimatedFuel: Double? = {
                guard let burnRate = defaultFuelBurnRate else { return nil }
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
                cruiseSpeed: cruiseSpeed,
                fuelBurnRate: defaultFuelBurnRate,
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
