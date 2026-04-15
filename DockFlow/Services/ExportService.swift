import Foundation

public final class ExportService: ExportProviding, @unchecked Sendable {
    private let store: PresetStoring

    public init(store: PresetStoring) {
        self.store = store
    }

    public func exportPreset(_ preset: Preset) throws -> Data {
        try store.exportPreset(preset)
    }

    public func importPreset(from data: Data) throws -> Preset {
        try store.importPreset(from: data)
    }

    public func suggestedFileName(for preset: Preset) -> String {
        let safe = preset.name
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let base = safe.isEmpty ? "Preset" : safe
        return "\(base).dockflow.json"
    }
}
