import SwiftUI

struct CopyAllButton: View {
    var title = "Copy All"
    let action: () -> Void

    @State private var isHovered = false
    @State private var isCopied = false

    var body: some View {
        Button {
            action()
            withAnimation(.easeInOut(duration: 0.2)) {
                isCopied = true
            }
            Task {
                try? await Task.sleep(for: .seconds(2))
                withAnimation(.easeInOut(duration: 0.2)) {
                    isCopied = false
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 10))
                Text(isCopied ? "Copied!" : title)
                    .font(.system(size: 11))
            }
            .foregroundStyle(isCopied ? .green : (isHovered ? .primary : .secondary))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.primary.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}
