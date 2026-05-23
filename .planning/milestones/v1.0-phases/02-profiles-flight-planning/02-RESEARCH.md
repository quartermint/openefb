# Phase 2: Profiles + Flight Planning - Research

**Researched:** 2026-03-21
**Domain:** SwiftData profile models, flight plan calculations, FAR currency rules, MapLibre route rendering
**Confidence:** HIGH

## Summary

Phase 2 builds on Phase 1's foundation (`AppState`, `AviationDatabase`, `MapService`, `ContentView` tab shell) to deliver three capabilities: aircraft/pilot profile management via SwiftData, A-to-B flight planning with fuel/time calculations, and pilot currency tracking per FAR 61.23/61.56/61.57.

The existing codebase provides strong foundations. The `_archive/` directory contains reference implementations of `AircraftProfileModel`, `PilotProfileModel`, `FlightPlanViewModel`, and associated views that were built against the old `ObservableObject` pattern. These serve as design references but must be rewritten for the `@Observable` macro pattern established in Phase 1. The `FlightPlan` and `Waypoint` structs in `AviationModels.swift` are already defined and usable. The `MapService` already has a `.route` layer case in `MapLayer` enum but returns empty layer identifiers -- this is the hook for route line rendering.

**Primary recommendation:** Extend `SchemaV1` with `AircraftProfile` and `PilotProfile` `@Model` classes, register all three models in a single `ModelContainer`, build ViewModels using `@Observable` (not `ObservableObject`), and add a `routeSource`/`routeLayer` to `MapService` for magenta great-circle line rendering.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Support multiple aircraft and pilot profiles with one "active" selection -- pilots fly different aircraft, some share iPads
- Form-based editing with labeled fields, inline validation (N-number format, medical class picker, date pickers for expiry dates)
- V-speed fields (Vr, Vx, Vy, Vs0, Vs1, Vne, Vno, Vfe) are optional in aircraft profile -- nice reference but not required to create a profile
- Profiles persisted in SwiftData with CloudKit-ready schema (sync disabled for v1, foundation for multi-device later)
- Route entry via airport search for departure and destination; direct line drawn on map -- simple A-to-B per v1 scope, no intermediate waypoints
- Summary card shows distance (nm), ETE (h:mm), fuel burn (gal) calculated from active aircraft profile -- all visible in one glance
- Multiple flight plans can be saved; most recent auto-loads on next launch for convenience
- Route displayed as magenta great-circle line (aviation standard) with departure/destination pins on the map
- Currency status displayed as traffic-light badges (green/yellow/red) on pilot profile screen -- green when >30 days from expiry, yellow when <=30 days, red when expired
- Track three currency types: medical certificate expiry, flight review (24 calendar months), and 61.57 night passenger-carrying (3 takeoffs + landings in 90 days)
- Currency warning badge shown on Aircraft tab icon plus inline on profile screen -- visible but not intrusive during normal use
- 61.57 night currency uses manual entry in logbook (night landing count) until Phase 4 auto-populates from flight recording data

### Claude's Discretion
- Exact form layout and field ordering for profile editing
- Aircraft type picker implementation (free text vs predefined list)
- Flight plan card positioning relative to map
- Animation for route drawing on map
- SwiftData model versioning strategy details

### Deferred Ideas (OUT OF SCOPE)
- Multi-leg routing with per-leg calculations (v2)
- Weight & balance calculator (v2)
- ForeFlight CSV import/export (v2)
- CloudKit sync activation (v2)
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PLAN-01 | Pilot can create a flight plan with departure, destination, and route displayed on map | FlightPlan/Waypoint structs exist in AviationModels.swift; MapService needs route line layer; FlightPlanViewModel archive has calculation logic; airport search via DatabaseServiceProtocol.searchAirports() |
| PLAN-02 | Flight plan shows distance (nm), estimated time, and estimated fuel burn | Distance via CLLocation.distanceInNM(); ETE = distance/cruiseSpeed; fuel = ETE * burnRate; archive FlightPlanViewModel has all formulas |
| PLAN-03 | Pilot can store aircraft profile: N-number, type, fuel capacity, burn rate, cruise speed, V-speeds | SwiftData @Model with SchemaV1 extension; VSpeeds struct exists in Types.swift; AircraftDefaults.swift in archive has 30+ GA presets |
| PLAN-04 | Pilot can store pilot profile: name, certificate number, medical class/expiry, flight review date | SwiftData @Model with SchemaV1 extension; MedicalClass/CertificateType enums exist in Types.swift; currency computation per FAR 61.23/61.56/61.57 |
</phase_requirements>

## Standard Stack

### Core (already in project)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftData | iOS 17+ (framework) | User data persistence (profiles, flight plans) | Apple native, CloudKit-ready, already in use for UserSettings |
| GRDB.swift | 7.x (SPM) | Aviation database queries for airport search in flight plan | Already integrated, R-tree spatial + FTS5 search |
| MapLibre Native iOS | 6.x (SPM) | Route line rendering on map | Already integrated, GeoJSON source/layer pattern established |

### Supporting (no new dependencies)
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| CoreLocation | Framework | Distance calculations (Haversine) | Flight plan distance/bearing computation |
| SwiftUI | Framework | All profile and planning views | MVVM + @Observable pattern from Phase 1 |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| SwiftData for flight plans | GRDB (same as aviation DB) | SwiftData chosen per architecture decision; CloudKit-ready; flight plans are user data not aviation reference data |
| Manual distance calc | Turf.swift library | Unnecessary dependency; CLLocation.distance(from:) is accurate for A-to-B; great-circle is already correct |
| FAA N-number lookup | FAALookupService (archive) | Deferred -- archive code scrapes FAA HTML which is fragile; free-text aircraft type is simpler for v1 |

**Installation:** No new dependencies needed.

## Architecture Patterns

### Recommended Project Structure
```
efb-212/
├── Data/Models/
│   ├── UserSettings.swift          # Existing -- SchemaV1.UserSettings
│   ├── AircraftProfile.swift       # NEW -- SchemaV1.AircraftProfile @Model
│   ├── PilotProfile.swift          # NEW -- SchemaV1.PilotProfile @Model
│   └── FlightPlanRecord.swift      # NEW -- SchemaV1.FlightPlanRecord @Model (persisted flight plans)
├── ViewModels/
│   ├── AircraftProfileViewModel.swift   # NEW -- CRUD + active selection
│   ├── PilotProfileViewModel.swift      # NEW -- CRUD + currency computation
│   └── FlightPlanViewModel.swift        # NEW -- plan creation, distance/ETE/fuel calc
├── Views/
│   ├── Aircraft/
│   │   ├── AircraftListView.swift       # NEW -- list with add/edit/delete
│   │   ├── AircraftEditView.swift       # NEW -- form for profile fields
│   │   ├── PilotProfileView.swift       # NEW -- display + currency badges
│   │   └── PilotEditView.swift          # NEW -- form for pilot fields
│   ├── Planning/
│   │   ├── FlightPlanView.swift         # NEW -- departure/destination entry + summary card
│   │   └── FlightPlanSummaryCard.swift  # NEW -- floating card on map with DTG/ETE/fuel
│   └── Components/
│       └── CurrencyBadge.swift          # NEW -- green/yellow/red traffic light badge
├── Services/
│   └── CurrencyService.swift            # NEW -- FAR currency computation logic
└── Core/
    └── Types.swift                      # MODIFY -- add CurrencyStatus enum
```

### Pattern 1: SwiftData SchemaV1 Extension (Multiple Models in Same Version)
**What:** Add new `@Model` classes to the existing `SchemaV1` enum without creating V2
**When to use:** Adding new independent models that don't modify existing schema
**Example:**
```swift
// Data/Models/UserSettings.swift -- MODIFY to include new models in SchemaV1
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [UserSettings.self, AircraftProfile.self, PilotProfile.self, FlightPlanRecord.self]
    }

    @Model final class UserSettings { /* existing */ }
    @Model final class AircraftProfile { /* new */ }
    @Model final class PilotProfile { /* new */ }
    @Model final class FlightPlanRecord { /* new */ }
}
```
**Critical:** The `modelContainer(for:)` call in `efb_212App.swift` must register ALL models:
```swift
.modelContainer(for: [
    SchemaV1.UserSettings.self,
    SchemaV1.AircraftProfile.self,
    SchemaV1.PilotProfile.self,
    SchemaV1.FlightPlanRecord.self
])
```

### Pattern 2: @Observable ViewModel (Phase 1 Established Pattern)
**What:** ViewModels use `@Observable` macro (not `ObservableObject`) with `@MainActor`
**When to use:** All new ViewModels in Phase 2
**Example:**
```swift
@Observable
@MainActor
final class AircraftProfileViewModel {
    var profiles: [SchemaV1.AircraftProfile] = []
    var activeProfile: SchemaV1.AircraftProfile?
    var isEditing: Bool = false
    // ...
}
```
**Note:** The archive reference code uses `ObservableObject` + `@Published` -- this MUST be converted to `@Observable` macro pattern.

### Pattern 3: SwiftData @Query in Views (Direct Fetch)
**What:** Use `@Query` macro directly in SwiftUI views for live-updating data
**When to use:** List views that display all profiles
**Example:**
```swift
struct AircraftListView: View {
    @Query(sort: \SchemaV1.AircraftProfile.createdAt, order: .reverse)
    private var profiles: [SchemaV1.AircraftProfile]
    @Environment(\.modelContext) private var modelContext
    // ...
}
```
**Important:** `@Query` provides automatic observation of SwiftData changes. No manual refresh needed.

### Pattern 4: MapLibre Route Line Layer
**What:** Add a GeoJSON line source + line style layer for the magenta route
**When to use:** When a flight plan is created/updated
**Example:**
```swift
// In MapService -- add route source and layer
func addRouteLayer(to style: MLNStyle) {
    let source = MLNShapeSource(
        identifier: "route-line",
        shape: MLNPolylineFeature(coordinates: [], count: 0),
        options: nil
    )
    style.addSource(source)
    routeSource = source

    let lineLayer = MLNLineStyleLayer(identifier: "route-line-layer", source: source)
    lineLayer.lineColor = NSExpression(forConstantValue: UIColor.systemPink) // magenta
    lineLayer.lineWidth = NSExpression(forConstantValue: 3.0)
    lineLayer.lineCap = NSExpression(forConstantValue: "round")
    lineLayer.lineJoin = NSExpression(forConstantValue: "round")
    style.addLayer(lineLayer)
}

func updateRoute(departure: CLLocationCoordinate2D, destination: CLLocationCoordinate2D) {
    // Generate intermediate points along great-circle arc
    let coords = greatCirclePoints(from: departure, to: destination, count: 100)
    var mutableCoords = coords
    let polyline = MLNPolylineFeature(coordinates: &mutableCoords, count: UInt(coords.count))
    routeSource?.shape = polyline
}
```

### Pattern 5: Active Profile Selection via AppState
**What:** Store the active aircraft/pilot profile ID in AppState for cross-view access
**When to use:** Flight plan calculations need active aircraft performance data
**Example:**
```swift
// In AppState -- add profile selection state
var activeAircraftProfileID: PersistentIdentifier?
var activePilotProfileID: PersistentIdentifier?
```

### Anti-Patterns to Avoid
- **Creating SchemaV2 for new models:** Adding independent new models to an existing schema version does NOT require a new VersionedSchema. Only modify existing models or rename/delete fields requires V2 + migration.
- **Using ObservableObject in new code:** Phase 1 established `@Observable` macro. Archive reference code uses old pattern -- do NOT copy `@Published` / `ObservableObject` from archive.
- **Storing FlightPlan struct in SwiftData directly:** The `FlightPlan` struct in `AviationModels.swift` is a value type for runtime use. SwiftData needs a `@Model class FlightPlanRecord` that serializes/deserializes to/from the struct.
- **Fetching profiles in ViewModels manually:** Use `@Query` in views for live updates. Only use `modelContext.fetch()` in ViewModels when you need filtered/computed data.
- **Computing currency in views:** Currency logic (FAR 61.23/61.56/61.57) belongs in a dedicated `CurrencyService` or on the ViewModel -- not inline in SwiftUI views.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Great-circle distance | Custom Haversine formula | `CLLocation.distance(from:)` / existing `CLLocation.distanceInNM(to:)` | Already in CLLocation+Aviation.swift extension; Apple's implementation is geodetically accurate |
| Great-circle intermediate points | Simple lerp between lat/lon | Proper spherical interpolation | Linear interpolation on lat/lon coordinates produces incorrect paths at high latitudes |
| N-number validation | Complex regex | Simple `^N[0-9]{1,5}[A-Z]{0,2}$` regex | FAA format is well-defined: N + 1-5 digits + 0-2 suffix letters |
| Date expiration math | Manual day counting | `Calendar.current.dateComponents([.day], from:to:)` | Already used in Phase 1 for chart expiration; handles DST/leap year |
| Medical duration computation | Hardcoded months | Lookup table by class + age bracket per FAR 61.23 | Rules differ by class (1st/2nd/3rd/BasicMed) AND pilot age (under/over 40); table-driven is correct |

**Key insight:** Aviation date/currency computation has many edge cases (calendar months vs days, age-based medical durations, "end of month" rules for medicals). Use `Calendar` APIs consistently and keep the FAR rule lookup in a single testable service.

## Common Pitfalls

### Pitfall 1: ModelContainer Registration Mismatch
**What goes wrong:** App crashes on launch with "No ModelContainer found" or "Unknown model type"
**Why it happens:** `efb_212App.swift` currently registers only `SchemaV1.UserSettings.self`. Adding new `@Model` classes without updating the container registration causes runtime failures.
**How to avoid:** Update `efb_212App.swift` to register ALL model types in a single `modelContainer(for:)` call. Test launch immediately after adding models.
**Warning signs:** EXC_BREAKPOINT in SwiftData internals, "ModelContainer" in crash log.

### Pitfall 2: SchemaV1 Type Namespacing
**What goes wrong:** Compiler errors about ambiguous type names or "type not found"
**Why it happens:** `@Model` classes nested inside `SchemaV1` enum must be referenced as `SchemaV1.AircraftProfile` unless aliased. Views using `@Query` need the fully qualified type.
**How to avoid:** Either use `typealias AircraftProfile = SchemaV1.AircraftProfile` at file scope, or nest all `@Model` definitions INSIDE the `SchemaV1` enum. The archive code defines models at top level -- this will NOT work with VersionedSchema.
**Warning signs:** "Cannot find type 'AircraftProfile' in scope"

### Pitfall 3: Mixing @Observable and ObservableObject
**What goes wrong:** Views don't update when ViewModel state changes, or double-update glitches
**Why it happens:** Archive reference code uses `@Published` + `ObservableObject`. Phase 1 uses `@Observable` macro. Mixing patterns causes observation to break.
**How to avoid:** All new ViewModels MUST use `@Observable` + `@MainActor`. Use `@Bindable` in views for two-way bindings. Never use `@ObservedObject` or `@StateObject` with `@Observable` classes.
**Warning signs:** Values shown in views don't update after mutation.

### Pitfall 4: FlightPlan Struct vs FlightPlanRecord Model
**What goes wrong:** Attempting to persist `FlightPlan` (struct from AviationModels.swift) directly in SwiftData
**Why it happens:** `FlightPlan` is a `Codable` struct -- SwiftData requires `@Model class`. The struct is used at runtime by MapService and AppState; the model is for persistence.
**How to avoid:** Create `SchemaV1.FlightPlanRecord` as a `@Model class` with conversion methods `toFlightPlan()` and `init(from plan: FlightPlan)`. Keep `FlightPlan` struct for runtime use.
**Warning signs:** Compiler error about `@Model` on struct.

### Pitfall 5: MapService Route Layer Not Added in onStyleLoaded
**What goes wrong:** Route line never appears on map even though source data is correct
**Why it happens:** MapLibre style layers must be added in `onStyleLoaded(style:)`. If route layer is added later, it may not render until next style reload.
**How to avoid:** Add route source + layer in `MapService.onStyleLoaded()` alongside other layers. Initially empty, updated when flight plan is created. MapService already has this pattern for airports, weather, TFRs.
**Warning signs:** Route data is set but nothing visible on map; other layers work fine.

### Pitfall 6: Currency "Calendar Month" vs "Days" Confusion
**What goes wrong:** Medical expiration computed incorrectly, off by days or a month
**Why it happens:** FAR 61.23 uses "calendar months" (end of the last day of the month), not a fixed number of days. A medical issued Jan 15 expires at the end of the Nth calendar month from issuance -- meaning the last day of that month.
**How to avoid:** Use `Calendar.current.date(byAdding: .month, value: N, to: date)` and then compute end-of-month. The archive already uses this for flight review (24 months).
**Warning signs:** Currency shows expired when it should be valid (or vice versa) at month boundaries.

### Pitfall 7: Active Profile Lost on App Relaunch
**What goes wrong:** User selects an aircraft profile, relaunches app, selection is gone
**Why it happens:** Storing active profile reference only in AppState (which is in-memory). `PersistentIdentifier` is not `Codable` by default.
**How to avoid:** Store the active profile's unique identifier (e.g., N-number string or UUID string) in `UserSettings` SwiftData model. Resolve on app launch.
**Warning signs:** Active profile resets to nil after every app restart.

## Code Examples

### Great-Circle Intermediate Points (for smooth route line)
```swift
// Generate N intermediate points along a great-circle arc
// Source: Standard spherical interpolation formula
func greatCirclePoints(
    from start: CLLocationCoordinate2D,
    to end: CLLocationCoordinate2D,
    count: Int = 100
) -> [CLLocationCoordinate2D] {
    let lat1 = start.latitude.degreesToRadians  // uses existing extension
    let lon1 = start.longitude.degreesToRadians
    let lat2 = end.latitude.degreesToRadians
    let lon2 = end.longitude.degreesToRadians

    let d = 2 * asin(sqrt(
        pow(sin((lat1 - lat2) / 2), 2) +
        cos(lat1) * cos(lat2) * pow(sin((lon1 - lon2) / 2), 2)
    ))

    guard d > 0 else { return [start] }

    return (0...count).map { i in
        let f = Double(i) / Double(count)
        let a = sin((1 - f) * d) / sin(d)
        let b = sin(f * d) / sin(d)
        let x = a * cos(lat1) * cos(lon1) + b * cos(lat2) * cos(lon2)
        let y = a * cos(lat1) * sin(lon1) + b * cos(lat2) * sin(lon2)
        let z = a * sin(lat1) + b * sin(lat2)
        let lat = atan2(z, sqrt(x * x + y * y))
        let lon = atan2(y, x)
        return CLLocationCoordinate2D(
            latitude: lat.radiansToDegrees,  // uses existing extension
            longitude: lon.radiansToDegrees
        )
    }
}
```

### Currency Computation (FAR 61.23 Medical Duration)
```swift
// Source: 14 CFR 61.23 -- Medical certificates: Requirement and duration
enum CurrencyStatus: String, Sendable {
    case current    // green: > 30 days remaining
    case warning    // yellow: <= 30 days remaining
    case expired    // red: past expiration
}

struct CurrencyService {
    /// Compute medical currency status from expiry date.
    /// Per context decision: green > 30 days, yellow <= 30 days, red = expired.
    static func medicalStatus(expiryDate: Date?) -> CurrencyStatus {
        guard let expiry = expiryDate else { return .expired }
        let now = Date()
        if expiry < now { return .expired }
        let daysRemaining = Calendar.current.dateComponents([.day], from: now, to: expiry).day ?? 0
        return daysRemaining > 30 ? .current : .warning
    }

    /// Flight review valid for 24 calendar months from date of review (FAR 61.56).
    static func flightReviewStatus(reviewDate: Date?) -> CurrencyStatus {
        guard let review = reviewDate else { return .expired }
        guard let expiry = Calendar.current.date(byAdding: .month, value: 24, to: review) else {
            return .expired
        }
        return medicalStatus(expiryDate: expiry)
    }

    /// Night passenger-carrying currency: 3 T/O + landings to full stop
    /// within preceding 90 days (FAR 61.57(b)).
    /// nightLandings: array of (date, count) from manual logbook entries.
    static func nightCurrencyStatus(
        nightLandings: [(date: Date, count: Int)]
    ) -> CurrencyStatus {
        let now = Date()
        guard let ninetyDaysAgo = Calendar.current.date(byAdding: .day, value: -90, to: now) else {
            return .expired
        }

        let recentLandings = nightLandings
            .filter { $0.date >= ninetyDaysAgo }
            .reduce(0) { $0 + $1.count }

        if recentLandings >= 3 { return .current }
        return .expired  // No "warning" for 61.57 -- you either have 3 or you don't
    }
}
```

### AircraftProfile SwiftData Model
```swift
// Inside SchemaV1 enum
@Model
final class AircraftProfile {
    var id: UUID = UUID()
    var nNumber: String = ""              // FAA registration, e.g. "N4543A"
    var aircraftType: String = ""         // Free text, e.g. "Cessna 172SP"
    var fuelCapacityGallons: Double?      // Usable fuel -- gallons
    var fuelBurnGPH: Double?             // Cruise fuel burn -- gallons per hour
    var cruiseSpeedKts: Double?          // Cruise TAS -- knots
    var vSpeeds: Data?                   // JSON-encoded VSpeeds struct (optional)
    var isActive: Bool = false           // Currently selected aircraft
    var createdAt: Date = Date()

    // Inspection dates (from archive reference)
    var annualDue: Date?
    var transponderDue: Date?

    init(nNumber: String) {
        self.nNumber = nNumber
    }
}
```

### PilotProfile SwiftData Model
```swift
// Inside SchemaV1 enum
@Model
final class PilotProfile {
    var id: UUID = UUID()
    var name: String?
    var certificateNumber: String?
    var certificateType: String?         // CertificateType.rawValue
    var medicalClass: String?            // MedicalClass.rawValue
    var medicalExpiry: Date?
    var flightReviewDate: Date?
    var totalHours: Double?
    var isActive: Bool = false           // Currently selected pilot
    var createdAt: Date = Date()

    // Night currency manual entries (until Phase 4 auto-populates)
    var nightLandingEntries: Data?       // JSON-encoded [(date: Date, count: Int)]

    init() {}
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `ObservableObject` + `@Published` | `@Observable` macro + `@MainActor` | iOS 17 / WWDC 2023 | All Phase 2 ViewModels must use new pattern; archive code is reference only |
| Standalone `@Model` classes | `@Model` inside `VersionedSchema` enum | SwiftData best practice | Models must be nested in `SchemaV1` for migration support |
| `@StateObject` / `@ObservedObject` | `@State` / `@Bindable` / `@Environment` | iOS 17 | New observation system; `@Bindable` for two-way bindings with `@Observable` |

**Deprecated/outdated:**
- `FAALookupService` from archive: Scrapes FAA HTML -- fragile, deferred to v2
- `DatabaseManagerProtocol` in mock tests: Archive async protocol; current code uses synchronous `DatabaseServiceProtocol`

## Open Questions

1. **VSpeeds Storage Format**
   - What we know: `VSpeeds` struct exists in `Types.swift` as `Codable`. SwiftData can't store custom structs directly.
   - What's unclear: Whether to store as JSON `Data` blob or flatten into individual optional Int columns.
   - Recommendation: JSON `Data` blob via `vSpeeds: Data?` with encode/decode helpers. V-speeds are optional and treated as a unit -- no need to query individual fields. Simpler schema.

2. **Flight Plan Persistence Scope**
   - What we know: User decision says "multiple flight plans can be saved; most recent auto-loads on next launch."
   - What's unclear: Maximum number of saved plans; whether to auto-delete old plans.
   - Recommendation: Save unlimited plans, display as chronological list. No auto-delete for v1. Store `lastUsedAt: Date` on each `FlightPlanRecord` to identify most recent.

3. **Night Landing Manual Entry UI**
   - What we know: 61.57 night currency needs count of night landings in past 90 days. Phase 4 will auto-populate from recordings. For now, manual entry.
   - What's unclear: Where exactly in the UI to place the "add night landings" entry.
   - Recommendation: Add a simple "Log Night Landings" section on the pilot profile screen with date picker + count stepper. Minimal UI, just enough to compute currency.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (already in use) |
| Config file | efb-212Tests/ directory, Xcode test target |
| Quick run command | `xcodebuild test -scheme efb-212 -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' -only-testing:efb-212Tests` |
| Full suite command | `xcodebuild test -scheme efb-212 -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)'` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PLAN-01 | Flight plan created with departure + destination; route data generated | unit | `xcodebuild test ... -only-testing:efb-212Tests/FlightPlanViewModelTests` | Partial (archive tests exist, need @Observable rewrite) |
| PLAN-02 | Distance, ETE, fuel burn calculated correctly from aircraft profile | unit | `xcodebuild test ... -only-testing:efb-212Tests/FlightPlanViewModelTests` | Partial (archive tests cover distance/ETE, not fuel with profile) |
| PLAN-03 | Aircraft profile CRUD: create, read, update, delete; persists across launches | unit + integration | `xcodebuild test ... -only-testing:efb-212Tests/AircraftProfileTests` | No -- Wave 0 |
| PLAN-04 | Pilot profile CRUD + currency badges: green/yellow/red computed correctly | unit | `xcodebuild test ... -only-testing:efb-212Tests/CurrencyServiceTests` | No -- Wave 0 |

### Sampling Rate
- **Per task commit:** Quick test of affected test suite
- **Per wave merge:** Full suite
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `efb-212Tests/ServiceTests/CurrencyServiceTests.swift` -- covers PLAN-04 currency computation (medical, flight review, night 61.57)
- [ ] `efb-212Tests/DataTests/ProfileModelTests.swift` -- covers PLAN-03, PLAN-04 SwiftData model creation, persistence, and field validation
- [ ] `efb-212Tests/ViewModelTests/FlightPlanViewModelTests.swift` -- EXISTS but uses archive `DatabaseManagerProtocol`; needs rewrite for `DatabaseServiceProtocol` + `@Observable`
- [ ] Update `efb-212Tests/Mocks/MockDatabaseManager.swift` -- currently conforms to archived `DatabaseManagerProtocol`, needs alignment with current `DatabaseServiceProtocol`

## Sources

### Primary (HIGH confidence)
- Project codebase analysis: `efb-212/Core/Types.swift` (VSpeeds, MedicalClass, CertificateType enums), `efb-212/Core/AviationModels.swift` (FlightPlan/Waypoint structs), `efb-212/Data/Models/UserSettings.swift` (SchemaV1 pattern)
- Project archive reference: `_archive/AircraftProfile.swift`, `_archive/PilotProfile.swift`, `_archive/FlightPlanViewModel.swift`, `_archive/AircraftProfileView.swift`, `_archive/PilotProfileView.swift`, `_archive/AircraftDefaults.swift`
- Phase 1 established patterns: `efb-212/Core/AppState.swift` (@Observable), `efb-212/Services/MapService.swift` (GeoJSON layer pattern), `efb-212/ViewModels/MapViewModel.swift` (@Observable ViewModel)
- [14 CFR 61.23 -- Medical certificates](https://www.ecfr.gov/current/title-14/chapter-I/subchapter-D/part-61/subpart-A/section-61.23) -- medical duration rules
- [14 CFR 61.57 -- Recent flight experience](https://www.ecfr.gov/current/title-14/chapter-I/subchapter-D/part-61/subpart-A/section-61.57) -- night currency rules

### Secondary (MEDIUM confidence)
- [SwiftData VersionedSchema migration guide (Hacking with Swift)](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-create-a-complex-migration-using-versionedschema) -- multiple models in same schema version
- [ModelContainer with multiple models (Apple Forums)](https://developer.apple.com/forums/thread/744316) -- registering multiple model types
- [MapLibre SwiftUI DSL (GitHub)](https://github.com/maplibre/swiftui-dsl) -- polyline rendering patterns

### Tertiary (LOW confidence)
- [MapLibre Newsletter Dec 2025](https://maplibre.org/news/2026-01-03-maplibre-newsletter-december-2025/) -- recent iOS updates (unverified against current SPM version)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all technologies already in the project; no new dependencies needed
- Architecture: HIGH -- Phase 1 patterns well-established; archive code provides design reference
- Pitfalls: HIGH -- pitfalls derived from direct codebase analysis (protocol mismatch, schema registration, observation pattern differences)
- Currency computation: HIGH -- FAR rules are codified federal regulations with clear arithmetic

**Research date:** 2026-03-21
**Valid until:** 2026-04-21 (stable -- no fast-moving dependencies)
