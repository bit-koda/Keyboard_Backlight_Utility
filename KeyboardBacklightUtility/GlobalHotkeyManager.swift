import Carbon.HIToolbox
import Foundation

/// Registers global keyboard-backlight shortcuts without requiring Accessibility permission.
final class GlobalHotkeyManager {
    private static let hotkeySignature: OSType = 0x4B424C55 // "KBLU"
    private static let lowerHotkeyID: UInt32 = 1
    private static let raiseHotkeyID: UInt32 = 2
    private static let shortcutModifiers = UInt32(optionKey)

    private var lowerHotkey: EventHotKeyRef?
    private var raiseHotkey: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    var onLower: (() -> Void)?
    var onRaise: (() -> Void)?

    func start() {
        guard eventHandler == nil else { return }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let userInfo = Unmanaged.passUnretained(self).toOpaque()
        let handler: EventHandlerUPP = { _, event, userInfo in
            guard let event, let userInfo else { return noErr }

            var hotkeyID = EventHotKeyID()
            let result = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotkeyID
            )
            guard result == noErr else { return result }

            let manager = Unmanaged<GlobalHotkeyManager>
                .fromOpaque(userInfo)
                .takeUnretainedValue()
            switch hotkeyID.id {
            case GlobalHotkeyManager.lowerHotkeyID:
                DispatchQueue.main.async { manager.onLower?() }
            case GlobalHotkeyManager.raiseHotkeyID:
                DispatchQueue.main.async { manager.onRaise?() }
            default:
                break
            }
            return noErr
        }

        guard InstallEventHandler(
            GetEventDispatcherTarget(),
            handler,
            1,
            &eventType,
            userInfo,
            &eventHandler
        ) == noErr else {
            NSLog("KeyboardBacklightUtility: Could not register shortcut handler.")
            return
        }

        let lowerID = EventHotKeyID(
            signature: Self.hotkeySignature,
            id: Self.lowerHotkeyID
        )
        let raiseID = EventHotKeyID(
            signature: Self.hotkeySignature,
            id: Self.raiseHotkeyID
        )

        let lowerResult = RegisterEventHotKey(
            UInt32(kVK_DownArrow),
            Self.shortcutModifiers,
            lowerID,
            GetEventDispatcherTarget(),
            0,
            &lowerHotkey
        )
        let raiseResult = RegisterEventHotKey(
            UInt32(kVK_UpArrow),
            Self.shortcutModifiers,
            raiseID,
            GetEventDispatcherTarget(),
            0,
            &raiseHotkey
        )

        if lowerResult != noErr || raiseResult != noErr {
            NSLog("KeyboardBacklightUtility: Could not register Option Arrow shortcuts.")
            stop()
        }
    }

    func stop() {
        if let lowerHotkey {
            UnregisterEventHotKey(lowerHotkey)
        }
        if let raiseHotkey {
            UnregisterEventHotKey(raiseHotkey)
        }
        if let eventHandler {
            RemoveEventHandler(eventHandler)
        }

        lowerHotkey = nil
        raiseHotkey = nil
        eventHandler = nil
    }

    deinit {
        stop()
    }
}
