import Foundation

public enum ConfirmationMode: String, Codable, CaseIterable, Sendable {
    case always
    case firstTimeOnly
    case never

    public var displayLabel: String {
        switch self {
        case .always:        return "Every time"
        case .firstTimeOnly: return "Only the first time"
        case .never:         return "Never"
        }
    }
}

public enum GroupingStrategy: String, Codable, CaseIterable, Sendable {
    case singleCategory
    case byType
    case manualReview

    public var displayLabel: String {
        switch self {
        case .singleCategory: return "One category for everything"
        case .byType:         return "Group automatically by type"
        case .manualReview:   return "Review and assign manually"
        }
    }
}

public struct AppSettings: Codable, Hashable, Sendable {
    public var applyConfirmationMode: ConfirmationMode
    public var launchAssociatedApps: Bool
    public var autoBackupBeforeApply: Bool
    public var defaultSeparatorStyle: SeparatorStyle
    public var activePresetID: UUID?
    public var firstLaunchCompleted: Bool
    public var restartCfprefsdOnFailure: Bool
    public var maxBackupCount: Int
    public var defaultImportGrouping: GroupingStrategy
    public var launchAtLogin: Bool
    public var showCategoriesInMenuBar: Bool

    public init(
        applyConfirmationMode: ConfirmationMode = .firstTimeOnly,
        launchAssociatedApps: Bool = false,
        autoBackupBeforeApply: Bool = true,
        defaultSeparatorStyle: SeparatorStyle = .small,
        activePresetID: UUID? = nil,
        firstLaunchCompleted: Bool = false,
        restartCfprefsdOnFailure: Bool = true,
        maxBackupCount: Int = 10,
        defaultImportGrouping: GroupingStrategy = .byType,
        launchAtLogin: Bool = false,
        showCategoriesInMenuBar: Bool = true
    ) {
        self.applyConfirmationMode = applyConfirmationMode
        self.launchAssociatedApps = launchAssociatedApps
        self.autoBackupBeforeApply = autoBackupBeforeApply
        self.defaultSeparatorStyle = defaultSeparatorStyle
        self.activePresetID = activePresetID
        self.firstLaunchCompleted = firstLaunchCompleted
        self.restartCfprefsdOnFailure = restartCfprefsdOnFailure
        self.maxBackupCount = maxBackupCount
        self.defaultImportGrouping = defaultImportGrouping
        self.launchAtLogin = launchAtLogin
        self.showCategoriesInMenuBar = showCategoriesInMenuBar
    }

    public static let `default` = AppSettings()

    private enum CodingKeys: String, CodingKey {
        case applyConfirmationMode, launchAssociatedApps, autoBackupBeforeApply
        case defaultSeparatorStyle, activePresetID, firstLaunchCompleted
        case restartCfprefsdOnFailure, maxBackupCount, defaultImportGrouping
        case launchAtLogin, showCategoriesInMenuBar
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.applyConfirmationMode = try c.decodeIfPresent(ConfirmationMode.self, forKey: .applyConfirmationMode) ?? .firstTimeOnly
        self.launchAssociatedApps = try c.decodeIfPresent(Bool.self, forKey: .launchAssociatedApps) ?? false
        self.autoBackupBeforeApply = try c.decodeIfPresent(Bool.self, forKey: .autoBackupBeforeApply) ?? true
        self.defaultSeparatorStyle = try c.decodeIfPresent(SeparatorStyle.self, forKey: .defaultSeparatorStyle) ?? .small
        self.activePresetID = try c.decodeIfPresent(UUID.self, forKey: .activePresetID)
        self.firstLaunchCompleted = try c.decodeIfPresent(Bool.self, forKey: .firstLaunchCompleted) ?? false
        self.restartCfprefsdOnFailure = try c.decodeIfPresent(Bool.self, forKey: .restartCfprefsdOnFailure) ?? true
        self.maxBackupCount = try c.decodeIfPresent(Int.self, forKey: .maxBackupCount) ?? 10
        self.defaultImportGrouping = try c.decodeIfPresent(GroupingStrategy.self, forKey: .defaultImportGrouping) ?? .byType
        self.launchAtLogin = try c.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        self.showCategoriesInMenuBar = try c.decodeIfPresent(Bool.self, forKey: .showCategoriesInMenuBar) ?? true
    }
}
