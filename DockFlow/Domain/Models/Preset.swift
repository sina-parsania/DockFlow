import Foundation

public struct Preset: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var symbolName: String?
    public var tintHex: String?
    public var categories: [Category]
    public var createdAt: Date
    public var updatedAt: Date
    public var lastAppliedAt: Date?
    public var hotkey: Hotkey?
    public var autoLaunchApps: Bool
    public var separatorStyle: SeparatorStyle

    public init(
        id: UUID = UUID(),
        name: String,
        symbolName: String? = "square.stack.3d.up.fill",
        tintHex: String? = nil,
        categories: [Category] = [],
        createdAt: Date = .now,
        updatedAt: Date = .now,
        lastAppliedAt: Date? = nil,
        hotkey: Hotkey? = nil,
        autoLaunchApps: Bool = false,
        separatorStyle: SeparatorStyle = .small
    ) {
        self.id = id
        self.name = name
        self.symbolName = symbolName
        self.tintHex = tintHex
        self.categories = categories
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastAppliedAt = lastAppliedAt
        self.hotkey = hotkey
        self.autoLaunchApps = autoLaunchApps
        self.separatorStyle = separatorStyle
    }

    public var totalItems: Int {
        categories.reduce(0) { $0 + $1.items.count }
    }

    public var allItems: [DockItem] {
        categories.flatMap(\.items)
    }

    public func indexOf(categoryID: Category.ID) -> Int? {
        categories.firstIndex { $0.id == categoryID }
    }

    public func locate(itemID: DockItem.ID) -> (categoryIndex: Int, itemIndex: Int)? {
        for (ci, category) in categories.enumerated() {
            if let ii = category.indexOf(itemID: itemID) {
                return (ci, ii)
            }
        }
        return nil
    }
}
