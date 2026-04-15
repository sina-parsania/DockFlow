import Foundation

/// Pure conversion from a Preset into the two tile arrays that `cfprefsd` expects.
/// Deterministic — same input, same output.
public enum DockBuilder {
    public static func build(preset: Preset) -> DockLayout {
        var apps: [DockTileRepresentation] = []
        var others: [DockTileRepresentation] = []

        let separator = SpacerKind.from(separatorStyle: preset.separatorStyle)
        let lastCategoryIndex = preset.categories.count - 1

        for (categoryIndex, category) in preset.categories.enumerated() {
            var touchedApps = false
            var touchedOthers = false

            for item in category.items {
                guard let tile = tile(for: item) else { continue }
                switch item.kind {
                case .app:
                    apps.append(tile); touchedApps = true
                case .folder, .file, .url:
                    others.append(tile); touchedOthers = true
                case .spacer, .smallSpacer, .flexSpacer:
                    apps.append(tile); touchedApps = true
                }
            }

            let isLast = categoryIndex == lastCategoryIndex
            if !isLast, let separator {
                let sepTile = DockTileRepresentation.spacer(separator)
                if touchedApps   { apps.append(sepTile) }
                if touchedOthers { others.append(sepTile) }
            }
        }

        return DockLayout(apps: apps, others: others)
    }

    public static func tile(for item: DockItem) -> DockTileRepresentation? {
        switch item.kind {
        case .app:
            guard case .fileURL(let url) = item.target else { return nil }
            return .app(AppTile(
                label: item.displayName,
                fileURL: normalizedFileURL(url, directory: false),
                bundleIdentifier: item.bundleIdentifier
            ))

        case .folder:
            guard case .fileURL(let url) = item.target else { return nil }
            return .directory(DirectoryTile(
                label: item.displayName,
                fileURL: normalizedFileURL(url, directory: true)
            ))

        case .file:
            guard case .fileURL(let url) = item.target else { return nil }
            return .file(FileTile(
                label: item.displayName,
                fileURL: normalizedFileURL(url, directory: false)
            ))

        case .url:
            guard case .webURL(let url) = item.target else { return nil }
            return .url(URLTile(label: item.displayName, url: url))

        case .spacer, .smallSpacer, .flexSpacer:
            guard let kind = SpacerKind.from(itemKind: item.kind) else { return nil }
            return .spacer(kind)
        }
    }

    /// The Dock expects `_CFURLString` values with trailing slashes for directories.
    private static func normalizedFileURL(_ url: URL, directory: Bool) -> URL {
        let standardized = url.standardizedFileURL
        if directory && !standardized.absoluteString.hasSuffix("/") {
            return URL(string: standardized.absoluteString + "/") ?? standardized
        }
        return standardized
    }
}
