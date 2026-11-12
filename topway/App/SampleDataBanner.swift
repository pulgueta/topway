import SwiftUI

/// Tells the user that the app shows sample data, and lets the user exit sample mode.
struct SampleDataBanner: View {
    let onExit: () -> Void

    var body: some View {
        HStack(spacing: Layout.controlSpacing) {
            // The text keeps the primary color. Orange text on the orange tint is hard to read.
            Label {
                Text("Sample data")
            } icon: {
                Image(systemName: "testtube.2")
                    .foregroundStyle(.orange)
            }
            .font(.callout.weight(.semibold))
            .help("Topway does not connect to Railway. Changes stay until you exit.")

            Spacer()

            Button("Exit sample data") { onExit() }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Go back to the start screen.")
        }
        .padding(.horizontal, Layout.barPadding)
        .padding(.vertical, 6)
        .background(.orange.opacity(0.12))
    }
}

#Preview {
    SampleDataBanner(onExit: {})
        .frame(width: Layout.windowWidth)
}
