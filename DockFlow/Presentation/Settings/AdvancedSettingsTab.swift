import SwiftUI

public struct AdvancedSettingsTab: View {
    @Bindable var state: AppState

    public init(state: AppState) {
        self.state = state
    }

    public var body: some View {
        Form {
            Section {
                Toggle("Restart cfprefsd if apply doesn't propagate", isOn: Binding(
                    get: { state.settings.restartCfprefsdOnFailure },
                    set: { value in state.updateSettings { $0.restartCfprefsdOnFailure = value } }
                ))
            } header: {
                Text("Reliability")
            } footer: {
                Text("When enabled and the dock doesn't pick up the new values on the first try, DockFlow will restart the preferences daemon and retry once.")
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Open Application Support Folder") {
                    NSWorkspace.shared.activateFileViewerSelecting([AppPaths.applicationSupport])
                }
                Button("Clear Icon Cache") {
                    state.iconProvider.clearCache()
                }
            } header: {
                Text("Maintenance")
            }
        }
        .formStyle(.grouped)
        .padding(16)
    }
}
