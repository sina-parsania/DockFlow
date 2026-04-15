import SwiftUI

public struct ValidationBadge: View {
    let state: ValidationState

    public init(state: ValidationState) {
        self.state = state
    }

    public var body: some View {
        if state == .ok {
            EmptyView()
        } else {
            Image(systemName: state.symbolName)
                .foregroundStyle(tint)
                .imageScale(.small)
                .help(state.displayLabel)
        }
    }

    private var tint: Color {
        switch state {
        case .ok: return .green
        case .missing, .inaccessible, .unreachable: return .orange
        case .malformedURL: return .red
        }
    }
}
