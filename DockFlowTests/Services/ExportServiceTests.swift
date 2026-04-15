import XCTest
@testable import DockFlow

final class ExportServiceTests: XCTestCase {
    private var tempDir: URL!
    private var store: JSONPresetStore!
    private var exporter: ExportService!

    override func setUpWithError() throws {
        tempDir = Fixtures.tempDirectory(for: "ExportServiceTests")
        store = JSONPresetStore(fileURL: tempDir.appendingPathComponent("presets.json"))
        exporter = ExportService(store: store)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    func test_suggestedFileNameSanitizesInput() {
        let preset = Preset(name: "Work / Home : Blend")
        let name = exporter.suggestedFileName(for: preset)
        XCTAssertEqual(name, "Work - Home - Blend.dockflow.json")
    }

    func test_exportContainsOnlyThisPreset() throws {
        let preset = Fixtures.makePreset()
        let data = try exporter.exportPreset(preset)
        let string = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertTrue(string.contains(preset.name))
    }

    func test_importPresetRejectsInvalidData() {
        let data = "not json".data(using: .utf8)!
        XCTAssertThrowsError(try exporter.importPreset(from: data))
    }

    func test_importPresetAssignsFreshIdentifiers() throws {
        let original = Fixtures.makePreset()
        let data = try exporter.exportPreset(original)
        let imported = try exporter.importPreset(from: data)
        XCTAssertNotEqual(imported.id, original.id)
    }
}
