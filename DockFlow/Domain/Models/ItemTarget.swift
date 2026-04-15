import Foundation

public enum ItemTarget: Hashable, Sendable {
    case fileURL(URL)
    case webURL(URL)
    case none

    public var url: URL? {
        switch self {
        case .fileURL(let url), .webURL(let url): return url
        case .none: return nil
        }
    }

    public var displayPath: String {
        switch self {
        case .fileURL(let url): return url.path(percentEncoded: false)
        case .webURL(let url):  return url.absoluteString
        case .none:             return ""
        }
    }
}

extension ItemTarget: Codable {
    private enum CodingKeys: String, CodingKey { case type, value }
    private enum Kind: String, Codable { case fileURL, webURL, none }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try c.decode(Kind.self, forKey: .type)
        switch kind {
        case .fileURL:
            let raw = try c.decode(String.self, forKey: .value)
            guard let url = URL(string: raw) ?? URL(fileURLWithPath: raw, isDirectory: false) as URL? else {
                throw DecodingError.dataCorruptedError(
                    forKey: .value, in: c,
                    debugDescription: "Unparseable file URL: \(raw)")
            }
            self = .fileURL(url)
        case .webURL:
            let raw = try c.decode(String.self, forKey: .value)
            guard let url = URL(string: raw) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .value, in: c,
                    debugDescription: "Unparseable web URL: \(raw)")
            }
            self = .webURL(url)
        case .none:
            self = .none
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .fileURL(let url):
            try c.encode(Kind.fileURL, forKey: .type)
            try c.encode(url.absoluteString, forKey: .value)
        case .webURL(let url):
            try c.encode(Kind.webURL, forKey: .type)
            try c.encode(url.absoluteString, forKey: .value)
        case .none:
            try c.encode(Kind.none, forKey: .type)
        }
    }
}
