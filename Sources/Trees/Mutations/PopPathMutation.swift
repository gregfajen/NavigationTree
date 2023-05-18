import Foundation

public struct PopPathMutation: _MutationProtocol {
    let count: Int

    init(count: Int = 1) {
        precondition(count > 0)
        self.count = count
    }

    var `case`: Mutation { .pop(self) }

    func apply(to zipper: inout Zipper<some KindProtocol>, at _: Date) throws {
        guard let revert = zipper.stack.popLast() else {
            throw MutationError.invalidIndex
        }

        revert(&zipper.tree)
    }
}
