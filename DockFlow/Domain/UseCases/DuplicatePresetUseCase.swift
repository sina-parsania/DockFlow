import Foundation

public struct DuplicatePresetUseCase: Sendable {
    public init() {}

    public func execute(_ preset: Preset) -> Preset {
        var copy = preset
        copy.id = UUID()
        copy.name = preset.name + " Copy"
        copy.createdAt = .now
        copy.updatedAt = .now
        copy.lastAppliedAt = nil
        copy.hotkey = nil
        copy.categories = preset.categories.map { category in
            var cat = category
            cat.id = UUID()
            cat.items = category.items.map { item in
                var newItem = item
                newItem.id = UUID()
                return newItem
            }
            return cat
        }
        return copy
    }
}
