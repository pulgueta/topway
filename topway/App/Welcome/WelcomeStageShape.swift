import SwiftUI

/// The stage of the welcome window: a rectangle with a 45° cut at the top leading corner.
/// The other corners are square, because the stage goes to the window edges.
nonisolated struct WelcomeStageShape: Shape {
    /// The length of the cut along the top edge and along the leading edge.
    let cut: CGFloat

    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX + cut, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cut))
            path.closeSubpath()
        }
    }
}
