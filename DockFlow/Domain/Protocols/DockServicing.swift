import Foundation

public struct ApplyResult: Sendable {
    public let backupID: UUID?
    public let backupURL: URL?
    public let appliedAppCount: Int
    public let appliedOtherCount: Int
    public let missingItemIDs: [DockItem.ID]
    public let warnings: [String]

    public init(
        backupID: UUID? = nil,
        backupURL: URL? = nil,
        appliedAppCount: Int = 0,
        appliedOtherCount: Int = 0,
        missingItemIDs: [DockItem.ID] = [],
        warnings: [String] = []
    ) {
        self.backupID = backupID
        self.backupURL = backupURL
        self.appliedAppCount = appliedAppCount
        self.appliedOtherCount = appliedOtherCount
        self.missingItemIDs = missingItemIDs
        self.warnings = warnings
    }
}

public enum DockServiceError: Error, LocalizedError {
    case applyVerificationFailed
    case backupFailed(underlying: Error)
    case readFailed
    case restoreFailed(underlying: Error)
    case dockRestartFailed(underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .applyVerificationFailed:
            return "Dock values didn't stick after restart. Try again, or restore your last backup."
        case .backupFailed(let err):
            return "Could not back up current Dock: \(err.localizedDescription)"
        case .readFailed:
            return "Could not read the current Dock configuration."
        case .restoreFailed(let err):
            return "Could not restore Dock backup: \(err.localizedDescription)"
        case .dockRestartFailed(let err):
            return "Dock didn't restart cleanly: \(err.localizedDescription)"
        }
    }
}

public struct ApplyOptions: Sendable {
    public var createBackup: Bool
    public var launchAssociatedApps: Bool
    public var skipMissingItems: Bool
    public var restartCfprefsdOnFailure: Bool

    public init(
        createBackup: Bool = true,
        launchAssociatedApps: Bool = false,
        skipMissingItems: Bool = true,
        restartCfprefsdOnFailure: Bool = true
    ) {
        self.createBackup = createBackup
        self.launchAssociatedApps = launchAssociatedApps
        self.skipMissingItems = skipMissingItems
        self.restartCfprefsdOnFailure = restartCfprefsdOnFailure
    }
}

public protocol DockServicing: AnyObject, Sendable {
    func readCurrent() throws -> DockLayout
    func readRawPersistentApps() -> [[String: Any]]
    func readRawPersistentOthers() -> [[String: Any]]
    func apply(layout: DockLayout, options: ApplyOptions) async throws -> ApplyResult
    func restoreLatestBackup() async throws
    func restoreBackup(id: UUID) async throws
    func listBackups() -> [DockBackup]
}

public struct DockBackup: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let createdAt: Date
    public let fileURL: URL

    public init(id: UUID, createdAt: Date, fileURL: URL) {
        self.id = id
        self.createdAt = createdAt
        self.fileURL = fileURL
    }
}
