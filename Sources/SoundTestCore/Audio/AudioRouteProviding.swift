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
