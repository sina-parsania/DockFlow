import SwiftUI

public struct ColorSwatchPicker: View {
    @Binding var selectionHex: String?
    let swatches: [String]

    public init(selectionHex: Binding<String?>, swatches: [String] = PresetPalette.swatches) {
        self._selectionHex = selectionHex
        self.swatches = swatches
    }

    public var body: some View {
        HStack(spacing: 6) {
            Button {
                selectionHex = nil
            } label: {
                Circle()
                    .fill(.tertiary)
                    .frame(width: 18, height: 18)
                    .overlay(
                        Circle().stroke(selectionHex == nil ? Color.primary : .clear, lineWidth: 2)
                    )
            }
            .buttonStyle(.plain)

            ForEach(swatches, id: \.self) { hex in
                Button {
                    selectionHex = hex
                } label: {
                    Circle()
                        .fill(Color(hex: hex) ?? .gray)
                        .frame(width: 18, height: 18)
                        .overlay(
                            Circle().stroke(selectionHex == hex ? Color.primary : .clear, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
