//
//  FlightPlanViewModel.swift
//  efb-212
//
//  Flight plan creation, distance/ETE/fuel calculation, route rendering,
//  and SwiftData persistence. Uses @Observable macro (iOS 26 best practice).
//
//  Integrates with MapService for magenta great-circle route line rendering,
//  and AppState for cross-tab summary card display properties.
//

import Foundation
import Observation
import CoreLocation
import SwiftData
import UIKit
import MapLibre

@Observable
@MainActor
final class FlightPlanViewModel {

    // MARK: - Search State

    var departureQuery: String = ""
    var destinationQuery: String = ""
    var departureResults: [Airport] = []
    var destinationResults: [Airport] = []

    // MARK: - Selected Airports

    var selectedDeparture: Airport?
    var selectedDestination: Airport?

    // MARK: - Computed Plan Data

    var distanceNM: Double = 0                  // nautical miles
    var estimatedTimeSeconds: TimeInterval = 0  // seconds
    var estimatedFuelGallons: Double?           // gallons (nil if no aircraft profile)

    // MARK: - UI State

    var isCreating: Bool = false
    var savedPlans: [SchemaV1.FlightPlanRecord] = []
    var activePlanID: UUID?
    var lastError: EFBError?

    // MARK: - Formatted ETE

    /// ETE formatted as "h:mm" for display.
    var formattedETE: String {
        let hours = Int(estimatedTimeSeconds) / 3600
        let minutes = (Int(estimatedTimeSeconds) % 3600) / 60
        return String(format: "%d:%02d", hours, minutes)
    }

    // MARK: - Dependencies

    private let databaseService: any DatabaseServiceProtocol
    private var mapService: MapService?
    private var modelContext: ModelContext?
    private var appState: AppState

    // MARK: - Init

    init(databaseService: any DatabaseServiceProtocol, appState: AppState) {
        self.databaseService = databaseService
        self.appState = appState
    }

    // MARK: - Configuration

    /// Set MapService and ModelContext after initialization.
    /// Called from FlightPlanView.onAppear once services are available.
    func configure(mapService: MapService?, modelContext: ModelContext) {
        self.mapService = mapService
        self.modelContext = modelContext
        loadSavedPlans()
        if !savedPlans.isEmpty {
            loadMostRecentPlan()
        }
    }

    // MARK: - Airport Search

    /// Search airports matching departure query (minimum 2 characters).
    func searchDeparture() {
        guard departureQuery.count >= 2 else {
            departureResults = []
            return
        }
        do {
            departureResults = try databaseService.searchAirports(query: departureQuery, limit: 10)
        } catch {
            departureResults = []
        }
    }

    /// Search airports matching destination query (minimum 2 characters).
    func searchDestination() {
        guard destinationQuery.count >= 2 else {
            destinationResults = []
            return
        }
        do {
            destinationResults = try databaseService.searchAirports(query: destinationQuery, limit: 10)
        } catch {
            destinationResults = []
        }
    }

    // MARK: - Airport Selection

    /// Select a departure airport from search results.
    func selectDeparture(_ airport: Airport) {
        selectedDeparture = airport
        departureQuery = airport.icao
        departureResults = []
        if selectedDeparture != nil && selectedDestination != nil {
            calculateAndDrawRoute()
        }
    }

    /// Select a destination airport from search results.
    func selectDestination(_ airport: Airport) {
        selectedDestination = airport
        destinationQuery = airport.icao
        destinationResults = []
        if selectedDeparture != nil && selectedDestination != nil {
            calculateAndDrawRoute()
        }
    }

    // MARK: - Route Calculation and Drawing

    /// Calculate distance, ETE, fuel and draw route on map.
    /// Uses active aircraft profile for cruise speed and fuel burn if available.
    func calculateAndDrawRoute() {
        guard let dep = selectedDeparture, let dest = selectedDestination else { return }

        // Distance using existing CLLocationCoordinate2D extension -- nautical miles
        let distance = dep.coordinate.distanceInNM(to: dest.coordinate)
        distanceNM = distance

        // Get active aircraft from modelContext for speed and fuel data
        var cruiseSpeed: Double = 100  // default 100 knots TAS
        var fuelBurnRate: Double?

        if let context = modelContext {
            let descriptor = FetchDescriptor<SchemaV1.AircraftProfile>(
                predicate: #Predicate { $0.isActive == true }
            )
            if let activeAircraft = try? context.fetch(descriptor).first {
                if let speed = activeAircraft.cruiseSpeedKts, speed > 0 {
                    cruiseSpeed = speed
                }
                fuelBurnRate = activeAircraft.fuelBurnGPH
            }
        }

        // ETE: distance / speed * 3600 (convert hours to seconds)
        let ete = (distance / cruiseSpeed) * 3600
        estimatedTimeSeconds = ete

        // Fuel: (distance / speed) * burnRate = hours * GPH = gallons
        if let burnRate = fuelBurnRate, burnRate > 0 {
            estimatedFuelGallons = (distance / cruiseSpeed) * burnRate
        } else {
            estimatedFuelGallons = nil
        }

        // Draw route on map
        mapService?.updateRoute(departure: dep.coordinate, destination: dest.coordinate)
        mapService?.addRoutePins(departure: dep.coordinate, destination: dest.coordinate)

        // Update AppState display properties (critical for MapContainerView summary card overlay)
        appState.activeFlightPlan = true
        appState.distanceToNext = distanceNM
        appState.estimatedTimeEnroute = estimatedTimeSeconds
        appState.activePlanDeparture = dep.icao
        appState.activePlanDestination = dest.icao
        appState.activePlanFuelGallons = estimatedFuelGallons

        // Zoom map to show full route
        if let mapView = mapService?.mapView {
            let bounds = MLNCoordinateBounds(
                sw: CLLocationCoordinate2D(
                    latitude: min(dep.latitude, dest.latitude) - 0.5,
                    longitude: min(dep.longitude, dest.longitude) - 0.5
                ),
                ne: CLLocationCoordinate2D(
                    latitude: max(dep.latitude, dest.latitude) + 0.5,
                    longitude: max(dep.longitude, dest.longitude) + 0.5
                )
            )
            mapView.setVisibleCoordinateBounds(bounds, edgePadding: UIEdgeInsets(top: 80, left: 80, bottom: 80, right: 80), animated: true)
        }
    }

    // MARK: - Persistence

    /// Save the current flight plan to SwiftData.
    func savePlan() {
        guard let dep = selectedDeparture, let dest = selectedDestination else { return }
        guard let context = modelContext else { return }

        let record = SchemaV1.FlightPlanRecord()
        record.departureICAO = dep.icao
        record.departureName = dep.name
        record.departureLatitude = dep.latitude
        record.departureLongitude = dep.longitude
        record.destinationICAO = dest.icao
        record.destinationName = dest.name
        record.destinationLatitude = dest.latitude
        record.destinationLongitude = dest.longitude
        record.cruiseSpeedKts = distanceNM > 0 ? (distanceNM / (estimatedTimeSeconds / 3600)) : 100
        record.totalDistanceNM = distanceNM
        record.estimatedTimeSeconds = estimatedTimeSeconds
        record.estimatedFuelGallons = estimatedFuelGallons
        record.lastUsedAt = Date()
        record.createdAt = Date()

        context.insert(record)
        try? context.save()

        activePlanID = record.id
        loadSavedPlans()
    }

    /// Fetch all saved flight plans sorted by lastUsedAt descending.
    func loadSavedPlans() {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<SchemaV1.FlightPlanRecord>(
            sortBy: [SortDescriptor(\.lastUsedAt, order: .reverse)]
        )
        savedPlans = (try? context.fetch(descriptor)) ?? []
    }

    /// Load a saved flight plan record, looking up airports from database.
    func loadPlan(_ record: SchemaV1.FlightPlanRecord) {
        // Look up airports from database for full Airport data
        selectedDeparture = try? databaseService.airport(byICAO: record.departureICAO)
        selectedDestination = try? databaseService.airport(byICAO: record.destinationICAO)

        departureQuery = record.departureICAO
        destinationQuery = record.destinationICAO

        // Update lastUsedAt
        record.lastUsedAt = Date()
        try? modelContext?.save()

        activePlanID = record.id

        // Recalculate and draw the route
        if selectedDeparture != nil && selectedDestination != nil {
            calculateAndDrawRoute()
        }
    }

    /// Load the most recent saved plan (called on app launch).
    func loadMostRecentPlan() {
        guard let first = savedPlans.first else { return }
        loadPlan(first)
    }

    /// Clear the active flight plan and reset all state.
    func clearPlan() {
        departureQuery = ""
        destinationQuery = ""
        selectedDeparture = nil
        selectedDestination = nil
        departureResults = []
        destinationResults = []
        distanceNM = 0
        estimatedTimeSeconds = 0
        estimatedFuelGallons = nil
        activePlanID = nil

        mapService?.clearRoute()

        // Nil out all AppState display properties
        appState.activeFlightPlan = false
        appState.distanceToNext = nil
        appState.estimatedTimeEnroute = nil
        appState.activePlanDeparture = nil
        appState.activePlanDestination = nil
        appState.activePlanFuelGallons = nil
    }

    /// Delete a saved flight plan.
    func deletePlan(_ record: SchemaV1.FlightPlanRecord) {
        guard let context = modelContext else { return }

        // If deleting the active plan, clear it
        if record.id == activePlanID {
            clearPlan()
        }

        context.delete(record)
        try? context.save()
        loadSavedPlans()
    }
}
