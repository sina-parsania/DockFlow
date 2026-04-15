import Foundation

public enum DockPrefKey {
    public static let domain: CFString = "com.apple.dock" as CFString
    public static let persistentApps: CFString = "persistent-apps" as CFString
    public static let persistentOthers: CFString = "persistent-others" as CFString
}

/// Reads the live Dock preferences through `cfprefsd`.
public struct DockReader: Sendable {
    public init() {}

    public func persistentApps() -> [[String: Any]] {
        CFPreferencesCopyAppValue(DockPrefKey.persistentApps, DockPrefKey.domain)
            as? [[String: Any]] ?? []
    }

    public func persistentOthers() -> [[String: Any]] {
        CFPreferencesCopyAppValue(DockPrefKey.persistentOthers, DockPrefKey.domain)
            as? [[String: Any]] ?? []
    }

    public func raw(_ key: String) -> CFPropertyList? {
        CFPreferencesCopyAppValue(key as CFString, DockPrefKey.domain)
    }
}
