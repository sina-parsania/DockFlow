import Foundation
import SwiftUI
import Observation
import AppKit

public enum SearchItemFilter: String, CaseIterable, Hashable, Sendable {
    case all, apps, folders, files, urls, spacers, broken

    public var displayLabel: String {
        switch self {
        case .all:     return "All"
        case .apps:    return "Apps"
        case .folders: return "Folders"
        case .files:   return "Files"
        case .urls:    return "Web"
        case .spacers: return "Spacers"
        case .broken:  return "Broken"
        }
    }
}

public enum ApplyStatus: Equatable, Sendable {
    case idle
    case applying
    case succeeded(appliedAt: Date, appliedCount: Int, backupURL: URL?)
    case failed(message: String)
}

@Observable
public final class AppState {
    // MARK: - Dependencies

    public let store: PresetStoring
    public let dockService: DockServicing
    public let iconProvider: IconProviding
    public let validator: ValidationProviding
    public let exporter: ExportProviding
    public let hotkeyService: HotkeyService
    public let launchAtLogin: LaunchAtLoginService

    // MARK: - Published state

    public var presets: [Preset] = []
    public var settings: AppSettings = .default
    public var selectedPresetID: Preset.ID?
    public var selectedCategoryID: Category.ID?
    public var inspectorItemID: DockItem.ID?

    public var searchText: String = ""
    public var itemFilter: SearchItemFilter = .all

    public var applyStatus: ApplyStatus = .idle
    public var lastError: String?

    public var isInspectorVisible: Bool = true
    public var isFirstLaunch: Bool = false
    public var isOnboardingPresented: Bool = false
    public var isImportSheetPresented: Bool = false
    public var pendingConfirmation: ConfirmationRequest?

    // MARK: - Internal

    private let saveDebouncer = Debouncer(delay: 0.5, queue: .global(qos: .utility))
    public let undoManager = UndoManager()

    // MARK: - Init

    public init(
        store: PresetStoring,
        dockService: DockServicing,
        iconProvider: IconProviding,
        validator: ValidationProviding,
        exporter: ExportProviding,
        hotkeyService: HotkeyService,
        launchAtLogin: LaunchAtLoginService
    ) {
        self.store = store
        self.dockService = dockService
        self.iconProvider = iconProvider
        self.validator = validator
        self.exporter = exporter
        self.hotkeyService = hotkeyService
        self.launchAtLogin = launchAtLogin
    }

    public func setLaunchAtLogin(_ enabled: Bool) {
        let ok = launchAtLogin.setEnabled(enabled)
        if ok {
            settings.launchAtLogin = enabled
            persist()
        }
    }

    // MARK: - Bootstrapping

    @MainActor
    public func bootstrap() {
        AppPaths.ensureDirectoriesExist()
        do {
            let snapshot = try store.load()
            presets = snapshot.presets
            settings = snapshot.settings
            isFirstLaunch = !settings.firstLaunchCompleted
            if isFirstLaunch {
                isOnboardingPresented = true
            }
            if selectedPresetID == nil {
                selectedPresetID = settings.activePresetID ?? presets.first?.id
            }
            rebindHotkeys()
            Log.app.info("Loaded \(self.presets.count) presets")
        } catch {
            presets = []
            settings = .default
            lastError = error.localizedDescription
            Log.app.error("Failed to load snapshot: \(error.localizedDescription)")
        }
    }

    public func rebindHotkeys() {
        hotkeyService.start { [weak self] presetID in
            guard let self else { return }
            Task { @MainActor in
                guard let preset = self.preset(with: presetID) else { return }
                await self.applyPreset(preset, options: self.applyOptions(for: preset))
            }
        }
        for preset in presets {
            if let hotkey = preset.hotkey, hotkey.isValid {
                hotkeyService.register(presetID: preset.id, hotkey: hotkey)
            }
        }
    }

    // MARK: - Lookups

    public var selectedPreset: Preset? {
        guard let id = selectedPresetID else { return nil }
        return preset(with: id)
    }

    public func preset(with id: Preset.ID) -> Preset? {
        presets.first(where: { $0.id == id })
    }

    public func indexOfPreset(_ id: Preset.ID) -> Int? {
        presets.firstIndex(where: { $0.id == id })
    }

    public var filteredItemsInSelectedPreset: [(category: Category, item: DockItem)] {
        guard let preset = selectedPreset else { return [] }
        let needle = searchText.lowercased()
        var results: [(Category, DockItem)] = []
        for category in preset.categories {
            for item in category.items {
                if !matchesFilter(item: item) { continue }
                if !needle.isEmpty && !item.displayName.lowercased().contains(needle) { continue }
                results.append((category, item))
            }
        }
        return results
    }

    private func matchesFilter(item: DockItem) -> Bool {
        switch itemFilter {
        case .all:     return true
        case .apps:    return item.kind == .app
        case .folders: return item.kind == .folder
        case .files:   return item.kind == .file
        case .urls:    return item.kind == .url
        case .spacers: return item.kind.isSpacer
        case .broken:  return validator.validate(item).isProblem
        }
    }

    // MARK: - Preset mutations

    public func createPreset(named name: String = "New Preset") -> Preset {
        let preset = Preset(
            name: uniquePresetName(base: name),
            categories: [Category(name: "Apps", symbolName: "app.fill")]
        )
        registerUndo(
            action: { [weak self] in self?.removePreset(id: preset.id) },
            undo:   { [weak self] in self?.reinsert(preset: preset) }
        )
        presets.append(preset)
        selectedPresetID = preset.id
        selectedCategoryID = preset.categories.first?.id
        persist()
        return preset
    }

    public func removePreset(id: Preset.ID) {
        guard let index = indexOfPreset(id) else { return }
        let removed = presets.remove(at: index)
        if selectedPresetID == id {
            selectedPresetID = presets.first?.id
            selectedCategoryID = selectedPreset?.categories.first?.id
        }
        registerUndo(
            action: { [weak self] in self?.removePreset(id: removed.id) },
            undo:   { [weak self] in self?.reinsert(preset: removed, at: index) }
        )
        hotkeyService.unregister(presetID: id)
        persist()
    }

    public func duplicatePreset(id: Preset.ID) {
        guard let preset = preset(with: id) else { return }
        let copy = DuplicatePresetUseCase().execute(preset)
        presets.append(copy)
        selectedPresetID = copy.id
        persist()
    }

    public func reinsert(preset: Preset, at index: Int? = nil) {
        let insertAt = index ?? presets.count
        presets.insert(preset, at: min(insertAt, presets.count))
        persist()
    }

    public func renamePreset(id: Preset.ID, to newName: String) {
        guard let index = indexOfPreset(id) else { return }
        let old = presets[index].name
        let newValue = newName.isEmpty ? old : newName
        registerUndo(
            action: { [weak self] in self?.renamePreset(id: id, to: newValue) },
            undo:   { [weak self] in self?.renamePreset(id: id, to: old) }
        )
        presets[index].name = newValue
        presets[index].updatedAt = .now
        persist()
    }

    public func updatePreset(id: Preset.ID, mutate: (inout Preset) -> Void) {
        guard let index = indexOfPreset(id) else { return }
        var preset = presets[index]
        mutate(&preset)
        preset.updatedAt = .now
        presets[index] = preset
        persist()
    }

    public func reorderPresets(fromOffsets: IndexSet, toOffset: Int) {
        presets.move(fromOffsets: fromOffsets, toOffset: toOffset)
        persist()
    }

    // MARK: - Category mutations

    public func addCategory(to presetID: Preset.ID, named name: String = "New Group") {
        updatePreset(id: presetID) { preset in
            let category = Category(name: name, symbolName: "folder.fill")
            preset.categories.append(category)
            self.selectedCategoryID = category.id
        }
    }

    public func removeCategory(presetID: Preset.ID, categoryID: Category.ID, moveItemsTo: Category.ID?) {
        guard let presetIndex = indexOfPreset(presetID) else { return }
        let mover = MovePresetItemUseCase()
        let updated = mover.deleteCategory(
            preset: presets[presetIndex],
            categoryID: categoryID,
            moveItemsTo: moveItemsTo
        )
        let before = presets[presetIndex]
        registerUndo(
            action: { [weak self] in self?.presets[presetIndex] = updated },
            undo:   { [weak self] in self?.presets[presetIndex] = before }
        )
        presets[presetIndex] = updated
        if selectedCategoryID == categoryID {
            selectedCategoryID = updated.categories.first?.id
        }
        persist()
    }

    public func renameCategory(presetID: Preset.ID, categoryID: Category.ID, to newName: String) {
        updatePreset(id: presetID) { preset in
            guard let idx = preset.indexOf(categoryID: categoryID) else { return }
            preset.categories[idx].name = newName
        }
    }

    public func reorderCategories(presetID: Preset.ID, fromOffsets: IndexSet, toOffset: Int) {
        updatePreset(id: presetID) { preset in
            preset.categories.move(fromOffsets: fromOffsets, toOffset: toOffset)
        }
    }

    public func toggleCategoryCollapsed(presetID: Preset.ID, categoryID: Category.ID) {
        updatePreset(id: presetID) { preset in
            guard let idx = preset.indexOf(categoryID: categoryID) else { return }
            preset.categories[idx].isCollapsed.toggle()
        }
    }

    // MARK: - Item mutations

    public func addItem(_ item: DockItem, toCategoryID categoryID: Category.ID, inPresetID presetID: Preset.ID) {
        updatePreset(id: presetID) { preset in
            guard let idx = preset.indexOf(categoryID: categoryID) else { return }
            preset.categories[idx].items.append(item)
        }
    }

    public func removeItem(itemID: DockItem.ID, fromPresetID presetID: Preset.ID) {
        updatePreset(id: presetID) { preset in
            for i in preset.categories.indices {
                preset.categories[i].items.removeAll(where: { $0.id == itemID })
            }
        }
        if inspectorItemID == itemID { inspectorItemID = nil }
    }

    public func moveItem(
        itemID: DockItem.ID,
        inPresetID presetID: Preset.ID,
        toCategoryID: Category.ID,
        targetIndex: Int
    ) {
        guard let index = indexOfPreset(presetID) else { return }
        let mover = MovePresetItemUseCase()
        let updated = mover.execute(
            preset: presets[index],
            itemID: itemID,
            toCategoryID: toCategoryID,
            targetIndex: targetIndex
        )
        presets[index] = updated
        persist()
    }

    public func renameItem(itemID: DockItem.ID, inPresetID presetID: Preset.ID, to newName: String) {
        updatePreset(id: presetID) { preset in
            for i in preset.categories.indices {
                if let idx = preset.categories[i].indexOf(itemID: itemID) {
                    preset.categories[i].items[idx].displayName = newName
                    return
                }
            }
        }
    }

    // MARK: - Apply flow

    public func applyOptions(for preset: Preset) -> ApplyOptions {
        ApplyOptions(
            createBackup: settings.autoBackupBeforeApply,
            launchAssociatedApps: preset.autoLaunchApps || settings.launchAssociatedApps,
            skipMissingItems: true,
            restartCfprefsdOnFailure: settings.restartCfprefsdOnFailure
        )
    }

    @MainActor
    public func applyPreset(_ preset: Preset, options: ApplyOptions) async {
        applyStatus = .applying
        do {
            let useCase = ApplyPresetUseCase(dockService: dockService, validator: validator)
            let result = try await useCase.execute(preset: preset, options: options)
            if let index = indexOfPreset(preset.id) {
                presets[index].lastAppliedAt = .now
            }
            settings.firstLaunchCompleted = true
            settings.activePresetID = preset.id
            applyStatus = .succeeded(
                appliedAt: .now,
                appliedCount: result.appliedAppCount + result.appliedOtherCount,
                backupURL: result.backupURL
            )
            persist()
        } catch {
            applyStatus = .failed(message: error.localizedDescription)
            lastError = error.localizedDescription
            Log.dock.error("Apply failed: \(error.localizedDescription)")
        }
    }

    @MainActor
    public func restoreLatestBackup() async {
        do {
            try await dockService.restoreLatestBackup()
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - Import

    public func importCurrentDock(strategy: GroupingStrategy) {
        let useCase = ImportCurrentDockUseCase(dockService: dockService)
        let newPreset = useCase.execute(strategy: strategy)
        presets.append(newPreset)
        selectedPresetID = newPreset.id
        selectedCategoryID = newPreset.categories.first?.id
        persist()
    }

    // MARK: - Settings

    public func updateSettings(_ mutate: (inout AppSettings) -> Void) {
        mutate(&settings)
        persist()
    }

    public func completeOnboarding() {
        settings.firstLaunchCompleted = true
        isOnboardingPresented = false
        persist()
    }

    // MARK: - Persistence

    public func persist() {
        let snapshot = StoreSnapshot(version: 1, presets: presets, settings: settings)
        saveDebouncer.call { [store] in
            do {
                try store.save(snapshot)
            } catch {
                Log.store.error("Persist failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Utilities

    private func uniquePresetName(base: String) -> String {
        var candidate = base
        var counter = 2
        let existing = Set(presets.map(\.name))
        while existing.contains(candidate) {
            candidate = "\(base) \(counter)"
            counter += 1
        }
        return candidate
    }

    private func registerUndo(action: @escaping () -> Void, undo: @escaping () -> Void) {
        undoManager.registerUndo(withTarget: self) { state in
            undo()
            state.undoManager.registerUndo(withTarget: state) { _ in action() }
        }
    }
}

public struct ConfirmationRequest: Identifiable, Sendable {
    public let id = UUID()
    public let title: String
    public let message: String
    public let confirmLabel: String
    public let isDestructive: Bool
    public let confirm: @Sendable @MainActor () -> Void

    public init(
        title: String,
        message: String,
        confirmLabel: String,
        isDestructive: Bool = false,
        confirm: @escaping @Sendable @MainActor () -> Void
    ) {
        self.title = title
        self.message = message
        self.confirmLabel = confirmLabel
        self.isDestructive = isDestructive
        self.confirm = confirm
    }
}
