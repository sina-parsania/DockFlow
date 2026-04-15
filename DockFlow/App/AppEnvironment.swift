import Foundation

/// Dependency container. Holds concrete implementations of each protocol
/// in one place so the App entry point has a single `AppEnvironment.live` to
/// wire up the `AppState`. Unit tests swap implementations directly.
public final class AppEnvironment: Sendable {
    public let presetStore: PresetStoring
    public let dockService: DockServicing
    public let iconService: IconProviding
    public let validator: ValidationProviding
    public let exporter: ExportProviding
    public let hotkeyService: HotkeyService
    public let launchAtLogin: LaunchAtLoginService

    public init(
        presetStore: PresetStoring,
        dockService: DockServicing,
        iconService: IconProviding,
        validator: ValidationProviding,
        exporter: ExportProviding,
        hotkeyService: HotkeyService,
        launchAtLogin: LaunchAtLoginService
    ) {
        self.presetStore = presetStore
        self.dockService = dockService
        self.iconService = iconService
        self.validator = validator
        self.exporter = exporter
        self.hotkeyService = hotkeyService
        self.launchAtLogin = launchAtLogin
    }

    /// Concrete wiring for the production app.
    public static func live() -> AppEnvironment {
        AppPaths.ensureDirectoriesExist()
        let store = JSONPresetStore()
        return AppEnvironment(
            presetStore: store,
            dockService: DockService(),
            iconService: IconService(),
            validator: ValidationService(),
            exporter: ExportService(store: store),
            hotkeyService: HotkeyService(),
            launchAtLogin: LaunchAtLoginService()
        )
    }

    /// Convenience factory that constructs a fully-wired AppState.
    @MainActor
    public func makeAppState() -> AppState {
        let state = AppState(
            store: presetStore,
            dockService: dockService,
            iconProvider: iconService,
            validator: validator,
            exporter: exporter,
            hotkeyService: hotkeyService,
            launchAtLogin: launchAtLogin
        )
        state.bootstrap()
        return state
    }
}
