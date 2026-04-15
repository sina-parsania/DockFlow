import Foundation

public enum ExportError: Error, LocalizedError {
    case invalidData
    case unsupportedVersion(Int)
    case encodingFailed(underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .invalidData:                  return "The file isn't a valid DockFlow preset export."
        case .unsupportedVersion(let v):    return "This preset uses export format v\(v), which isn't supported by this version of DockFlow."
        case .encodingFailed(let err):      return "Failed to encode preset: \(err.localizedDescription)"
        }
    }
}

public protocol ExportProviding: AnyObject, Sendable {
    func exportPreset(_ preset: Preset) throws -> Data
    func importPreset(from data: Data) throws -> Preset
    func suggestedFileName(for preset: Preset) -> String
}
