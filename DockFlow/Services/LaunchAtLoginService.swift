import Foundation
import ServiceManagement

/// Wraps `SMAppService.mainApp` for the macOS 13+ "open at login" API.
/// No helper plist required — macOS uses the main bundle identifier.
public final class LaunchAtLoginService: @unchecked Sendable {
    public init() {}

    public var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    public var needsApproval: Bool {
        SMAppService.mainApp.status == .requiresApproval
    }

    @discardableResult
    public func setEnabled(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return true
        } catch {
            Log.app.error("Launch-at-login toggle failed: \(error.localizedDescription)")
            return false
        }
    }

    /// Opens System Settings → Login Items so the user can approve a requiresApproval state.
    public func openLoginItemsSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
