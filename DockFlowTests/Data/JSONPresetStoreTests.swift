import XCTest
@testable import DockFlow

final class JSONPresetStoreTests: XCTestCase {
    private var tempDir: URL!
    private var store: JSONPresetStore!

    override func setUpWithError() throws {
        tempDir = Fixtures.tempDirectory(for: "JSONPresetStoreTests")
        store = JSONPresetStore(fileURL: tempDir.appendingPathComponent("presets.json"))
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    func test_loadWithoutFileReturnsDefaults() throws {
        let snapshot = try store.load()
        XCTAssertEqual(snapshot.presets.count, 0)
        XCTAssertEqual(snapshot.version, 1)
    }

    func test_saveAndLoadRoundTrip() throws {
        let original = StoreSnapshot(
            presets: [Fixtures.makePreset()],
            settings: AppSettings(launchAssociatedApps: true)
        )
        try store.save(original)
        let loaded = try store.load()
        XCTAssertEqual(loaded.presets.count, 1)
        XCTAssertEqual(loaded.presets[0].name, "Workday")
        XCTAssertEqual(loaded.settings.launchAssociatedApps, true)
    }

    func test_corruptedFileThrows() throws {
        let url = tempDir.appendingPathComponent("presets.json")
        try "not json".data(using: .utf8)?.write(to: url)
        XCTAssertThrowsError(try store.load()) { error in
            guard case PresetStoreError.corrupted = error else {
                XCTFail("Expected corrupted error, got \(error)")
                return
            }
        }
    }

    func test_exportImportRoundTripAssignsNewID() throws {
        let original = Fixtures.makePreset()
        let data = try store.exportPreset(original)
        let imported = try store.importPreset(from: data)
        XCTAssertNotEqual(imported.id, original.id)
        XCTAssertEqual(imported.name, original.name)
        XCTAssertEqual(imported.categories.count, original.categories.count)
    }

    func test_importRejectsUnsupportedVersion() throws {
        let invalidWrapper: [String: Any] = [
            "version": 999,
            "preset": [
                "id": UUID().uuidString,
                "name": "From future",
                "categories": [],
                "createdAt": "2026-01-01T00:00:00Z",
                "updatedAt": "2026-01-01T00:00:00Z",
                "autoLaunchApps": false,
                "separatorStyle": "small"
            ] as [String: Any]
        ]
        let data = try JSONSerialization.data(withJSONObject: invalidWrapper)
        XCTAssertThrowsError(try store.importPreset(from: data)) { error in
            guard case ExportError.unsupportedVersion(let version) = error else {
                XCTFail("Expected unsupportedVersion error, got \(error)")
                return
            }
            XCTAssertEqual(version, 999)
        }
    }
}
