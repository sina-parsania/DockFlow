import Foundation
import Carbon.HIToolbox

/// Global hotkey registration via Carbon's `RegisterEventHotKey`.
/// Carbon hotkeys don't require Accessibility TCC and work from non-sandboxed apps.
public final class HotkeyService: @unchecked Sendable {
    public typealias Handler = (UUID) -> Void

    private struct Registration {
        let presetID: UUID
        let ref: EventHotKeyRef
        let id: UInt32
    }

    private var registrations: [UInt32: Registration] = [:]
    private var handler: Handler?
    private var eventHandlerRef: EventHandlerRef?
    private var nextHotkeyID: UInt32 = 1
    private let lock = NSLock()

    public init() {}

    public func start(handler: @escaping Handler) {
        lock.lock(); defer { lock.unlock() }
        self.handler = handler
        if eventHandlerRef == nil {
            installEventHandler()
        }
    }

    public func stop() {
        lock.lock(); defer { lock.unlock() }
        for reg in registrations.values {
            UnregisterEventHotKey(reg.ref)
        }
        registrations.removeAll()
        if let ref = eventHandlerRef {
            RemoveEventHandler(ref)
            eventHandlerRef = nil
        }
        handler = nil
    }

    public func register(presetID: UUID, hotkey: Hotkey) {
        lock.lock(); defer { lock.unlock() }
        removeRegistration(for: presetID)

        guard hotkey.isValid else { return }

        var ref: EventHotKeyRef?
        let hotkeyID = nextHotkeyID
        nextHotkeyID &+= 1
        let eventHotKeyID = EventHotKeyID(signature: fourCharCode("DFHK"), id: hotkeyID)
        let status = RegisterEventHotKey(
            UInt32(hotkey.keyCode),
            hotkey.modifiers,
            eventHotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )
        if status == noErr, let ref {
            registrations[hotkeyID] = Registration(presetID: presetID, ref: ref, id: hotkeyID)
            Log.hotkey.info("Registered hotkey for preset \(presetID.uuidString)")
        } else {
            Log.hotkey.error("RegisterEventHotKey failed with status \(status)")
        }
    }

    public func unregister(presetID: UUID) {
        lock.lock(); defer { lock.unlock() }
        removeRegistration(for: presetID)
    }

    // MARK: - Private

    private func removeRegistration(for presetID: UUID) {
        if let key = registrations.first(where: { $0.value.presetID == presetID })?.key,
           let reg = registrations.removeValue(forKey: key) {
            UnregisterEventHotKey(reg.ref)
        }
    }

    private func installEventHandler() {
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let selfPointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let userData, let event else { return OSStatus(eventNotHandledErr) }
                var hkID = EventHotKeyID()
                let size = MemoryLayout<EventHotKeyID>.size
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil, size, nil, &hkID
                )
                guard status == noErr else { return status }
                let service = Unmanaged<HotkeyService>.fromOpaque(userData).takeUnretainedValue()
                service.handleEvent(hotkeyID: hkID.id)
                return noErr
            },
            1,
            &eventSpec,
            selfPointer,
            &eventHandlerRef
        )
    }

    private func handleEvent(hotkeyID: UInt32) {
        lock.lock()
        let registration = registrations[hotkeyID]
        let currentHandler = handler
        lock.unlock()
        if let reg = registration {
            DispatchQueue.main.async { currentHandler?(reg.presetID) }
        }
    }

    private func fourCharCode(_ string: String) -> FourCharCode {
        var result: FourCharCode = 0
        for byte in string.utf8.prefix(4) {
            result = (result << 8) + FourCharCode(byte)
        }
        return result
    }
}
