import Foundation

public struct Zipper<Kind: KindProtocol> {
    public internal(set) var tree: Tree<Kind>
    var stack: [(inout Tree<Kind>) -> Void]

    init(_ tree: Tree<Kind>) {
        self.tree = tree
        self.stack = []
    }

    mutating func push(_ element: PathElement) throws {
        let revert = try tree.traverse(path: element)
        stack.append(revert)
    }

    mutating func pop() throws {
        guard let revert = stack.popLast() else {
            throw MutationError.zipperStackError
        }

        revert(&tree)
    }

    mutating func push(_ path: [PathElement]) throws {
        for element in path {
            try push(element)
        }
    }

    mutating func popAll() throws {
        while !stack.isEmpty {
            try pop()
        }
    }
}

public enum PathElement: Hashable {
    case descend
    case enterTab(TabIndex)
}

extension Tree {
    mutating func traverse(path: PathElement) throws -> (inout Tree) -> Void {
        switch (path, self) {
            case let (.descend, ._stack(stack)):
                self = stack.tail
                return { $0 = $0.presenting(stack.elements) }

            case let (.descend, ._ghost(tail)):
                self = tail
                return { $0 = ._ghost($0) }

            case let (.descend, ._replacement(replacement)):
                self = replacement.tree
                return {
                    $0 = ._replacement(
                        Replacement(tree: $0, payload: replacement.payload, start: replacement.start)
                    )
                }

            case (.descend, _):
                throw MutationError.invalidIndex

            case let (.enterTab(index), ._tabs(tabs)):
                return try traverseTab(index, in: tabs)

            case (.enterTab, _):
                throw MutationError.invalidIndex
        }
    }

    mutating func traverseTab(_ index: TabIndex, in tabs: Tabs) throws -> (inout Tree) -> Void {
        var tabs = tabs
        self = tabs[index]

        return { tree in
            tabs[index] = tree
            tree = ._tabs(tabs)
        }
    }
}
