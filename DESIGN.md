# Design System — OpenEFB

> **Memorable feeling we are designing for:** *"This was built by someone who actually flies."*
>
> Every decision in this document serves that line. When in doubt, ask: would a pilot trust this?

---

## 1. Product Context

- **What this is:** An open-source iPad VFR Electronic Flight Bag — moving-map navigation, flight recording, AI debrief
- **Who it's for:** General aviation pilots flying VFR, in-cockpit, on a mounted or kneeboard iPad
- **Real-world use environment:**
  - Direct sunlight up to ~100,000 lux at altitude (often through canopy/windscreen)
  - Turbulence and vibration during taxi, takeoff, cruise, and approach
  - Gloves (winter, high-altitude, formation, instructor)
  - Night flight with preserved dark adaptation (635-660nm red-light discipline)
  - One hand on the yoke; iPad interaction is single-handed and brief
- **Competitors / context:** ForeFlight (enterprise blue navy, dense, utilitarian), Garmin Pilot (cluttered all-caps), SkyDemon (clean European hobbyist), FltPlan Go (free, ugly)
- **Positioning moat:** Open source. The product should signal *"pilot-built tool"*, not *"enterprise EFB skinned over a SaaS."*

---

## 2. Aesthetic Direction

- **Direction:** Modernist sectional cartography meets cockpit hardware
- **Decoration level:** Minimal — typography and chart symbology do the work
- **Mood:** Paper-and-ink restraint by day, instrument-panel calm by dusk, true-red discipline at night. The chart is the protagonist; chrome yields.
- **Material logic:** Matte gunmetal chassis, sectional paper canvas, hairline rules. No gradients pretending to be glass. No drop shadows. No decorative blobs. No bouncy motion.
- **Inspirations referenced (for reviewers):**
  - The face of an FAA sectional chart
  - Airbus B612 cockpit typography research
  - Dieter Rams' Braun product chrome
  - Vintage avionics readouts (steam-gauge tabular discipline)

**Anti-references:** No purple gradients. No 3-column SaaS feature grids. No centered everything. No system-ui as a primary face. No pill-radius primary CTAs. No all-caps Helvetica headings (that's Garmin's mistake).

---

## 3. Typography — B612 (the moat)

OpenEFB uses **B612** as its primary typeface — the open-source aviation font designed by Airbus and Intactile DESIGN for cockpit screens. SIL OFL licensed. Ships with the app.

> Why B612 is the right call for an *open-source* EFB:
> - Designed for the literal problem: arm's-length cockpit legibility, vibration tolerance, sunlight glare
> - Distinct glyphs: slashed zero, unambiguous 1/I/l, wide aperture
> - True tabular numerics (mono variant)
> - Free, redistributable, no licensing tax
> - No competitor EFB uses it — instant differentiation

### Type Stack

| Role | Font | Weight | Notes |
|---|---|---|---|
| Display / hero | **B612** | Bold | Page titles, alert banners |
| Body / UI / labels | **B612** | Regular, Medium | Default UI text |
| Numerics — alt / hdg / freq / GS / ETE / DTK / DIS | **B612 Mono** | Medium | `tnum` ON always; slashed zero |
| Critical alert readouts | **B612 Mono** | Bold | Pattern altitude, freq tune confirm, AGL warnings |
| Marketing site / PRD (out-of-app only) | **Source Serif 4** | Regular, Bold | Optional editorial face |

### Type Rules

- **Never thinner than Regular** weight in flight context. Vibration eats hairlines.
- **Tabular numerics ALWAYS on** for any number that changes during flight.
- **Minimum body size: 16pt.** Floor of 15pt for dense table rows (squawk lists, runway selection). Never smaller.
- **Critical readouts: 24-32pt** B612 Mono Medium or Bold.
- **Caps only for tiny chips:** `VFR` `IFR` `TFR` `ADS-B` `MOA` `CTAF` `ATIS` `CTAF`. Never caps for headings or buttons.
- **No italics in flight UI.** Reserve for citation in docs only.

### Type Scale (px / pt — iPad)

| Token | Size | Line height | Use |
|---|---|---|---|
| `text-xs` | 13 | 18 | Chart strip labels, footnotes |
| `text-sm` | 15 | 20 | Dense table rows |
| `text-base` | 16 | 22 | Default body |
| `text-md` | 18 | 24 | Section labels |
| `text-lg` | 22 | 28 | Card titles |
| `text-xl` | 28 | 34 | Critical readouts (alt, GS) |
| `text-2xl` | 32 | 38 | Hero readout (active freq, target alt) |
| `text-3xl` | 44 | 50 | Emergency / alert banner only |

---

## 4. Color — Three-Mode System

OpenEFB ships **three** color modes, not two. Every other EFB has light/dark; we treat cockpit lighting as a tri-state problem because the physics of the cockpit demand it.

| Mode | When it triggers | Why |
|---|---|---|
| **☀️ Paper-Day** | Daytime, ambient > 1,000 lux, default mode in daylight | AMOLED dark UI *loses* under direct sun (>50k lux) — the screen becomes more reflective than emissive. High-contrast warm paper with black ink wins. |
| **🌆 Dark-Dusk** | Civil twilight to ~1,000 lux, sunset/sunrise, hangar, dim cabin | Standard "dark mode." AMOLED-friendly. The mode every other EFB uses as their default. |
| **🌙 Red-Night** | Civil night, pilot opt-in, or auto-trigger at moonlight ambient | True 635-660nm phosphor. Blue channel hard-clamped to preserve cone dark adaptation. |

**Auto-switching:** Combine `UIScreen.brightness` + ambient light sensor + civil twilight calculation from current GPS position. Manual override always available; never override the pilot.

### ☀️ Paper-Day Tokens

```
chassis      #1A1D1F   gunmetal frame (chrome surfaces only)
surface      #F4EFE5   sectional warm paper (canvas)
surface-2    #E8E2D4   raised panel / sidebar
ink          #0F1112   primary text, hairlines
ink-muted    #4A5258   secondary text
hairline     #B9B1A1   panel separators
accent       #D81B60   sectional magenta — actions, ownship, brand
data-cyan    #0077A8   Class B / IFR routing
caution      #B8541A   advisory amber
warning      #B9251A   alert red
ok           #2F7A4C   active recording / in-spec
```

### 🌆 Dark-Dusk Tokens

```
chassis      #000000   true black (AMOLED pixel-off)
surface      #0E1216   raised panel
surface-2    #161C21   secondary panel
ink          #F4EFE5   warm white — matches paper-day, no cool cast
ink-muted    #9AA3AA
hairline     #2B353C
accent       #FF3D7A   magenta brightened for dark surface
data-cyan    #4AB3E0
caution      #E0A040
warning      #E25B4E
ok           #4ECB89
```

### 🌙 Red-Night Tokens

```
chassis      #050000
surface      #0E0000
surface-2    #1A0303
ink          #FF3A1F   primary readouts
ink-muted    #9E1808
hairline     #3A0907
accent       #FF5A35   active / ownship / tap target
warning      #FF7048   alert (brightest tier; reserved)
```

### Red-Night Invariants (hard rules, enforce in code)

These are not theme values — they are invariants. Violations break dark adaptation and undo the entire mode.

1. **Blue channel ≤ `0x08`** on every visible pixel. Filter at the SwiftUI `Color` layer; never let a designer ship `Color.blue` in this mode.
2. **No pure white anywhere.** No `#FFF`. No `Color.white`.
3. **No green, cyan, violet** in chart symbology — re-map Class B/C cyan to red ink-muted in this mode.
4. **No gradients.** No glows. No drop shadows.
5. **No motion on critical readouts.** Movement triggers cone activation. Static text only.
6. **Filled states preferred over outlined.** Outlines force the eye to do edge-detection work.
7. **Reserve the brightest red (`#FF7048`)** for active alerts only. Everything else dims toward `#9E1808`.

### Sectional Chart Color Continuity

The FAA sectional chart's symbology is sacred — it's baked into pilot training and FAR/AIM references. **Never re-color chart features for branding.**

- Class B/C airspace stays cyan in Paper-Day and Dark-Dusk (per FAA)
- Class D rings and MOA polygons stay magenta in Paper-Day and Dark-Dusk (per FAA)
- In Red-Night, all chart features re-render in red monochrome (dark-adaptation overrides convention)
- The UI accent (magenta `#D81B60`) deliberately matches the sectional's Class D magenta — chart continuity, not coincidence.

---

## 5. Spacing — 4pt Base, Cockpit Density

```
2xs  2pt
xs   4pt
sm   8pt
md   12pt
base 16pt   (default screen padding)
lg   24pt   (section gap, sidebar padding)
xl   32pt
2xl  48pt
3xl  64pt
```

- **Base unit:** 4pt (Apple HIG alignment, plays nice with SwiftUI's pixel-perfect rendering)
- **Default screen padding:** 16pt portrait, 24pt iPad landscape sidebar
- **List row vertical padding:** 12-16pt (dense enough to scan, forgiving enough to glove-tap)
- **Section gap:** 24pt
- **Hairline rules:** 1pt minimum, 1.5pt for primary dividers, never less than 1pt
- **Bezel inset:** all edge-pinned controls ≥18pt from the screen edge (palm-rejection in mount)

---

## 6. Layout — Glove- and Turbulence-Tolerant

### Tap Targets

| Context | Minimum | Recommended | Rationale |
|---|---|---|---|
| Standard UI | 44pt | 48pt | Apple HIG floor |
| In-flight high-frequency (direct-to, nearest, freq tune, scratchpad) | 56pt | 56pt | Glove + turbulence tolerance |
| Mode switch / destructive (commit FPL, end flight, delete) | 60pt | 64pt | High-cost actions deserve big targets |
| Hit area vs. visible affordance | +6pt all sides | +10pt all sides | Invisible padding makes confident tapping easier |

### Layout Rules

- **Persistent vertical tool rail** on the leading edge (left in LTR) for the moving-map screen. Never collapses.
- **Bottom dock** for in-flight high-frequency actions (direct-to, nearest, freq tune, scratchpad).
- **Top instrument strip** (56pt tall) for tabular nav readouts — never disappears during flight.
- **Slide-over panels**, not modals. Turbulence eats modal dismiss buttons.
- **Critical live data anchored to corners**, not floating cards. Pilots eye-pin to corners.
- **One dominant action zone per screen.** Don't compete with the map.
- **Left-aligned content blocks** for nav data. Never center operational numbers — alignment carries scan speed.
- **Lists:** visually dense, interactively forgiving — compact rows with oversized invisible tap zones.

### Border Radius

| Token | Value | Use |
|---|---|---|
| `radius-sm` | 4pt | Chips, badges, chart callouts |
| `radius-md` | 8pt | Buttons, list rows |
| `radius-lg` | 12pt | Cards, panels |
| `radius-xl` | 16pt | Modals, sheets |
| `radius-pill` | 9999 | **NEVER** for primary CTAs (reads as marketing); reserve for tag chips only |

### iPad Layout Anchors

- **Landscape (primary orientation):** Tool rail left (64pt), instrument strip top (56pt), bottom dock (72pt), map canvas fills remaining
- **Portrait (secondary):** Instrument strip top (56pt), bottom dock (72pt), tool rail collapses to top-right corner menu, map fills the rest
- **Max content width** in any panel: 720pt (wider lines lose scan speed)

---

## 7. Motion — Minimal-Functional

The cockpit is not a place for delight animations. Motion has one job: aid comprehension.

| Token | Duration | Easing | Use |
|---|---|---|---|
| `motion-instant` | 0ms | linear | Mode switches (day/dusk/night) — no transition |
| `motion-micro` | 80ms | ease-out | Tap feedback, toggle |
| `motion-short` | 150ms | ease-out | Panel enter |
| `motion-exit` | 100ms | ease-in | Panel exit, modal dismiss |
| `motion-medium` | 250ms | ease-in-out | Sheet present (rare) |

### Motion Rules

- **No spring physics on data panels.** No bouncing. Springs are for marketing sites.
- **Mode switches are instant.** Crossfading day → night defeats the entire point of red-night mode (your eye sees blue mid-transition).
- **Haptics on threshold crossings:** 1000ft AGL, pattern altitude entry, freq tune confirm — `UIImpactFeedbackGenerator.light`. Never on routine taps.
- **In Red-Night mode: no motion at all on chart layers or critical readouts.** Motion forces cone activation and destroys dark adaptation.

---

## 8. Components (selected — see Storybook later)

### Instrument Strip
Persistent 56pt-tall bar at the top of map and flight-plan screens. Contains tabular B612 Mono readouts: GS, ALT, HDG, ETE, DTK, DIS. Hairline vertical dividers between fields. Field label in `ink-muted` 13pt above value in `ink` 28pt. Tabular numerics, slashed zero.

### Ownship Symbol
Magenta `accent` chevron arrow, pointing along true track. 32pt total. Course-line projection forward at 50% opacity, hairline 1.5pt. Never centered visually — center on GPS position. Brightest visual element on the chart in all three modes.

### Tool Rail Icon
56pt tap area, 28pt visible glyph, 14pt label below. Active state: 4pt magenta accent dot to the left of the glyph (matches ownship color — visual continuity). Inactive: `ink-muted`.

### Dock Button
56pt × 56pt minimum, 16pt corner radius, 1.5pt magenta accent border, `ink` (or per-mode equivalent) label in B612 Bold caps 14pt. No fill in default state; magenta fill on press.

### Chart Callout
Compact label over the sectional. Background `surface` at 92% opacity, hairline 1pt `hairline`, B612 13pt `ink`. Tabular numerics for elevations and frequencies.

### Alert Banner
Full-width 64pt at the top of the screen (below instrument strip). `warning` background, `ink-on-warning` text (warm white in all modes), B612 Bold 22pt. Auto-dismisses in 5s unless tapped. No animation on appear — instant.

---

## 9. Deliberate Departures from ForeFlight

These are the visible signals that say "this is not enterprise software."

1. **Open-source aviation typography (B612)**, not Helvetica/Univers/SF. The font itself is positioning.
2. **Three color modes, not two.** Paper-Day solves a problem ForeFlight punts on (sunlight readability). Red-Night solves a problem ForeFlight half-solves (dark adaptation).
3. **Sectional magenta as brand color.** Continuity with the chart itself; refuses the "aviation blue" cliché.
4. **No top tab bar.** Tool rail on the leading edge + bottom dock. Top is reserved for instrument data.
5. **Tabular discipline.** Every flight number in B612 Mono with `tnum`. ForeFlight mixes proportional and tabular figures inconsistently.
6. **Ruthless hierarchy.** In flight, map / nearest / freq / scratchpad win. Everything else yields. ForeFlight treats every feature as equal — OpenEFB does not.

---

## 10. Cockpit-Reality Checklist (for code review and QA)

Before any UI change ships, verify against this list:

- [ ] All tabular numerics use B612 Mono with `tnum` enabled
- [ ] No body text smaller than 16pt (15pt floor in dense tables only)
- [ ] No tap target smaller than 44pt; in-flight controls ≥56pt
- [ ] No hairline thinner than 1pt
- [ ] In Red-Night mode, blue channel of every color ≤ 0x08
- [ ] In Red-Night mode, no motion on critical readouts
- [ ] No `Color.white`, no `#FFF` — use `ink` token per mode
- [ ] No `Color.blue` in any cockpit-context UI
- [ ] No pill-radius primary CTA
- [ ] Mode switch is instant (no transition crossfade)
- [ ] Top instrument strip never collapses or animates out
- [ ] All FAA chart symbology colors preserved in Paper-Day and Dark-Dusk
- [ ] Sunlight test: render screen at 1000 nits, confirm contrast ratio ≥ 7:1 for primary text
- [ ] Glove test: every primary action reachable with a winter-gloved thumb

---

## 11. Approved Design References

The following AI-rendered mockups define the visual target for v1.0:

- `~/.gstack/projects/quartermint-openefb/designs/design-system-20260523/variant-A-paper-day.png` — Paper-Day mode, moving-map hero
- `~/.gstack/projects/quartermint-openefb/designs/design-system-20260523/variant-B-dark-dusk.png` — Dark-Dusk mode, evening flight
- `~/.gstack/projects/quartermint-openefb/designs/design-system-20260523/variant-C-red-night.png` — Red-Night mode, night VFR

These are visual targets, not pixel specs. Match the *feel* — typography discipline, color restraint, layout hierarchy, instrument continuity.

---

## 12. Decisions Log

| Date | Decision | Rationale |
|---|---|---|
| 2026-05-23 | Initial design system created via `/design-consultation` | Three-mode color system, B612 typography, sectional-magenta brand. Synthesized from competitive research (ForeFlight/Garmin/SkyDemon/FltPlan), NASA 1992 typography research, Airbus B612 cockpit font work, and outside design voices (Codex + Claude subagent). |
| 2026-05-23 | Adopted three-mode color (Paper-Day / Dark-Dusk / Red-Night) | First-principles departure from category two-mode convention. AMOLED dark mode loses under 100k-lux sunlight; correct architecture separates sunlight-readability from low-light-comfort from dark-adaptation. |
| 2026-05-23 | Adopted B612 as primary typography | Airbus open-source cockpit font. Solves the literal arm's-length cockpit legibility problem, aligns with the project's open-source moat, no competitor uses it. |
| 2026-05-23 | Adopted sectional magenta `#D81B60` as brand/action color | Continuity with FAA sectional chart's Class D symbology. Refuses the "aviation enterprise blue" cliché. |
