import Foundation
import Trees

extension SlabHostController {
    struct State {
        var currentDate: Date
        var isAtRest: Bool
        var tree: Tree<Live>

        @MainActor
        init(tree: Tree<Live>, at date: Date = .now) {
            var tree = tree
            self.isAtRest = tree.mutate(to: date)
            self.tree = tree
            self.currentDate = date
        }

        @MainActor
        mutating func unify(with desiredTree: Tree<Blueprint>, at newDate: Date = .now) {
            precondition(newDate > currentDate)
            var context = UnificationContext(actual: tree, desired: desiredTree, date: newDate)
            _ = try! context.unify()

            tree = context.actual.tree
            isAtRest = tree.mutate(to: newDate)
            currentDate = newDate
        }

        @MainActor
        mutating func update(to newDate: Date = .now) {
            isAtRest = tree.mutate(to: newDate)
            currentDate = newDate
        }
    }
}
