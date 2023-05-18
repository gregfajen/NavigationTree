import Foundation

public protocol BlueprintProtocol: Hashable, Sendable { }

public indirect enum Blueprint {
    public typealias LeafPayload = Empty
    public typealias PresentationPayload = Empty

    case leaf(LeafBlueprint)
    case stack(StackBlueprint)
    case tabs(TabsBlueprint)
}

extension Blueprint: CompleteBlueprint {
    public var `case`: Blueprint { self }
}

extension Blueprint: KindProtocol {
    public static let shouldGhostDismissals = true

    public static func makeTree(from leafBlueprint: LeafBlueprint) -> LeafNode<Blueprint> {
        LeafNode(blueprint: leafBlueprint, payload: nil)
    }

    public static func makeTree(from tabsBlueprint: TabsBlueprint) -> TabsNode<Blueprint> {
        TabsNode(
            makeTree(from: tabsBlueprint.lhs),
            makeTree(from: tabsBlueprint.rhs),
            style: tabsBlueprint.style,
            background: makeTree(from: tabsBlueprint.background),
            selection: tabsBlueprint.selection
        )
    }

    public static func makeTree(from stackBlueprint: StackBlueprint) -> StackNode<Blueprint> {
        StackNode(
            presenting: stackBlueprint.elements.map {
                .init(
                    leaf: makeTree(from: $0.child),
                    style: $0.style,
                    timing: nil
                )
            },
            over: makeTree(from: stackBlueprint.tail)
        )
    }

//    public static func makeTree(
//        from presentationBlueprint: PresentationBlueprint,
//        tail tailBlueprint: some CompleteBlueprint
//    ) -> PresentationNode<Blueprint> {
//        PresentationNode(
//            presenting: makeTree(from: presentationBlueprint.child),
//            over: makeTree(from: tailBlueprint),
//            style: presentationBlueprint.style,
//            timing: nil
//        )
//    }

    public static func replacementPayload(for _: Tree<Blueprint>) -> Empty {
        nil
    }
}

extension Tree<Mock> {
    var asBlueprintTree: Tree<Blueprint> {
        switch self {
            case let ._leaf(leafNode):
                return ._leaf(
                    LeafNode(blueprint: leafNode.blueprint, payload: nil)
                )

            case let ._stack(stackNode):
                return ._stack(stackNode.asBlueprintStack)

            case let ._tabs(tabsNode):
                let lhs = tabsNode.lhs.asBlueprintTree
                let rhs = tabsNode.rhs.asBlueprintTree
                let background = tabsNode.background.asBlueprintNode
                return ._tabs(TabsNode(
                    lhs,
                    rhs,
                    style: tabsNode.style,
                    background: background,
                    selection: tabsNode.selection
                ))

//            case let ._presentation(presentationNode):
//                return ._presentation(
//                    PresentationNode<Blueprint>(
//                        presenting: LeafNode(blueprint: presentationNode.head.blueprint, payload: nil),
//                        over: presentationNode.tail.asBlueprintTree,
//                        style: presentationNode.style,
//                        timing: nil
//                    )
//                )

            case let ._ghost(tree):
                return ._ghost(tree.asBlueprintTree)

            case let ._replacement(replacement):
                fatalError()
        }
    }
}
