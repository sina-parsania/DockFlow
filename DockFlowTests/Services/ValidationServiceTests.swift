import XCTest
@testable import DockFlow

final class ValidationServiceTests: XCTestCase {
    private let validator = ValidationService()

    override func setUp() {
        super.setUp()
        validator.invalidateCache()
    }

    func test_existingFilePassesValidation() {
        let item = DockItem.file(url: URL(fileURLWithPath: "/etc/hosts"))
        XCTAssertEqual(validator.validate(item), .ok)
    }

    func test_missingFileReportsMissing() {
        let item = DockItem.file(url: URL(fileURLWithPath: "/definitely-not-there-\(UUID().uuidString)"))
        XCTAssertEqual(validator.validate(item), .missing)
    }

    func test_malformedWebURLFails() {
        let item = DockItem(
            kind: .url,
            displayName: "Bad",
            target: .webURL(URL(string: "about:blank")!)
        )
        XCTAssertEqual(validator.validate(item), .malformedURL)
    }

    func test_validHttpsURLPasses() {
        let item = DockItem.webLink(url: Fixtures.exampleURL)
        XCTAssertEqual(validator.validate(item), .ok)
    }

    func test_spacerAlwaysValid() {
        XCTAssertEqual(validator.validate(.spacer()), .ok)
    }

    func test_validateAllInPresetReturnsEntry() {
        let preset = Fixtures.makePreset()
        let result = validator.validateAll(in: preset)
        XCTAssertEqual(result.count, preset.totalItems)
    }
}
