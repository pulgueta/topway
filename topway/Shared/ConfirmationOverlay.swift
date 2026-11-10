import SwiftUI
import TopwayCore

struct ConfirmationOverlay: View {
    let request: ConfirmationRequest
    let onCancel: () -> Void
    let onConfirm: () -> Void

    @State private var typedText = ""
    @FocusState private var isNameFieldFocused: Bool

    private var canConfirm: Bool {
        request.harm.canConfirm(typedText: typedText, targetName: request.targetName)
    }

    private var isProduction: Bool {
        request.environmentName.map(ConfirmationRules.isProduction(environmentName:)) ?? false
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .contentShape(Rectangle())

            VStack(alignment: .leading, spacing: 12) {
                if isProduction {
                    productionLabel
                }

                Text(request.title)
                    .font(.system(size: 14, weight: .semibold))
                    .fixedSize(horizontal: false, vertical: true)

                Text(request.message)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if request.harm.needsTypedName {
                    nameField
                }

                buttons
            }
            .padding(16)
            .frame(width: 280, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
            .accessibilityAddTraits(.isModal)
        }
        .task {
            isNameFieldFocused = request.harm.needsTypedName
        }
    }

    private var productionLabel: some View {
        Text("Production environment")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(Color.red))
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Type \(request.targetName) to continue.")
                .font(.system(size: 12, weight: .medium))
                .fixedSize(horizontal: false, vertical: true)

            TextField(request.targetName, text: $typedText)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 13, design: .monospaced))
                .autocorrectionDisabled()
                .focused($isNameFieldFocused)
                .accessibilityLabel("Name to confirm")
        }
    }

    private var buttons: some View {
        HStack {
            Button("Cancel", action: onCancel)
                .keyboardShortcut(.cancelAction)

            Spacer()

            Button(request.actionTitle, role: request.isDestructive ? .destructive : nil) {
                onConfirm()
            }
            .buttonStyle(.borderedProminent)
            .tint(request.isDestructive ? .red : .accentColor)
            .disabled(!canConfirm)
        }
        .controlSize(.regular)
    }
}
