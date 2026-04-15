import SwiftUI
import Carbon.HIToolbox

public struct HotkeysSettingsTab: View {
    @Bindable var state: AppState

    public init(state: AppState) {
        self.state = state
    }

    public var body: some View {
        Form {
            Section {
                if state.presets.isEmpty {
                    Text("Create a preset before assigning a hotkey.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(state.presets) { preset in
                        HotkeyRow(state: state, preset: preset)
                    }
                }
            } header: {
                Text("Per-preset hotkeys")
            } footer: {
                Text("Hotkeys apply a preset from anywhere on the system. Use modifier-based combinations (⌘, ⌃, ⌥, ⇧) to avoid conflicts with app shortcuts.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(16)
    }
}

private struct HotkeyRow: View {
    @Bindable var state: AppState
    let preset: Preset

    var body: some View {
        HStack {
            Image(systemName: preset.symbolName ?? "square.stack.3d.up.fill")
                .foregroundStyle(Color(hex: preset.tintHex ?? "") ?? .accentColor)
            Text(preset.name).lineLimit(1)
            Spacer()
            HotkeyRecorder(
                hotkey: Binding(
                    get: { preset.hotkey },
                    set: { newHotkey in
                        state.updatePreset(id: preset.id) { $0.hotkey = newHotkey }
                        state.rebindHotkeys()
                    }
                )
            )
        }
    }
}

private struct HotkeyRecorder: View {
    @Binding var hotkey: Hotkey?
    @State private var isRecording = false
    @State private var monitor: Any?

    var body: some View {
        Button {
            toggleRecording()
        } label: {
            Text(displayText)
                .monospacedDigit()
                .frame(minWidth: 120)
                .padding(.vertical, 4)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isRecording
                              ? AnyShapeStyle(Color.accentColor.opacity(0.2))
                              : AnyShapeStyle(.quaternary.opacity(0.4)))
                )
        }
        .buttonStyle(.plain)
        .overlay(alignment: .trailing) {
            if hotkey != nil && !isRecording {
                Button {
                    hotkey = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 4)
            }
        }
    }

    private var displayText: String {
        if isRecording { return "Press keys…" }
        guard let hotkey, hotkey.isValid else { return "Click to record" }
        return describe(hotkey: hotkey)
    }

    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            guard isRecording else { return event }
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let carbonFlags = carbonModifiers(from: flags)
            if carbonFlags != 0 {
                hotkey = Hotkey(keyCode: UInt16(event.keyCode), modifiers: carbonFlags)
                stopRecording()
                return nil
            }
            return event
        }
    }

    private func stopRecording() {
        isRecording = false
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    private func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var value: UInt32 = 0
        if flags.contains(.command) { value |= UInt32(cmdKey) }
        if flags.contains(.option)  { value |= UInt32(optionKey) }
        if flags.contains(.control) { value |= UInt32(controlKey) }
        if flags.contains(.shift)   { value |= UInt32(shiftKey) }
        return value
    }

    private func describe(hotkey: Hotkey) -> String {
        var parts: [String] = []
        if hotkey.modifiers & UInt32(controlKey) != 0 { parts.append("⌃") }
        if hotkey.modifiers & UInt32(optionKey)  != 0 { parts.append("⌥") }
        if hotkey.modifiers & UInt32(shiftKey)   != 0 { parts.append("⇧") }
        if hotkey.modifiers & UInt32(cmdKey)     != 0 { parts.append("⌘") }
        parts.append(keyCodeDisplay(hotkey.keyCode))
        return parts.joined()
    }

    private func keyCodeDisplay(_ keyCode: UInt16) -> String {
        if let label = specialKeyLabel(keyCode) { return label }
        let source = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
        guard let layoutPtr = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else {
            return "Key \(keyCode)"
        }
        let layoutData = unsafeBitCast(layoutPtr, to: CFData.self) as Data
        var deadKeyState: UInt32 = 0
        var chars = [UniChar](repeating: 0, count: 4)
        var length = 0
        let status = layoutData.withUnsafeBytes { buffer -> OSStatus in
            guard let layout = buffer.bindMemory(to: UCKeyboardLayout.self).baseAddress else {
                return OSStatus(kUCOutputBufferTooSmall)
            }
            return UCKeyTranslate(
                layout,
                keyCode,
                UInt16(kUCKeyActionDisplay),
                0, UInt32(LMGetKbdType()),
                UInt32(kUCKeyTranslateNoDeadKeysBit),
                &deadKeyState,
                chars.count,
                &length,
                &chars
            )
        }
        guard status == noErr, length > 0 else { return "Key \(keyCode)" }
        return String(utf16CodeUnits: chars, count: length).uppercased()
    }

    private func specialKeyLabel(_ keyCode: UInt16) -> String? {
        switch Int(keyCode) {
        case kVK_Return:    return "↩"
        case kVK_Tab:       return "⇥"
        case kVK_Space:     return "␣"
        case kVK_Delete:    return "⌫"
        case kVK_Escape:    return "⎋"
        case kVK_LeftArrow: return "←"
        case kVK_RightArrow: return "→"
        case kVK_UpArrow:   return "↑"
        case kVK_DownArrow: return "↓"
        case kVK_F1:  return "F1";  case kVK_F2:  return "F2";  case kVK_F3:  return "F3"
        case kVK_F4:  return "F4";  case kVK_F5:  return "F5";  case kVK_F6:  return "F6"
        case kVK_F7:  return "F7";  case kVK_F8:  return "F8";  case kVK_F9:  return "F9"
        case kVK_F10: return "F10"; case kVK_F11: return "F11"; case kVK_F12: return "F12"
        default: return nil
        }
    }
}
