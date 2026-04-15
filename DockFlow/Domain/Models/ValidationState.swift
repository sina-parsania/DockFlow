import Foundation

public enum ValidationState: Hashable, Sendable {
    case ok
    case missing
    case inaccessible
    case malformedURL
    case unreachable

    public var isProblem: Bool { self != .ok }

    public var displayLabel: String {
        switch self {
        case .ok:            return "OK"
        case .missing:       return "Missing"
        case .inaccessible:  return "Inaccessible"
        case .malformedURL:  return "Malformed URL"
        case .unreachable:   return "Unreachable"
        }
    }

    public var symbolName: String {
        switch self {
        case .ok:            return "checkmark.circle.fill"
        case .missing:       return "exclamationmark.triangle.fill"
        case .inaccessible:  return "lock.slash.fill"
        case .malformedURL:  return "link.badge.plus"
        case .unreachable:   return "wifi.exclamationmark"
        }
    }
}

public struct DockLayout: Equatable, Sendable {
    public var apps: [DockTileRepresentation]
    public var others: [DockTileRepresentation]

    public init(apps: [DockTileRepresentation] = [], others: [DockTileRepresentation] = []) {
        self.apps = apps
        self.others = others
    }

    public var isEmpty: Bool { apps.isEmpty && others.isEmpty }
    public var totalTileCount: Int { apps.count + others.count }
}
