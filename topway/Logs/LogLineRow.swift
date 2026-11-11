import SwiftUI
import TopwayCore

/// One log line in a monospaced font. Warnings and errors have a symbol and a color,
/// so the level does not show by color only.
struct LogLineRow: View {
    let line: LogLine

    private var symbol: String? {
        switch line.level {
        case .info: nil
        case .warning: "exclamationmark.triangle.fill"
        case .error: "xmark.octagon.fill"
        }
    }

    private var color: Color {
        switch line.level {
        case .info: .primary
        case .warning: .orange
        case .error: .red
        }
    }

    private var accessibilityText: String {
        switch line.level {
        case .info: line.message
        case .warning: "Warning: \(line.message)"
        case .error: "Error: \(line.message)"
        }
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Group {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 9))
                        .foregroundStyle(color)
                } else {
                    Color.clear
                }
            }
            .frame(width: 10, height: 10)

            Text(line.message)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }
}
