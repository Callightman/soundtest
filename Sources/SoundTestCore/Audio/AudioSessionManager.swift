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
        // Activation only from a settled state (callers use activate(); never speculative).
        case (.inactive, .activate):                 return .active
        case (.needsReprobe, .activate):             return .active
        // Interruptions can begin while active OR mid-reprobe.
        case (.active, .interruptionBegan):          return .interrupted
        case (.needsReprobe, .interruptionBegan):    return .interrupted
        // After ANY interruption we re-probe before declaring active again, so a route
        // change that happened during the interruption is never lost.
        case (.interrupted, .interruptionEnded(let resume)): return resume ? .needsReprobe : .inactive
        case (.active, .routeChanged):               return .needsReprobe
        case (.needsReprobe, .reprobed):             return .active
        case (_, .didEnterBackground):               return .inactive
        case (.inactive, .willEnterForeground):      return .active
        default:                                     return self
        }
    }
}

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

    /// One-time category configuration. Call once at startup before activating.
    public func configureSession() throws {
        try session.setCategory(.playback, mode: .moviePlayback, options: [])
    }

    /// Activates the audio session. Call `configureSession()` first.
    public func activate() throws {
        try session.setActive(true)
        state = state.applying(.activate)
    }

    /// Drives the lifecycle state machine. MUST be called from the matching AVAudioSession
    /// notification observers (interruption / route change) and SwiftUI scenePhase changes —
    /// never speculatively.
    public func handle(_ event: AudioSessionState.Event) {
        state = state.applying(event)
    }
}
#endif
