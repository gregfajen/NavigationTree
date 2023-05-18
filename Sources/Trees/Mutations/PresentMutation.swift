import SwiftUI

public struct PresentMutation: _MutationProtocol {
    let blueprint: PresentationBlueprint
    let index: Int

    init(blueprint: PresentationBlueprint, at index: Int) {
        self.blueprint = blueprint
        self.index = index
    }

    /// for testing
    internal init(headID: String, at index: Int) {
        self = .init(
            blueprint: PresentationBlueprint(
                child: LeafBlueprint(id: headID) {
                    EmptyView()
                },
                style: MockPresentationStyle()
            ),
            at: index
        )
    }

    var `case`: Mutation { .present(self) }

    func apply<Kind>(to zipper: inout Zipper<Kind>, at date: Date) throws {
        guard case let ._leaf(leaf) = Kind.makeTree(from: blueprint.child) else {
            throw MutationError.mutationNotApplicable
        }

        switch zipper.tree {
            case let ._stack(stack):
                let stack = stack.updated { stack in
                    stack.elements.insert(
                        StackNode<Kind>.Element(
                            leaf: leaf,
                            style: blueprint.style,
                            timing: Kind.presentationTiming(presentationDate: date)
                        ),
                        at: index
                    )
                }
                zipper.tree = ._stack(stack)

            default:
                precondition(index == 0)
                zipper.tree = zipper.tree.presenting(
                    leaf,
                    style: blueprint.style,
                    timing: Kind.presentationTiming(presentationDate: date)
                )
        }
    }
}
