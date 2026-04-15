import SwiftUI

public struct ItemRow: View {
    @Bindable var state: AppState
    let presetID: Preset.ID
    let categoryID: Category.ID
    let item: DockItem

    public init(state: AppState, presetID: Preset.ID, categoryID: Category.ID, item: DockItem) {
        self.state = state
        self.presetID = presetID
        self.categoryID = categoryID
        self.item = item
    }

    public var body: some View {
        HStack(spacing: 10) {
            iconView
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(item.displayName)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .font(.body)
                    ValidationBadge(state: state.validator.validate(item))
                }
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer(minLength: 8)

            Button {
                state.inspectorItemID = item.id
                state.isInspectorVisible = true
            } label: {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Show details")

            Button(role: .destructive) {
                state.removeItem(itemID: item.id, fromPresetID: presetID)
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Remove item")
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(state.inspectorItemID == item.id ? Color.accentColor.opacity(0.1) : .clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            state.inspectorItemID = item.id
        }
        .contextMenu {
            contextMenu
        }
    }

    @ViewBuilder
    private var iconView: some View {
        if item.kind.isSpacer {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(.quaternary.opacity(0.6))
                Image(systemName: item.kind.symbolName)
                    .foregroundStyle(.secondary)
            }
        } else {
            Image(nsImage: state.iconProvider.icon(for: item))
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }

    private var subtitle: String {
        switch item.target {
        case .fileURL(let url): return url.path(percentEncoded: false)
        case .webURL(let url):  return url.absoluteString
        case .none:             return item.kind.displayLabel
        }
    }

    @ViewBuilder
    private var contextMenu: some View {
        Button("Show Info") {
            state.inspectorItemID = item.id
            state.isInspectorVisible = true
        }
        if let preset = state.preset(with: presetID) {
            Menu("Move to…") {
                ForEach(preset.categories.filter { $0.id != categoryID }) { category in
                    Button(category.name) {
                        state.moveItem(
                            itemID: item.id,
                            inPresetID: presetID,
                            toCategoryID: category.id,
                            targetIndex: category.items.count
                        )
                    }
                }
            }
        }
        Divider()
        Button("Remove", role: .destructive) {
            state.removeItem(itemID: item.id, fromPresetID: presetID)
        }
    }
}
