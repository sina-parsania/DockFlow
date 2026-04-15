import XCTest
@testable import DockFlow

final class DockImporterTests: XCTestCase {
    private let importer = DockImporter()

    func test_mapAppTile() {
        let raw: [String: Any] = [
            "tile-type": "file-tile",
            "tile-data": [
                "file-label": "Safari",
                "file-type": 41,
                "bundle-identifier": "com.apple.Safari",
                "file-data": [
                    "_CFURLString": "file:///Applications/Safari.app/",
                    "_CFURLStringType": 15
                ] as [String: Any]
            ] as [String: Any]
        ]
        guard let item = importer.mapTile(raw) else { XCTFail("Expected item"); return }
        XCTAssertEqual(item.kind, .app)
        XCTAssertEqual(item.displayName, "Safari")
        XCTAssertEqual(item.bundleIdentifier, "com.apple.Safari")
    }

    func test_mapDirectoryTile() {
        let raw: [String: Any] = [
            "tile-type": "directory-tile",
            "tile-data": [
                "file-label": "Documents",
                "file-type": 2,
                "file-data": [
                    "_CFURLString": "file:///Users/me/Documents/",
                    "_CFURLStringType": 15
                ] as [String: Any]
            ] as [String: Any]
        ]
        guard let item = importer.mapTile(raw) else { XCTFail("Expected item"); return }
        XCTAssertEqual(item.kind, .folder)
    }

    func test_mapURLTile() {
        let raw: [String: Any] = [
            "tile-type": "url-tile",
            "tile-data": [
                "label": "Anthropic",
                "url": [
                    "_CFURLString": "https://www.anthropic.com",
                    "_CFURLStringType": 15
                ] as [String: Any]
            ] as [String: Any]
        ]
        guard let item = importer.mapTile(raw) else { XCTFail("Expected item"); return }
        XCTAssertEqual(item.kind, .url)
        if case .webURL(let url) = item.target {
            XCTAssertEqual(url.absoluteString, "https://www.anthropic.com")
        } else {
            XCTFail("Expected webURL target")
        }
    }

    func test_mapSpacerVariants() {
        XCTAssertEqual(importer.mapTile(["tile-type": "spacer-tile"])?.kind, .spacer)
        XCTAssertEqual(importer.mapTile(["tile-type": "small-spacer-tile"])?.kind, .smallSpacer)
        XCTAssertEqual(importer.mapTile(["tile-type": "flex-spacer-tile"])?.kind, .flexSpacer)
    }

    func test_mapUnknownTileReturnsNil() {
        XCTAssertNil(importer.mapTile(["tile-type": "alien-tile"]))
        XCTAssertNil(importer.mapTile([:]))
    }

    func test_fileTileWithExplicitFileTypeOne() {
        let raw: [String: Any] = [
            "tile-type": "file-tile",
            "tile-data": [
                "file-label": "report.pdf",
                "file-type": 1,
                "file-data": [
                    "_CFURLString": "file:///tmp/report.pdf",
                    "_CFURLStringType": 15
                ] as [String: Any]
            ] as [String: Any]
        ]
        let item = importer.mapTile(raw)
        XCTAssertEqual(item?.kind, .file)
    }
}
