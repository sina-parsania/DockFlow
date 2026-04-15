import Foundation
import os

public enum Log {
    public static let app      = Logger(subsystem: subsystem, category: "app")
    public static let dock     = Logger(subsystem: subsystem, category: "dock")
    public static let store    = Logger(subsystem: subsystem, category: "store")
    public static let ui       = Logger(subsystem: subsystem, category: "ui")
    public static let hotkey   = Logger(subsystem: subsystem, category: "hotkey")
    public static let validation = Logger(subsystem: subsystem, category: "validation")

    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.dockflow.app"
}
