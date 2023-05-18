import Combine
import ComposableArchitecture
import Dependencies
import SwiftUI
import Trees

public struct TreeLink<Content: View>: View {
    @Environment(\.slabProxy)
    var slabProxy

    let shouldBePresented: AsyncStream<Bool>
    let blueprint: PresentationBlueprint
    let content: Content

    @State var proxy: SlabProxy?

    init(
        shouldBePresented: AsyncStream<Bool>,
        blueprint: PresentationBlueprint,
        content: Content
    ) {
        self.shouldBePresented = shouldBePresented
        self.blueprint = blueprint
        self.content = content
    }

    public var body: some View {
        content
            .onChange(of: slabProxy) { proxy = $0 }
            .task {
                for await shouldBePresented in shouldBePresented.dropFirst().removeDuplicates() {
                    if shouldBePresented {
                        try? present()
                    } else {
                        try! dismiss()
                    }
                }
            }
    }

    func present() throws {
        try mutateLocalTree { tree in
            tree.present(Blueprint.makeTree(from: blueprint.child), style: blueprint.style)
        }
    }

    func dismiss() throws {
        try mutateParentTree { tree in
            try tree.dismiss()
        }
    }

    func mutateParentTree(mutation: (inout Tree<Blueprint>) throws -> Void) throws {
        guard let proxy else { return }
        var path = proxy.path

        guard path.popLast() != nil else { return }
        try mutateTree(at: path, mutation: mutation)
    }

    func mutateLocalTree(mutation: (inout Tree<Blueprint>) throws -> Void) throws {
        guard let proxy else { return }
        try mutateTree(at: proxy.path, mutation: mutation)
    }

    func mutateTree(at path: [PathElement], mutation: (inout Tree<Blueprint>) throws -> Void) throws {
        try proxy?.navigationStore.desiredTree.mutateSubtree(at: path, mutation: mutation)
    }
}

class SlabProxy: Equatable {
    @Dependency(\.navigationStore)
    var navigationStore

    weak var slab: Slab?

    var path: [PathElement]

    init() {
        self.path = []
    }

    static let `default` = SlabProxy()

    static func == (lhs: SlabProxy, rhs: SlabProxy) -> Bool {
        lhs.path == rhs.path
    }
}

struct SlabProxyKey: EnvironmentKey {
    static var defaultValue: SlabProxy?
}

extension EnvironmentValues {
    var slabProxy: SlabProxy? {
        get { self[SlabProxyKey.self] }
        set { self[SlabProxyKey.self] = newValue }
    }
}

public extension View {
    func presenting(
        when shouldBePresented: AsyncStream<Bool>,
        tag: String,
        style: some PresentationStyle,
        @ViewBuilder content: @escaping () -> some View
    ) -> some View {
        TreeLink(
            shouldBePresented: shouldBePresented,
            blueprint: PresentationBlueprint(child: LeafBlueprint(id: tag, body: content), style: style),
            content: self
        )
    }

    func presenting<Destination: Equatable, Action>(
        case path: CasePath<Destination, some Any>,
        of store: Store<Destination, Action>,
        dismissAction: Action,
        blueprint: PresentationBlueprint
    ) -> some View {
        ComposableTreeLink(
            parent: self,
            blueprint: blueprint,
            store: store,
            path: path,
            dismissAction: dismissAction
        )
    }

    func presenting<Destination: Equatable, Action>(
        case path: CasePath<Destination, some Any>,
        of store: Store<Destination, Action>,
        dismissAction: Action,
//        blueprint: PresentationBlueprint
        tag: String,
        style: any PresentationStyle,
        content: @escaping () -> some View
    ) -> some View {
        ComposableTreeLink(
            parent: self,
            blueprint: PresentationBlueprint(child: LeafBlueprint(id: tag, body: content), style: style),
            store: store,
            path: path,
            dismissAction: dismissAction
        )
    }
}

struct ComposableTreeLink<Destination: Equatable, Case, Action, Parent: View>: View {
    let parent: Parent
    let blueprint: PresentationBlueprint

    let store: Store<Destination, Action>
    let path: CasePath<Destination, Case>
    let dismissAction: Action

    init(
        parent: Parent,
        blueprint: PresentationBlueprint,
        store: Store<Destination, Action>,
        path: CasePath<Destination, Case>,
        dismissAction: Action
    ) {
        self.parent = parent
        self.blueprint = blueprint
        self.store = store
        self.path = path
        self.dismissAction = dismissAction
    }

    var body: some View {
        TreeLink(
            shouldBePresented: makeStream(),
            blueprint: blueprint,
            content: parent
        )
    }

    func makeStream() -> AsyncStream<Bool> {
        store.scope {
            path.extract(from: $0) != nil
        }
        .stream
    }
}

extension Store where State: Equatable {
    var viewStore: ViewStore<State, Action> {
        ViewStore(self)
    }

    public var stream: AsyncStream<State> {
        viewStore.stream
    }
}

public extension ViewStore {
    var stream: AsyncStream<ViewState> {
        AsyncStream(publisher.values)
    }
}

extension Store {
    func ifLet<Wrapped>() -> AsyncStream<Store<Wrapped, Action>> where State == Wrapped? {
        AsyncStream<Store<State.Wrapped, Action>> { continuation in
            let cancellable: any Cancellable = self.ifLet { store in
                continuation.yield(store)
            }

            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }
}
