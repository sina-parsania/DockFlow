import Foundation

/// Converts raw tile dictionaries (as returned by `DockReader`) into domain `DockItem`s.
public struct DockImporter: Sendable {
    public init() {}

    public func mapTile(_ raw: [String: Any]) -> DockItem? {
        guard let tileType = raw["tile-type"] as? String else { return nil }
        let data = raw["tile-data"] as? [String: Any] ?? [:]

        switch tileType {
        case "file-tile":
            let fileType = data["file-type"] as? Int ?? -1
            guard let fileURL = extractFileURL(from: data) else { return nil }
            let label = (data["file-label"] as? String) ?? fileURL.lastPathComponent
            let bundleID = data["bundle-identifier"] as? String

            if fileType == AppTile.fileType || fileURL.pathExtension == "app" {
                return DockItem.app(
                    url: fileURL,
                    bundleIdentifier: bundleID,
                    displayName: label
                )
            } else if fileType == DirectoryTile.fileType || isDirectory(fileURL) {
                return DockItem.folder(url: fileURL, displayName: label)
            } else {
                return DockItem.file(url: fileURL, displayName: label)
            }

        case "directory-tile":
            guard let fileURL = extractFileURL(from: data) else { return nil }
            let label = (data["file-label"] as? String) ?? fileURL.lastPathComponent
            return DockItem.folder(url: fileURL, displayName: label)

        case "url-tile":
            let urlDict = data["url"] as? [String: Any]
            guard
                let urlString = urlDict?["_CFURLString"] as? String,
                let url = URL(string: urlString)
            else { return nil }
            let label = (data["label"] as? String) ?? url.host() ?? url.absoluteString
            return DockItem.webLink(url: url, displayName: label)

        case "spacer-tile":
            return DockItem.spacer(.spacer)
        case "small-spacer-tile":
            return DockItem.spacer(.smallSpacer)
        case "flex-spacer-tile":
            return DockItem.spacer(.flexSpacer)

        default:
            return nil
        }
    }

    public func mapTiles(_ rawArray: [[String: Any]]) -> [DockItem] {
        rawArray.compactMap(mapTile)
    }

    // MARK: - Private helpers

    private func extractFileURL(from data: [String: Any]) -> URL? {
        if let fileData = data["file-data"] as? [String: Any],
           let urlString = fileData["_CFURLString"] as? String,
           let url = URL(string: urlString) {
            return url
        }
        return nil
    }

    private func isDirectory(_ url: URL) -> Bool {
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: url.path(percentEncoded: false), isDirectory: &isDir)
        return exists && isDir.boolValue
    }
}
