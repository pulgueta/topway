import SwiftUI
import TopwayCore

/// Shows how the logs screen gets its lines, with a symbol, a text and a help text.
struct LogConnectionLabel: View {
    let state: LogStreamState

    var body: some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: symbol)
                .foregroundStyle(color)
        }
        .help(help)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Connection: \(text)")
    }

    private var text: String {
        switch state {
        case .connecting: "Connecting…"
        case .connection(.live): "Live"
        case .connection(.reconnecting): "Reconnecting…"
        case .connection(.polling): "Checks every 5 seconds"
        case .ended: "End of log"
        case .stopped: "Stopped"
        }
    }

    private var symbol: String {
        switch state {
        case .connecting: "ellipsis"
        case .connection(.live): "dot.radiowaves.left.and.right"
        case .connection(.reconnecting): "arrow.triangle.2.circlepath"
        case .connection(.polling): "clock.arrow.circlepath"
        case .ended: "checkmark.circle"
        case .stopped: "stop.circle"
        }
    }

    private var color: Color {
        switch state {
        case .connection(.live): .green
        case .connection(.reconnecting): .orange
        default: .secondary
        }
    }

    private var help: String {
        switch state {
        case .connecting: "Topway connects to Railway."
        case .connection(.live): "New lines show when they arrive."
        case .connection(.reconnecting): "The live connection stopped. Topway connects again."
        case .connection(.polling):
            "The live connection is not available. Topway reads the logs every 5 seconds."
        case .ended: "This log has no more lines."
        case .stopped: "An error stopped this log."
        }
    }
}
