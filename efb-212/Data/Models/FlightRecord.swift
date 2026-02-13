//
//  FlightRecord.swift
//  efb-212
//
//  SwiftData model for recorded flight entries in the digital logbook.
//  Each record captures departure, arrival, duration, and optional route/distance.
//  CloudKit-ready for future premium sync.
//

import SwiftData
import Foundation

@Model
final class FlightRecordModel {
    var flightID: UUID
    var date: Date
    var departure: String                    // ICAO identifier
    var arrival: String                      // ICAO identifier
    var route: String?                       // Route string (e.g., "KPAO V334 KSQL")
    var duration: TimeInterval               // seconds
    var totalDistance: Double?                // nautical miles
    var remarks: String?

    init(
        flightID: UUID = UUID(),
        date: Date,
        departure: String,
        arrival: String,
        duration: TimeInterval
    ) {
        self.flightID = flightID
        self.date = date
        self.departure = departure
        self.arrival = arrival
        self.duration = duration
    }
}
