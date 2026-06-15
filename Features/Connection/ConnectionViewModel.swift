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
