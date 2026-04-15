import Foundation

public struct Category: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var symbolName: String?
    public var tintHex: String?
    public var isCollapsed: Bool
    public var items: [DockItem]

    public init(
        id: UUID = UUID(),
        name: String,
        symbolName: String? = nil,
        tintHex: String? = nil,
        isCollapsed: Bool = false,
        items: [DockItem] = []
    ) {
        self.id = id
        self.name = name
        self.symbolName = symbolName
        self.tintHex = tintHex
        self.isCollapsed = isCollapsed
        self.items = items
    }

    public var isEmpty: Bool { items.isEmpty }

    public func indexOf(itemID: DockItem.ID) -> Int? {
        items.firstIndex { $0.id == itemID }
    }
}
