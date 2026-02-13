//
//  DeviceCapabilities.swift
//  efb-212
//
//  Detects hardware features at launch (GPS, cellular, memory, screen).
//  Used to adapt behavior for WiFi-only vs. cellular iPads.
//

import UIKit
import CoreLocation

struct DeviceCapabilities {
    let hasGPS: Bool
    let hasCellular: Bool
    let screenSize: CGSize
    let deviceModel: String
    let totalMemoryGB: Double

    static func detect() -> DeviceCapabilities {
        let hasGPS = CLLocationManager.headingAvailable()
        let hasCellular = hasGPS  // Cellular iPads have GPS; WiFi-only don't
        let processInfo = ProcessInfo.processInfo

        // Determine screen size from the first connected scene's window,
        // falling back to a sensible iPad default if no scene is available yet.
        let screenSize: CGSize
        if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first {
            screenSize = windowScene.screen.bounds.size
        } else {
            screenSize = CGSize(width: 1024, height: 1366)  // iPad Pro 12.9" default
        }

        return DeviceCapabilities(
            hasGPS: hasGPS,
            hasCellular: hasCellular,
            screenSize: screenSize,
            deviceModel: UIDevice.current.model,
            totalMemoryGB: Double(processInfo.physicalMemory) / 1_073_741_824
        )
    }
}
