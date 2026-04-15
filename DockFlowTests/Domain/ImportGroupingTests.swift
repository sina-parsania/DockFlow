import XCTest
@testable import DockFlow

final class ImportGroupingTests: XCTestCase {

    func test_byTypeBuildsBuckets() {
        let items: [DockItem] = [
            .app(url: Fixtures.safariURL),
            .app(url: Fixtures.terminalURL),
            .folder(url: Fixtures.documentsURL),
            .webLink(url: Fixtures.exampleURL),
            .file(url: Fixtures.reportURL),
            .spacer(.smallSpacer)
        ]
        let categories = ImportCurrentDockUseCase.buildTypeCategories(items: items)
        let names = categories.map(\.name)
        XCTAssertEqual(Set(names), Set(["Apps", "Folders", "Files", "Web", "Spacers"]))
        XCTAssertEqual(categories.first(where: { $0.name == "Apps" })?.items.count, 2)
        XCTAssertEqual(categories.first(where: { $0.name == "Web" })?.items.count, 1)
    }

    func test_byTypeDropsEmptyBuckets() {
        let items: [DockItem] = [.app(url: Fixtures.safariURL)]
        let categories = ImportCurrentDockUseCase.buildTypeCategories(items: items)
        XCTAssertEqual(categories.count, 1)
        XCTAssertEqual(categories[0].name, "Apps")
    }
}
