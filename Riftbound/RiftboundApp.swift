import SwiftUI

@main
struct RiftboundApp: App {
    @StateObject private var game = GameStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(game)
        }
    }
}
