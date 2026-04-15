import SwiftUI

public struct PresetSidebar: View {
    @Bindable var state: AppState
    @State private var editingPresetID: Preset.ID?
    @State private var editingName: String = ""

    public init(state: AppState) {
        self.state = state
    }

    public var body: some View {
        VStack(spacing: 0) {
            sidebarList
            Divider()
            bottomBar
        }
    }

    private var sidebarList: some View {
        List(selection: $state.selectedPresetID) {
            Section {
                ForEach(filteredPresets) { preset in
                    row(for: preset)
                        .tag(preset.id)
                        .contextMenu { contextMenu(for: preset) }
                }
                .onMove { indices, newOffset in
                    state.reorderPresets(fromOffsets: indices, toOffset: newOffset)
                }
            } header: {
                Text("Presets")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.sidebar)
    }

    private func row(for preset: Preset) -> some View {
        HStack(spacing: 8) {
            Image(systemName: preset.symbolName ?? "square.stack.3d.up.fill")
                .foregroundStyle(tint(for: preset))
                .frame(width: 20)

            if editingPresetID == preset.id {
                TextField("Name", text: $editingName, onCommit: {
                    state.renamePreset(id: preset.id, to: editingName)
                    editingPresetID = nil
                })
                .textFieldStyle(.roundedBorder)
                .controlSize(.small)
            } else {
                Text(preset.name)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer(minLength: 4)

            if state.settings.activePresetID == preset.id {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.secondary)
                    .imageScale(.small)
                    .help("Currently applied")
            }

            if let hotkey = preset.hotkey, hotkey.isValid {
                Image(systemName: "command")
                    .foregroundStyle(.tertiary)
                    .imageScale(.small)
            }
        }
        .padding(.vertical, 2)
    }

    private var filteredPresets: [Preset] {
        let needle = state.searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !needle.isEmpty else { return state.presets }
        return state.presets.filter {
            $0.name.lowercased().contains(needle) ||
            $0.allItems.contains(where: { $0.displayName.lowercased().contains(needle) })
        }
    }

    @ViewBuilder
    private func contextMenu(for preset: Preset) -> some View {
        Button("Apply") {
            Task { @MainActor in
                await state.applyPreset(preset, options: state.applyOptions(for: preset))
            }
        }
        Button("Rename") {
            editingPresetID = preset.id
            editingName = preset.name
        }
        Button("Duplicate") { state.duplicatePreset(id: preset.id) }
        Button("Export…") { exportPreset(preset) }
        Divider()
        Button("Delete", role: .destructive) {
            state.removePreset(id: preset.id)
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 6) {
            Menu {
                Button("New Preset") { _ = state.createPreset() }
                Button("Import Current Dock…") { state.isImportSheetPresented = true }
                Button("Import from File…") { importPresetFromFile() }
            } label: {
                Image(systemName: "plus")
                    .frame(width: 24, height: 22)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .help("Create or import a preset")

            Spacer()

            Menu {
                Button("Restore Latest Backup") {
                    Task { @MainActor in await state.restoreLatestBackup() }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .frame(width: 24, height: 22)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .help("More actions")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    private func tint(for preset: Preset) -> Color {
        if let hex = preset.tintHex, let color = Color(hex: hex) { return color }
        return .accentColor
    }

    @MainActor
    private func exportPreset(_ preset: Preset) {
        let defaultName = state.exporter.suggestedFileName(for: preset)
        guard let url = FilePickerHelper.pickSaveLocation(defaultName: defaultName) else { return }
        do {
            let data = try state.exporter.exportPreset(preset)
            try data.write(to: url, options: .atomic)
        } catch {
            state.lastError = error.localizedDescription
        }
    }

    @MainActor
    private func importPresetFromFile() {
        let urls = FilePickerHelper.pick(
            FilePickerHelper.PickOptions(
                canChooseFiles: true,
                canChooseDirectories: false,
                allowsMultipleSelection: false
            )
        )
        guard let url = urls.first else { return }
        do {
            let data = try Data(contentsOf: url)
            let preset = try state.exporter.importPreset(from: data)
            state.presets.append(preset)
            state.selectedPresetID = preset.id
            state.persist()
        } catch {
            state.lastError = error.localizedDescription
        }
    }
}
