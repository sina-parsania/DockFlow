import Foundation

public struct MovePresetItemUseCase: Sendable {
    public init() {}

    /// Moves an item within the same category or across categories.
    /// Returns a new Preset with the mutation applied, or the original if the move is a no-op.
    public func execute(
        preset: Preset,
        itemID: DockItem.ID,
        toCategoryID: Category.ID,
        targetIndex: Int
    ) -> Preset {
        guard let source = preset.locate(itemID: itemID) else { return preset }
        guard let destIndex = preset.indexOf(categoryID: toCategoryID) else { return preset }

        var updated = preset
        let item = updated.categories[source.categoryIndex].items.remove(at: source.itemIndex)

        var adjustedTarget = max(0, targetIndex)
        if source.categoryIndex == destIndex && source.itemIndex < adjustedTarget {
            adjustedTarget -= 1
        }
        adjustedTarget = min(adjustedTarget, updated.categories[destIndex].items.count)

        updated.categories[destIndex].items.insert(item, at: adjustedTarget)
        updated.updatedAt = .now
        return updated
    }

    /// Reorders categories within a preset.
    public func moveCategory(
        preset: Preset,
        categoryID: Category.ID,
        toIndex: Int
    ) -> Preset {
        guard let fromIndex = preset.indexOf(categoryID: categoryID) else { return preset }
        var updated = preset
        let category = updated.categories.remove(at: fromIndex)
        var adjustedTarget = max(0, toIndex)
        if fromIndex < adjustedTarget { adjustedTarget -= 1 }
        adjustedTarget = min(adjustedTarget, updated.categories.count)
        updated.categories.insert(category, at: adjustedTarget)
        updated.updatedAt = .now
        return updated
    }

    public func deleteCategory(
        preset: Preset,
        categoryID: Category.ID,
        moveItemsTo destinationID: Category.ID?
    ) -> Preset {
        guard let fromIndex = preset.indexOf(categoryID: categoryID) else { return preset }
        var updated = preset
        let removed = updated.categories.remove(at: fromIndex)

        if let destinationID, let destIndex = updated.indexOf(categoryID: destinationID) {
            updated.categories[destIndex].items.append(contentsOf: removed.items)
        }
        updated.updatedAt = .now
        return updated
    }
}
