import SwiftUI

public struct SettingsView: View {
    @Bindable var state: AppState

    public init(state: AppState) {
        self.state = state
    }

    public var body: some View {
        TabView {
            GeneralSettingsTab(state: state)
                .tabItem { Label("General", systemImage: "gearshape") }
            HotkeysSettingsTab(state: state)
                .tabItem { Label("Hotkeys", systemImage: "keyboard") }
            AdvancedSettingsTab(state: state)
                .tabItem { Label("Advanced", systemImage: "slider.horizontal.3") }
        }
        .frame(width: 520, height: 380)
    }
}
