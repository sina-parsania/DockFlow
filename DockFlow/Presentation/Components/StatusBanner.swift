import SwiftUI

public struct StatusBanner: View {
    public enum Style { case info, success, warning, error }

    let style: Style
    let title: String
    let message: String?
    let action: (title: String, handler: () -> Void)?

    public init(
        style: Style,
        title: String,
        message: String? = nil,
        action: (title: String, handler: () -> Void)? = nil
    ) {
        self.style = style
        self.title = title
        self.message = message
        self.action = action
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbol)
                .foregroundStyle(tint)
                .imageScale(.medium)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.callout).fontWeight(.medium)
                if let message { Text(message).font(.caption).foregroundStyle(.secondary) }
            }
            Spacer(minLength: 8)
            if let action {
                Button(action.title, action: action.handler)
                    .controlSize(.small)
                    .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(backgroundFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(tint.opacity(0.25), lineWidth: 1)
        )
    }

    private var symbol: String {
        switch style {
        case .info: return "info.circle"
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.octagon.fill"
        }
    }

    private var tint: Color {
        switch style {
        case .info: return .accentColor
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        }
    }

    private var backgroundFill: AnyShapeStyle {
        AnyShapeStyle(tint.opacity(0.08))
    }
}
