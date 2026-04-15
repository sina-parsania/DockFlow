import Foundation

public enum AppPaths {
    public static let bundleIdentifier = "com.dockflow.app"

    public static var applicationSupport: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("DockFlow", isDirectory: true)
    }

    public static var presetsFile: URL {
        applicationSupport.appendingPathComponent("presets.json", isDirectory: false)
    }

    public static var backupsDirectory: URL {
        applicationSupport.appendingPathComponent("Backups", isDirectory: true)
    }

    public static var logsDirectory: URL {
        applicationSupport.appendingPathComponent("Logs", isDirectory: true)
    }

    public static func ensureDirectoriesExist() {
        let fm = FileManager.default
        for dir in [applicationSupport, backupsDirectory, logsDirectory] {
            if !fm.fileExists(atPath: dir.path(percentEncoded: false)) {
                try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
            }
        }
    }
}

public enum FileSystemSafety {
    /// Atomically writes `data` to `url`. Creates parent directories if needed.
    public static func atomicWrite(_ data: Data, to url: URL) throws {
        let fm = FileManager.default
        let parent = url.deletingLastPathComponent()
        if !fm.fileExists(atPath: parent.path(percentEncoded: false)) {
            try fm.createDirectory(at: parent, withIntermediateDirectories: true)
        }
        let tempURL = parent.appendingPathComponent(".\(UUID().uuidString).tmp", isDirectory: false)
        try data.write(to: tempURL, options: .atomic)
        if fm.fileExists(atPath: url.path(percentEncoded: false)) {
            _ = try fm.replaceItemAt(url, withItemAt: tempURL)
        } else {
            try fm.moveItem(at: tempURL, to: url)
        }
    }
}
