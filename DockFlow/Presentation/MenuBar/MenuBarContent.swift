import SwiftUI

public struct MenuBarContent: View {
    @Bindable var state: AppState
    @Environment(\.openWindow) private var openWindow

    public init(state: AppState) {
        self.state = state
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            if state.presets.isEmpty {
                emptyPresets
            } else {
                presetList
            }
            Divider()
            footer
        }
        .frame(width: 340)
        .padding(.vertical, 6)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 0) {
                Text("DockFlow").font(.headline)
                if let preset = state.presets.first(where: { $0.id == state.settings.activePresetID }) {
                    Text("Active: \(preset.name)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private var emptyPresets: some View {
        VStack(spacing: 6) {
            Text("No presets yet")
                .font(.callout)
                .foregroundStyle(.secondary)
            Button("Open DockFlow…") { focusMainWindow() }
                .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
    }

    private var presetList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(state.presets.enumerated()), id: \.element.id) { index, preset in
                    PresetMenuRow(
                        state: state,
                        preset: preset,
                        shortcutIndex: index < 9 ? index + 1 : nil,
                        showCategories: state.settings.showCategoriesInMenuBar
                    )
                    .padding(.horizontal, 6)
                }
            }
            .padding(.vertical, 4)
        }
        .frame(maxHeight: 360)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 0) {
            MenuBarFooterButton(
                symbol: "macwindow",
                title: "Open DockFlow…",
                trailing: "⌘⇧O"
            ) {
                focusMainWindow()
            }

            MenuBarFooterButton(
                symbol: "arrow.down.square",
                title: "Import Current Dock"
            ) {
                state.isImportSheetPresented = true
                focusMainWindow()
            }

            MenuBarFooterButton(
                symbol: "arrow.uturn.backward",
                title: "Restore Latest Dock Backup"
            ) {
                Task { @MainActor in await state.restoreLatestBackup() }
            }

            MenuBarFooterButton(
                symbol: "gearshape",
                title: "Settings…",
                trailing: "⌘,"
            ) {
                focusMainWindow()
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }

            Divider().padding(.vertical, 2)

            MenuBarFooterButton(
                symbol: "power",
                title: "Quit DockFlow",
                trailing: "⌘Q"
            ) {
                NSApp.terminate(nil)
            }
        }
    }

    @MainActor
    private func focusMainWindow() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        openWindow(id: "main")
    }
}

private struct PresetMenuRow: View {
    @Bindable var state: AppState
    let preset: Preset
    let shortcutIndex: Int?
    let showCategories: Bool
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            applyRow
            if showCategories, !preset.categories.isEmpty {
                categoriesSummary
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isHovering ? Color.accentColor.opacity(0.12) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .onTapGesture { applyPreset() }
    }

    private var applyRow: some View {
        HStack(spacing: 10) {
            Image(systemName: preset.symbolName ?? "square.stack.3d.up.fill")
                .foregroundStyle(Color(hex: preset.tintHex ?? "") ?? .accentColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 0) {
                Text(preset.name)
                    .font(.body)
                    .lineLimit(1)
                Text("\(preset.categories.count) categor\(preset.categories.count == 1 ? "y" : "ies") · \(preset.totalItems) items")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if state.settings.activePresetID == preset.id {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.secondary)
                    .imageScale(.small)
                    .help("Currently applied")
            }

            if let shortcutIndex {
                Text("⌘\(shortcutIndex)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(.quaternary.opacity(0.5)))
            }
        }
    }

    private var categoriesSummary: some View {
        HStack(spacing: 4) {
            ForEach(preset.categories.prefix(6)) { category in
                HStack(spacing: 3) {
                    Image(systemName: category.symbolName ?? "folder.fill")
                        .imageScale(.small)
                        .foregroundStyle(Color(hex: category.tintHex ?? "") ?? .secondary)
                    Text(category.name)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule().fill(.quaternary.opacity(0.4))
                )
            }
            if preset.categories.count > 6 {
                Text("+\(preset.categories.count - 6)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(.leading, 30)
        .padding(.top, 4)
    }

    @MainActor
    private func applyPreset() {
        Task { @MainActor in
            await state.applyPreset(preset, options: state.applyOptions(for: preset))
        }
    }
}

private struct MenuBarFooterButton: View {
    let symbol: String
    let title: String
    var trailing: String? = nil
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .frame(width: 18)
                    .foregroundStyle(.secondary)
                Text(title)
                Spacer()
                if let trailing {
                    Text(trailing)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                Rectangle().fill(isHovering ? Color.accentColor.opacity(0.12) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}
