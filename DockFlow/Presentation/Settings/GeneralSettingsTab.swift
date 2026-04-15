import SwiftUI

public struct GeneralSettingsTab: View {
    @Bindable var state: AppState

    public init(state: AppState) {
        self.state = state
    }

    public var body: some View {
        Form {
            Section {
                Toggle("Open DockFlow at login", isOn: Binding(
                    get: { state.settings.launchAtLogin },
                    set: { state.setLaunchAtLogin($0) }
                ))
                if state.launchAtLogin.needsApproval {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Login item needs approval in System Settings.")
                            .font(.caption)
                        Spacer()
                        Button("Open Settings") { state.launchAtLogin.openLoginItemsSettings() }
                            .controlSize(.small)
                    }
                }
                Toggle("Show category previews in the menu bar", isOn: Binding(
                    get: { state.settings.showCategoriesInMenuBar },
                    set: { value in state.updateSettings { $0.showCategoriesInMenuBar = value } }
                ))
            } header: {
                Text("Startup & Menu Bar")
            } footer: {
                Text("Keep DockFlow running in the menu bar so your presets are always one click away. The first time you enable login-at-launch, macOS may ask you to approve the login item.")
                    .foregroundStyle(.secondary)
            }

            Section {
                Picker("Confirm before apply", selection: Binding(
                    get: { state.settings.applyConfirmationMode },
                    set: { value in state.updateSettings { $0.applyConfirmationMode = value } }
                )) {
                    ForEach(ConfirmationMode.allCases, id: \.self) { mode in
                        Text(mode.displayLabel).tag(mode)
                    }
                }
                Toggle("Launch associated apps when a preset is applied", isOn: Binding(
                    get: { state.settings.launchAssociatedApps },
                    set: { value in state.updateSettings { $0.launchAssociatedApps = value } }
                ))
                Toggle("Back up the current Dock before applying a preset", isOn: Binding(
                    get: { state.settings.autoBackupBeforeApply },
                    set: { value in state.updateSettings { $0.autoBackupBeforeApply = value } }
                ))
                Stepper(value: Binding(
                    get: { state.settings.maxBackupCount },
                    set: { value in state.updateSettings { $0.maxBackupCount = value } }
                ), in: 1...50) {
                    Text("Keep **\(state.settings.maxBackupCount)** backups")
                }
            } header: {
                Text("Apply")
            }

            Section {
                Picker("Default separator style", selection: Binding(
                    get: { state.settings.defaultSeparatorStyle },
                    set: { value in state.updateSettings { $0.defaultSeparatorStyle = value } }
                )) {
                    ForEach(SeparatorStyle.allCases, id: \.self) { style in
                        Text(style.displayLabel).tag(style)
                    }
                }

                Picker("Default import grouping", selection: Binding(
                    get: { state.settings.defaultImportGrouping },
                    set: { value in state.updateSettings { $0.defaultImportGrouping = value } }
                )) {
                    ForEach(GroupingStrategy.allCases, id: \.self) { strategy in
                        Text(strategy.displayLabel).tag(strategy)
                    }
                }
            } header: {
                Text("Appearance")
            }
        }
        .formStyle(.grouped)
        .padding(16)
    }
}
