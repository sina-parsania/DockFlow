import Foundation

public struct Hotkey: Codable, Hashable, Sendable {
    public var keyCode: UInt16
    public var modifiers: UInt32

    public init(keyCode: UInt16, modifiers: UInt32) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    public static let empty = Hotkey(keyCode: 0, modifiers: 0)

    public var isValid: Bool { keyCode != 0 && modifiers != 0 }
}
