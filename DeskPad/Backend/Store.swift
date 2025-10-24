import Foundation
import ReSwift

// Global store follows ReSwift pattern - synchronisation handled by ReSwift internally
nonisolated(unsafe) let store = Store<AppState>(
    reducer: appReducer,
    state: AppState.initialState,
    middleware: [
        sideEffectsMiddleware,
    ]
)
