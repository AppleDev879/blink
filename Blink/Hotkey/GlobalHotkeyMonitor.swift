import AppKit
import Carbon
import Foundation

/// Registers a system-wide hotkey via Carbon `RegisterEventHotKey`.
final class GlobalHotkeyMonitor {
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private var onTrigger: (() -> Void)?

    deinit {
        unregister()
    }

    func register(_ chord: HotkeyChord, onTrigger: @escaping () -> Void) {
        unregister()
        self.onTrigger = onTrigger

        var carbonMods: UInt32 = 0
        if chord.modifiers.contains(.command) { carbonMods |= UInt32(cmdKey) }
        if chord.modifiers.contains(.shift) { carbonMods |= UInt32(shiftKey) }
        if chord.modifiers.contains(.option) { carbonMods |= UInt32(optionKey) }
        if chord.modifiers.contains(.control) { carbonMods |= UInt32(controlKey) }

        let hotKeyID = EventHotKeyID(signature: OSType(0x424C4E4B), id: 1) // 'BLNK'
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            chord.keyCode,
            carbonMods,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )
        guard status == noErr else { return }
        hotKeyRef = ref

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let userData = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let userData else { return noErr }
                let monitor = Unmanaged<GlobalHotkeyMonitor>.fromOpaque(userData).takeUnretainedValue()
                var hotKeyID = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                if hotKeyID.signature == OSType(0x424C4E4B) {
                    DispatchQueue.main.async {
                        monitor.onTrigger?()
                    }
                }
                return noErr
            },
            1,
            &eventType,
            userData,
            &handlerRef
        )
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let handlerRef {
            RemoveEventHandler(handlerRef)
            self.handlerRef = nil
        }
        onTrigger = nil
    }
}
