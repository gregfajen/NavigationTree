import SwiftUI

public indirect enum Tree<Kind: KindProtocol>: TreeProtocol {
    case _leaf(Leaf)
    case _stack(Stack)
    case _replacement(Replacement)
    case _tabs(Tabs)
    case _ghost(Self)

    public var blueprint: Blueprint {
        switch self {
            case let ._leaf(tree): return tree.blueprint.case
            case let ._stack(tree): return tree.blueprint.case
            case let ._tabs(tree): return tree.blueprint.case
            case let ._ghost(tree): return tree.blueprint
            case let ._replacement(tree): return tree.tree.blueprint
        }
    }
}

// MARK: -

extension Tree {
    public typealias Timing = Kind.PresentationPayload

    /// returns a simplified tree by removing fully dismissed nodes
    public func at(_ date: Date) -> Self {
        switch self {
            case ._leaf:
                return self

            case let ._stack(stack):
                let stack = stack.at(date)
                if stack.isEmpty {
                    return stack.tail
                } else {
                    return ._stack(
                        stack.at(date)
                    )
                }

            case let ._replacement(replacement):
                if replacement.isFullyDismissed(at: date) {
                    return replacement.tree.at(date)
                } else {
                    return ._replacement(
                        Replacement(
                            tree: replacement.tree.at(date),
                            payload: replacement.payload,
                            start: replacement.start
                        )
                    )
                }

            case let ._tabs(tabs):
                return ._tabs(
                    Tabs(
                        tabs.lhs.at(date),
                        tabs.rhs.at(date),
                        style: tabs.style,
                        background: tabs.background,
                        selection: tabs.selection
                    )
                )

            case let ._ghost(tail):
                return ._ghost(tail.at(date))
        }
    }

    static func leaf(_ id: String = UUID().uuidString) -> Self where Kind == Blueprint {
        let leaf = Leaf(blueprint: .mock(id), payload: nil)
        return ._leaf(leaf)
    }

    static func leaf(_ id: String = UUID().uuidString) -> Self where Kind == Mock {
        let leaf = Leaf(blueprint: .mock(id), payload: nil)
        return ._leaf(leaf)
    }

    static func tabs(
        _ lhs: Self,
        _ rhs: Self,
        style: SlabStyle = .identity,
        background: LeafNode<Kind> = Kind.makeTree(from: .black),
        selection: TabIndex = .lhs
    ) -> Self {
        ._tabs(Tabs(lhs, rhs, style: style, background: background, selection: selection))
    }

    func presenting(_ element: Stack.Element) -> Self {
        switch self {
            case let ._stack(stack):
                return ._stack(
                    stack.appending(element)
                )

            default:
                return ._stack(
                    Stack(
                        presenting: element,
                        over: self
                    )
                )
        }
    }

    func presenting(_ elements: [Stack.Element]) -> Self {
        switch self {
            case let ._stack(stack):
                return ._stack(
                    stack.appending(contentsOf: elements)
                )

            default:
                return ._stack(
                    Stack(
                        presenting: elements,
                        over: self
                    )
                )
        }
    }

    func presenting(_ id: String = UUID().uuidString) -> Self where Kind == Blueprint {
        presenting(
            Stack.Element(
                leaf: Leaf(blueprint: .mock(id), payload: nil),
                style: MockPresentationStyle(),
                timing: nil
            )
        )
    }

    func presenting(_ id: String = UUID().uuidString, at date: Date = .now) -> Self where Kind == Mock {
        presenting(
            Stack.Element(
                leaf: Leaf(blueprint: .mock(id), payload: nil),
                style: MockPresentationStyle(),
                timing: Kind.presentationTiming(presentationDate: date)
            )
        )
    }

    func presenting(_ leaf: Leaf, style: some PresentationStyle, timing: Kind.PresentationPayload) -> Self {
        presenting(
            Stack.Element(
                leaf: leaf,
                style: style,
                timing: timing
            )
        )
    }

    func presenting(blueprint: LeafBlueprint, payload: Leaf.Payload, at date: Date) -> Self {
        let leaf = Leaf(blueprint: blueprint, payload: payload)
        return presenting(
            leaf,
            style: MockPresentationStyle(),
            timing: Kind.presentationTiming(presentationDate: date)
        )
    }

    public mutating func present(_ leaf: Leaf, style: some PresentationStyle, timing: Timing) {
        self = presenting(leaf, style: style, timing: timing)
    }

    public mutating func present(_ leaf: Leaf, style: some PresentationStyle) where Kind == Blueprint {
        self = presenting(leaf, style: style, timing: nil)
    }

    public mutating func dismiss() {
        guard case let ._stack(stack) = self else {
            return
        }

        self = ._stack(
            stack.updated { stack in
                _ = stack.elements.popLast()
            }
        )
    }

    public mutating func present(
        _ id: String,
        style: some PresentationStyle,
        timing: Timing,
        @ViewBuilder body: @escaping () -> some View
    ) where Kind == Blueprint {
        present(
            Leaf(
                blueprint: LeafBlueprint(
                    id: id,
                    body: body
                ),
                payload: nil
            ),
            style: style,
            timing: timing
        )
    }
}

public protocol TreeProtocol: Hashable {
    associatedtype Kind: KindProtocol
}

public extension TreeProtocol {
    typealias Leaf = LeafNode<Kind>
    typealias Replacement = ReplacementNode<Kind>
    typealias Stack = StackNode<Kind>
    typealias Tabs = TabsNode<Kind>
}

// MARK: - Equatable

extension Tree: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.isEqual(to: rhs)
    }

    public func isEqual(to other: Tree<some KindProtocol>) -> Bool {
        switch (self, other) {
            case let (._leaf(lhs), ._leaf(rhs)):
                return lhs.blueprint == rhs.blueprint

            case let (._stack(lhs), ._stack(rhs)):
                return lhs.tail.isEqual(to: rhs.tail) &&
                    lhs.elements.count == rhs.elements.count &&
                    zip(lhs.elements, rhs.elements).allSatisfy { lhs, rhs in
                        lhs.isEqual(to: rhs)
                    }

            case let (._tabs(lhs), ._tabs(rhs)):
                return lhs.lhs.isEqual(to: rhs.lhs) &&
                    lhs.rhs.isEqual(to: rhs.rhs) &&
                    lhs.selection == rhs.selection

            case let (._replacement(actualReplacement), ._ghost(desiredTail)):
                return actualReplacement.tree.isEqual(to: desiredTail)

            /// case only occurs when `Desired` == `Blueprint`
            /// ghosts equal each other regardless of whether `allowGhosting` is true or false
            case let (._ghost(actualTail), ._ghost(desiredTail)):
                return actualTail.isEqual(to: desiredTail)

            default:
                return false
        }
    }
}
