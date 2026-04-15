import Foundation

/// Stateless validator. Every call hits the filesystem fresh so results
/// always reflect the current state of the user's disk.
public final class ValidationService: ValidationProviding, @unchecked Sendable {
    private let fm: FileManager

    public init(fileManager: FileManager = .default) {
        self.fm = fileManager
    }

    public func validate(_ item: DockItem) -> ValidationState {
        switch item.target {
        case .fileURL(let url):
            let path = url.path(percentEncoded: false)
            if !fm.fileExists(atPath: path) { return .missing }
            if !fm.isReadableFile(atPath: path) { return .inaccessible }
            return .ok
        case .webURL(let url):
            guard let scheme = url.scheme?.lowercased(),
                  scheme == "http" || scheme == "https" else {
                return .malformedURL
            }
            guard url.host()?.isEmpty == false else { return .malformedURL }
            return .ok
        case .none:
            return .ok
        }
    }

    public func validateAll(in preset: Preset) -> [DockItem.ID: ValidationState] {
        var result: [DockItem.ID: ValidationState] = [:]
        for category in preset.categories {
            for item in category.items {
                result[item.id] = validate(item)
            }
        }
        return result
    }

    public func invalidateCache() {
        // No-op. This service is stateless.
    }
}
