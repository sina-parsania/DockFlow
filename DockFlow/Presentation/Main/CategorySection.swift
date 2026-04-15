import SwiftUI

public struct CategorySection: View {
    @Bindable var state: AppState
    let presetID: Preset.ID
    let category: Category
    @State private var isRenaming = false
    @State private var draftName: String = ""
    @State private var deleteRequest: DeleteRequest?

    public init(state: AppState, presetID: Preset.ID, category: Category) {
        self.state = state
        self.presetID = presetID
        self.category = category
    }

    struct DeleteRequest: Identifiable {
        let id = UUID()
        let categoryID: Category.ID
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            header
            if !category.isCollapsed {
                if category.items.isEmpty {
                    placeholder
                } else {
                    ForEach(category.items) { item in
                        ItemRow(state: state, presetID: presetID, categoryID: category.id, item: item)
                    }
                }
                addItemMenu
            }
        }
        .padding(.vertical, 6)
        .confirmationDialog(
            "Delete category “\(category.name)”?",
            isPresented: Binding(
                get: { deleteRequest != nil },
                set: { if !$0 { deleteRequest = nil } }
            ),
            presenting: deleteRequest
        ) { _ in
            if !category.items.isEmpty, let otherCategory = otherCategories.first {
                Button("Move \(category.items.count) item\(category.items.count == 1 ? "" : "s") to \(otherCategory.name) and delete") {
                    state.removeCategory(presetID: presetID, categoryID: category.id, moveItemsTo: otherCategory.id)
                }
            }
            Button("Delete category and items", role: .destructive) {
                state.removeCategory(presetID: presetID, categoryID: category.id, moveItemsTo: nil)
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Button {
                state.toggleCategoryCollapsed(presetID: presetID, categoryID: category.id)
            } label: {
                Image(systemName: category.isCollapsed ? "chevron.right" : "chevron.down")
                    .frame(width: 14)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Image(systemName: category.symbolName ?? "folder.fill")
                .foregroundStyle(tint)

            if isRenaming {
                TextField("Name", text: $draftName, onCommit: commitRename)
                    .textFieldStyle(.roundedBorder)
                    .controlSize(.small)
                    .frame(maxWidth: 220)
            } else {
                Text(category.name)
                    .font(.headline)
                    .onTapGesture(count: 2) {
                        draftName = category.name
                        isRenaming = true
                    }
            }

            Text("\(category.items.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(.quaternary.opacity(0.4)))

            Spacer()

            Menu {
                Button("Rename") {
                    draftName = category.name
                    isRenaming = true
                }
                Menu("Symbol") {
                    ForEach(SymbolPickerView.defaultSymbols, id: \.self) { symbol in
                        Button {
                            state.updatePreset(id: presetID) { preset in
                                guard let idx = preset.indexOf(categoryID: category.id) else { return }
                                preset.categories[idx].symbolName = symbol
                            }
                        } label: {
                            Label(symbol, systemImage: symbol)
                        }
                    }
                }
                Divider()
                Button("Delete", role: .destructive) {
                    deleteRequest = DeleteRequest(categoryID: category.id)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
        }
    }

    private var otherCategories: [Category] {
        guard let preset = state.preset(with: presetID) else { return [] }
        return preset.categories.filter { $0.id != category.id }
    }

    private var tint: Color {
        if let hex = category.tintHex, let color = Color(hex: hex) { return color }
        return .secondary
    }

    private func commitRename() {
        state.renameCategory(presetID: presetID, categoryID: category.id, to: draftName)
        isRenaming = false
    }

    // MARK: - Content placeholders

    private var placeholder: some View {
        Text("Drop apps, folders, files, or URLs here.")
            .font(.callout)
            .foregroundStyle(.secondary)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(.quaternary, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            )
    }

    // MARK: - Add item menu

    private var addItemMenu: some View {
        HStack(spacing: 8) {
            Menu {
                Button("Add Apps…") { pickApps() }
                Button("Add Folder…") { pickFolders() }
                Button("Add File…") { pickFiles() }
                Button("Add Web Link…") { addURLPrompt() }
                Divider()
                Button("Add Small Spacer") { addSpacer(kind: .smallSpacer) }
                Button("Add Full Spacer") { addSpacer(kind: .spacer) }
                Button("Add Flex Spacer") { addSpacer(kind: .flexSpacer) }
            } label: {
                Label("Add Item", systemImage: "plus")
            }
            .menuStyle(.button)
            .controlSize(.small)

            Spacer()
        }
        .padding(.top, 4)
    }

    @MainActor
    private func pickApps() {
        let urls = FilePickerHelper.pick(.apps)
        for url in urls {
            let bundle = Bundle(url: url)
            let newItem = DockItem.app(
                url: url,
                bundleIdentifier: bundle?.bundleIdentifier,
                displayName: url.deletingPathExtension().lastPathComponent
            )
            state.addItem(newItem, toCategoryID: category.id, inPresetID: presetID)
        }
    }

    @MainActor
    private func pickFolders() {
        let urls = FilePickerHelper.pick(.folders)
        for url in urls {
            state.addItem(DockItem.folder(url: url), toCategoryID: category.id, inPresetID: presetID)
        }
    }

    @MainActor
    private func pickFiles() {
        let urls = FilePickerHelper.pick(.files)
        for url in urls {
            state.addItem(DockItem.file(url: url), toCategoryID: category.id, inPresetID: presetID)
        }
    }

    @MainActor
    private func addURLPrompt() {
        let alert = NSAlert()
        alert.messageText = "Add Web Link"
        alert.informativeText = "Enter a full URL (https://…)."
        alert.alertStyle = .informational
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 22))
        textField.placeholderString = "https://example.com"
        alert.accessoryView = textField
        alert.addButton(withTitle: "Add")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let trimmed = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), url.scheme != nil else { return }
        state.addItem(DockItem.webLink(url: url), toCategoryID: category.id, inPresetID: presetID)
    }

    private func addSpacer(kind: ItemKind) {
        state.addItem(DockItem.spacer(kind), toCategoryID: category.id, inPresetID: presetID)
    }
}
