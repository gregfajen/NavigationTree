import Foundation

public extension Tree where Kind == Blueprint {
    mutating func mutateSubtree(
        at path: [PathElement],
        mutation: (inout Self) throws -> Void
    ) throws {
        var zipper = Zipper(self)

        try zipper.push(path)
        try mutation(&zipper.tree)

        try zipper.popAll()
        self = zipper.tree
    }

    mutating func mutateTabs(
        mutation: (inout Tabs) throws -> Void
    ) throws {
        var zipper = Zipper(self)

        while true {
            guard case let ._tabs(initialTabs) = zipper.tree else {
                try zipper.push(.descend)
                continue
            }

            var tabs = initialTabs
            try mutation(&tabs)
            zipper.tree = ._tabs(tabs)

            try zipper.popAll()
            self = zipper.tree
            return
        }
    }

    mutating func replace(with blueprint: some CompleteBlueprint) {
        self = Blueprint.makeTree(from: blueprint)
    }
}
