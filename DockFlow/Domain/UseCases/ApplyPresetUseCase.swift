import Foundation
import AppKit

public struct ApplyPresetUseCase: Sendable {
    private let dockService: DockServicing
    private let validator: ValidationProviding

    public init(
        dockService: DockServicing,
        validator: ValidationProviding
    ) {
        self.dockService = dockService
        self.validator = validator
    }

    public func execute(
        preset: Preset,
        options: ApplyOptions
    ) async throws -> ApplyResult {
        let validationResults = validator.validateAll(in: preset)
        let missingItemIDs = validationResults
            .filter { $0.value == .missing || $0.value == .inaccessible }
            .map(\.key)

        let filteredPreset: Preset
        if options.skipMissingItems, !missingItemIDs.isEmpty {
            filteredPreset = stripMissing(preset: preset, missingIDs: Set(missingItemIDs))
        } else {
            filteredPreset = preset
        }

        let layout = DockBuilder.build(preset: filteredPreset)
        var result = try await dockService.apply(layout: layout, options: options)

        if options.launchAssociatedApps {
            await launchApps(in: filteredPreset)
        }

        let warnings = buildWarnings(validationResults: validationResults)
        result = ApplyResult(
            backupID: result.backupID,
            backupURL: result.backupURL,
            appliedAppCount: result.appliedAppCount,
            appliedOtherCount: result.appliedOtherCount,
            missingItemIDs: missingItemIDs,
            warnings: warnings
        )
        return result
    }

    // MARK: - Private

    private func stripMissing(preset: Preset, missingIDs: Set<DockItem.ID>) -> Preset {
        var copy = preset
        copy.categories = copy.categories.map { category in
            var updated = category
            updated.items = category.items.filter { !missingIDs.contains($0.id) }
            return updated
        }
        return copy
    }

    private func launchApps(in preset: Preset) async {
        let urls = preset.allItems.compactMap { item -> URL? in
            guard item.kind == .app, case .fileURL(let url) = item.target else { return nil }
            return url
        }
        await MainActor.run {
            let workspace = NSWorkspace.shared
            let running = Set(workspace.runningApplications.compactMap(\.bundleIdentifier))
            let config = NSWorkspace.OpenConfiguration()
            config.activates = false
            for url in urls {
                if let bundle = Bundle(url: url),
                   let bundleID = bundle.bundleIdentifier,
                   running.contains(bundleID) {
                    continue
                }
                workspace.openApplication(at: url, configuration: config) { _, error in
                    if let error {
                        Log.dock.warning("Failed to launch \(url.lastPathComponent): \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func buildWarnings(validationResults: [DockItem.ID: ValidationState]) -> [String] {
        validationResults
            .filter { $0.value.isProblem }
            .map { "Item \($0.key.uuidString.prefix(8)) had status \($0.value.displayLabel)" }
    }
}
