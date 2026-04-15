import Foundation

public final class JSONPresetStore: PresetStoring, @unchecked Sendable {
    public static let currentSchemaVersion = 1
    public static let exportSchemaVersion = 1

    private let fileURL: URL
    private let queue = DispatchQueue(label: "com.dockflow.presetstore", qos: .utility)
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(fileURL: URL = AppPaths.presetsFile) {
        self.fileURL = fileURL

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .custom { date, enc in
            var c = enc.singleValueContainer()
            try c.encode(formatter.string(from: date))
        }
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { dec in
            let container = try dec.singleValueContainer()
            let raw = try container.decode(String.self)
            if let date = formatter.date(from: raw) { return date }
            let fallback = ISO8601DateFormatter()
            fallback.formatOptions = [.withInternetDateTime]
            if let date = fallback.date(from: raw) { return date }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unparseable date: \(raw)")
        }
        self.decoder = decoder
    }

    // MARK: - Load / Save snapshot

    public func load() throws -> StoreSnapshot {
        let fm = FileManager.default
        guard fm.fileExists(atPath: fileURL.path(percentEncoded: false)) else {
            return StoreSnapshot()
        }
        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            throw PresetStoreError.corrupted(reason: "Unable to read file: \(error.localizedDescription)")
        }
        do {
            let snapshot = try decoder.decode(StoreSnapshot.self, from: data)
            if snapshot.version > Self.currentSchemaVersion {
                throw PresetStoreError.unsupportedSchemaVersion(
                    found: snapshot.version, supported: Self.currentSchemaVersion)
            }
            return snapshot
        } catch let err as PresetStoreError {
            throw err
        } catch {
            throw PresetStoreError.corrupted(reason: error.localizedDescription)
        }
    }

    public func save(_ snapshot: StoreSnapshot) throws {
        let data: Data
        do {
            data = try encoder.encode(snapshot)
        } catch {
            throw PresetStoreError.writeFailed(reason: error.localizedDescription)
        }
        do {
            try FileSystemSafety.atomicWrite(data, to: fileURL)
        } catch {
            throw PresetStoreError.writeFailed(reason: error.localizedDescription)
        }
    }

    // MARK: - Export / Import single preset

    public func exportPreset(_ preset: Preset) throws -> Data {
        let wrapper = PresetExport(version: Self.exportSchemaVersion, preset: preset)
        return try encoder.encode(wrapper)
    }

    public func importPreset(from data: Data) throws -> Preset {
        do {
            let wrapper = try decoder.decode(PresetExport.self, from: data)
            guard wrapper.version <= Self.exportSchemaVersion else {
                throw ExportError.unsupportedVersion(wrapper.version)
            }
            var imported = wrapper.preset
            imported.id = UUID()
            imported.createdAt = .now
            imported.updatedAt = .now
            imported.lastAppliedAt = nil
            return imported
        } catch let err as ExportError {
            throw err
        } catch {
            throw ExportError.invalidData
        }
    }
}

public struct PresetExport: Codable, Sendable {
    public let version: Int
    public let preset: Preset

    public init(version: Int, preset: Preset) {
        self.version = version
        self.preset = preset
    }
}
