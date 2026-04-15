import Foundation

public enum ItemKind: String, Codable, CaseIterable, Hashable, Sendable {
    case app
    case folder
    case file
    case url
    case spacer
    case smallSpacer
    case flexSpacer

    public var isSpacer: Bool {
        switch self {
        case .spacer, .smallSpacer, .flexSpacer: return true
        default: return false
        }
    }

    public var requiresTarget: Bool { !isSpacer }

    public var displayLabel: String {
        switch self {
        case .app:         return "Application"
        case .folder:      return "Folder"
        case .file:        return "File"
        case .url:         return "Web Link"
        case .spacer:      return "Spacer"
        case .smallSpacer: return "Small Spacer"
        case .flexSpacer:  return "Flex Spacer"
        }
    }

    public var symbolName: String {
        switch self {
        case .app:         return "app.fill"
        case .folder:      return "folder.fill"
        case .file:        return "doc.fill"
        case .url:         return "link"
        case .spacer:      return "rectangle.split.3x1"
        case .smallSpacer: return "rectangle.split.2x1"
        case .flexSpacer:  return "arrow.left.and.right"
        }
    }
}
