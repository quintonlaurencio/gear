import UIKit
import SwiftUI

class AppLifecycleHandler: ObservableObject {
    static let shared = AppLifecycleHandler()

    // Callbacks for lifecycle events
    private var onDidEnterBackground: (() -> Void)?
    private var onWillEnterForeground: (() -> Void)?

    private init() {
        setupObservers()
    }

    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIScene.didEnterBackgroundNotification,
            object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIScene.willEnterForegroundNotification,
            object: nil)
    }

    @objc private func appDidEnterBackground() {
        print("App entered background")
        onDidEnterBackground?()
    }

    @objc private func appWillEnterForeground() {
        print("App will enter foreground")
        onWillEnterForeground?()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // Public methods to set callbacks
    func setDidEnterBackgroundAction(_ action: @escaping () -> Void) {
        onDidEnterBackground = action
    }

    func setWillEnterForegroundAction(_ action: @escaping () -> Void) {
        onWillEnterForeground = action
    }
}
