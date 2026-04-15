import Foundation

public struct DockItem: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var kind: ItemKind
    public var displayName: String
    public var target: ItemTarget
    public var bundleIdentifier: String?

    public init(
        id: UUID = UUID(),
        kind: ItemKind,
        displayName: String,
        target: ItemTarget,
        bundleIdentifier: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.displayName = displayName
        self.target = target
        self.bundleIdentifier = bundleIdentifier
    }

    public static func spacer(_ kind: ItemKind = .smallSpacer) -> DockItem {
        precondition(kind.isSpacer, "spacer() requires a spacer kind")
        return DockItem(kind: kind, displayName: kind.displayLabel, target: .none)
    }

    public static func app(url: URL, bundleIdentifier: String? = nil, displayName: String? = nil) -> DockItem {
        DockItem(
            kind: .app,
            displayName: displayName ?? url.deletingPathExtension().lastPathComponent,
            target: .fileURL(url),
            bundleIdentifier: bundleIdentifier
        )
    }

    public static func folder(url: URL, displayName: String? = nil) -> DockItem {
        DockItem(
            kind: .folder,
            displayName: displayName ?? url.lastPathComponent,
            target: .fileURL(url)
        )
    }

    public static func file(url: URL, displayName: String? = nil) -> DockItem {
        DockItem(
            kind: .file,
            displayName: displayName ?? url.lastPathComponent,
            target: .fileURL(url)
        )
    }

    public static func webLink(url: URL, displayName: String? = nil) -> DockItem {
        DockItem(
            kind: .url,
            displayName: displayName ?? url.host() ?? url.absoluteString,
            target: .webURL(url)
        )
    }
}
