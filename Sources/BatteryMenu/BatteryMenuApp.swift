import AppKit
import BatteryCore
import SwiftUI

@main
enum BatteryMenuMain {
    @MainActor
    static func main() {
        if CommandLine.arguments.contains("--preview") {
            PreviewRunner.run()
        } else {
            BatteryMenuApp.main()
        }
    }
}

private struct BatteryMenuApp: App {
    @StateObject private var store = BatteryStore()

    var body: some Scene {
        MenuBarExtra {
            BatteryPanel(store: store)
        } label: {
            MenuBarLabel(snapshot: store.snapshot)
        }
        .menuBarExtraStyle(.window)

        Settings {
            BatterySettingsView()
        }
    }
}

private enum PreviewRunner {
    @MainActor private static var window: NSWindow?

    @MainActor
    static func run() {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)

        let store = BatteryStore()
        let controller = NSHostingController(rootView: BatteryPanel(store: store))
        let previewWindow = NSWindow(contentViewController: controller)
        previewWindow.title = "Battery Menu 预览"
        previewWindow.styleMask = [.titled, .closable, .miniaturizable]
        previewWindow.setContentSize(NSSize(width: 390, height: 560))
        previewWindow.center()
        previewWindow.makeKeyAndOrderFront(nil)
        window = previewWindow

        app.activate(ignoringOtherApps: true)
        app.run()
    }
}
