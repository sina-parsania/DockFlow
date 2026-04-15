import XCTest
@testable import DockFlow

final class CategoryOrderingTests: XCTestCase {
    private let mover = MovePresetItemUseCase()

    func test_moveItemAcrossCategoriesMaintainsTargetIndex() {
        let preset = Fixtures.makePreset()
        let itemToMove = preset.categories[0].items[1] // Terminal
        let targetCategoryID = preset.categories[1].id // Docs

        let updated = mover.execute(
            preset: preset,
            itemID: itemToMove.id,
            toCategoryID: targetCategoryID,
            targetIndex: 0
        )

        XCTAssertEqual(updated.categories[0].items.count, 2)
        XCTAssertEqual(updated.categories[1].items.first?.id, itemToMove.id)
        XCTAssertEqual(updated.categories[1].items.count, 3)
    }

    func test_moveItemWithinSameCategoryAdjustsIndex() {
        let preset = Fixtures.makePreset()
        let firstCategoryID = preset.categories[0].id
        let last = preset.categories[0].items.last!

        let updated = mover.execute(
            preset: preset,
            itemID: last.id,
            toCategoryID: firstCategoryID,
            targetIndex: 0
        )

        XCTAssertEqual(updated.categories[0].items.first?.id, last.id)
        XCTAssertEqual(updated.categories[0].items.count, 3)
    }

    func test_reorderCategories() {
        let preset = Fixtures.makePreset()
        let webID = preset.categories[2].id
        let updated = mover.moveCategory(preset: preset, categoryID: webID, toIndex: 0)
        XCTAssertEqual(updated.categories[0].id, webID)
    }

    func test_deleteCategoryWithReassignmentMovesItems() {
        let preset = Fixtures.makePreset()
        let docsID = preset.categories[1].id
        let appsID = preset.categories[0].id
        let docsItemCount = preset.categories[1].items.count

        let updated = mover.deleteCategory(
            preset: preset,
            categoryID: docsID,
            moveItemsTo: appsID
        )

        XCTAssertEqual(updated.categories.count, 2)
        XCTAssertEqual(
            updated.categories.first(where: { $0.id == appsID })?.items.count,
            preset.categories.first(where: { $0.id == appsID })!.items.count + docsItemCount
        )
    }

    func test_deleteCategoryWithoutReassignmentDropsItems() {
        let preset = Fixtures.makePreset()
        let docsID = preset.categories[1].id
        let updated = mover.deleteCategory(preset: preset, categoryID: docsID, moveItemsTo: nil)
        XCTAssertEqual(updated.categories.count, 2)
        XCTAssertFalse(updated.categories.contains(where: { $0.id == docsID }))
    }
}
