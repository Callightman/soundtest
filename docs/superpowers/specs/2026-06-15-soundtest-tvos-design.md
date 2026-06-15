# SoundTest for tvOS — Design Spec

**Date:** 2026-06-15
**Status:** Approved (scope) — pending spec review
**Owner:** emrahsumer@gmail.com
**Repo:** https://github.com/Callightman/soundtest

## 1. Goal

Build the most complete, polished, and reliable **tvOS** audio-test app on the App Store:
a tool for verifying, testing, and tuning a home-theater system's Dolby Atmos / surround
playback. It must match every feature of the incumbent *"Sound test for Dolby Atmos"*
(id 6447675518) and exceed it with calibration, deeper tests, and an honest format-capability
report.

**Non-negotiable quality bar:** no memory leaks, no crashes, no "audio is broken after
returning from background" bugs, and excellent, trustworthy diagnostics.

## 2. Decisions (locked)

| Decision | Choice |
|---|---|
| Platform | **tvOS-only** (architecture kept clean to allow universal later) |
| Monetization | **Paid upfront** (no IAP, no subscription) — a deliberate marketing wedge |
| Calibration | **By-ear guided, on-device** (no iPhone-mic companion; data model leaves room for v2 companion) |
| Scope | Full feature set (5 tabs) designed in one pass; implementation phased by the plan |
| Min OS | tvOS 18+ (built with Xcode 26.4.1 / Swift 6.3.1, strict concurrency) |

## 3. Competitive & user research (summary)

- Incumbent (id 6447675518): $19.99 one-time, universal, ~10 ratings worldwide, **no written
  reviews**. Features: Diagnostics, Test Tones (stereo→9.1.6, pink noise −20/−30 dBFS),
  Spatial Test (3D objects), Dolby demo videos.
- Rivals with real signal: *Surround Speaker Check* (39 ratings @ 3.8★) and *Studio Six Digital
  Surround Generator* (pro integrator tool: polarity, delay, EQ test signals).
- **User wants** (forums/competitor history): one-time purchase (not subscription); individual
  speaker isolation; stereo-pair test; subwoofer/bass suite (sweeps, crossover, manual freq);
  polarity/phase, delay/distance, level-match; keep the praised 3D visualization.
- **Umut's direct feedback:** calibration; more tests; "what can my system actually play"
  (formats — Atmos/DTS/etc, show all).

### Honest technical constraint
Apple TV/tvOS does **not** decode DTS and has **no microphone**. The capability report shows
only what tvOS can truthfully deliver on the current route (Atmos E-AC3 JOC, Dolby Digital/+,
multichannel PCM, channel count, sample rate) and explains clearly that DTS is not an Apple TV
output format — never a fake "supported" badge. Calibration is by-ear, not mic-measured.

**DTS decision (locked): explain-only, no third-party decoder.** Two distinct layers were
considered:
1. *Bitstream/passthrough to the AVR* (what a real "DTS test" requires) — **impossible on Apple
   TV** at the OS/HDMI level; no library (VLCKit/FFmpeg included) can enable it.
2. *Software-decode DTS → PCM and play it* (what TVVLCKit does, as in the team's prior IPTV app)
   — technically possible, but the AVR then receives plain PCM, so it validates nothing about
   the user's DTS hardware, and TVVLCKit is a large (~tens of MB) dependency that conflicts with
   the lean/low-memory goal.
Therefore v1 ships **explain-only**: the capability matrix states plainly that Apple TV cannot
bitstream DTS to a receiver. TVVLCKit-based DTS *playback* remains a possible future add-on, not
in v1.

## 4. App structure — 5 tabs

### 4.1 Connection / Diagnostics
- "Dolby Atmos supported / not / unknown" status card with **Run Audio Diagnostics**.
- Live readout from `AVAudioSession`: current route (e.g. "Living Room — HDMI"), output channel
  count, sample rate, multichannel-content supported.
- **Format-capability matrix**: Stereo, 5.1, 7.1, 5.1.2/5.1.4/7.1.2/7.1.4 Atmos — each marked
  supported/unsupported with an explanatory note; DTS row explicitly explained as
  not-applicable on Apple TV.
- Diagnostics routine: probes route + plays short verification tones and reports findings.

### 4.2 Test Tones
- Speaker-layout picker `X.Y.Z` from Stereo up to **9.1.6**.
- Per-channel playback, **isolate single speaker**, and **stereo-pair** test.
- Pink noise at **−20 dBFS** and **−30 dBFS** (LFE level-corrected, e.g. −30/−40).
- Sine tones + frequency sweeps; channel walk-through ("next speaker") flow.
- **All tones synthesized in real time** via `AVAudioEngine` (`AVAudioSourceNode`) — no large
  bundled audio files → minimal memory footprint, no asset bloat.

### 4.3 Spatial Test
- 3D object-placement tests (the fun effects: chirp, ratchet, boat horn, etc.) using Apple's
  **PHASE** engine (or `AVAudioEnvironmentNode`) for true positional audio.
- Improved on-screen visualization of the moving sound source.
- Downloadable effect packs handled with a cache + eviction policy (no unbounded memory).

### 4.4 Calibration (NEW — by-ear guided)
- Guided wizard: per-channel **level matching**, **distance/delay** setup, **polarity/phase**
  check (in-phase vs out-of-phase A/B), **subwoofer crossover sweep**.
- Saves a named **calibration profile** (persisted). Pink-noise reference + optional hint to use
  any phone SPL-meter app.
- Data model is companion-ready: profile/measurement types are defined so a future
  iPhone-mic companion can populate them without schema changes.

### 4.5 Demos + About
- Demos: browse/play publicly available Dolby Atmos demo videos (Amaze, Leaf, Shattered, …).
- About: app info, version, privacy policy link, contact, credits.

## 5. Architecture

- **UI:** SwiftUI for tvOS, MVVM, the tvOS focus engine. One feature module per tab; each view
  model owns its state and exposes a narrow interface.
- **Audio core (shared service layer):**
  - `AudioSessionManager` — configures/activates `AVAudioSession`, observes interruptions and
    route changes, republishes capability state.
  - `ToneEngine` — `AVAudioEngine` graph for real-time synthesis (pink noise, sine, sweeps) and
    per-channel routing via channel layouts.
  - `SpatialEngine` — PHASE/environment-node graph for object placement.
  - `CapabilityProbe` — reads route/channel/format info; produces the capability matrix.
  - `CalibrationStore` — persists calibration profiles.
- **Lifecycle correctness (the bug class to kill):**
  - Observe `scenePhase`; tear down/rebuild the audio engine deterministically on
    background/foreground.
  - Handle `AVAudioSession.interruptionNotification` and `routeChangeNotification`; resume or
    surface state cleanly.
  - Single source of truth for "is audio active"; no orphaned engines/timers.
- **Concurrency:** Swift 6 strict concurrency; audio callbacks are real-time-safe (no allocation
  / locks on the render thread).
- **Memory:** synthesized tones (no big WAVs); bounded caches for demo/spatial assets;
  Instruments leak + allocations pass as an acceptance gate.

## 6. Error handling & edge cases

- No Atmos / stereo-only route → capability matrix and tests degrade gracefully with clear copy.
- Route changes mid-test (HDMI unplug, AirPlay switch) → stop safely, re-probe, inform user.
- Interruption (Siri, other audio) → pause and resume or reset cleanly.
- Unsupported layout selected → only offer layouts the current route can address; explain limits.
- Demo/effect download failure → retry + offline messaging; never crash.

## 7. Testing strategy

- Unit tests: `CapabilityProbe` mapping, dBFS/level math, calibration profile persistence,
  tone-frequency generation correctness.
- Integration/UI: tab navigation + focus, wizard flow, layout picker bounds.
- Manual on-device matrix: real Apple TV + AVR/soundbar, route-change and background/foreground
  cycling.
- Quality gates: zero leaks in Instruments; clean Swift 6 concurrency build; no crashes across
  the lifecycle test matrix.

## 8. ASO (locked direction)

- **App name (≤30):** `Atmos Speaker & Sound Test`
- **Subtitle (≤30):** `Surround Calibrate & Diagnose`
- **Keywords (≤100):** `dolby,atmos,surround,speaker,5.1,7.1,9.1.6,test,tone,calibration,home,theater,avr,spatial,sub,dts`
- **Hook:** "One-time purchase. No subscription. Test, calibrate, and prove your Dolby Atmos system."
- Description leads with the one-time/no-subscription wedge, then Diagnostics / Test Tones /
  Spatial / Calibration / Demos, then honest format notes.

## 9. Supporting deliverables

- **GitHub Pages** on `Callightman/soundtest`: privacy policy, contact page, and Apple
  privacy-label content as HTML (required for App Store distribution).
- App Store Connect upload via the existing API key
  (`/Users/sumer/.private_keys/AuthKey_59C6SC9QFV.p8`, key `59C6SC9QFV`, issuer
  `d8519f8e-…343f48`).

## 10. Out of scope (v1)

- iPhone-mic calibration companion (data model is ready for it; app is not built).
- Universal iOS/iPadOS build.
- Subscriptions / IAP.
- DTS decoding (not possible on tvOS).

## 11. Open risks

- True Atmos **object** test playback may require bundled/streamed encoded Atmos assets rather
  than pure synthesis — to be resolved in the implementation plan (PHASE-rendered objects vs
  pre-encoded clips).
- Atmos-capability detection has no single clean public API; will combine channel-count + route
  inspection + a known Atmos asset probe, and label "unknown" honestly when indeterminate.
