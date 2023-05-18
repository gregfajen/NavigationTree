import Dependencies
import SwiftUI
import Trees

public class NavigationStore {
    @Streamed
    public var desiredTree: Tree<Blueprint>

    public init(blueprint: some CompleteBlueprint) {
        self.desiredTree = Blueprint.makeTree(from: blueprint)
    }
}

extension NavigationStore: DependencyKey {
    public static var liveValue: NavigationStore {
        NavigationStore(blueprint: .default)
    }
}

public extension DependencyValues {
    var navigationStore: NavigationStore {
        get { self[NavigationStore.self] }
        set { self[NavigationStore.self] = newValue }
    }
}

extension CompleteBlueprint where Self == LeafBlueprint {
    static var `default`: LeafBlueprint {
        LeafBlueprint(id: "default") {
            Color.black.ignoresSafeArea()
        }
    }
}
