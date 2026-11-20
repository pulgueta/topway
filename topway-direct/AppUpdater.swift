import AppKit
import Combine
import Sparkle

/// The Sparkle updater of the direct build. The App Store build does not have this type, because
/// the App Store updates that build.
///
/// Topway has no Dock icon (`LSUIElement`), so a scheduled update alert can show behind other
/// windows. The gentle reminders put Topway in the Dock with a badge while the update shows, and
/// put it back in the background when the update session ends. See
/// https://sparkle-project.org/documentation/gentle-reminders/.
@Observable
final class AppUpdater: NSObject, SPUStandardUserDriverDelegate {
    /// `false` when the updater did not start, and while Sparkle downloads data in the background.
    private(set) var canCheckForUpdates = false

    /// Sparkle keeps this value in the user defaults, and it can change it after its permission
    /// prompt. Sparkle sends each change back to Topway, also a change that Topway made, so Topway
    /// sends only a different value to Sparkle. Thus Sparkle gets only the changes of the user.
    var automaticallyChecksForUpdates = false {
        didSet {
            guard let updater = controller?.updater,
                automaticallyChecksForUpdates != updater.automaticallyChecksForUpdates
            else { return }
            updater.automaticallyChecksForUpdates = automaticallyChecksForUpdates
        }
    }

    /// The permission prompt of Sparkle can turn this on. It is `false` while Sparkle does not
    /// check for updates automatically, but Sparkle keeps the choice of the user for when the
    /// checks start again. As for `automaticallyChecksForUpdates`, Topway sends only a different
    /// value to Sparkle.
    var automaticallyDownloadsUpdates = false {
        didSet {
            guard let updater = controller?.updater,
                automaticallyDownloadsUpdates != updater.automaticallyDownloadsUpdates
            else { return }
            updater.automaticallyDownloadsUpdates = automaticallyDownloadsUpdates
        }
    }

    /// `nil` in a build with no update key, and in a preview. Then Sparkle never starts.
    @ObservationIgnored private var controller: SPUStandardUpdaterController?
    @ObservationIgnored private var subscriptions: Set<AnyCancellable> = []

    /// `false` in a build with no update key, and in a preview. Then the controls are off.
    var isAvailable: Bool { controller != nil }

    /// - Parameter startsUpdater: `false` gives an updater that never starts, for a preview.
    init(startsUpdater: Bool = true) {
        super.init()
        // With no valid key, Sparkle does not start, and it shows an error at each launch.
        guard
            startsUpdater,
            // The build fills `SUPublicEDKey` from `SPARKLE_PUBLIC_ED_KEY`.
            Self.hasPublicKey(infoValue: Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey"))
        else { return }

        // The controller starts the updater. It keeps only a weak reference to its delegate.
        let controller = SPUStandardUpdaterController(
            startingUpdater: true, updaterDelegate: nil, userDriverDelegate: self)
        self.controller = controller
        // Sparkle sends the KVO changes on the main thread.
        controller.updater.publisher(for: \.canCheckForUpdates)
            .sink { [weak self] in self?.canCheckForUpdates = $0 }
            .store(in: &subscriptions)
        controller.updater.publisher(for: \.automaticallyChecksForUpdates)
            .sink { [weak self] in self?.automaticallyChecksForUpdates = $0 }
            .store(in: &subscriptions)
        controller.updater.publisher(for: \.automaticallyDownloadsUpdates)
            .sink { [weak self] in self?.automaticallyDownloadsUpdates = $0 }
            .store(in: &subscriptions)
    }

    /// `true` when the Info.plist value is a key. A build with no key gives an empty value.
    static func hasPublicKey(infoValue value: Any?) -> Bool {
        guard let text = value as? String else { return false }
        let key = text.trimmingCharacters(in: .whitespacesAndNewlines)
        // A build setting that the build did not expand stays as `$(NAME)`.
        return !key.isEmpty && !key.hasPrefix("$(")
    }

    /// Brings Topway to the front first, so that the update window shows above other apps.
    func checkForUpdates() {
        NSApp.activate()
        controller?.updater.checkForUpdates()
    }

    // MARK: - Gentle reminders

    var supportsGentleScheduledUpdateReminders: Bool { true }

    func standardUserDriverWillHandleShowingUpdate(
        _ handleShowingUpdate: Bool, forUpdate update: SUAppcastItem, state: SPUUserUpdateState
    ) {
        // While the update shows, Topway is in the Dock and in the app switcher, so the user can
        // find the update window again. For a check that the user did not start, the badge tells
        // the user that an update is available.
        NSApp.setActivationPolicy(.regular)
        if !state.userInitiated {
            NSApp.dockTile.badgeLabel = "1"
        }
    }

    func standardUserDriverDidReceiveUserAttention(forUpdate update: SUAppcastItem) {
        NSApp.dockTile.badgeLabel = nil
    }

    func standardUserDriverWillFinishUpdateSession() {
        NSApp.setActivationPolicy(.accessory)
    }
}
