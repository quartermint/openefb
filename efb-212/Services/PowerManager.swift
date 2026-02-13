//
//  PowerManager.swift
//  efb-212
//
//  Monitors battery state and adaptively degrades services to preserve power.
//  PowerState enum is defined in Core/Types.swift.
//

import UIKit
import Combine

final class PowerManager: ObservableObject {
    @Published var batteryLevel: Double = 1.0
    @Published var batteryState: UIDevice.BatteryState = .unknown
    @Published var powerState: PowerState = .normal

    private var cancellables = Set<AnyCancellable>()

    init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        startMonitoring()
    }

    private func startMonitoring() {
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateBatteryState()
            }
            .store(in: &cancellables)

        updateBatteryState()
    }

    private func updateBatteryState() {
        batteryLevel = Double(UIDevice.current.batteryLevel)
        batteryState = UIDevice.current.batteryState

        if batteryLevel < 0.10 && batteryState != .charging {
            powerState = .emergency
        } else if batteryLevel < 0.20 && batteryState != .charging {
            powerState = .batteryConscious
        } else {
            powerState = .normal
        }
    }
}
