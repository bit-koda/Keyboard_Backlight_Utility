import SwiftUI

struct MenuBarPanel: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Keyboard", comment: "Control Center panel heading for keyboard backlight controls.")
                .font(.headline)

            Text("Keyboard backlight shortcuts", comment: "Heading above the app's keyboard backlight shortcuts.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                ShortcutRow(
                    title: "Dim keyboard backlight",
                    shortcut: "⌥↓"
                )
                ShortcutRow(
                    title: "Brighten keyboard backlight",
                    shortcut: "⌥↑"
                )
            }

            Text("These shortcuts work anywhere while the app is running.", comment: "Explains that the keyboard shortcuts are global.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(width: 308)
    }
}

private struct ShortcutRow: View {
    let title: LocalizedStringKey
    let shortcut: String

    var body: some View {
        HStack {
            Text(title)

            Spacer()

            Text(shortcut)
                .font(.body.monospaced())
                .foregroundStyle(.secondary)
                .accessibilityLabel(accessibleShortcut)
        }
    }

    private var accessibleShortcut: String {
        switch shortcut {
        case "⌥↓":
            "Option Down Arrow"
        case "⌥↑":
            "Option Up Arrow"
        default:
            shortcut
        }
    }
}
