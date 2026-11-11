import SwiftUI

/// Tells the user that the app shows sample data, and lets the user exit sample mode.
struct SampleDataBanner: View {
    let onExit: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Label("Sample data", systemImage: "testtube.2")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.orange)
                .help("Topway does not connect to Railway. Changes stay until you exit.")

            Spacer()

            Button("Exit sample data", action: onExit)
                .font(.system(size: 11))
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Go back to the start screen.")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.orange.opacity(0.1))
    }
}

#Preview {
    SampleDataBanner(onExit: {})
        .frame(width: 320)
}
