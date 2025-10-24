import AppKit
import ReSwift

@MainActor
class SubscriberViewController<ViewData: ViewDataType>: NSViewController, @preconcurrency StoreSubscriber {
    typealias StoreSubscriberStateType = ViewData.StateFragment

    override func viewWillAppear() {
        super.viewWillAppear()

        store.subscribe(self) { subscription in
            subscription
                .select(ViewData.fragment(of:))
                .skipRepeats()
        }
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()

        store.unsubscribe(self)
    }

    func newState(state: ViewData.StateFragment) {
        update(with: ViewData(for: state))
    }

    func update(with _: ViewData) {
        fatalError("Please override the SubscriberViewController update method.")
    }
}

protocol ViewDataType {
    associatedtype StateFragment: Equatable

    static func fragment(of appState: AppState) -> StateFragment

    init(for fragment: StateFragment)
}
