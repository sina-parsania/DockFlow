import XCTest
@testable import DockFlow

final class DuplicatePresetTests: XCTestCase {
    func test_duplicateAssignsFreshIdentifiers() {
        let preset = Fixtures.makePreset()
        let copy = DuplicatePresetUseCase().execute(preset)

        XCTAssertNotEqual(copy.id, preset.id)
        XCTAssertEqual(copy.categories.count, preset.categories.count)

        for (a, b) in zip(copy.categories, preset.categories) {
            XCTAssertNotEqual(a.id, b.id)
            XCTAssertEqual(a.items.count, b.items.count)
            for (itemA, itemB) in zip(a.items, b.items) {
                XCTAssertNotEqual(itemA.id, itemB.id)
                XCTAssertEqual(itemA.displayName, itemB.displayName)
            }
        }
    }

    func test_duplicateAppendsCopySuffixAndClearsHotkey() {
        var preset = Fixtures.makePreset()
        preset.hotkey = Hotkey(keyCode: 4, modifiers: 256)
        let copy = DuplicatePresetUseCase().execute(preset)
        XCTAssertEqual(copy.name, preset.name + " Copy")
        XCTAssertNil(copy.hotkey)
        XCTAssertNil(copy.lastAppliedAt)
    }
}
