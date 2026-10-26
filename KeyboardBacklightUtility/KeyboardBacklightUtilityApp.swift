import SwiftUI

@main
struct KeyboardBacklightUtilityApp: App {
    @StateObject private var model = BacklightViewModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarPanel()
        } label: {
            Image(systemName: "keyboard")
                .symbolRenderingMode(.hierarchical)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
        }
    }
}
