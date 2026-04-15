import Foundation

public struct ImportCurrentDockUseCase: Sendable {
    private let dockService: DockServicing
    private let importer: DockImporter

    public init(
        dockService: DockServicing,
        importer: DockImporter = DockImporter()
    ) {
        self.dockService = dockService
        self.importer = importer
    }

    public func execute(strategy: GroupingStrategy, nameSuggestion: String? = nil) -> Preset {
        let rawApps = dockService.readRawPersistentApps()
        let rawOthers = dockService.readRawPersistentOthers()
        let appItems = importer.mapTiles(rawApps)
        let otherItems = importer.mapTiles(rawOthers)

        let name = nameSuggestion ?? defaultName()

        switch strategy {
        case .singleCategory:
            return Preset(
                name: name,
                categories: [
                    Category(name: "Imported", items: appItems + otherItems)
                ]
            )
        case .byType:
            return Preset(
                name: name,
                categories: Self.buildTypeCategories(items: appItems + otherItems)
            )
        case .manualReview:
            return Preset(
                name: name,
                categories: [
                    Category(name: "Unassigned", items: appItems + otherItems)
                ]
            )
        }
    }

    public static func buildTypeCategories(items: [DockItem]) -> [Category] {
        var apps: [DockItem] = []
        var folders: [DockItem] = []
        var files: [DockItem] = []
        var urls: [DockItem] = []
        var spacers: [DockItem] = []

        for item in items {
            switch item.kind {
            case .app:                         apps.append(item)
            case .folder:                      folders.append(item)
            case .file:                        files.append(item)
            case .url:                         urls.append(item)
            case .spacer, .smallSpacer, .flexSpacer: spacers.append(item)
            }
        }

        return [
            Category(name: "Apps",    symbolName: "app.fill",     items: apps),
            Category(name: "Folders", symbolName: "folder.fill",  items: folders),
            Category(name: "Files",   symbolName: "doc.fill",     items: files),
            Category(name: "Web",     symbolName: "link",         items: urls),
            Category(name: "Spacers", symbolName: "rectangle.split.3x1", items: spacers)
        ].filter { !$0.isEmpty }
    }

    private func defaultName() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "Imported — \(formatter.string(from: .now))"
    }
}
