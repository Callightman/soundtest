import Foundation

public struct CapabilityProbe: Sendable {
    public init() {}

    /// Heuristic mapping from an output route to a capability report.
    ///
    /// Stereo / 5.1 / 7.1 gate on `maxOutputChannels` (the route's physical capability).
    /// Atmos has no clean public API on tvOS, so we use the higher of the live and maximum
    /// channel counts — a receiver may report fewer *active* channels than its physical max
    /// while still being Atmos-capable over HDMI. Atmos is therefore only ever `.supported`
    /// (HDMI + >= 8 channels) or `.unknown`; it is never `.unsupported`, because we cannot
    /// prove a route is incapable of Atmos (no false red badge, just as there's no fake green one).
    public func evaluate(_ s: RouteSnapshot) -> CapabilityReport {
        let isHDMI = s.portType.lowercased().contains("hdmi")
        let atmosChannels = max(s.outputChannels, s.maxOutputChannels)

        let stereo: SupportState = s.maxOutputChannels >= 2 ? .supported : .unsupported
        let s51: SupportState = s.maxOutputChannels >= 6 ? .supported : .unsupported
        let s71: SupportState = s.maxOutputChannels >= 8 ? .supported : .unsupported
        let atmos: SupportState = (isHDMI && atmosChannels >= 8) ? .supported : .unknown

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
