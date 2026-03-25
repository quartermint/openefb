# Phase Learnings

Project-specific patterns, gotchas, and solutions.
Searched by `/gsd:discuss-phase` and `/gsd:plan-phase`.

*Last updated: 2026-03-25*

---

### MapLibre MGL_IF syntax invalid in MapLibre Native iOS
<!-- problem_type: bug -->
<!-- component: Map/Styling -->
<!-- root_cause: MGL_IF is a macOS-only Objective-C macro, not available in MapLibre Native iOS Swift API -->
<!-- resolution_type: fix -->
<!-- severity: high -->
<!-- date: 2026-03-25 -->

**Problem:** Map style expressions using `MGL_IF` syntax failed to compile in the iOS target.
**Root Cause:** `MGL_IF` is an Objective-C preprocessor macro from the legacy Mapbox macOS SDK. MapLibre Native iOS uses a different expression API (`NSExpression` with `mgl_if:` or the newer `MLNExpression` DSL). Documentation and Stack Overflow answers mix macOS and iOS APIs freely.
**Solution:** Use MapLibre Native iOS's `NSExpression`-based conditional expressions or the Swift DSL directly. Avoid any `MGL_*` macros -- they're macOS/ObjC only.
**Key Insight:** MapLibre's iOS and macOS APIs diverged significantly. When searching for expression syntax, always verify the example is from the iOS/Swift SDK, not the macOS/ObjC one. The naming overlap is deceptive.

### Fresh start over refactor saved weeks
<!-- problem_type: architecture -->
<!-- component: Project-wide -->
<!-- root_cause: Existing codebase had 60%+ code needing rewriting, making incremental refactor slower than greenfield -->
<!-- resolution_type: design_change -->
<!-- severity: high -->
<!-- date: 2026-03-25 -->

**Problem:** Attempted incremental refactoring of the map layer and data pipeline was taking longer than expected, with each fix revealing more entangled dependencies.
**Root Cause:** Over 60% of the codebase needed rewriting. The remaining 40% was structured around assumptions that no longer held, making it actively fight the refactor.
**Solution:** Started fresh with clean architecture, porting only the validated business logic and tested utilities. The new structure was buildable within days.
**Key Insight:** When more than ~50% of a codebase needs rewriting, incremental refactor is slower than a clean start. The old code's structure actively fights you. Port the proven logic, drop the scaffolding.

### SourceKit false positives in SPM inter-package deps
<!-- problem_type: bug -->
<!-- component: Build/SPM -->
<!-- root_cause: SourceKit reports errors on valid cross-package references that compile fine with swiftc -->
<!-- resolution_type: workaround -->
<!-- severity: medium -->
<!-- date: 2026-03-25 -->

**Problem:** Xcode showed red errors on imports and type references between SPM packages, but the project built and ran successfully.
**Root Cause:** SourceKit's index doesn't always resolve inter-package dependencies correctly, especially with complex dependency graphs or when packages re-export types. The actual compiler (`swiftc`) handles these fine.
**Solution:** Trust `swift build` over Xcode's error display. If it builds, the errors are SourceKit false positives. Restarting Xcode or cleaning the build folder sometimes resolves them, but they often return.
**Key Insight:** SourceKit and swiftc are different tools with different resolution strategies. For SPM monorepos with many inter-package dependencies, SourceKit will show phantom errors. Don't chase them -- verify with `swift build` and move on.
