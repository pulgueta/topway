import SwiftUI

/// Tells the user that the app shows sample data, and lets the user exit sample mode.
struct SampleDataBanner: View {
    let onExit: () -> Void

    var body: some View {
        HStack(spacing: Layout.controlSpacing) {
            Label("Sample data", systemImage: "testtube.2")
                .font(.callout.weight(.semibold))
                .foregroundStyle(.orange)
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
