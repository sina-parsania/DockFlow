import SwiftUI
import AppKit

@main
struct DockFlowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @State private var environment: AppEnvironment = .live()
    @State private var state: AppState = {
        let env = AppEnvironment.live()
        return MainActor.assumeIsolated { env.makeAppState() }
    }()

    var body: some Scene {
        WindowGroup(id: "main") {
            MainWindow(state: state)
                .frame(minWidth: 760, idealWidth: 960, minHeight: 520, idealHeight: 620)
                .background(MainWindowAccessor())
                .onAppear {
                    NSApp.setActivationPolicy(.regular)
                    NSApp.activate(ignoringOtherApps: true)
                }
        }
        .defaultSize(width: 960, height: 620)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Preset") { _ = state.createPreset() }
                    .keyboardShortcut("n", modifiers: [.command])
                Button("New Category") {
                    if let presetID = state.selectedPresetID {
                        state.addCategory(to: presetID)
                    }
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
                .disabled(state.selectedPresetID == nil)
            }
            CommandGroup(after: .toolbar) {
                Button("Apply Preset") {
                    if let preset = state.selectedPreset {
                        Task { @MainActor in
                            await state.applyPreset(preset, options: state.applyOptions(for: preset))
                        }
                    }
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .disabled(state.selectedPreset == nil)

                Button("Import Current Dock…") {
                    state.isImportSheetPresented = true
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])

                Divider()

                Menu("Switch to Preset") {
                    ForEach(Array(state.presets.prefix(9).enumerated()), id: \.element.id) { index, preset in
                        Button(preset.name) {
                            Task { @MainActor in
                                await state.applyPreset(preset, options: state.applyOptions(for: preset))
                            }
                        }
                        .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: [.command])
                    }
                }
                .disabled(state.presets.isEmpty)
            }
            CommandGroup(replacing: .undoRedo) {
                Button("Undo") { state.undoManager.undo() }
                    .keyboardShortcut("z", modifiers: [.command])
                    .disabled(!state.undoManager.canUndo)
                Button("Redo") { state.undoManager.redo() }
                    .keyboardShortcut("z", modifiers: [.command, .shift])
                    .disabled(!state.undoManager.canRedo)
            }
        }

        MenuBarExtra {
            MenuBarContent(state: state)
        } label: {
            Image("MenuBarIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(state: state)
        }
    }
}

private struct MainWindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            if let window = view.window {
                AppDelegate.shared?.registerMainWindow(window)
            }
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}
