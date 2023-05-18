import ComposableArchitecture
import NavigationTree
import PresentationStyles
import SwiftUI

public struct Demo: View {
    let navigationTree: NavigationTree
    let store: StoreOf<DemoFeature>

    @Dependency(\.navigationStore)
    static var navigation

    @MainActor
    public init() {
        self.store = _store
        self.navigationTree = NavigationTree(
            initial: Demo.splashBlueprint,
            desiredStateStream: Demo.navigation.$desiredTree.map(\.blueprint).asStream()
        )

        ViewStore(store).send(.startup)
    }

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            navigationTree
        }
    }
}
