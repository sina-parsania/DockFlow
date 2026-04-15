import Foundation

public final class BackupStore: Sendable {
    private let baseDirectory: URL
    private let maxBackupCount: Int

    public init(
        baseDirectory: URL = AppPaths.backupsDirectory,
        maxBackupCount: Int = 10
    ) {
        self.baseDirectory = baseDirectory
        self.maxBackupCount = maxBackupCount
    }

    public struct Snapshot: Codable, Sendable {
        public let id: UUID
        public let createdAt: Date
        public let persistentApps: Data
        public let persistentOthers: Data

        public init(id: UUID = UUID(), createdAt: Date = .now, persistentApps: Data, persistentOthers: Data) {
            self.id = id
            self.createdAt = createdAt
            self.persistentApps = persistentApps
            self.persistentOthers = persistentOthers
        }
    }

    public func write(apps: [[String: Any]], others: [[String: Any]]) throws -> DockBackup {
        try FileManager.default.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
        let id = UUID()
        let date = Date()

        let payload: [String: Any] = [
            "id": id.uuidString,
            "createdAt": ISO8601DateFormatter().string(from: date),
            "persistent-apps": apps,
            "persistent-others": others
        ]

        let data = try PropertyListSerialization.data(
            fromPropertyList: payload,
            format: .xml,
            options: 0
        )

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withColonSeparatorInTime]
        let filename = "\(formatter.string(from: date))-\(id.uuidString).plist"
            .replacingOccurrences(of: ":", with: "-")
        let fileURL = baseDirectory.appendingPathComponent(filename, isDirectory: false)
        try FileSystemSafety.atomicWrite(data, to: fileURL)

        pruneOldBackups()
        return DockBackup(id: id, createdAt: date, fileURL: fileURL)
    }

    public func list() -> [DockBackup] {
        let fm = FileManager.default
        guard let entries = try? fm.contentsOfDirectory(
            at: baseDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        let backups: [DockBackup] = entries.compactMap { url in
            guard url.pathExtension == "plist" else { return nil }
            guard
                let data = try? Data(contentsOf: url),
                let plist = try? PropertyListSerialization.propertyList(from: data, format: nil),
                let dict = plist as? [String: Any],
                let idString = dict["id"] as? String,
                let id = UUID(uuidString: idString)
            else { return nil }

            let date: Date
            if
                let iso = dict["createdAt"] as? String,
                let parsed = ISO8601DateFormatter().date(from: iso)
            {
                date = parsed
            } else {
                let attrs = try? fm.attributesOfItem(atPath: url.path(percentEncoded: false))
                date = attrs?[.modificationDate] as? Date ?? .distantPast
            }

            return DockBackup(id: id, createdAt: date, fileURL: url)
        }

        return backups.sorted { $0.createdAt > $1.createdAt }
    }

    public func loadSnapshot(id: UUID) throws -> (apps: [[String: Any]], others: [[String: Any]])? {
        guard let backup = list().first(where: { $0.id == id }) else { return nil }
        return try load(url: backup.fileURL)
    }

    public func loadLatest() throws -> (apps: [[String: Any]], others: [[String: Any]])? {
        guard let latest = list().first else { return nil }
        return try load(url: latest.fileURL)
    }

    private func load(url: URL) throws -> (apps: [[String: Any]], others: [[String: Any]]) {
        let data = try Data(contentsOf: url)
        let plist = try PropertyListSerialization.propertyList(from: data, format: nil)
        guard let dict = plist as? [String: Any] else {
            throw DockServiceError.restoreFailed(underlying: NSError(
                domain: "BackupStore", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Backup file is not a dictionary."]
            ))
        }
        let apps = dict["persistent-apps"] as? [[String: Any]] ?? []
        let others = dict["persistent-others"] as? [[String: Any]] ?? []
        return (apps, others)
    }

    private func pruneOldBackups() {
        let all = list()
        guard all.count > maxBackupCount else { return }
        let toDelete = all.dropFirst(maxBackupCount)
        for backup in toDelete {
            try? FileManager.default.removeItem(at: backup.fileURL)
        }
    }
}
