import Foundation

public protocol KindProtocol {
    associatedtype LeafPayload: Hashable, Sendable
    associatedtype PresentationPayload: Hashable
    associatedtype ReplacementPayload: Hashable

    /// only true for `Blueprint`
    static var shouldGhostDismissals: Bool { get }

    static func makeTree(from blueprint: some CompleteBlueprint) -> Tree<Self>
    static func makeTree(from leafBlueprint: LeafBlueprint) -> LeafNode<Self>
    static func makeTree(from tabsBlueprint: TabsBlueprint) -> TabsNode<Self>
    static func makeTree(from stackBlueprint: StackBlueprint) -> StackNode<Self>

//    @available(*, deprecated)
//    static func makeTree(
//        from presentationBlueprint: PresentationBlueprint,
//        tail tailBlueprint: some CompleteBlueprint
//    ) -> PresentationNode<Self>

    static func presentationTiming(presentationDate: Date) -> PresentationPayload
    static func presentationTiming(presentationDate: Date, dismissalDate: Date) -> PresentationPayload

    static func replacementPayload(for tree: Tree<Self>) -> ReplacementPayload
}

public extension KindProtocol {
    // only `Blueprint`s should ghost
    static var shouldGhostDismissals: Bool { false }

    static func makeTree(from blueprint: some CompleteBlueprint) -> Tree<Self> {
        switch blueprint.case {
            case let .leaf(leaf):
                return ._leaf(makeTree(from: leaf))

            case let .stack(stack):
                return ._stack(makeTree(from: stack))

            case let .tabs(tabs):
                return ._tabs(makeTree(from: tabs))
        }
    }
}

public extension KindProtocol where PresentationPayload == Empty {
    static func presentationTiming(presentationDate _: Date) -> PresentationPayload {
        nil
    }

    static func presentationTiming(presentationDate _: Date, dismissalDate _: Date) -> PresentationPayload {
        nil
    }
}

public extension KindProtocol where PresentationPayload == PresentationTiming {
    static func presentationTiming(presentationDate: Date) -> PresentationPayload {
        PresentationTiming(presentationDate: presentationDate)
    }

    static func presentationTiming(presentationDate: Date, dismissalDate: Date) -> PresentationPayload {
        PresentationTiming(presentationDate: presentationDate, dismissalDate: dismissalDate)
    }
}
