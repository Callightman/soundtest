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
