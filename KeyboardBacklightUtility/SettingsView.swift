import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            LabeledContent("Global shortcuts", value: "F1 / F2")
            LabeledContent("Menu bar icon", value: "Keyboard")
            Text("Brightness controls send macOS illumination commands. The displayed percentage tracks changes made in this app and may differ if you change brightness elsewhere.")
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(width: 440)
    }
}
