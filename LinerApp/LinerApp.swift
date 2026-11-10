import SwiftUI

@main
struct LinerApp: App {
    init() {
        AudioPlayerService.shared.setupAudioSession()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}
