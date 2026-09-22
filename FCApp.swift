import SwiftUI
import MusicKit

@main
struct FCApp: App {
    @StateObject private var music = MusicController()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(music)
        }
    }
}
