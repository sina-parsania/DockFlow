import Foundation
import AppKit

public final class IconService: IconProviding, @unchecked Sendable {
    private let workspace: NSWorkspace
    private let lock = NSLock()
    private var cache: [String: NSImage] = [:]
    private var accessOrder: [String] = []
    private let maxEntries: Int

    public init(workspace: NSWorkspace = .shared, maxEntries: Int = 512) {
        self.workspace = workspace
        self.maxEntries = maxEntries
    }

    public func icon(for item: DockItem) -> NSImage {
        let key = item.iconCacheKey
        if let cached = fetch(key) { return cached }

        let image = resolve(item: item)
        store(key: key, image: image)
        return image
    }

    public func icon(forFilePath path: String) -> NSImage {
        let key = "file:" + path
        if let cached = fetch(key) { return cached }
        let image = workspace.icon(forFile: path)
        image.size = NSSize(width: 64, height: 64)
        store(key: key, image: image)
        return image
    }

    public func icon(forBundleIdentifier bundleID: String) -> NSImage? {
        guard let url = workspace.urlForApplication(withBundleIdentifier: bundleID) else { return nil }
        return icon(forFilePath: url.path(percentEncoded: false))
    }

    public func clearCache() {
        lock.lock(); defer { lock.unlock() }
        cache.removeAll()
        accessOrder.removeAll()
    }

    // MARK: - Private

    private func resolve(item: DockItem) -> NSImage {
        switch item.target {
        case .fileURL(let url):
            let icon = workspace.icon(forFile: url.path(percentEncoded: false))
            icon.size = NSSize(width: 64, height: 64)
            return icon
        case .webURL:
            return systemFallbackIcon(symbolName: "link")
        case .none:
            return systemFallbackIcon(symbolName: item.kind.symbolName)
        }
    }

    private func systemFallbackIcon(symbolName: String) -> NSImage {
        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) {
            let config = NSImage.SymbolConfiguration(pointSize: 32, weight: .regular)
            return image.withSymbolConfiguration(config) ?? image
        }
        return NSImage(size: NSSize(width: 32, height: 32))
    }

    private func fetch(_ key: String) -> NSImage? {
        lock.lock(); defer { lock.unlock() }
        guard let image = cache[key] else { return nil }
        touch(key)
        return image
    }

    private func store(key: String, image: NSImage) {
        lock.lock(); defer { lock.unlock() }
        cache[key] = image
        touch(key)
        if accessOrder.count > maxEntries {
            let overflow = accessOrder.count - maxEntries
            for removedKey in accessOrder.prefix(overflow) {
                cache.removeValue(forKey: removedKey)
            }
            accessOrder.removeFirst(overflow)
        }
    }

    private func touch(_ key: String) {
        if let idx = accessOrder.firstIndex(of: key) {
            accessOrder.remove(at: idx)
        }
        accessOrder.append(key)
    }
}
