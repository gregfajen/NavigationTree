import ComposableArchitecture
import NavigationTree
import SwiftUI

var _store = Store(
    initialState: DemoFeature.State(),
    reducer: DemoFeature()
)

struct DemoFeature: ReducerProtocol {
    @Dependency(\.navigationStore)
    var navigation

    enum Destination {
        case child
    }

    struct State: Equatable {
        var mainDestination: Destination?
        var selectedTab: TabIndex = .lhs
        var profileState = ProfileFeature.State()

        init() { }
    }

    enum Action: Hashable {
        case startup

        case goToSplash
        case goToMain
        case goToTabs
        case selectTab(TabIndex)

        case presentChild
        case dismiss

        case profileAction(ProfileFeature.Action)
    }

    var body: some ReducerProtocolOf<Self> {
        Reduce { state, action in
            switch action {
                case .startup:
                    return .send(.goToMain)
                        .delay(
                            for: 1,
                            scheduler: DispatchQueue.main
                        )
                        .eraseToEffect()

                case .goToSplash:
                    navigation.desiredTree.replace(with: Demo.splashBlueprint)
                    return .send(.startup)

                case .goToMain:
                    navigation.desiredTree.replace(with: Demo.mainBlueprint())
                    return .none

                case .goToTabs:
                    navigation.desiredTree.replace(with: Demo.tabsBlueprint)
                    return .none

                case .presentChild:
                    state.mainDestination = .child
                    return .none

                case .dismiss:
                    state.mainDestination = nil
                    return .none

                case let .selectTab(index):
                    try! navigation.desiredTree.mutateTabs { tabs in
                        tabs.selection = index
                    }
                    state.selectedTab = index

                    return .none

                case .profileAction:
                    return .none
            }
        }

        Scope(state: \.profileState, action: /Action.profileAction) {
            ProfileFeature()
        }
    }
}
