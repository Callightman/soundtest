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
