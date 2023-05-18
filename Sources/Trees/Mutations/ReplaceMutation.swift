import Foundation

public struct ReplaceMutation: _MutationProtocol {
    let blueprint: Blueprint

    init(blueprint: Blueprint) {
        self.blueprint = blueprint
    }

    init(blueprint: some CompleteBlueprint) {
        self.blueprint = blueprint.case
    }

    var `case`: Mutation { .replace(self) }

    func apply<Kind>(to zipper: inout Zipper<Kind>, at date: Date) throws {
        if Kind.shouldGhostDismissals {
            /// insert a `Ghost` into the `Desired` tree so that both trees end up structurally symmetric,
            zipper.tree = ._ghost(zipper.tree)
            return
        }

        zipper.tree = ._replacement(
            ReplacementNode(
                tree: Kind.makeTree(from: blueprint),
                payload: Kind.replacementPayload(for: zipper.tree),
                start: date
            )
        )
    }
}
