import Foundation
import ReSwift
import ScreenCaptureKit

enum CaptureMode: Equatable {
    case fullDesktop
    case window(CGWindowID)
}

struct CapturedWindow: Equatable {
    let windowID: CGWindowID
    let title: String
    let applicationName: String
    let ownerPID: pid_t

    static func == (lhs: CapturedWindow, rhs: CapturedWindow) -> Bool {
        return lhs.windowID == rhs.windowID
    }
}

struct WindowCaptureState: Equatable {
    let captureMode: CaptureMode
    let availableWindows: [CapturedWindow]
    let isCapturing: Bool

    static var initialState: WindowCaptureState {
        return WindowCaptureState(
            captureMode: .fullDesktop,
            availableWindows: [],
            isCapturing: false
        )
    }
}

func windowCaptureReducer(action: Action, state: WindowCaptureState) -> WindowCaptureState {
    switch action {
    case let WindowCaptureAction.setMode(mode):
        return WindowCaptureState(
            captureMode: mode,
            availableWindows: state.availableWindows,
            isCapturing: state.isCapturing
        )

    case let WindowCaptureAction.updateAvailableWindows(windows):
        return WindowCaptureState(
            captureMode: state.captureMode,
            availableWindows: windows,
            isCapturing: state.isCapturing
        )

    case let WindowCaptureAction.setCapturing(isCapturing):
        return WindowCaptureState(
            captureMode: state.captureMode,
            availableWindows: state.availableWindows,
            isCapturing: isCapturing
        )

    default:
        return state
    }
}
