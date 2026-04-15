import SwiftUI

public struct MainWindow: View {
    @Bindable var state: AppState
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    public init(state: AppState) {
        self.state = state
    }

    public var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            PresetSidebar(state: state)
                .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 340)
        } content: {
            PresetDetail(state: state)
                .navigationSplitViewColumnWidth(min: 420, ideal: 580)
                .toolbar {
                    ToolbarItemGroup(placement: .automatic) {
                        toolbarContent
                    }
                }
                .searchable(text: $state.searchText, placement: .toolbar, prompt: "Search items")
        } detail: {
            if state.isInspectorVisible, let presetID = state.selectedPresetID {
                Inspector(state: state, presetID: presetID)
                    .navigationSplitViewColumnWidth(min: 260, ideal: 300, max: 360)
            } else {
                Color.clear.frame(maxWidth: 0)
            }
        }
        .navigationTitle(state.selectedPreset?.name ?? "DockFlow")
        .sheet(isPresented: $state.isOnboardingPresented) {
            OnboardingView(state: state)
        }
        .sheet(isPresented: $state.isImportSheetPresented) {
            ImportDockSheet(state: state)
        }
        .alert(state.lastError ?? "", isPresented: Binding(
            get: { state.lastError != nil },
            set: { if !$0 { state.lastError = nil } }
        )) {
            Button("OK", role: .cancel) { state.lastError = nil }
        }
    }

    @ViewBuilder
    private var toolbarContent: some View {
        if state.selectedPreset != nil {
            Picker("Filter", selection: $state.itemFilter) {
                ForEach(SearchItemFilter.allCases, id: \.self) { filter in
                    Text(filter.displayLabel).tag(filter)
                }
            }
            .pickerStyle(.menu)

            Button {
                state.isImportSheetPresented = true
            } label: {
                Label("Import Dock", systemImage: "arrow.down.square")
            }
            .help("Import the live Dock into a new preset")

            Button {
                state.isInspectorVisible.toggle()
            } label: {
                Label("Inspector", systemImage: "sidebar.right")
            }
            .help("Toggle the inspector panel")
        }
    }
}
