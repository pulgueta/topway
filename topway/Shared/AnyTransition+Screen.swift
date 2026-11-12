import SwiftUI

extension AnyTransition {
    /// A screen one level down moves in from the trailing edge.
    /// With Reduce Motion, it only fades.
    static func screen(reduceMotion: Bool) -> AnyTransition {
        reduceMotion ? .opacity : .move(edge: .trailing).combined(with: .opacity)
    }
}
