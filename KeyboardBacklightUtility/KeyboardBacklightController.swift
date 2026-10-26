import AppKit

/// Controls the built-in keyboard backlight by posting macOS illumination commands.
///
/// Apple silicon Macs do not expose the legacy `AppleKeyboardBacklight` IOKit service.
/// These system-defined events use the same command path as the keyboard's illumination keys.
@MainActor
final class KeyboardBacklightController {
    private static let illuminationUpKeyCode = 21
    private static let illuminationDownKeyCode = 22
    private static let auxiliaryControlButtonsSubtype: Int16 = 8
    private static let brightnessSteps = 16

    private(set) var brightness = 1.0

    enum SupportStatus {
        case available
        case unavailable(String)
    }

    var supportStatus: SupportStatus {
        .available
    }

    func readBrightness() -> Double? {
        brightness
    }

    @discardableResult
    func writeBrightness(_ value: Double) -> Bool {
        let requestedBrightness = min(1.0, max(0.0, value))
        let difference = requestedBrightness - brightness
        let stepCount = Int((abs(difference) * Double(Self.brightnessSteps)).rounded())

        guard stepCount > 0 else { return true }

        let keyCode = difference > 0
            ? Self.illuminationUpKeyCode
            : Self.illuminationDownKeyCode

        for _ in 0..<stepCount {
            postIlluminationKey(keyCode)
        }

        // macOS does not provide a public API to read the physical brightness level.
        // Keep a logical value so the UI reflects commands issued by this utility.
        brightness = requestedBrightness
        return true
    }

    private func postIlluminationKey(_ keyCode: Int) {
        for eventState in [0xA, 0xB] {
            let data1 = (keyCode << 16) | (eventState << 8)
            guard let event = NSEvent.otherEvent(
                with: .systemDefined,
                location: .zero,
                modifierFlags: [],
                timestamp: 0,
                windowNumber: 0,
                context: nil,
                subtype: Self.auxiliaryControlButtonsSubtype,
                data1: data1,
                data2: -1
            ) else {
                continue
            }

            event.cgEvent?.post(tap: .cghidEventTap)
        }
    }
}
