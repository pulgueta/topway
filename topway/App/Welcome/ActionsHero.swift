import SwiftUI

/// The picture of the actions page: a small copy of the live logs and, in front of it, a
/// copy of the confirmation for a restart in production. The texts come from the sample
/// data and from the restart confirmation. The picture is only decoration.
struct ActionsHero: View {
    var body: some View {
        ZStack {
            logsCard
                .offset(x: -96, y: -22)
            confirmationCard
                .offset(x: 92, y: 22)
        }
        .foregroundStyle(.white)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var logsCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Deploy logs")
                .font(.system(size: 11, weight: .semibold))
            logLine("GET /api/cart 200 12ms")
            logLine(
                "Cache miss rate above 40%", symbol: "exclamationmark.triangle.fill", color: .orange
            )
            logLine(
                "Request to inventory failed", symbol: "exclamationmark.octagon.fill", color: .red)
        }
        .padding(12)
        .frame(width: 236, alignment: .leading)
        .background { WelcomeSurface(cornerRadius: 14) }
    }

    /// A log line. As in the logs screen, a warning or an error has a symbol in color. The
    /// line does not wrap: its end can go behind the confirmation.
    private func logLine(_ text: String, symbol: String? = nil, color: Color = .clear) -> some View
    {
        HStack(spacing: 5) {
            Image(systemName: symbol ?? "circle")
                .foregroundStyle(color)
                .frame(width: 12)
            Text(verbatim: text)
                .fixedSize()
        }
        .font(.system(size: 10, design: .monospaced))
    }

    private var confirmationCard: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label("Production environment", systemImage: "exclamationmark.octagon.fill")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.red)

            Label {
                Text("Restart web in production?")
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            }
            .font(.system(size: 12, weight: .semibold))

            Text("The service stops for a short time.")
                .font(.system(size: 10))

            HStack(spacing: 6) {
                Spacer()
                pictureButton("Cancel", fill: .white.opacity(0.16))
                pictureButton("Restart", fill: WelcomePalette.accent)
            }
            .padding(.top, 2)
        }
        .padding(12)
        .frame(width: 248, alignment: .leading)
        .background { WelcomeSurface(cornerRadius: 14, isOpaque: true) }
        .shadow(color: .black.opacity(0.35), radius: 16, y: 8)
    }

    /// A button in the picture. It looks like a button, but it is not a control.
    private func pictureButton(_ title: LocalizedStringKey, fill: Color) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(fill, in: .capsule)
    }
}
