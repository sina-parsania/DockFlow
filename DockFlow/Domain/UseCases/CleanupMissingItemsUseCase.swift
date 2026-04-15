import Foundation

/// Scans every preset and removes items whose file/app no longer exists on disk.
/// Returns a summary of what was removed so the UI can tell the user.
public struct CleanupMissingItemsUseCase: Sendable {
    private let validator: ValidationProviding

    public init(validator: ValidationProviding) {
        self.validator = validator
    }

    public struct Report: Sendable, Equatable {
        public var removedByPreset: [UUID: [RemovedItem]]

        public var totalRemoved: Int {
            removedByPreset.values.reduce(0) { $0 + $1.count }
        }

        public var isEmpty: Bool { removedByPreset.isEmpty }
    }

    public struct RemovedItem: Sendable, Equatable {
        public let itemID: UUID
        public let displayName: String
        public let kind: ItemKind
        public let categoryName: String
    }

    public func execute(presets: inout [Preset]) -> Report {
        var removedByPreset: [UUID: [RemovedItem]] = [:]

        for presetIndex in presets.indices {
            var removedInThisPreset: [RemovedItem] = []

            for categoryIndex in presets[presetIndex].categories.indices {
                let categoryName = presets[presetIndex].categories[categoryIndex].name
                let items = presets[presetIndex].categories[categoryIndex].items

                let survivors = items.filter { item in
                    let state = validator.validate(item)
                    let shouldRemove = (state == .missing)
                    if shouldRemove {
                        removedInThisPreset.append(RemovedItem(
                            itemID: item.id,
                            displayName: item.displayName,
                            kind: item.kind,
                            categoryName: categoryName
                        ))
                    }
                    return !shouldRemove
                }

                presets[presetIndex].categories[categoryIndex].items = survivors
            }

            if !removedInThisPreset.isEmpty {
                presets[presetIndex].updatedAt = .now
                removedByPreset[presets[presetIndex].id] = removedInThisPreset
            }
        }

        return Report(removedByPreset: removedByPreset)
    }
}
