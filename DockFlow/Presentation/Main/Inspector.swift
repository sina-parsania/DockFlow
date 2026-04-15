import SwiftUI

public struct Inspector: View {
    @Bindable var state: AppState
    let presetID: Preset.ID

    public init(state: AppState, presetID: Preset.ID) {
        self.state = state
        self.presetID = presetID
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            Divider()
            content
            Spacer()
        }
        .padding(16)
        .frame(minWidth: 260)
    }

    private var header: some View {
        HStack {
            Text("Details").font(.headline)
            Spacer()
            Button {
                state.isInspectorVisible = false
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var content: some View {
        if let item = resolvedItem {
            itemDetails(for: item)
        } else if let preset = state.preset(with: presetID) {
            presetDetails(for: preset)
        } else {
            EmptyStateView(
                symbol: "sidebar.right",
                title: "Nothing Selected",
                message: "Pick an item from a category to see its details, or a preset for its apply options."
            )
        }
    }

    private var resolvedItem: DockItem? {
        guard
            let id = state.inspectorItemID,
            let preset = state.preset(with: presetID)
        else { return nil }
        return preset.allItems.first(where: { $0.id == id })
    }

    // MARK: - Item details

    @ViewBuilder
    private func itemDetails(for item: DockItem) -> some View {
        HStack(spacing: 12) {
            Image(nsImage: state.iconProvider.icon(for: item))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48, height: 48)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayName).font(.headline)
                Text(item.kind.displayLabel)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }

        LabeledRow("Status") {
            let validation = state.validator.validate(item)
            HStack(spacing: 4) {
                Image(systemName: validation.symbolName)
                    .foregroundStyle(validation.isProblem ? Color.orange : Color.green)
                Text(validation.displayLabel)
            }
        }

        LabeledRow("Location") {
            Text(item.target.displayPath)
                .lineLimit(3)
                .textSelection(.enabled)
        }

        if let bundleID = item.bundleIdentifier {
            LabeledRow("Bundle ID") {
                Text(bundleID).textSelection(.enabled)
            }
        }

        HStack {
            Button("Reveal in Finder") { revealInFinder(item: item) }
                .disabled(item.target.url == nil || item.kind == .url)
            Button("Re-target…") { retarget(item: item) }
                .disabled(item.kind.isSpacer)
        }
    }

    @MainActor
    private func revealInFinder(item: DockItem) {
        guard case .fileURL(let url) = item.target else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    @MainActor
    private func retarget(item: DockItem) {
        let urls = FilePickerHelper.pick(
            FilePickerHelper.PickOptions(
                canChooseFiles: true,
                canChooseDirectories: true,
                allowsMultipleSelection: false
            )
        )
        guard let url = urls.first else { return }
        state.updatePreset(id: presetID) { preset in
            for i in preset.categories.indices {
                if let idx = preset.categories[i].indexOf(itemID: item.id) {
                    preset.categories[i].items[idx].target = .fileURL(url)
                    return
                }
            }
        }
        state.validator.invalidateCache()
    }

    // MARK: - Preset details

    @ViewBuilder
    private func presetDetails(for preset: Preset) -> some View {
        LabeledRow("Name") {
            TextField("Name", text: Binding(
                get: { preset.name },
                set: { state.renamePreset(id: preset.id, to: $0) }
            ))
        }

        LabeledRow("Symbol") {
            Menu {
                ForEach(SymbolPickerView.defaultSymbols, id: \.self) { symbol in
                    Button {
                        state.updatePreset(id: preset.id) { $0.symbolName = symbol }
                    } label: {
                        Label(symbol, systemImage: symbol)
                    }
                }
            } label: {
                Image(systemName: preset.symbolName ?? "square.stack.3d.up.fill")
            }
            .menuStyle(.button)
        }

        LabeledRow("Tint") {
            ColorSwatchPicker(selectionHex: Binding(
                get: { preset.tintHex },
                set: { hex in state.updatePreset(id: preset.id) { $0.tintHex = hex } }
            ))
        }

        LabeledRow("Separator") {
            Picker("", selection: Binding(
                get: { preset.separatorStyle },
                set: { style in state.updatePreset(id: preset.id) { $0.separatorStyle = style } }
            )) {
                ForEach(SeparatorStyle.allCases, id: \.self) { style in
                    Text(style.displayLabel).tag(style)
                }
            }
            .labelsHidden()
        }

        LabeledRow("Launch apps on apply") {
            Toggle("", isOn: Binding(
                get: { preset.autoLaunchApps },
                set: { value in state.updatePreset(id: preset.id) { $0.autoLaunchApps = value } }
            ))
            .labelsHidden()
        }

        LabeledRow("Items") {
            Text("\(preset.totalItems) across \(preset.categories.count) categor\(preset.categories.count == 1 ? "y" : "ies")")
                .foregroundStyle(.secondary)
        }

        if let lastApplied = preset.lastAppliedAt {
            LabeledRow("Last applied") {
                Text(lastApplied, format: .relative(presentation: .named))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct LabeledRow<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    init(_ title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            content()
        }
    }
}
