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
