import Cocoa
import ReSwift

enum AppDelegateAction: Action {
    case didFinishLaunching
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var windowCaptureManager: WindowCaptureManager!
    var windowCaptureMenuManager: WindowCaptureMenuManager!

    func applicationDidFinishLaunching(_: Notification) {
        windowCaptureManager = WindowCaptureManager()
        windowCaptureMenuManager = WindowCaptureMenuManager(windowCaptureManager: windowCaptureManager)

        // Manually subscribe menu manager since it's not in view hierarchy
        store.subscribe(windowCaptureMenuManager) { subscription in
            subscription
                .select(WindowCaptureMenuViewData.fragment(of:))
                .skipRepeats()
        }

        let viewController = ScreenViewController()
        window = NSWindow(contentViewController: viewController)
        window.delegate = viewController
        window.title = "DeskPad"
        window.makeKeyAndOrderFront(nil)
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.titleVisibility = .hidden
        window.backgroundColor = .white
        window.contentMinSize = CGSize(width: 400, height: 300)
        window.contentMaxSize = CGSize(width: 3840, height: 2160)
        window.styleMask.insert(.resizable)
        window.collectionBehavior.insert(.fullScreenNone)

        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        let appSubMenu = NSMenu(title: "DeskPad")
        let quitMenuItem = NSMenuItem(
            title: "Quit DeskPad",
            action: #selector(NSApp.terminate),
            keyEquivalent: "q"
        )
        appSubMenu.addItem(quitMenuItem)
        appMenuItem.submenu = appSubMenu

        let captureMenuItem = NSMenuItem()
        captureMenuItem.submenu = windowCaptureMenuManager.createMenu()
        captureMenuItem.title = "Capture"

        mainMenu.items = [appMenuItem, captureMenuItem]
        NSApplication.shared.mainMenu = mainMenu

        store.dispatch(AppDelegateAction.didFinishLaunching)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        return true
    }
}
