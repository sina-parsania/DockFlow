import Foundation
import AppKit

public protocol IconProviding: AnyObject, Sendable {
    func icon(for item: DockItem) -> NSImage
    func icon(forFilePath path: String) -> NSImage
    func icon(forBundleIdentifier bundleID: String) -> NSImage?
    func clearCache()
}
