import Foundation
import ReSwift
import ScreenCaptureKit

enum WindowCaptureAction: Action {
    case setMode(CaptureMode)
    case updateAvailableWindows([CapturedWindow])
    case setCapturing(Bool)
    case refreshWindowList
}

private var windowListRefreshTimer: Timer?

func windowCaptureSideEffect() -> SideEffect {
    return { _, dispatch, _ in
        if windowListRefreshTimer == nil {
            windowListRefreshTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                Task {
                    await refreshWindowList(dispatch: dispatch)
                }
            }

            Task {
                await refreshWindowList(dispatch: dispatch)
            }
        }
    }
}

@MainActor
private func refreshWindowList(dispatch: @escaping DispatchFunction) async {
    do {
        let content = try await SCShareableContent.excludingDesktopWindows(
            false,
            onScreenWindowsOnly: false
        )

        let windows = content.windows.compactMap { window -> CapturedWindow? in
            guard let appName = window.owningApplication?.applicationName,
                  let title = window.title,
                  !appName.isEmpty,
                  !title.isEmpty,
                  appName != "Window Server",
                  appName != "Dock",
                  appName != "DeskPad",
                  window.frame.width >= 800,
                  window.frame.height >= 600,
                  window.isOnScreen
            else {
                return nil
            }

            return CapturedWindow(
                windowID: window.windowID,
                title: title,
                applicationName: appName,
                ownerPID: window.owningApplication?.processID ?? 0
            )
        }

        dispatch(WindowCaptureAction.updateAvailableWindows(windows))
    } catch {
        dispatch(WindowCaptureAction.updateAvailableWindows([]))
    }
}
