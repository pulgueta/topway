import Testing
import TopwayCore

struct LogScrollMetricsTests {
    /// A 1,000-point log in a 300-point view. An offset of 700 shows the bottom.
    private func metrics(offset: Double, height: Double = 1_000) -> LogScrollMetrics {
        LogScrollMetrics(offsetY: offset, contentHeight: height, visibleMaxY: offset + 300)
    }

    @Test("A bounce at the bottom keeps follow on")
    func bounceAtBottom() {
        let bounced = metrics(offset: 690).isFollowing(
            after: metrics(offset: 720), wasFollowing: true)

        #expect(bounced)
    }

    @Test("A real scroll up turns follow off")
    func scrollUp() {
        #expect(!metrics(offset: 400).isFollowing(after: metrics(offset: 700), wasFollowing: true))
    }

    @Test("A scroll back to the bottom turns follow on")
    func backToBottom() {
        #expect(metrics(offset: 700).isFollowing(after: metrics(offset: 400), wasFollowing: false))
    }

    @Test("New lines that make the log taller do not change follow")
    func contentGrows() {
        let old = metrics(offset: 700)
        let taller = metrics(offset: 700, height: 1_200)

        #expect(taller.isFollowing(after: old, wasFollowing: true))
        #expect(!taller.isFollowing(after: old, wasFollowing: false))
    }
}
