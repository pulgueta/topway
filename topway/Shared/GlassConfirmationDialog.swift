import SwiftUI
import TopwayCore

/// A confirmation presented as a floating Liquid Glass dialog over a dimmed backdrop,
/// layered inside the current view.
///
/// Used instead of the native `confirmationDialog`/`alert`, which present in a
/// separate window and steal key focus. That dismisses the `MenuBarExtra(.window)`
/// popover out from under the dialog. Present it with the `destructiveConfirmation(...)`
/// modifier, attached to a view that fills the popover so the backdrop covers the
/// whole surface.
@MainActor
struct GlassConfirmationDialog: View {
    let request: ConfirmationRequest
    var isLoading: Bool = false
    let onConfirm: () -> Void
    let onCancel: () -> Void

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
            // Dimmed backdrop; tapping outside cancels (unless mid-action).
            Rectangle()
                .fill(.black.opacity(0.3))
                .ignoresSafeArea()
                .contentShape(.rect)
                .onTapGesture {
                    if !isLoading { onCancel() }
                }

            card
                .padding(28)
        }
        .task {
            isNameFieldFocused = request.harm.needsTypedName
        }
    }

    private var card: some View {
        VStack(spacing: 14) {
            if isProduction {
                productionLabel
            }

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(request.isDestructive ? .red : .orange)

                Text(request.title)
                    .font(.system(size: 14, weight: .semibold))
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
            }

            Text(request.message)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            if request.harm.needsTypedName {
                nameField
            }

            buttons
        }
        .padding(18)
        .frame(maxWidth: 264)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
        .accessibilityAddTraits(.isModal)
    }

    private var productionLabel: some View {
        Text("Production environment")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(Color.red))
            .frame(maxWidth: .infinity, alignment: .leading)
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
                .disabled(isLoading)
                .accessibilityLabel("Name to confirm")
        }
    }

    private var buttons: some View {
        HStack(spacing: 10) {
            Button("Cancel", action: onCancel)
                .buttonStyle(.bordered)
                .controlSize(.large)
                .keyboardShortcut(.cancelAction)
                .disabled(isLoading)

            Button(action: onConfirm) {
                HStack(spacing: 4) {
                    if isLoading {
                        ProgressView()
                            .controlSize(.small)
                            .scaleEffect(0.8)
                    }
                    Text(request.actionTitle)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(request.isDestructive ? .red : .accentColor)
            .controlSize(.large)
            .disabled(isLoading || !canConfirm)
        }
    }
}

#Preview {
    VStack {
        Text("Background content")
        Spacer()
    }
    .frame(width: 320, height: 400)
    .destructiveConfirmation(
        request: ConfirmationRequest(
            harm: .high,
            title: "Delete My Project?",
            message: "This removes all services, deployments and data in the project.",
            actionTitle: "Delete project",
            isDestructive: true,
            targetName: "My Project",
            environmentName: "production",
            perform: {}
        ),
        onConfirm: {},
        onCancel: {}
    )
}
