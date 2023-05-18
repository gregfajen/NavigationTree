import Algorithms
import Foundation

public enum Mutation: _MutationProtocol {
    case replace(ReplaceMutation)
    case present(PresentMutation)
    case dismiss(DismissMutation)
    case selectTab(SelectTabMutation)
    case push(PushPathMutation)
    case pop(PopPathMutation)

    var `case`: Mutation { self }

    func apply(to zipper: inout Zipper<some KindProtocol>, at date: Date) throws {
        switch self {
            case let .replace(mutation): try mutation.apply(to: &zipper, at: date)
            case let .present(mutation): try mutation.apply(to: &zipper, at: date)
            case let .dismiss(mutation): try mutation.apply(to: &zipper, at: date)
            case let .selectTab(mutation): try mutation.apply(to: &zipper, at: date)
            case let .push(mutation): try mutation.apply(to: &zipper, at: date)
            case let .pop(mutation): try mutation.apply(to: &zipper, at: date)
        }
    }

    var isTraversal: Bool {
        switch self {
            case .push, .pop: return true
            default: return false
        }
    }

    static func descend(count: Int = 1) -> Mutation {
        .push(PushPathMutation(pathElements: .init(repeating: .descend, count: count)))
    }

    static func selectTab(_ tabIndex: TabIndex) -> Mutation {
        .selectTab(SelectTabMutation(selection: tabIndex))
    }

    static func enterTab(_ tabIndex: TabIndex) -> Mutation {
        .push(PushPathMutation(pathElement: .enterTab(tabIndex)))
    }

    static func present(_ child: String, at index: Int = 0) -> Mutation {
        .present(PresentMutation(headID: child, at: index))
    }

    static func pop(count: Int = 1) -> Mutation {
        .pop(PopPathMutation(count: count))
    }

    static func replaceTree(with blueprint: Blueprint) -> Mutation {
        .replace(ReplaceMutation(blueprint: blueprint))
    }

    static func dismiss(_ expectedID: String) -> Mutation {
        .dismiss(
            DismissMutation(expectedID: expectedID)
        )
    }
}

protocol _MutationProtocol: Hashable {
    var `case`: Mutation { get }
    func apply<Kind: KindProtocol>(to zipper: inout Zipper<Kind>, at date: Date) throws
}

enum MutationError: Error {
    case invalidIndex
    case mutationNotApplicable
    case zipperStackError
}

extension Sequence where Element: _MutationProtocol {
    var cases: [Mutation] {
        map(\.case)
    }

    func apply(to zipper: inout Zipper<some KindProtocol>, at date: Date) throws {
        for mutation in self {
            try mutation.apply(to: &zipper, at: date)
        }
    }

    func simplify() -> [Mutation] {
        cases
            .chunked { lhs, rhs in
                lhs.isTraversal && rhs.isTraversal
            }
            .flatMap(simplifyChunk)
    }

    private func simplifyChunk(_ chunk: some Sequence<Mutation>) -> [Mutation] {
        var pathElements = [PathElement]()
        var popCount = 0

        for mutation in chunk {
            switch mutation {
                case .present, .dismiss, .replace, .selectTab:
                    return Array(chunk)

                case let .push(mutation):
                    pathElements.append(contentsOf: mutation.pathElements)

                case let .pop(mutation):
                    for _ in 0 ..< mutation.count {
                        if pathElements.popLast() == nil {
                            popCount += 1
                        }
                    }
            }
        }

        assert(popCount >= 0)
        if popCount > 1 {
            assert(pathElements.isEmpty)
        }

        if popCount > 0 {
            return [.pop(PopPathMutation(count: popCount))]
        } else if pathElements.isEmpty {
            return []
        } else {
            return [.push(PushPathMutation(pathElements: pathElements))]
        }
    }
}
