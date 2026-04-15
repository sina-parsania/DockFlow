import SwiftUI

public struct ImportDockSheet: View {
    @Bindable var state: AppState
    @State private var grouping: GroupingStrategy = .byType

    public init(state: AppState) {
        self.state = state
        _grouping = State(initialValue: state.settings.defaultImportGrouping)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Import Current Dock").font(.title2).fontWeight(.semibold)
            Text("DockFlow will read your live Dock and create a new preset. Choose how to arrange imported items.")
                .font(.callout)
                .foregroundStyle(.secondary)

            Picker("Arrangement", selection: $grouping) {
                ForEach(GroupingStrategy.allCases, id: \.self) { strategy in
                    Text(strategy.displayLabel).tag(strategy)
                }
            }
            .pickerStyle(.radioGroup)

            Spacer()

            HStack {
                Spacer()
                Button("Cancel") {
                    state.isImportSheetPresented = false
                }
                .keyboardShortcut(.escape, modifiers: [])

                Button("Import") {
                    state.importCurrentDock(strategy: grouping)
                    state.isImportSheetPresented = false
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(22)
        .frame(width: 440, height: 240)
    }
}
