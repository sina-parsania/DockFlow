import Foundation
import AppKit

public struct DockRestarter: Sendable {
    public init() {}

    /// Sends SIGTERM to the Dock via `killall`. launchd relaunches it through its LaunchAgent.
    public func restartDock() throws {
        try run(executable: "/usr/bin/killall", arguments: ["Dock"])
    }

    /// As a last resort when writes don't propagate, kick the preferences daemon.
    public func restartCfprefsd() throws {
        try run(executable: "/usr/bin/killall", arguments: ["cfprefsd"])
    }

    private func run(executable: String, arguments: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        let nullFD = FileHandle(forWritingAtPath: "/dev/null")
        process.standardOutput = nullFD
        process.standardError = nullFD
        try process.run()
        process.waitUntilExit()
        // `killall` returns 1 when no matching process exists, which is fine.
        if process.terminationStatus > 1 {
            throw DockServiceError.dockRestartFailed(
                underlying: NSError(
                    domain: "DockRestarter",
                    code: Int(process.terminationStatus),
                    userInfo: [NSLocalizedDescriptionKey: "killall exited with status \(process.terminationStatus)"]
                )
            )
        }
    }
}
