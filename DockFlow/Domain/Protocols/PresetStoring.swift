import Foundation

public struct StoreSnapshot: Codable, Sendable {
    public var version: Int
    public var presets: [Preset]
    public var settings: AppSettings

    public init(version: Int = 1, presets: [Preset] = [], settings: AppSettings = .default) {
        self.version = version
        self.presets = presets
        self.settings = settings
    }
}

public enum PresetStoreError: Error, LocalizedError, Equatable {
    case corrupted(reason: String)
    case unsupportedSchemaVersion(found: Int, supported: Int)
    case writeFailed(reason: String)

    public var errorDescription: String? {
        switch self {
        case .corrupted(let reason):
            return "Preset store is corrupted: \(reason)"
        case .unsupportedSchemaVersion(let found, let supported):
            return "Preset file uses schema v\(found). This build supports v\(supported)."
        case .writeFailed(let reason):
            return "Couldn't save presets: \(reason)"
        }
    }
}

public protocol PresetStoring: AnyObject, Sendable {
    func load() throws -> StoreSnapshot
    func save(_ snapshot: StoreSnapshot) throws
    func exportPreset(_ preset: Preset) throws -> Data
    func importPreset(from data: Data) throws -> Preset
}
