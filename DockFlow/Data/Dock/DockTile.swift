import Foundation

/// Mirrors a single tile entry inside `persistent-apps` / `persistent-others`.
/// Shape matches what `cfprefsd` serializes into `com.apple.dock.plist`.
public enum DockTileRepresentation: Hashable, Sendable {
    case app(AppTile)
    case directory(DirectoryTile)
    case file(FileTile)
    case url(URLTile)
    case spacer(SpacerKind)

    public var rawDictionary: [String: Any] {
        switch self {
        case .app(let tile):        return tile.rawDictionary
        case .directory(let tile):  return tile.rawDictionary
        case .file(let tile):       return tile.rawDictionary
        case .url(let tile):        return tile.rawDictionary
        case .spacer(let kind):     return kind.rawDictionary
        }
    }
}

public enum SpacerKind: String, Hashable, Sendable {
    case regular     = "spacer-tile"
    case small       = "small-spacer-tile"
    case flex        = "flex-spacer-tile"

    public var rawDictionary: [String: Any] {
        ["tile-type": self.rawValue, "tile-data": [String: Any]()]
    }

    public static func from(separatorStyle: SeparatorStyle) -> SpacerKind? {
        switch separatorStyle {
        case .none:    return nil
        case .small:   return .small
        case .regular: return .regular
        case .flex:    return .flex
        }
    }

    public static func from(itemKind: ItemKind) -> SpacerKind? {
        switch itemKind {
        case .spacer:       return .regular
        case .smallSpacer:  return .small
        case .flexSpacer:   return .flex
        default:            return nil
        }
    }
}

public struct AppTile: Hashable, Sendable {
    public let label: String
    public let fileURL: URL
    public let bundleIdentifier: String?

    public init(label: String, fileURL: URL, bundleIdentifier: String?) {
        self.label = label
        self.fileURL = fileURL
        self.bundleIdentifier = bundleIdentifier
    }

    /// 41 = application bundle per Apple's LaunchServices file-type codes used by Dock.
    public static let fileType: Int = 41

    public var rawDictionary: [String: Any] {
        var tileData: [String: Any] = [
            "file-label": label,
            "file-type": Self.fileType,
            "dock-extra": false,
            "file-data": [
                "_CFURLString": fileURL.absoluteString,
                "_CFURLStringType": 15
            ] as [String: Any]
        ]
        if let bundleIdentifier {
            tileData["bundle-identifier"] = bundleIdentifier
        }
        return [
            "tile-type": "file-tile",
            "tile-data": tileData
        ]
    }
}

public struct DirectoryTile: Hashable, Sendable {
    public let label: String
    public let fileURL: URL

    /// Arrangement: 1=name, 2=date added, 3=date modified, 4=date created, 5=kind.
    public var arrangement: Int = 1
    /// Display as: 0=stack, 1=folder.
    public var displayAs: Int = 1
    /// Show as: 0=automatic, 1=fan, 2=grid, 3=list.
    public var showAs: Int = 0

    /// 2 = directory per Apple's file-type code used by Dock.
    public static let fileType: Int = 2

    public init(label: String, fileURL: URL, arrangement: Int = 1, displayAs: Int = 1, showAs: Int = 0) {
        self.label = label
        self.fileURL = fileURL
        self.arrangement = arrangement
        self.displayAs = displayAs
        self.showAs = showAs
    }

    public var rawDictionary: [String: Any] {
        let tileData: [String: Any] = [
            "file-label": label,
            "file-type": Self.fileType,
            "arrangement": arrangement,
            "displayas": displayAs,
            "showas": showAs,
            "file-data": [
                "_CFURLString": fileURL.absoluteString,
                "_CFURLStringType": 15
            ] as [String: Any]
        ]
        return [
            "tile-type": "directory-tile",
            "tile-data": tileData
        ]
    }
}

public struct FileTile: Hashable, Sendable {
    public let label: String
    public let fileURL: URL

    /// 1 = regular file per Apple's file-type code used by Dock.
    public static let fileType: Int = 1

    public init(label: String, fileURL: URL) {
        self.label = label
        self.fileURL = fileURL
    }

    public var rawDictionary: [String: Any] {
        let tileData: [String: Any] = [
            "file-label": label,
            "file-type": Self.fileType,
            "file-data": [
                "_CFURLString": fileURL.absoluteString,
                "_CFURLStringType": 15
            ] as [String: Any]
        ]
        return [
            "tile-type": "file-tile",
            "tile-data": tileData
        ]
    }
}

public struct URLTile: Hashable, Sendable {
    public let label: String
    public let url: URL

    public init(label: String, url: URL) {
        self.label = label
        self.url = url
    }

    public var rawDictionary: [String: Any] {
        let tileData: [String: Any] = [
            "label": label,
            "url": [
                "_CFURLString": url.absoluteString,
                "_CFURLStringType": 15
            ] as [String: Any]
        ]
        return [
            "tile-type": "url-tile",
            "tile-data": tileData
        ]
    }
}
