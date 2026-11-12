import SwiftUI
import TopwayCore

/// A confirmation that shows as a Liquid Glass card above a dimmed backdrop, in the
/// menu bar window.
///
/// Do not use `confirmationDialog` or `alert`. They open a separate window and take the
/// key focus, and that closes the `MenuBarExtra(.window)` window. Show this dialog with the
/// `destructiveConfirmation(...)` modifier on a view that fills the window, so the backdrop
/// covers all content.
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
            // A click outside the card cancels, but not while the action runs.
            Rectangle()
                .fill(.black.opacity(0.3))
                .ignoresSafeArea()
                .contentShape(.rect)
                .onTapGesture {
                    if !isLoading { onCancel() }
                }
                .accessibilityHidden(true)

            card
                .padding(24)
        }
        .task {
            isNameFieldFocused = request.harm.needsTypedName
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isProduction {
                productionLabel
            }

            Label {
                Text(request.title)
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(request.isDestructive ? .red : .orange)
            }
            .font(.headline)
            .accessibilityAddTraits(.isHeader)

            Text(request.message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if request.harm.needsTypedName {
                nameField
            }

            buttons
        }
        .padding(18)
        .frame(maxWidth: 300)
        // The one custom glass surface of the app. Its buttons are not glass, because
        // glass on glass is hard to read.
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }

    private var productionLabel: some View {
        Text("Production environment")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(.red, in: .capsule)
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Type \(request.targetName) to continue.")
                .font(.callout.weight(.medium))
                .fixedSize(horizontal: false, vertical: true)

            TextField("Name to confirm", text: $typedText, prompt: Text(request.targetName))
                .textFieldStyle(.roundedBorder)
                .font(.body.monospaced())
                .autocorrectionDisabled()
                .focused($isNameFieldFocused)
                .disabled(isLoading)
        }
    }

    private var buttons: some View {
        HStack(spacing: 10) {
            Button("Cancel") { onCancel() }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)
                .disabled(isLoading)

            confirmButton
        }
        .controlSize(.large)
    }

    /// Return confirms only an action that is not destructive, so a fast Return cannot delete.
    @ViewBuilder
    private var confirmButton: some View {
        let button = Button {
            onConfirm()
        } label: {
            HStack(spacing: 6) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
                Text(request.actionTitle)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(request.isDestructive ? .red : .accentColor)
        .disabled(isLoading || !canConfirm)

        if request.isDestructive {
            button
        } else {
            button.keyboardShortcut(.defaultAction)
        }
    }
}

#Preview {
    VStack {
        Text("Background content")
        Spacer()
    }
    .frame(width: Layout.windowWidth, height: Layout.windowHeight)
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
