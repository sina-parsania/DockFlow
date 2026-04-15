import XCTest
@testable import DockFlow

final class PresetCodableTests: XCTestCase {
    private func encoder() -> JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }

    private func decoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    func test_presetRoundTrip() throws {
        let original = Fixtures.makePreset()
        let data = try encoder().encode(original)
        let decoded = try decoder().decode(Preset.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func test_itemTargetEncodesFileURL() throws {
        let target: ItemTarget = .fileURL(Fixtures.safariURL)
        let data = try encoder().encode(target)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertTrue(json.contains("fileURL"))
        XCTAssertTrue(json.contains("Safari.app"))
    }

    func test_itemTargetEncodesWebURL() throws {
        let target: ItemTarget = .webURL(Fixtures.exampleURL)
        let data = try encoder().encode(target)
        let decoded = try decoder().decode(ItemTarget.self, from: data)
        XCTAssertEqual(decoded, .webURL(Fixtures.exampleURL))
    }

    func test_itemTargetEncodesNone() throws {
        let target: ItemTarget = .none
        let data = try encoder().encode(target)
        let decoded = try decoder().decode(ItemTarget.self, from: data)
        XCTAssertEqual(decoded, .none)
    }

    func test_allItemKindsRoundTrip() throws {
        let items: [DockItem] = [
            .app(url: Fixtures.safariURL),
            .folder(url: Fixtures.documentsURL),
            .file(url: Fixtures.reportURL),
            .webLink(url: Fixtures.exampleURL),
            .spacer(.spacer),
            .spacer(.smallSpacer),
            .spacer(.flexSpacer)
        ]
        let data = try encoder().encode(items)
        let decoded = try decoder().decode([DockItem].self, from: data)
        XCTAssertEqual(decoded, items)
    }
}
