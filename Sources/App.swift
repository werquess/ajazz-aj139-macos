import SwiftUI

@main
struct AJ139App: App {
    @StateObject private var model = MouseModel()
    @AppStorage("pollInterval") private var pollInterval = 15.0

    var body: some Scene {
        WindowGroup {
            ContentView(m: model).onAppear { model.start(interval: pollInterval) }
        }
        .windowResizability(.contentSize)
    }
}
