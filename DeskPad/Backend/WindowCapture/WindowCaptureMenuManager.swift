import AppKit
import ReSwift

@MainActor
final class WindowCaptureMenuManager: SubscriberViewController<WindowCaptureMenuViewData> {
    private var captureMenu: NSMenu?
    private let windowCaptureManager: WindowCaptureManager

    init(windowCaptureManager: WindowCaptureManager) {
        self.windowCaptureManager = windowCaptureManager
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func createMenu() -> NSMenu {
        let menu = NSMenu(title: "Capture")
        captureMenu = menu
        updateMenu()
        return menu
    }

    override func update(with _: WindowCaptureMenuViewData) {
        updateMenu()
    }

    private func updateMenu() {
        guard let menu = captureMenu else { return }

        menu.removeAllItems()

        let fullDesktopItem = NSMenuItem(
            title: "Full Virtual Desktop",
            action: #selector(selectFullDesktop),
            keyEquivalent: ""
        )
        fullDesktopItem.target = self

        let state = store.state?.windowCaptureState
        if case .fullDesktop = state?.captureMode {
            fullDesktopItem.state = .on
        }

        menu.addItem(fullDesktopItem)
        menu.addItem(NSMenuItem.separator())

        if let windows = state?.availableWindows, !windows.isEmpty {
            for window in windows {
                let menuItem = NSMenuItem(
                    title: "\(window.applicationName): \(window.title)",
                    action: #selector(selectWindow(_:)),
                    keyEquivalent: ""
                )
                menuItem.target = self
                menuItem.representedObject = window.windowID

                if case let .window(selectedID) = state?.captureMode, selectedID == window.windowID {
                    menuItem.state = .on
                }

                menu.addItem(menuItem)
            }
        } else {
            let noWindowsItem = NSMenuItem(
                title: "No Windows Available",
                action: nil,
                keyEquivalent: ""
            )
            noWindowsItem.isEnabled = false
            menu.addItem(noWindowsItem)
        }
    }

    @objc private func selectFullDesktop() {
        store.dispatch(WindowCaptureAction.setMode(.fullDesktop))

        Task {
            windowCaptureManager.stopCapture()
        }
    }

    @objc private func selectWindow(_ sender: NSMenuItem) {
        guard let windowID = sender.representedObject as? CGWindowID else {
            return
        }

        store.dispatch(WindowCaptureAction.setMode(.window(windowID)))

        guard let displayID = store.state?.screenConfigurationState.displayID else {
            return
        }

        Task {
            do {
                try await windowCaptureManager.startCapture(
                    mode: .window(windowID),
                    virtualDisplayID: displayID
                )
            } catch {
                store.dispatch(WindowCaptureAction.setMode(.fullDesktop))
            }
        }
    }
}

struct WindowCaptureMenuViewData: ViewDataType {
    struct StateFragment: Equatable {
        let windowCaptureState: WindowCaptureState
    }

    static func fragment(of appState: AppState) -> StateFragment {
        return StateFragment(windowCaptureState: appState.windowCaptureState)
    }

    let captureMode: CaptureMode
    let availableWindows: [CapturedWindow]

    init(for fragment: StateFragment) {
        captureMode = fragment.windowCaptureState.captureMode
        availableWindows = fragment.windowCaptureState.availableWindows
    }
}
