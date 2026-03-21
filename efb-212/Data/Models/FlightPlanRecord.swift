//
//  FlightPlanRecord.swift
//  efb-212
//
//  SwiftData model for saved flight plans.
//  Stored in SchemaV1 for versioned migration support.
//  Converts to/from the lightweight FlightPlan struct used at runtime.
//

import Foundation
import SwiftData

// MARK: - FlightPlanRecord

extension SchemaV1 {

    @Model
    final class FlightPlanRecord {
        /// Unique identifier for this record.
        var id: UUID = UUID()

        /// User-assigned name for this flight plan.
        var name: String?

        /// Departure airport ICAO identifier (e.g., "KPAO").
        var departureICAO: String = ""

        /// Departure airport display name.
        var departureName: String = ""

        /// Departure airport latitude -- degrees.
        var departureLatitude: Double = 0

        /// Departure airport longitude -- degrees.
        var departureLongitude: Double = 0

        /// Destination airport ICAO identifier (e.g., "KSQL").
        var destinationICAO: String = ""

        /// Destination airport display name.
        var destinationName: String = ""

        /// Destination airport latitude -- degrees.
        var destinationLatitude: Double = 0

        /// Destination airport longitude -- degrees.
        var destinationLongitude: Double = 0

        /// Planned cruise altitude -- feet MSL.
        var cruiseAltitude: Int = 3000

        /// Planned cruise true airspeed -- knots.
        var cruiseSpeedKts: Double = 100

        /// Fuel burn rate -- gallons per hour.
        var fuelBurnGPH: Double?

        /// Total route distance -- nautical miles.
        var totalDistanceNM: Double = 0

        /// Estimated time enroute -- seconds.
        var estimatedTimeSeconds: Double = 0

        /// Estimated fuel required -- gallons.
        var estimatedFuelGallons: Double?

        /// Free-text notes for this flight plan.
        var notes: String?

        /// Last time this plan was used/activated.
        var lastUsedAt: Date = Date()

        /// Date this record was created.
        var createdAt: Date = Date()

        init() {}

        // MARK: - Conversion

        /// Convert this SwiftData record to a lightweight FlightPlan struct for runtime use.
        func toFlightPlan() -> FlightPlan {
            let departureWaypoint = Waypoint(
                identifier: departureICAO,
                name: departureName,
                latitude: departureLatitude,
                longitude: departureLongitude,
                type: .airport
            )
            let destinationWaypoint = Waypoint(
                identifier: destinationICAO,
                name: destinationName,
                latitude: destinationLatitude,
                longitude: destinationLongitude,
                type: .airport
            )

            return FlightPlan(
                id: id,
                name: name,
                departure: departureICAO,
                destination: destinationICAO,
                waypoints: [departureWaypoint, destinationWaypoint],
                cruiseAltitude: cruiseAltitude,
                cruiseSpeed: cruiseSpeedKts,
                fuelBurnRate: fuelBurnGPH,
                totalDistance: totalDistanceNM,
                estimatedTime: estimatedTimeSeconds,
                estimatedFuel: estimatedFuelGallons,
                createdAt: createdAt,
                notes: notes
            )
        }

        /// Create a record from a FlightPlan struct with airport display names.
        convenience init(from plan: FlightPlan, departureName: String, destinationName: String) {
            self.init()
            self.id = plan.id
            self.name = plan.name
            self.departureICAO = plan.departure
            self.departureName = departureName
            self.destinationICAO = plan.destination
            self.destinationName = destinationName
            self.cruiseAltitude = plan.cruiseAltitude
            self.cruiseSpeedKts = plan.cruiseSpeed
            self.fuelBurnGPH = plan.fuelBurnRate
            self.totalDistanceNM = plan.totalDistance
            self.estimatedTimeSeconds = plan.estimatedTime
            self.estimatedFuelGallons = plan.estimatedFuel
            self.notes = plan.notes

            // Extract coordinates from waypoints if available
            if let dep = plan.waypoints.first {
                self.departureLatitude = dep.latitude
                self.departureLongitude = dep.longitude
            }
            if let dest = plan.waypoints.last, plan.waypoints.count > 1 {
                self.destinationLatitude = dest.latitude
                self.destinationLongitude = dest.longitude
            }
        }
    }
}
