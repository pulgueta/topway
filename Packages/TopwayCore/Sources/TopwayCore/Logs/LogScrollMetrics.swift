import Foundation

/// The scroll position of the log lines. It decides if the logs screen follows new lines.
public struct LogScrollMetrics: Equatable, Sendable {
    /// The distance from the bottom that still counts as the bottom.
    static let bottomTolerance: CGFloat = 16

    public let offsetY: CGFloat
    public let contentHeight: CGFloat
    public let visibleMaxY: CGFloat

    public init(offsetY: CGFloat, contentHeight: CGFloat, visibleMaxY: CGFloat) {
        self.offsetY = offsetY
        self.contentHeight = contentHeight
        self.visibleMaxY = visibleMaxY
    }

    /// At the bottom, follow is on, also after a bounce that moves up a little. Else a move up
    /// with no change in size comes from the user, so follow is off. Else follow does not change.
    public func isFollowing(after old: LogScrollMetrics, wasFollowing: Bool) -> Bool {
        if visibleMaxY >= contentHeight - Self.bottomTolerance {
            return true
        }
        if contentHeight == old.contentHeight, offsetY < old.offsetY {
            return false
        }
        return wasFollowing
    }
}
