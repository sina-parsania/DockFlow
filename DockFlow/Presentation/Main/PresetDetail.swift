import SwiftUI

public struct PresetDetail: View {
    @Bindable var state: AppState

    public init(state: AppState) {
        self.state = state
    }

    public var body: some View {
        Group {
            if let preset = state.selectedPreset {
                presetContent(preset)
            } else {
                EmptyStateView(
                    symbol: "square.stack.3d.up",
                    title: "No Preset Selected",
                    message: "Create your first preset or import your current Dock to get started.",
                    actionTitle: "New Preset",
                    action: { _ = state.createPreset() }
                )
            }
        }
    }

    @ViewBuilder
    private func presetContent(_ preset: Preset) -> some View {
        VStack(spacing: 0) {
            toolbar(preset)
            Divider()
            cleanupBanner().padding(.horizontal, 12).padding(.top, 12)
            statusBanner().padding(.horizontal, 12).padding(.top, 12)
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if preset.categories.isEmpty {
                        EmptyStateView(
                            symbol: "folder.badge.plus",
                            title: "No Categories Yet",
                            message: "Categories let you group apps, folders, files, and links into logical sections that become visually separated regions in your dock.",
                            actionTitle: "Add Category",
                            action: { state.addCategory(to: preset.id) }
                        )
                    } else {
                        ForEach(preset.categories) { category in
                            CategorySection(state: state, presetID: preset.id, category: category)
                        }
                    }
                }
                .padding(20)
            }
        }
    }

    @ViewBuilder
    private func cleanupBanner() -> some View {
        if let report = state.lastCleanupReport, !report.isEmpty {
            StatusBanner(
                style: .warning,
                title: "Removed \(report.totalRemoved) missing item\(report.totalRemoved == 1 ? "" : "s")",
                message: summarize(report),
                action: (title: "Dismiss", handler: { state.dismissCleanupReport() })
            )
        }
    }

    private func summarize(_ report: CleanupMissingItemsUseCase.Report) -> String {
        let pairs = report.removedByPreset.flatMap { (presetID, items) -> [String] in
            guard let presetName = state.preset(with: presetID)?.name else { return [] }
            return items.map { "\($0.displayName) · \(presetName) › \($0.categoryName)" }
        }
        return pairs.prefix(5).joined(separator: "\n") + (pairs.count > 5 ? "\n…and \(pairs.count - 5) more" : "")
    }

    @ViewBuilder
    private func statusBanner() -> some View {
        switch state.applyStatus {
        case .idle:
            EmptyView()
        case .applying:
            StatusBanner(style: .info, title: "Applying preset…", message: nil)
        case .succeeded(_, let count, _):
            StatusBanner(
                style: .success,
                title: "Applied \(count) item\(count == 1 ? "" : "s") to the Dock",
                message: "A backup was saved if enabled in Settings."
            )
        case .failed(let message):
            StatusBanner(
                style: .error,
                title: "Apply failed",
                message: message,
                action: (title: "Restore backup", handler: {
                    Task { @MainActor in await state.restoreLatestBackup() }
                })
            )
        }
    }

    private func toolbar(_ preset: Preset) -> some View {
        HStack(spacing: 10) {
            Image(systemName: preset.symbolName ?? "square.stack.3d.up.fill")
                .foregroundStyle(Color(hex: preset.tintHex ?? "") ?? .accentColor)

            TextField(
                "Preset name",
                text: Binding(
                    get: { preset.name },
                    set: { state.renamePreset(id: preset.id, to: $0) }
                )
            )
            .textFieldStyle(.plain)
            .font(.title3)
            .fontWeight(.semibold)

            Spacer()

            Button {
                state.addCategory(to: preset.id)
            } label: {
                Label("New Category", systemImage: "folder.badge.plus")
            }
            .controlSize(.small)

            Button {
                Task { @MainActor in
                    await state.applyPreset(preset, options: state.applyOptions(for: preset))
                }
            } label: {
                Label("Apply", systemImage: "arrow.up.forward.app.fill")
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .disabled(state.applyStatus == .applying)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}
