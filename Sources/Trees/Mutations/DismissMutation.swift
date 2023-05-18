import Foundation
import XCTestDynamicOverlay

public struct DismissMutation: _MutationProtocol {
    let expectedID: String

    var isTraversal: Bool { false }
    var `case`: Mutation { .dismiss(self) }

    func apply<Kind>(to zipper: inout Zipper<Kind>, at date: Date) throws {
        if Kind.shouldGhostDismissals {
            return
        }

        guard case let ._stack(stack) = zipper.tree else {
            throw MutationError.mutationNotApplicable
        }

        zipper.tree = ._stack(
            stack.updated { stack in
                stack.elements = stack.elements.map {
                    $0.updated { element in
                        if element.leaf.id == expectedID {
                            element = element.dismissed(at: date)
                        }
                    }
                }
            }
        )
    }
}
