import XCTest
@testable import DockFlow

final class CleanupMissingItemsTests: XCTestCase {
    private let validator = ValidationService()

    override func setUp() {
        super.setUp()
        validator.invalidateCache()
    }

    func test_removesMissingItemsAndKeepsSurvivors() {
        let missingURL = URL(fileURLWithPath: "/does-not-exist-\(UUID().uuidString).app", isDirectory: true)
        let existingURL = URL(fileURLWithPath: "/etc/hosts", isDirectory: false)

        var presets: [Preset] = [
            Preset(
                name: "Mix",
                categories: [
                    Category(name: "Apps", items: [
                        .app(url: missingURL, displayName: "Ghost"),
                        .file(url: existingURL, displayName: "hosts")
                    ])
                ]
            )
        ]

        let useCase = CleanupMissingItemsUseCase(validator: validator)
        let report = useCase.execute(presets: &presets)

        XCTAssertEqual(report.totalRemoved, 1)
        XCTAssertEqual(presets[0].categories[0].items.count, 1)
        XCTAssertEqual(presets[0].categories[0].items.first?.displayName, "hosts")
        XCTAssertEqual(report.removedByPreset[presets[0].id]?.first?.displayName, "Ghost")
    }

    func test_keepsSpacersAndWebLinksEvenIfTheyAreBroken() {
        var presets: [Preset] = [
            Preset(
                name: "Keepers",
                categories: [
                    Category(name: "Misc", items: [
                        .spacer(.smallSpacer),
                        .webLink(url: URL(string: "https://example.com")!)
                    ])
                ]
            )
        ]

        let useCase = CleanupMissingItemsUseCase(validator: validator)
        let report = useCase.execute(presets: &presets)

        XCTAssertTrue(report.isEmpty)
        XCTAssertEqual(presets[0].categories[0].items.count, 2)
    }

    func test_reportIsEmptyWhenNothingMissing() {
        var presets: [Preset] = [
            Preset(name: "Clean", categories: [
                Category(name: "A", items: [.file(url: URL(fileURLWithPath: "/etc/hosts"))])
            ])
        ]

        let useCase = CleanupMissingItemsUseCase(validator: validator)
        let report = useCase.execute(presets: &presets)
        XCTAssertTrue(report.isEmpty)
        XCTAssertFalse(presets[0].categories[0].items.isEmpty)
    }
}
