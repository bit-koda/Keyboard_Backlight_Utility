import AppKit
import Foundation
import Combine

@MainActor
final class BacklightViewModel: ObservableObject {
    @Published var brightness: Double = 0
    @Published var statusText = "Checking keyboard backlight…"
    @Published var errorMessage: String?
    @Published var isAvailable = false

    private let controller = KeyboardBacklightController()
    private var hotkeys: GlobalHotkeyManager?

    init() {
        refresh()
        let manager = GlobalHotkeyManager()
        manager.onLower = { [weak self] in
            Task { @MainActor in self?.adjust(by: -0.1) }
        }
        manager.onRaise = { [weak self] in
            Task { @MainActor in self?.adjust(by: 0.1) }
        }
        manager.start()
        hotkeys = manager
    }

    func refresh() {
        guard let current = controller.readBrightness() else {
            isAvailable = false
            statusText = "Backlight control unsupported"
            errorMessage = """
            macOS did not accept a keyboard illumination command.
            Check that your Mac has a built-in backlit keyboard and that keyboard backlight controls work in System Settings.
            """
            return
        }
        brightness = current
        isAvailable = true
        statusText = "Keyboard backlight available"
        errorMessage = nil
    }

    func adjust(to requestedValue: Double) {
        guard isAvailable else { refresh(); return }
        let requested = min(1.0, max(0.0, requestedValue))
        guard controller.writeBrightness(requested),
              let actual = controller.readBrightness() else {
            isAvailable = false
            statusText = "Brightness change failed"
            errorMessage = "The system did not confirm the requested brightness. Use System Settings → Keyboard and report this issue to the developer."
            return
        }
        brightness = actual
        statusText = "Brightness verified"
        errorMessage = nil
    }

    func adjust(by amount: Double) {
        guard isAvailable else {
            refresh()
            return
        }
        let current = brightness
        let requested = min(1.0, max(0.0, current + amount))
        guard controller.writeBrightness(requested) else {
            isAvailable = false
            statusText = "Brightness change failed"
            errorMessage = """
            The system rejected the brightness change. No successful update was confirmed.
            Please use System Settings → Keyboard to adjust brightness, then report this diagnostic from the app to the developer.
            """
            return
        }
        // Read back to verify that hardware accepted the requested value.
        guard let actual = controller.readBrightness() else {
            isAvailable = false
            statusText = "Could not verify brightness"
            errorMessage = "The write returned, but the app could not read back the hardware value. The change is unverified."
            return
        }
        brightness = actual
        statusText = "Brightness verified"
        errorMessage = nil
    }

    func reportIssue() {
        let model = ProcessInfo.processInfo.environment["MODEL_IDENTIFIER"] ?? "Model identifier unavailable"
        let os = ProcessInfo.processInfo.operatingSystemVersionString
        let body = """
        KeyboardBacklightUtility diagnostic report

        macOS: \(os)
        Hardware model: \(model)
        Status: \(statusText)
        Error: \(errorMessage ?? "None")
        Backend: macOS illumination events
        """
        let encoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:developer@example.com?subject=KeyboardBacklightUtility%20Issue&body=\(encoded)") {
            NSWorkspace.shared.open(url)
        }
    }
}
