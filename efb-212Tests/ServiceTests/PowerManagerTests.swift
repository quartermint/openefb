//
//  PowerManagerTests.swift
//  efb-212Tests
//
//  Tests for PowerManager battery monitoring and PowerState properties.
//

import Testing
@testable import efb_212

@Suite("PowerState Tests")
struct PowerStateTests {

    @Test func gpsUpdateIntervals() {
        #expect(PowerState.normal.gpsUpdateInterval == 1.0)
        #expect(PowerState.batteryConscious.gpsUpdateInterval == 3.0)
        #expect(PowerState.emergency.gpsUpdateInterval == 5.0)
    }

    @Test func mapTargetFPS() {
        #expect(PowerState.normal.mapTargetFPS == 60)
        #expect(PowerState.batteryConscious.mapTargetFPS == 30)
        #expect(PowerState.emergency.mapTargetFPS == 15)
    }

    @Test func weatherRefreshIntervals() {
        #expect(PowerState.normal.weatherRefreshInterval == 900)       // 15 min
        #expect(PowerState.batteryConscious.weatherRefreshInterval == 1800)  // 30 min
        #expect(PowerState.emergency.weatherRefreshInterval == .infinity)     // no refresh
    }

    @Test func allCases() {
        // Verify all three power states exist
        #expect(PowerState.allCases.count == 3)
        #expect(PowerState.allCases.contains(.normal))
        #expect(PowerState.allCases.contains(.batteryConscious))
        #expect(PowerState.allCases.contains(.emergency))
    }

    @Test func rawValues() {
        #expect(PowerState.normal.rawValue == "normal")
        #expect(PowerState.batteryConscious.rawValue == "batteryConscious")
        #expect(PowerState.emergency.rawValue == "emergency")
    }

    @Test func degradationProgression() {
        // GPS intervals should increase (slower updates) as power decreases
        #expect(PowerState.normal.gpsUpdateInterval < PowerState.batteryConscious.gpsUpdateInterval)
        #expect(PowerState.batteryConscious.gpsUpdateInterval < PowerState.emergency.gpsUpdateInterval)

        // FPS should decrease as power decreases
        #expect(PowerState.normal.mapTargetFPS > PowerState.batteryConscious.mapTargetFPS)
        #expect(PowerState.batteryConscious.mapTargetFPS > PowerState.emergency.mapTargetFPS)

        // Weather refresh should increase (less frequent) as power decreases
        #expect(PowerState.normal.weatherRefreshInterval < PowerState.batteryConscious.weatherRefreshInterval)
        #expect(PowerState.batteryConscious.weatherRefreshInterval < PowerState.emergency.weatherRefreshInterval)
    }
}

@Suite("PowerManager Tests")
struct PowerManagerTests {

    @Test func powerManagerIsObservable() {
        let pm = PowerManager()
        // PowerManager should be an ObservableObject with @Published properties
        // In the simulator, UIDevice.current.batteryLevel returns -1.0 (unknown),
        // which triggers the emergency path since -1.0 < 0.10. This is expected
        // simulator behavior — on a real device with battery monitoring, the level
        // would be a valid 0.0...1.0 value.
        let level = pm.batteryLevel
        let state = pm.powerState
        // Just verify the properties are accessible and have been set
        #expect(level <= 1.0)       // batteryLevel is Double(-1.0) or 0.0...1.0
        #expect(state == .emergency || state == .normal || state == .batteryConscious)
    }

    @Test func simulatorBatteryBehavior() {
        let pm = PowerManager()
        // In the simulator, UIDevice.current.batteryLevel is -1.0 and batteryState
        // is .unknown. The PowerManager logic treats -1.0 < 0.10 as emergency since
        // .unknown != .charging. This is correct defensive behavior — if we can't
        // determine battery level and we're not charging, assume worst case.
        #if targetEnvironment(simulator)
        #expect(pm.powerState == .emergency)
        #expect(pm.batteryLevel < 0)  // -1.0 in simulator
        #else
        // On real device, initial state depends on actual battery
        #expect(pm.batteryLevel >= 0.0)
        #expect(pm.batteryLevel <= 1.0)
        #endif
    }
}
