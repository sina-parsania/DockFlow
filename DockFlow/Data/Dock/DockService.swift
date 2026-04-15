import Foundation

public final class DockService: DockServicing, @unchecked Sendable {
    private let reader: DockReader
    private let writer: DockWriter
    private let restarter: DockRestarter
    private let importer: DockImporter
    private let backupStore: BackupStore

    public init(
        reader: DockReader = DockReader(),
        writer: DockWriter = DockWriter(),
        restarter: DockRestarter = DockRestarter(),
        importer: DockImporter = DockImporter(),
        backupStore: BackupStore = BackupStore()
    ) {
        self.reader = reader
        self.writer = writer
        self.restarter = restarter
        self.importer = importer
        self.backupStore = backupStore
    }

    // MARK: - Read

    public func readCurrent() throws -> DockLayout {
        DockLayout(
            apps: readRawPersistentApps().compactMap(rawTileToRepresentation),
            others: readRawPersistentOthers().compactMap(rawTileToRepresentation)
        )
    }

    public func readRawPersistentApps() -> [[String: Any]] {
        reader.persistentApps()
    }

    public func readRawPersistentOthers() -> [[String: Any]] {
        reader.persistentOthers()
    }

    // MARK: - Apply

    public func apply(layout: DockLayout, options: ApplyOptions) async throws -> ApplyResult {
        Log.dock.info("Applying layout apps=\(layout.apps.count) others=\(layout.others.count)")

        var backupID: UUID?
        var backupURL: URL?
        if options.createBackup {
            let currentApps = reader.persistentApps()
            let currentOthers = reader.persistentOthers()
            do {
                let backup = try backupStore.write(apps: currentApps, others: currentOthers)
                backupID = backup.id
                backupURL = backup.fileURL
            } catch {
                throw DockServiceError.backupFailed(underlying: error)
            }
        }

        let rawApps = layout.apps.map(\.rawDictionary)
        let rawOthers = layout.others.map(\.rawDictionary)

        try await writeAndRestart(apps: rawApps, others: rawOthers)

        let verified = try await verify(expectedAppsCount: rawApps.count, expectedOthersCount: rawOthers.count)
        if !verified {
            Log.dock.warning("Primary apply didn't verify — retrying via cfprefsd")
            if options.restartCfprefsdOnFailure {
                try restarter.restartCfprefsd()
                try await Task.sleep(nanoseconds: 300_000_000)
                try await writeAndRestart(apps: rawApps, others: rawOthers)
                let secondVerified = try await verify(expectedAppsCount: rawApps.count, expectedOthersCount: rawOthers.count)
                if !secondVerified {
                    throw DockServiceError.applyVerificationFailed
                }
            } else {
                throw DockServiceError.applyVerificationFailed
            }
        }

        return ApplyResult(
            backupID: backupID,
            backupURL: backupURL,
            appliedAppCount: rawApps.count,
            appliedOtherCount: rawOthers.count
        )
    }

    // MARK: - Restore

    public func restoreLatestBackup() async throws {
        guard let snapshot = try backupStore.loadLatest() else {
            throw DockServiceError.restoreFailed(underlying: NSError(
                domain: "DockService", code: -10,
                userInfo: [NSLocalizedDescriptionKey: "No backup available."]))
        }
        try await writeAndRestart(apps: snapshot.apps, others: snapshot.others)
    }

    public func restoreBackup(id: UUID) async throws {
        guard let snapshot = try backupStore.loadSnapshot(id: id) else {
            throw DockServiceError.restoreFailed(underlying: NSError(
                domain: "DockService", code: -11,
                userInfo: [NSLocalizedDescriptionKey: "Backup not found."]))
        }
        try await writeAndRestart(apps: snapshot.apps, others: snapshot.others)
    }

    public func listBackups() -> [DockBackup] { backupStore.list() }

    // MARK: - Private

    private func writeAndRestart(apps: [[String: Any]], others: [[String: Any]]) async throws {
        writer.setPersistentApps(apps)
        writer.setPersistentOthers(others)
        _ = writer.synchronize()
        try restarter.restartDock()
        try await Task.sleep(nanoseconds: 400_000_000)
    }

    private func verify(expectedAppsCount: Int, expectedOthersCount: Int) async throws -> Bool {
        let apps = reader.persistentApps()
        let others = reader.persistentOthers()
        return apps.count == expectedAppsCount && others.count == expectedOthersCount
    }

    private func rawTileToRepresentation(_ raw: [String: Any]) -> DockTileRepresentation? {
        guard let tileType = raw["tile-type"] as? String else { return nil }
        let data = raw["tile-data"] as? [String: Any] ?? [:]
        switch tileType {
        case "small-spacer-tile": return .spacer(.small)
        case "flex-spacer-tile":  return .spacer(.flex)
        case "spacer-tile":       return .spacer(.regular)
        case "url-tile":
            guard
                let urlDict = data["url"] as? [String: Any],
                let urlString = urlDict["_CFURLString"] as? String,
                let url = URL(string: urlString)
            else { return nil }
            let label = data["label"] as? String ?? ""
            return .url(URLTile(label: label, url: url))
        case "directory-tile":
            guard
                let fileData = data["file-data"] as? [String: Any],
                let urlString = fileData["_CFURLString"] as? String,
                let url = URL(string: urlString)
            else { return nil }
            let label = data["file-label"] as? String ?? url.lastPathComponent
            return .directory(DirectoryTile(label: label, fileURL: url))
        case "file-tile":
            guard
                let fileData = data["file-data"] as? [String: Any],
                let urlString = fileData["_CFURLString"] as? String,
                let url = URL(string: urlString)
            else { return nil }
            let label = data["file-label"] as? String ?? url.lastPathComponent
            let fileType = data["file-type"] as? Int ?? -1
            if fileType == AppTile.fileType || url.pathExtension == "app" {
                return .app(AppTile(
                    label: label,
                    fileURL: url,
                    bundleIdentifier: data["bundle-identifier"] as? String
                ))
            } else {
                return .file(FileTile(label: label, fileURL: url))
            }
        default:
            return nil
        }
    }
}
