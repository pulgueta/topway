import SwiftUI
import TopwayCore

/// One service in the projects list. It opens the service screen.
struct ServiceRow: View {
    let service: Service
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: Layout.controlSpacing) {
                Image(systemName: "cube")
                    .foregroundStyle(.secondary)
                    .frame(width: 16)

                Text(service.name)
                    .lineLimit(1)

                Spacer(minLength: Layout.controlSpacing)

                // Always visible, to show that the row opens a screen.
                Image(systemName: "chevron.forward")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(RowButtonStyle())
        .help("Show the variables and deployments of \(service.name).")
        .accessibilityHint("Shows the variables and deployments.")
    }
}
