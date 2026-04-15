import AppKit
import SwiftUI

public final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    public static weak var shared: AppDelegate?

    override public init() {
        super.init()
        AppDelegate.shared = self
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Start as an accessory app so the Dock icon only appears when the main
        // window is open. `MenuBarExtra` keeps running in the menu bar either way.
        NSApp.setActivationPolicy(.accessory)
    }

    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if !hasVisibleWindows {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        }
        return true
    }

    // MARK: - Window lifecycle

    public func registerMainWindow(_ window: NSWindow) {
        window.delegate = self
        window.isReleasedWhenClosed = false
    }

    public func windowWillClose(_ notification: Notification) {
        // When the main window closes, drop back to accessory mode so the app
        // hides from the regular Dock while still showing the menu bar item.
        NSApp.setActivationPolicy(.accessory)
    }
}
