import Foundation
import AppKit

/// Thin passthrough to `NSWorkspace`. Does NOT cache — every call returns
/// whatever macOS currently renders for that file, so changes on disk
/// (app updates, replaced icons, moved files) show up immediately.
public final class IconService: IconProviding, @unchecked Sendable {
    private let workspace: NSWorkspace
    private let iconSize: NSSize

    public init(workspace: NSWorkspace = .shared, iconSize: NSSize = NSSize(width: 64, height: 64)) {
        self.workspace = workspace
        self.iconSize = iconSize
    }

    public func icon(for item: DockItem) -> NSImage {
        switch item.target {
        case .fileURL(let url):
            return icon(forFilePath: url.path(percentEncoded: false))
        case .webURL:
            return symbolFallback(item.kind.symbolName)
        case .none:
            return symbolFallback(item.kind.symbolName)
        }
    }

    public func icon(forFilePath path: String) -> NSImage {
        let image = workspace.icon(forFile: path)
        image.size = iconSize
        return image
    }

    public func icon(forBundleIdentifier bundleID: String) -> NSImage? {
        guard let url = workspace.urlForApplication(withBundleIdentifier: bundleID) else { return nil }
        return icon(forFilePath: url.path(percentEncoded: false))
    }

    public func clearCache() {
        // No-op. This service does not cache. Kept to satisfy the protocol
        // and for any UI affordance that wants to "refresh icons".
    }

    private func symbolFallback(_ symbolName: String) -> NSImage {
        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) {
            let config = NSImage.SymbolConfiguration(pointSize: 32, weight: .regular)
            return image.withSymbolConfiguration(config) ?? image
        }
        return NSImage(size: iconSize)
    }
}
