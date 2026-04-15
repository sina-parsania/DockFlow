import Foundation

public protocol ValidationProviding: AnyObject, Sendable {
    func validate(_ item: DockItem) -> ValidationState
    func validateAll(in preset: Preset) -> [DockItem.ID: ValidationState]
    func invalidateCache()
}
