import Foundation

public enum SeparatorStyle: String, Codable, CaseIterable, Hashable, Sendable {
    case none
    case small
    case regular
    case flex

    public var displayLabel: String {
        switch self {
        case .none:    return "None"
        case .small:   return "Small spacer"
        case .regular: return "Full spacer"
        case .flex:    return "Flex spacer"
        }
    }

    public var itemKind: ItemKind? {
        switch self {
        case .none:    return nil
        case .small:   return .smallSpacer
        case .regular: return .spacer
        case .flex:    return .flexSpacer
        }
    }
}
