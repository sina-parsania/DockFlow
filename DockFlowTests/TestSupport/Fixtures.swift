import Foundation
@testable import DockFlow

public enum Fixtures {
    public static let safariURL = URL(fileURLWithPath: "/Applications/Safari.app", isDirectory: true)
    public static let terminalURL = URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app", isDirectory: true)
    public static let finderURL = URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app", isDirectory: true)
    public static let documentsURL = URL(fileURLWithPath: NSHomeDirectory() + "/Documents", isDirectory: true)
    public static let reportURL = URL(fileURLWithPath: "/tmp/dockflow-report.pdf", isDirectory: false)
    public static let exampleURL = URL(string: "https://example.com")!

    public static func makePreset() -> Preset {
        // Use a fixed instant rounded to the second so Codable round-trips are exact.
        let fixedDate = Date(timeIntervalSince1970: 1_764_844_800)
        return Preset(
            name: "Workday",
            categories: [
                Category(name: "Apps", symbolName: "app.fill", items: [
                    .app(url: safariURL, bundleIdentifier: "com.apple.Safari"),
                    .app(url: terminalURL, bundleIdentifier: "com.apple.Terminal"),
                    .app(url: finderURL, bundleIdentifier: "com.apple.finder")
                ]),
                Category(name: "Docs", items: [
                    .folder(url: documentsURL),
                    .file(url: reportURL)
                ]),
                Category(name: "Web", items: [
                    .webLink(url: exampleURL, displayName: "Example")
                ])
            ],
            createdAt: fixedDate,
            updatedAt: fixedDate
        )
    }

    public static func tempDirectory(for test: String = #function) -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("dockflow-test-\(test)-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
