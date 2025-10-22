import ReSwift

struct AppState: Equatable {
    let mouseLocationState: MouseLocationState
    let screenConfigurationState: ScreenConfigurationState
    let windowCaptureState: WindowCaptureState

    static var initialState: AppState {
        return AppState(
            mouseLocationState: .initialState,
            screenConfigurationState: .initialState,
            windowCaptureState: .initialState
        )
    }
}

func appReducer(action: Action, state: AppState?) -> AppState {
    let state = state ?? .initialState

    return AppState(
        mouseLocationState: mouseLocationReducer(action: action, state: state.mouseLocationState),
        screenConfigurationState: screenConfigurationReducer(action: action, state: state.screenConfigurationState),
        windowCaptureState: windowCaptureReducer(action: action, state: state.windowCaptureState)
    )
}
