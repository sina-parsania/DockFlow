import AppKit
import UniformTypeIdentifiers

public enum FilePickerHelper {
    public struct PickOptions {
        public var canChooseFiles: Bool = true
        public var canChooseDirectories: Bool = true
        public var allowsMultipleSelection: Bool = true
        public var contentTypes: [UTType] = []
        public var directoryURL: URL?

        public init(
            canChooseFiles: Bool = true,
            canChooseDirectories: Bool = true,
            allowsMultipleSelection: Bool = true,
            contentTypes: [UTType] = [],
            directoryURL: URL? = nil
        ) {
            self.canChooseFiles = canChooseFiles
            self.canChooseDirectories = canChooseDirectories
            self.allowsMultipleSelection = allowsMultipleSelection
            self.contentTypes = contentTypes
            self.directoryURL = directoryURL
        }

        public static let apps = PickOptions(
            canChooseFiles: true,
            canChooseDirectories: false,
            allowsMultipleSelection: true,
            contentTypes: [.application],
            directoryURL: URL(fileURLWithPath: "/Applications")
        )

        public static let folders = PickOptions(
            canChooseFiles: false,
            canChooseDirectories: true,
            allowsMultipleSelection: true
        )

        public static let files = PickOptions(
            canChooseFiles: true,
            canChooseDirectories: false,
            allowsMultipleSelection: true
        )
    }

    @MainActor
    public static func pick(_ options: PickOptions) -> [URL] {
        let panel = NSOpenPanel()
        panel.canChooseFiles = options.canChooseFiles
        panel.canChooseDirectories = options.canChooseDirectories
        panel.allowsMultipleSelection = options.allowsMultipleSelection
        panel.canCreateDirectories = false
        panel.treatsFilePackagesAsDirectories = false
        if !options.contentTypes.isEmpty {
            panel.allowedContentTypes = options.contentTypes
        }
        if let directoryURL = options.directoryURL {
            panel.directoryURL = directoryURL
        }
        return panel.runModal() == .OK ? panel.urls : []
    }

    @MainActor
    public static func pickSaveLocation(defaultName: String, contentType: UTType = .json) -> URL? {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [contentType]
        panel.nameFieldStringValue = defaultName
        panel.canCreateDirectories = true
        return panel.runModal() == .OK ? panel.url : nil
    }
}
