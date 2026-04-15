import XCTest
@testable import DockFlow

final class DockBuilderTests: XCTestCase {

    func test_buildPlacesAppsAndOthersInCorrectLists() {
        let preset = Fixtures.makePreset()
        let layout = DockBuilder.build(preset: preset)

        // 3 apps in category 1 + small-spacer separators between Apps/Docs and Docs/Web that produce
        // tiles on the apps side only when the preceding category had apps.
        // Apps list: 3 apps + 1 small-spacer after Apps (since next category Docs has items).
        XCTAssertEqual(layout.apps.count, 3 + 1)
        // Others list: 2 Docs items + 1 small-spacer after Docs (since Web has items) + 1 URL.
        XCTAssertEqual(layout.others.count, 2 + 1 + 1)
    }

    func test_separatorsAreOmittedAfterLastCategory() {
        let preset = Preset(
            name: "Two groups",
            categories: [
                Category(name: "A", items: [.app(url: Fixtures.safariURL)]),
                Category(name: "B", items: [.app(url: Fixtures.terminalURL)])
            ],
            separatorStyle: .small
        )
        let layout = DockBuilder.build(preset: preset)

        // 2 apps + exactly one separator between them, none at the end.
        XCTAssertEqual(layout.apps.count, 3)
        if case .spacer(let kind) = layout.apps[1] {
            XCTAssertEqual(kind, .small)
        } else {
            XCTFail("Expected spacer between categories")
        }
    }

    func test_separatorStyleNoneDoesNotEmitSpacers() {
        let preset = Preset(
            name: "No sep",
            categories: [
                Category(name: "A", items: [.app(url: Fixtures.safariURL)]),
                Category(name: "B", items: [.app(url: Fixtures.terminalURL)])
            ],
            separatorStyle: .none
        )
        let layout = DockBuilder.build(preset: preset)
        XCTAssertEqual(layout.apps.count, 2)
    }

    func test_emptyPresetProducesEmptyLayout() {
        let preset = Preset(name: "Empty")
        let layout = DockBuilder.build(preset: preset)
        XCTAssertTrue(layout.isEmpty)
    }

    func test_spacerOnlyCategoryEmitsSpacerInAppsList() {
        let preset = Preset(
            name: "Spacer-only",
            categories: [
                Category(name: "Spacers", items: [.spacer(.flexSpacer)])
            ],
            separatorStyle: .none
        )
        let layout = DockBuilder.build(preset: preset)
        XCTAssertEqual(layout.apps.count, 1)
        XCTAssertEqual(layout.others.count, 0)
        if case .spacer(let kind) = layout.apps[0] {
            XCTAssertEqual(kind, .flex)
        } else {
            XCTFail("Expected flex spacer")
        }
    }

    func test_separatorIsNotInsertedForEmptyCategories() {
        let preset = Preset(
            name: "Empty middle",
            categories: [
                Category(name: "A", items: [.app(url: Fixtures.safariURL)]),
                Category(name: "Empty", items: []),
                Category(name: "B", items: [.app(url: Fixtures.terminalURL)])
            ],
            separatorStyle: .small
        )
        let layout = DockBuilder.build(preset: preset)
        // Empty middle category → no tiles, no separator from it. Separator between A and B still emitted after A.
        XCTAssertEqual(layout.apps.count, 3)
    }

    func test_categoriesAreDeterministic() {
        let preset = Fixtures.makePreset()
        let a = DockBuilder.build(preset: preset)
        let b = DockBuilder.build(preset: preset)
        XCTAssertEqual(a, b)
    }

    func test_tileForAppContainsFileType41() {
        let item = DockItem.app(url: Fixtures.safariURL, bundleIdentifier: "com.apple.Safari")
        guard let tile = DockBuilder.tile(for: item), case .app(let appTile) = tile else {
            XCTFail("Expected app tile"); return
        }
        let dict = appTile.rawDictionary
        let data = dict["tile-data"] as? [String: Any]
        XCTAssertEqual(data?["file-type"] as? Int, 41)
        XCTAssertEqual(data?["bundle-identifier"] as? String, "com.apple.Safari")
    }

    func test_tileForFolderHasTrailingSlashInURL() {
        let item = DockItem.folder(url: Fixtures.documentsURL)
        guard let tile = DockBuilder.tile(for: item), case .directory(let dirTile) = tile else {
            XCTFail("Expected directory tile"); return
        }
        let dict = dirTile.rawDictionary
        let data = dict["tile-data"] as? [String: Any]
        let fileData = data?["file-data"] as? [String: Any]
        let urlString = fileData?["_CFURLString"] as? String ?? ""
        XCTAssertTrue(urlString.hasSuffix("/"))
    }

    func test_tileForURLUsesUrlTileShape() {
        let item = DockItem.webLink(url: Fixtures.exampleURL, displayName: "Example")
        guard let tile = DockBuilder.tile(for: item), case .url(let urlTile) = tile else {
            XCTFail("Expected url tile"); return
        }
        let dict = urlTile.rawDictionary
        XCTAssertEqual(dict["tile-type"] as? String, "url-tile")
        let data = dict["tile-data"] as? [String: Any]
        XCTAssertEqual(data?["label"] as? String, "Example")
    }
}
