import SwiftUI

public struct SymbolPickerView: View {
    @Binding var selection: String?
    let symbols: [String]

    public init(
        selection: Binding<String?>,
        symbols: [String] = SymbolPickerView.defaultSymbols
    ) {
        self._selection = selection
        self.symbols = symbols
    }

    public static let defaultSymbols: [String] = [
        "square.stack.3d.up.fill", "macbook", "briefcase.fill", "graduationcap.fill",
        "paintpalette.fill", "gamecontroller.fill", "music.note.list", "message.fill",
        "envelope.fill", "sparkles", "hammer.fill", "terminal.fill",
        "camera.fill", "photo.stack.fill", "globe", "bolt.fill",
        "moon.fill", "sun.max.fill", "figure.run", "cart.fill",
        "book.fill", "newspaper.fill", "heart.fill", "star.fill"
    ]

    public var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.adaptive(minimum: 36)), count: 1), spacing: 6) {
            ForEach(symbols, id: \.self) { symbol in
                Button {
                    selection = symbol
                } label: {
                    Image(systemName: symbol)
                        .frame(width: 28, height: 28)
                        .padding(4)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(selection == symbol ? Color.accentColor.opacity(0.25) : Color.clear)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .frame(width: 220)
    }
}
