# OpenEFB — TestFlight Submission Prep

Generated 2026-07-04 (weekend swarm, lane F). Goal: make the first TestFlight
submission a ~20-minute button-press. Everything here is a draft for Ryan to
review, not an automated upload.

## State at prep time
- Sim build: **GREEN** (iPad Pro 11-inch M4, iOS 26.0.1) after fixing one
  type-check-timeout compile error in `AviationDatabase.swift` (commit `84ee16e`, local only).
- Full test suite: **207 tests, 0 failures** (sim).
- SPM resolution: clean, no hang (GRDB 7.9.0, MapLibre Native 6.23.0).

## Do-this-first checklist (the 20-minute path)
1. **Add export-compliance key** to avoid the per-upload question:
   set `ITSAppUsesNonExemptEncryption = NO` (app only uses standard HTTPS to
   aviationweather.gov — exempt). Add as an Info.plist / INFOPLIST_KEY build
   setting. See `ARCHIVE_CONFIG.md`.
2. **Decide device family** — currently `TARGETED_DEVICE_FAMILY = 1,2`
   (iPhone + iPad) and Mac-Designed-for-iPad is ON. PRD says iPad VFR EFB.
   If iPad-only is intended, set family to `2` before archiving. See `ARCHIVE_CONFIG.md`.
3. **Archive**: Xcode → Any iOS Device (arm64) → Product → Archive
   (Release config, Automatic signing, team SKGLKG576D).
4. **Distribute** → App Store Connect → Upload → TestFlight.
5. Paste metadata from `APP_STORE_METADATA.md`; set privacy answers from
   `PRIVACY_NUTRITION_LABELS.md`.
6. Add screenshots (see `screenshots/` — placeholders; capture on device or a
   larger iPad sim at the required App Store resolutions before public release;
   TestFlight internal testing does not require store screenshots).

## Files
- `ARCHIVE_CONFIG.md` — verified build settings + the two decisions above.
- `APP_STORE_METADATA.md` — name, subtitle, description, keywords, categories, support text.
- `PRIVACY_NUTRITION_LABELS.md` — nutrition-label answers derived from actual code usage.

## Caveats (verify before public release, not blocking for TestFlight internal)
- Screenshots here are a starting set from the simulator; App Store Connect
  requires specific iPad resolutions (13" 2048x2732). Regenerate for the store listing.
- Metadata copy is a first draft in Ryan's voice conventions (no bravado, no em-dash) — review.
