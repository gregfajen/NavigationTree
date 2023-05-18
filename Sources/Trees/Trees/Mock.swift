import Foundation

struct Mock: KindProtocol {
    typealias LeafPayload = Empty
    typealias PresentationPayload = PresentationTiming

    static var defaultPresentationTiming: PresentationTiming {
        PresentationPayload(presentationDate: .now)
    }

    static func makeTree(from leafBlueprint: LeafBlueprint) -> LeafNode<Mock> {
        LeafNode(blueprint: leafBlueprint, payload: nil)
    }

    static func makeTree(from tabsBlueprint: TabsBlueprint) -> TabsNode<Mock> {
        TabsNode(
            makeTree(from: tabsBlueprint.lhs),
            makeTree(from: tabsBlueprint.rhs),
            style: tabsBlueprint.style,
            background: makeTree(from: tabsBlueprint.background),
            selection: tabsBlueprint.selection
        )
    }

    public static func makeTree(from stackBlueprint: StackBlueprint) -> StackNode<Mock> {
        StackNode(
            presenting: stackBlueprint.elements.map {
                .init(
                    leaf: makeTree(from: $0.child),
                    style: $0.style,
                    timing: defaultPresentationTiming
                )
            },
            over: makeTree(from: stackBlueprint.tail)
        )
    }

//    static func makeTree(
//        from presentationBlueprint: PresentationBlueprint,
//        tail tailBlueprint: some CompleteBlueprint
//    ) -> PresentationNode<Mock> {
//        PresentationNode(
//            presenting: LeafNode(blueprint: presentationBlueprint.child, payload: nil),
//            over: makeTree(from: tailBlueprint),
//            style: presentationBlueprint.style,
//            timing: Mock.defaultPresentationTiming
//        )
//    }

    static func replacementPayload(for _: Tree<Mock>) -> Empty {
        nil
    }
}
