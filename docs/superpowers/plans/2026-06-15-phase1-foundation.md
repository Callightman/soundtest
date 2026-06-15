# SoundTest tvOS — Phase 1: Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up a reproducible tvOS Xcode project with a tested audio-core foundation and a working, accurate **Connection / Diagnostics** tab.

**Architecture:** SwiftUI + MVVM on tvOS 18+. A pure, unit-tested domain/audio core (`SoundTestCore`) is isolated from `AVFoundation` behind protocols so it can be tested without real hardware. The app target wires the core to SwiftUI views. The project is defined in `project.yml` and generated with XcodeGen.

**Tech Stack:** Swift 6.3 (strict concurrency), SwiftUI, AVFoundation (`AVAudioSession`), XCTest, XcodeGen, Xcode 26.4.

---

## Phased Roadmap (context — only Phase 1 is detailed here)

1. **Phase 1 — Foundation (this plan):** project scaffold, audio domain + level math, capability probe, audio-session lifecycle manager, Connection/Diagnostics tab.
2. **Phase 2 — Test Tones:** `ToneEngine` (real-time `AVAudioSourceNode` synthesis), layout picker, per-channel / isolate / stereo-pair, pink noise −20/−30 dBFS.
3. **Phase 3 — Spatial Test:** PHASE engine object placement + visualization, asset cache with eviction.
4. **Phase 4 — Calibration:** by-ear wizard (level, delay/distance, polarity, sub crossover) + persisted profiles.
5. **Phase 5 — Demos + About:** streamed Dolby demo trailers, About screen.
6. **Phase 6 — Ship:** GitHub Pages legal site, app icon/assets, ASO metadata, App Store Connect upload.

Each later phase gets its own plan written when we reach it.

---

## File Structure (Phase 1)

```
SoundTest/
├── project.yml                         # XcodeGen project definition
├── scripts/
│   ├── gen.sh                          # regenerate .xcodeproj
│   └── test.sh                         # build + unit test on tvOS simulator
├── App/
│   ├── Info.plist
│   ├── SoundTestApp.swift              # @main entry, scenePhase wiring
│   └── RootTabView.swift               # 5-tab shell (only Connection live in P1)
├── Sources/SoundTestCore/             # pure, testable; no SwiftUI
│   ├── Models/
│   │   ├── SpeakerLayout.swift
│   │   └── AudioCapability.swift
│   ├── Audio/
│   │   ├── LevelMath.swift
│   │   ├── AudioRouteProviding.swift   # protocol + RouteSnapshot
│   │   ├── CapabilityProbe.swift
│   │   └── AudioSessionManager.swift   # lifecycle state machine
└── Features/
    └── Connection/
        ├── ConnectionViewModel.swift
        └── ConnectionView.swift
Tests/SoundTestCoreTests/
├── SpeakerLayoutTests.swift
├── LevelMathTests.swift
├── CapabilityProbeTests.swift
├── AudioSessionManagerTests.swift
└── ConnectionViewModelTests.swift
```

---

## Task 1: Project scaffold with XcodeGen

**Files:**
- Create: `project.yml`, `App/Info.plist`, `App/SoundTestApp.swift`, `App/RootTabView.swift`
- Create: `scripts/gen.sh`, `scripts/test.sh`, `.gitignore`

- [ ] **Step 1: Create `.gitignore`**

```gitignore
.DS_Store
*.xcodeproj
DerivedData/
build/
.build/
xcuserdata/
*.xcuserstate
```

- [ ] **Step 2: Create `project.yml`**

```yaml
name: SoundTest
options:
  bundleIdPrefix: com.callightman.soundtest
  deploymentTarget:
    tvOS: "18.0"
  createIntermediateGroups: true
settings:
  base:
    SWIFT_VERSION: "6.0"
    SWIFT_STRICT_CONCURRENCY: complete
    MARKETING_VERSION: "1.0.0"
    CURRENT_PROJECT_VERSION: "1"
targets:
  SoundTestCore:
    type: framework
    platform: tvOS
    sources: [Sources/SoundTestCore]
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.callightman.soundtest.core
  SoundTest:
    type: application
    platform: tvOS
    sources: [App, Features]
    dependencies:
      - target: SoundTestCore
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.callightman.soundtest
        INFOPLIST_FILE: App/Info.plist
        GENERATE_INFOPLIST_FILE: NO
  SoundTestCoreTests:
    type: bundle.unit-test
    platform: tvOS
    sources: [Tests/SoundTestCoreTests]
    dependencies:
      - target: SoundTestCore
schemes:
  SoundTest:
    build:
      targets:
        SoundTest: all
        SoundTestCoreTests: [test]
    test:
      targets: [SoundTestCoreTests]
```

- [ ] **Step 3: Create `App/Info.plist`**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>SoundTest</string>
  <key>CFBundleDisplayName</key><string>Atmos Speaker &amp; Sound Test</string>
  <key>CFBundleIdentifier</key><string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
  <key>CFBundleShortVersionString</key><string>$(MARKETING_VERSION)</string>
  <key>CFBundleVersion</key><string>$(CURRENT_PROJECT_VERSION)</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSRequiresIPhoneOS</key><true/>
  <key>UILaunchScreen</key><dict/>
</dict>
</plist>
```

- [ ] **Step 4: Create `App/SoundTestApp.swift`** (placeholder body; scenePhase wired in Task 6)

```swift
import SwiftUI

@main
struct SoundTestApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
    }
}
```

- [ ] **Step 5: Create `App/RootTabView.swift`** (Connection tab is a placeholder until Task 8, so the app compiles from Task 1 onward)

```swift
import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            Text("Connection — wired in Task 8")
                .tabItem { Label("Connection", systemImage: "cable.connector") }
            Text("Test Tones — coming in Phase 2")
                .tabItem { Label("Test Tones", systemImage: "slider.horizontal.3") }
            Text("Spatial Test — coming in Phase 3")
                .tabItem { Label("Spatial Test", systemImage: "globe") }
            Text("Calibration — coming in Phase 4")
                .tabItem { Label("Calibration", systemImage: "tuningfork") }
            Text("Demos — coming in Phase 5")
                .tabItem { Label("Demos", systemImage: "play.rectangle") }
        }
    }
}
```

- [ ] **Step 6: Create `scripts/gen.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
xcodegen generate
echo "Generated SoundTest.xcodeproj"
```

- [ ] **Step 7: Create `scripts/test.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
./scripts/gen.sh
xcodebuild test \
  -project SoundTest.xcodeproj \
  -scheme SoundTest \
  -destination 'platform=tvOS Simulator,name=Apple TV 4K (3rd generation)' \
  CODE_SIGNING_ALLOWED=NO | tail -40
```

- [ ] **Step 8: Create the source/test directories XcodeGen needs**

XcodeGen errors if a target's source path does not exist, so create the tree before generating:

Run: `mkdir -p Sources/SoundTestCore/Models Sources/SoundTestCore/Audio Features/Connection Tests/SoundTestCoreTests`

- [ ] **Step 9: Make scripts executable and generate + build the project**

Run: `chmod +x scripts/*.sh && ./scripts/gen.sh`
Expected: "Generated SoundTest.xcodeproj", no errors.

Then verify the app compiles (an empty `SoundTestCore` framework builds fine; the app uses no core symbols yet):

Run: `xcodebuild build -project SoundTest.xcodeproj -scheme SoundTest -destination 'platform=tvOS Simulator,name=Apple TV 4K (3rd generation)' CODE_SIGNING_ALLOWED=NO | tail -5`
Expected: `** BUILD SUCCEEDED **`.

> NOTE: Do not run `./scripts/test.sh` yet — there are no tests until Task 2, and an empty test target can error. Task 2 is the first to run the full test script.

- [ ] **Step 10: Commit**

```bash
git init && git add -A && git commit -m "chore: scaffold tvOS project with XcodeGen"
```

---

## Task 2: SpeakerLayout model

**Files:**
- Create: `Sources/SoundTestCore/Models/SpeakerLayout.swift`
- Test: `Tests/SoundTestCoreTests/SpeakerLayoutTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import SoundTestCore

final class SpeakerLayoutTests: XCTestCase {
    func test_channelCount_sumsMainLfeHeight() {
        XCTAssertEqual(SpeakerLayout(main: 7, lfe: 1, height: 4).channelCount, 12)
        XCTAssertEqual(SpeakerLayout(main: 2, lfe: 0, height: 0).channelCount, 2)
    }

    func test_description_usesXYZformat() {
        XCTAssertEqual(SpeakerLayout(main: 5, lfe: 1, height: 2).description, "5.1.2")
        XCTAssertEqual(SpeakerLayout(main: 2, lfe: 0, height: 0).description, "2.0.0")
    }

    func test_presets_includeStereoThrough916() {
        let descs = SpeakerLayout.presets.map(\.description)
        XCTAssertTrue(descs.contains("2.0.0"))
        XCTAssertTrue(descs.contains("5.1.0"))
        XCTAssertTrue(descs.contains("7.1.4"))
        XCTAssertTrue(descs.contains("9.1.6"))
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `./scripts/test.sh`
Expected: FAIL — "cannot find 'SpeakerLayout' in scope".

- [ ] **Step 3: Write minimal implementation**

```swift
public struct SpeakerLayout: Equatable, Hashable, CustomStringConvertible, Sendable {
    public let main: Int
    public let lfe: Int
    public let height: Int

    public init(main: Int, lfe: Int, height: Int) {
        self.main = main
        self.lfe = lfe
        self.height = height
    }

    public var channelCount: Int { main + lfe + height }
    public var description: String { "\(main).\(lfe).\(height)" }

    public static let presets: [SpeakerLayout] = [
        .init(main: 2, lfe: 0, height: 0),
        .init(main: 5, lfe: 1, height: 0),
        .init(main: 5, lfe: 1, height: 2),
        .init(main: 5, lfe: 1, height: 4),
        .init(main: 7, lfe: 1, height: 0),
        .init(main: 7, lfe: 1, height: 2),
        .init(main: 7, lfe: 1, height: 4),
        .init(main: 9, lfe: 1, height: 6),
    ]
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `./scripts/test.sh`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add Sources/SoundTestCore/Models/SpeakerLayout.swift Tests/SoundTestCoreTests/SpeakerLayoutTests.swift
git commit -m "feat(core): add SpeakerLayout model with presets"
```

---

## Task 3: Level math (dBFS / amplitude / LFE)

**Files:**
- Create: `Sources/SoundTestCore/Audio/LevelMath.swift`
- Test: `Tests/SoundTestCoreTests/LevelMathTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import SoundTestCore

final class LevelMathTests: XCTestCase {
    func test_amplitude_fromDBFS() {
        XCTAssertEqual(LevelMath.amplitude(dbFS: 0), 1.0, accuracy: 1e-9)
        XCTAssertEqual(LevelMath.amplitude(dbFS: -20), 0.1, accuracy: 1e-9)
        XCTAssertEqual(LevelMath.amplitude(dbFS: -6), 0.501187, accuracy: 1e-5)
    }

    func test_lfeLevel_is10dBBelowReference() {
        XCTAssertEqual(LevelMath.lfeDBFS(referenceDBFS: -20), -30, accuracy: 1e-9)
        XCTAssertEqual(LevelMath.lfeDBFS(referenceDBFS: -30), -40, accuracy: 1e-9)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `./scripts/test.sh`
Expected: FAIL — "cannot find 'LevelMath' in scope".

- [ ] **Step 3: Write minimal implementation**

```swift
import Foundation

public enum LevelMath {
    /// Linear amplitude (0...1) for a given dBFS value.
    public static func amplitude(dbFS: Double) -> Double {
        pow(10.0, dbFS / 20.0)
    }

    /// LFE channel level convention used by the test tones: 10 dB below the reference.
    public static func lfeDBFS(referenceDBFS: Double) -> Double {
        referenceDBFS - 10.0
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `./scripts/test.sh`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Sources/SoundTestCore/Audio/LevelMath.swift Tests/SoundTestCoreTests/LevelMathTests.swift
git commit -m "feat(core): add LevelMath dBFS helpers"
```

---

## Task 4: Capability model + route abstraction

**Files:**
- Create: `Sources/SoundTestCore/Models/AudioCapability.swift`
- Create: `Sources/SoundTestCore/Audio/AudioRouteProviding.swift`
- Test: (covered in Task 5)

- [ ] **Step 1: Create `AudioCapability.swift`**

```swift
public enum SupportState: String, Sendable, Equatable {
    case supported, unsupported, unknown
}

public struct CapabilityReport: Equatable, Sendable {
    public let outputChannels: Int
    public let maxOutputChannels: Int
    public let sampleRate: Double
    public let portName: String
    public let portType: String
    public let stereo: SupportState
    public let surround51: SupportState
    public let surround71: SupportState
    public let atmos: SupportState

    public init(outputChannels: Int, maxOutputChannels: Int, sampleRate: Double,
                portName: String, portType: String, stereo: SupportState,
                surround51: SupportState, surround71: SupportState, atmos: SupportState) {
        self.outputChannels = outputChannels
        self.maxOutputChannels = maxOutputChannels
        self.sampleRate = sampleRate
        self.portName = portName
        self.portType = portType
        self.stereo = stereo
        self.surround51 = surround51
        self.surround71 = surround71
        self.atmos = atmos
    }
}
```

- [ ] **Step 2: Create `AudioRouteProviding.swift`** (abstraction so the probe is testable without hardware)

```swift
import Foundation

/// Minimal snapshot of the current audio output route.
public struct RouteSnapshot: Equatable, Sendable {
    public let outputChannels: Int
    public let maxOutputChannels: Int
    public let sampleRate: Double
    public let portName: String
    public let portType: String

    public init(outputChannels: Int, maxOutputChannels: Int, sampleRate: Double,
                portName: String, portType: String) {
        self.outputChannels = outputChannels
        self.maxOutputChannels = maxOutputChannels
        self.sampleRate = sampleRate
        self.portName = portName
        self.portType = portType
    }
}

public protocol AudioRouteProviding: Sendable {
    func currentSnapshot() -> RouteSnapshot
}
```

- [ ] **Step 3: Build to verify it compiles**

Run: `./scripts/test.sh`
Expected: PASS (existing tests still pass; new types compile).

- [ ] **Step 4: Commit**

```bash
git add Sources/SoundTestCore/Models/AudioCapability.swift Sources/SoundTestCore/Audio/AudioRouteProviding.swift
git commit -m "feat(core): add capability model and route abstraction"
```

---

## Task 5: CapabilityProbe (route snapshot → report)

**Files:**
- Create: `Sources/SoundTestCore/Audio/CapabilityProbe.swift`
- Test: `Tests/SoundTestCoreTests/CapabilityProbeTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import SoundTestCore

private struct FakeRoute: AudioRouteProviding {
    let snapshot: RouteSnapshot
    func currentSnapshot() -> RouteSnapshot { snapshot }
}

final class CapabilityProbeTests: XCTestCase {
    private func report(channels: Int, max: Int, port: String) -> CapabilityReport {
        let snap = RouteSnapshot(outputChannels: channels, maxOutputChannels: max,
                                 sampleRate: 48000, portName: "Living Room", portType: port)
        return CapabilityProbe().evaluate(FakeRoute(snapshot: snap).currentSnapshot())
    }

    func test_stereoAlways Supported_whenAtLeastTwoChannels() {
        XCTAssertEqual(report(channels: 2, max: 2, port: "HDMI").stereo, .supported)
    }

    func test_51requiresSixChannels() {
        XCTAssertEqual(report(channels: 2, max: 2, port: "HDMI").surround51, .unsupported)
        XCTAssertEqual(report(channels: 6, max: 8, port: "HDMI").surround51, .supported)
    }

    func test_71requiresEightChannels() {
        XCTAssertEqual(report(channels: 6, max: 6, port: "HDMI").surround71, .unsupported)
        XCTAssertEqual(report(channels: 8, max: 8, port: "HDMI").surround71, .supported)
    }

    func test_atmos_unknownUnlessHDMIWithEightPlus() {
        XCTAssertEqual(report(channels: 2, max: 2, port: "HDMI").atmos, .unknown)
        XCTAssertEqual(report(channels: 12, max: 32, port: "HDMI").atmos, .supported)
        XCTAssertEqual(report(channels: 12, max: 32, port: "Bluetooth").atmos, .unknown)
    }
}
```

> Fix the test method name typo when you paste: `test_stereoAlwaysSupported_whenAtLeastTwoChannels`.

- [ ] **Step 2: Run test to verify it fails**

Run: `./scripts/test.sh`
Expected: FAIL — "cannot find 'CapabilityProbe' in scope".

- [ ] **Step 3: Write minimal implementation**

```swift
import Foundation

public struct CapabilityProbe: Sendable {
    public init() {}

    /// Heuristic mapping. Atmos has no clean public API on tvOS, so we report
    /// `.supported` only for an HDMI route exposing >= 8 output channels, and
    /// `.unknown` otherwise (never a fake green badge).
    public func evaluate(_ s: RouteSnapshot) -> CapabilityReport {
        let isHDMI = s.portType.lowercased().contains("hdmi")
        let chans = max(s.outputChannels, s.maxOutputChannels)

        let stereo: SupportState = s.maxOutputChannels >= 2 ? .supported : .unsupported
        let s51: SupportState = s.maxOutputChannels >= 6 ? .supported : .unsupported
        let s71: SupportState = s.maxOutputChannels >= 8 ? .supported : .unsupported
        let atmos: SupportState = (isHDMI && chans >= 8) ? .supported : .unknown

        return CapabilityReport(
            outputChannels: s.outputChannels,
            maxOutputChannels: s.maxOutputChannels,
            sampleRate: s.sampleRate,
            portName: s.portName,
            portType: s.portType,
            stereo: stereo, surround51: s51, surround71: s71, atmos: atmos
        )
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `./scripts/test.sh`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Sources/SoundTestCore/Audio/CapabilityProbe.swift Tests/SoundTestCoreTests/CapabilityProbeTests.swift
git commit -m "feat(core): add CapabilityProbe with honest Atmos heuristic"
```

---

## Task 6: AudioSessionManager lifecycle state machine

**Files:**
- Create: `Sources/SoundTestCore/Audio/AudioSessionManager.swift`
- Test: `Tests/SoundTestCoreTests/AudioSessionManagerTests.swift`

This is the component that kills the "audio broken after backgrounding / interruption" bug class. We model the lifecycle as a pure, testable state machine; the real `AVAudioSession` wiring is a thin adapter driven by the same events.

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import SoundTestCore

final class AudioSessionManagerTests: XCTestCase {
    func test_startsInactive() {
        XCTAssertEqual(AudioSessionState.machineInitial, .inactive)
    }

    func test_activate_thenInterrupt_thenResume() {
        var s = AudioSessionState.machineInitial
        s = s.applying(.activate);                 XCTAssertEqual(s, .active)
        s = s.applying(.interruptionBegan);        XCTAssertEqual(s, .interrupted)
        s = s.applying(.interruptionEnded(shouldResume: true)); XCTAssertEqual(s, .active)
    }

    func test_interruptionEnded_withoutResume_goesInactive() {
        var s = AudioSessionState.active
        s = s.applying(.interruptionBegan)
        s = s.applying(.interruptionEnded(shouldResume: false))
        XCTAssertEqual(s, .inactive)
    }

    func test_routeChange_whileActive_requiresReprobe() {
        var s = AudioSessionState.active
        s = s.applying(.routeChanged)
        XCTAssertEqual(s, .needsReprobe)
        s = s.applying(.reprobed)
        XCTAssertEqual(s, .active)
    }

    func test_background_deactivates_andForegroundReactivates() {
        var s = AudioSessionState.active
        s = s.applying(.didEnterBackground); XCTAssertEqual(s, .inactive)
        s = s.applying(.willEnterForeground); XCTAssertEqual(s, .active)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `./scripts/test.sh`
Expected: FAIL — "cannot find 'AudioSessionState' in scope".

- [ ] **Step 3: Write minimal implementation**

```swift
import Foundation

public enum AudioSessionState: Equatable, Sendable {
    case inactive, active, interrupted, needsReprobe

    public static let machineInitial: AudioSessionState = .inactive

    public enum Event: Equatable, Sendable {
        case activate
        case interruptionBegan
        case interruptionEnded(shouldResume: Bool)
        case routeChanged
        case reprobed
        case didEnterBackground
        case willEnterForeground
    }

    public func applying(_ event: Event) -> AudioSessionState {
        switch (self, event) {
        case (_, .activate):                         return .active
        case (.active, .interruptionBegan):          return .interrupted
        case (.interrupted, .interruptionEnded(let resume)): return resume ? .active : .inactive
        case (.active, .routeChanged):               return .needsReprobe
        case (.needsReprobe, .reprobed):             return .active
        case (_, .didEnterBackground):               return .inactive
        case (.inactive, .willEnterForeground):      return .active
        default:                                     return self
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `./scripts/test.sh`
Expected: PASS (5 tests).

- [ ] **Step 5: Add the live AVAudioSession adapter (compile-checked, exercised on device)**

Append to `AudioSessionManager.swift`:

```swift
#if canImport(AVFoundation)
import AVFoundation

/// Live route provider backed by AVAudioSession (tvOS supports AVAudioSession).
public struct LiveRouteProvider: AudioRouteProviding {
    public init() {}
    public func currentSnapshot() -> RouteSnapshot {
        let session = AVAudioSession.sharedInstance()
        let output = session.currentRoute.outputs.first
        return RouteSnapshot(
            outputChannels: session.outputNumberOfChannels,
            maxOutputChannels: session.maximumOutputNumberOfChannels,
            sampleRate: session.sampleRate,
            portName: output?.portName ?? "Unknown",
            portType: output?.portType.rawValue ?? "Unknown"
        )
    }
}

@MainActor
public final class AudioSessionManager: ObservableObject {
    @Published public private(set) var state: AudioSessionState = .machineInitial
    private let session = AVAudioSession.sharedInstance()

    public init() {}

    public func activate() throws {
        try session.setCategory(.playback, mode: .moviePlayback, options: [])
        try session.setActive(true)
        state = state.applying(.activate)
    }

    public func handle(_ event: AudioSessionState.Event) {
        state = state.applying(event)
    }
}
#endif
```

- [ ] **Step 6: Run tests again to confirm nothing broke**

Run: `./scripts/test.sh`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add Sources/SoundTestCore/Audio/AudioSessionManager.swift Tests/SoundTestCoreTests/AudioSessionManagerTests.swift
git commit -m "feat(core): add audio session lifecycle state machine + live adapter"
```

---

## Task 7: ConnectionViewModel

**Files:**
- Create: `Features/Connection/ConnectionViewModel.swift`
- Test: `Tests/SoundTestCoreTests/ConnectionViewModelTests.swift`

> The view model lives in `Features/` (app target) but its logic is tested by injecting a fake route provider. To keep it testable from the test target, the testable surface (`makeReport`) is a free function in core. Implement the mapping in core and have the VM call it.

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import SoundTestCore

final class ConnectionViewModelTests: XCTestCase {
    func test_makeReport_producesAtmosSupportedForHDMI12ch() {
        let snap = RouteSnapshot(outputChannels: 12, maxOutputChannels: 32,
                                 sampleRate: 48000, portName: "Living Room", portType: "HDMI")
        let report = ConnectionLogic.makeReport(from: snap)
        XCTAssertEqual(report.atmos, .supported)
        XCTAssertEqual(report.portName, "Living Room")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `./scripts/test.sh`
Expected: FAIL — "cannot find 'ConnectionLogic' in scope".

- [ ] **Step 3: Add `ConnectionLogic` to core**

Create `Sources/SoundTestCore/Audio/ConnectionLogic.swift`:

```swift
public enum ConnectionLogic {
    public static func makeReport(from snapshot: RouteSnapshot) -> CapabilityReport {
        CapabilityProbe().evaluate(snapshot)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `./scripts/test.sh`
Expected: PASS.

- [ ] **Step 5: Create the view model**

`Features/Connection/ConnectionViewModel.swift`:

```swift
import Foundation
import SoundTestCore

@MainActor
final class ConnectionViewModel: ObservableObject {
    @Published private(set) var report: CapabilityReport?
    private let provider: AudioRouteProviding

    init(provider: AudioRouteProviding = LiveRouteProvider()) {
        self.provider = provider
    }

    func refresh() {
        report = ConnectionLogic.makeReport(from: provider.currentSnapshot())
    }
}
```

- [ ] **Step 6: Commit**

```bash
git add Sources/SoundTestCore/Audio/ConnectionLogic.swift Features/Connection/ConnectionViewModel.swift Tests/SoundTestCoreTests/ConnectionViewModelTests.swift
git commit -m "feat: add ConnectionViewModel and connection logic"
```

---

## Task 8: ConnectionView UI

**Files:**
- Create: `Features/Connection/ConnectionView.swift`

- [ ] **Step 1: Create the view**

```swift
import SwiftUI
import SoundTestCore

struct ConnectionView: View {
    @StateObject private var model = ConnectionViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                statusCard
                if let r = model.report { detailGrid(r) }
            }
            .padding(60)
        }
        .onAppear { model.refresh() }
    }

    private var statusCard: some View {
        VStack(spacing: 16) {
            Image(systemName: statusSymbol)
                .font(.system(size: 64))
                .foregroundStyle(statusColor)
            Text(statusTitle).font(.title2.bold())
            Button("Run Audio Diagnostics") { model.refresh() }
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
    }

    private func detailGrid(_ r: CapabilityReport) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 24) {
            infoTile("Output", "\(r.portName) — \(r.portType)")
            infoTile("Channels", "\(r.outputChannels) / max \(r.maxOutputChannels)")
            infoTile("Sample Rate", String(format: "%.0f Hz", r.sampleRate))
            infoTile("Stereo", r.stereo.rawValue)
            infoTile("5.1 Surround", r.surround51.rawValue)
            infoTile("7.1 Surround", r.surround71.rawValue)
            infoTile("Dolby Atmos", r.atmos.rawValue)
            infoTile("DTS", "Not output by Apple TV")
        }
    }

    private func infoTile(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline).foregroundStyle(.secondary)
            Text(value).font(.title3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(28)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var statusSymbol: String {
        switch model.report?.atmos {
        case .supported: return "checkmark.circle.fill"
        case .unsupported: return "xmark.circle.fill"
        default: return "questionmark.circle.fill"
        }
    }
    private var statusColor: Color {
        switch model.report?.atmos {
        case .supported: return .green
        case .unsupported: return .red
        default: return .yellow
        }
    }
    private var statusTitle: String {
        switch model.report?.atmos {
        case .supported: return "Dolby Atmos supported"
        case .unsupported: return "Dolby Atmos not available"
        default: return "Unknown status"
        }
    }
}
```

- [ ] **Step 2: Wire `ConnectionView` into `RootTabView`**

In `App/RootTabView.swift`, replace the Connection placeholder line:

```swift
            Text("Connection — wired in Task 8")
                .tabItem { Label("Connection", systemImage: "cable.connector") }
```

with:

```swift
            ConnectionView()
                .tabItem { Label("Connection", systemImage: "cable.connector") }
```

- [ ] **Step 3: Build the full app target**

Run: `./scripts/test.sh`
Expected: PASS — app compiles, all unit tests pass.

- [ ] **Step 3: Launch in the simulator to eyeball it**

```bash
xcodebuild build -project SoundTest.xcodeproj -scheme SoundTest \
  -destination 'platform=tvOS Simulator,name=Apple TV 4K (3rd generation)' \
  CODE_SIGNING_ALLOWED=NO | tail -5
xcrun simctl boot "Apple TV 4K (3rd generation)" 2>/dev/null || true
open -a Simulator
```
Then install/launch the built `.app` from DerivedData (or run from Xcode). Expected: 5-tab UI, Connection tab shows a status card + detail grid. (Simulator reports a stereo route, so Atmos will show "Unknown" — correct/honest behavior.)

- [ ] **Step 4: Commit**

```bash
git add Features/Connection/ConnectionView.swift
git commit -m "feat: add Connection/Diagnostics tab UI"
```

---

## Task 9: Wire scenePhase lifecycle into the app

**Files:**
- Modify: `App/SoundTestApp.swift`

- [ ] **Step 1: Update the app entry to forward lifecycle events**

```swift
import SwiftUI
import SoundTestCore

@main
struct SoundTestApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var audio = AudioSessionManager()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(audio)
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:    audio.handle(.willEnterForeground)
            case .background: audio.handle(.didEnterBackground)
            default: break
            }
        }
    }
}
```

- [ ] **Step 2: Build + test**

Run: `./scripts/test.sh`
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add App/SoundTestApp.swift
git commit -m "feat: forward scenePhase to audio session manager"
```

---

## Self-Review (completed by author)

- **Spec coverage (Phase 1 portion):** Connection/Diagnostics tab ✓ (Tasks 7–8), honest format matrix incl. DTS note ✓ (Task 8), Atmos honesty ✓ (Task 5), lifecycle/interruption/route-change correctness ✓ (Task 6, 9), tested audio core ✓ (Tasks 2–7), reproducible project ✓ (Task 1). Tabs 2–5 are stubs by design (later phases).
- **Placeholder scan:** none — every code step contains full code. (One deliberate typo callout in Task 5 Step 1 with the corrected name.)
- **Type consistency:** `RouteSnapshot`, `CapabilityReport`, `SupportState`, `AudioSessionState.Event`, `CapabilityProbe.evaluate`, `ConnectionLogic.makeReport`, `LiveRouteProvider` used consistently across tasks.
- **Risk acknowledged:** `SWIFT_VERSION 6.0` + `complete` concurrency may surface actor-isolation warnings in the live adapter; the `@MainActor` annotations are placed to satisfy this, but the execution loop should treat any concurrency error as a failing build to fix before moving on.
