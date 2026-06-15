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
