# Screenshots

- `01-launch.png` — first-run onboarding page ("Navigate with GPS"), captured
  on iPad Pro 11-inch (M4), iOS 26.0.1, 2026-07-04.

## Status: starting set only
The app opens into a multi-page onboarding carousel that requires taps to
advance to the moving map. GUI tap automation was not reliable against this
headless simulator during the swarm, so only the onboarding hero was captured.

For the App Store listing, do a short manual pass:
1. Launch on an **iPad Pro 13-inch (M4)** simulator (store requires 2048x2732).
2. Walk through onboarding, grant location, land on the moving map.
3. Capture: moving map with ownship, airport info sheet, weather layer, flight
   planning, and a flight replay/debrief screen.
4. `xcrun simctl io <device> screenshot <name>.png`.

TestFlight **internal** testing does not require store screenshots, so this is
not a blocker for the first internal build.
