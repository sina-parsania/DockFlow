import Foundation

/// Writes Dock preferences through `cfprefsd`.
///
/// Must run from a non-sandboxed process. A sandboxed `CFPreferencesSetValue`
/// against `com.apple.dock` silently fails — `cfprefsd` refuses cross-domain writes.
public struct DockWriter: Sendable {
    public init() {}

    public func setPersistentApps(_ array: [[String: Any]]) {
        CFPreferencesSetValue(
            DockPrefKey.persistentApps,
            array as CFArray,
            DockPrefKey.domain,
            kCFPreferencesCurrentUser,
            kCFPreferencesAnyHost
        )
    }

    public func setPersistentOthers(_ array: [[String: Any]]) {
        CFPreferencesSetValue(
            DockPrefKey.persistentOthers,
            array as CFArray,
            DockPrefKey.domain,
            kCFPreferencesCurrentUser,
            kCFPreferencesAnyHost
        )
    }

    public func synchronize() -> Bool {
        CFPreferencesAppSynchronize(DockPrefKey.domain)
    }
}
