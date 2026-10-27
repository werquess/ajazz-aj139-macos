import SwiftUI

@main
struct AJ139App: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @ObservedObject private var model = MouseModel.shared
    @AppStorage("menuBar") private var menuBar = true

    var body: some Scene {
        Window("AJ139 Driver", id: "main") {
            ContentView(m: model, input: .shared)
        }
        .windowResizability(.contentSize)

        MenuBarExtra(isInserted: $menuBar) {
            MenuBarView(m: model, input: .shared)
        } label: {
            MenuBarLabel(m: model)
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.applyDockPolicy()
        MouseModel.shared.start(interval: UserDefaults.standard.object(forKey: "pollInterval") as? Double ?? 15)
        InputStore.shared.start()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    static func applyDockPolicy() {
        let show = UserDefaults.standard.object(forKey: "showDock") as? Bool ?? true
        NSApp.setActivationPolicy(show ? .regular : .accessory)
    }
}
