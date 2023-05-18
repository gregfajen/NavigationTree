import Foundation
import Trees

public struct Live: KindProtocol {
    public typealias LeafPayload = Slab?
    public typealias PresentationPayload = PresentationTiming

    static var defaultPresentationTiming: PresentationTiming {
        PresentationTiming(presentationDate: .now)
    }

    public static func makeTree(from leafBlueprint: LeafBlueprint) -> LeafNode<Live> {
        LeafNode(
            blueprint: leafBlueprint,
            payload: nil
        )
    }

    public static func makeTree(from tabsBlueprint: TabsBlueprint) -> TabsNode<Live> {
        TabsNode(
            makeTree(from: tabsBlueprint.lhs),
            makeTree(from: tabsBlueprint.rhs),
            style: tabsBlueprint.style,
            background: makeTree(from: tabsBlueprint.background),
            selection: tabsBlueprint.selection
        )
    }

    public static func makeTree(from stackBlueprint: StackBlueprint) -> StackNode<Live> {
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

    public static func replacementPayload(for tree: Tree<Live>) -> [Slab] {
        tree.orderedSlabs
    }
}

@MainActor
extension Tree where Kind == Live {
    /// allocates Slabs for new presentation nodes, and removes stale presentation nodes (deallocated their slabs)
    /// - Parameter date: the date to use for timing calculations, almost always `.now`
    /// - Returns: whether or not the system is in a state of rest. `false` if we have pending presentations,
    /// dismissals, or transitions
    mutating func mutate(to date: Date = .now) -> Bool {
        var isAtRest = true
        self = mutated(to: date, isAtRest: &isAtRest)
        return isAtRest
    }

    func mutated(
        to date: Date = .now,
        isAtRest: inout Bool,
        slabStyles: SlabStyles = .identity,
        path: [PathElement] = []
    ) -> Self {
        switch self {
            case let ._leaf(leaf):
                return ._leaf(leaf.mutated(to: date, slabStyles: slabStyles, path: path))

            case let ._stack(stack):
                if stack.isFullyDismissed(at: date) {
                    return stack.tail.mutated(to: date, isAtRest: &isAtRest, slabStyles: slabStyles, path: path)
                } else {
                    return ._stack(
                        stack.mutated(to: date, isAtRest: &isAtRest, slabStyles: slabStyles, path: path)
                    )
                }

            case let ._replacement(replacement):
                if replacement.isFullyDismissed(at: date) {
                    return replacement.tree.mutated(to: date, isAtRest: &isAtRest, slabStyles: slabStyles, path: path)
                } else {
                    return ._replacement(
                        replacement
                            .mutated(to: date, isAtRest: &isAtRest, slabStyles: slabStyles, path: path)
                    )
                }

            case let ._tabs(tabs):
                return ._tabs(
                    tabs.mutated(to: date, isAtRest: &isAtRest, slabStyles: slabStyles, path: path)
                )

            case ._ghost:
                fatalError()
        }
    }
}

extension LeafNode where Kind == Live {
    @MainActor
    func mutated(to _: Date, slabStyles: SlabStyles, path: [PathElement]) -> Self {
        var copy = self
        copy.payload = copy.payload ?? Slab(blueprint: blueprint)

        if let slab = copy.payload {
            slab.path = path
            slab.makeStyle = slabStyles.callAsFunction
        }

        return copy
    }
}

extension ReplacementNode where Kind == Live {
    func style(for date: Date) -> SlabStyle {
        let opacity = clamp((date - start) / transitionDuration)
        return SlabStyle(opacity: opacity)
    }

    @MainActor
    func mutated(to date: Date, isAtRest: inout Bool, slabStyles: SlabStyles, path: [PathElement]) -> Self {
        let style = style(for: date)

        var copy = self
        isAtRest = false
        copy.tree = copy.tree.mutated(
            to: date,
            isAtRest: &isAtRest,
            slabStyles: slabStyles.appending(style),
            path: path
        )
        return copy
    }
}

extension StackNode where Kind == Live {
    @MainActor
    func mutated(to date: Date, isAtRest: inout Bool, slabStyles: SlabStyles, path: [PathElement]) -> Self {
        let result = updated { copy in
            var slabStyles = slabStyles

            copy.elements = copy.elements.reversed().compactMap { element in

                let slice = element.style.slice(at: date, timing: element.timing)
                let element = element.mutated(
                    to: date,
                    isAtRest: &isAtRest,
                    slabStyles: slabStyles.appending(slice.childStyle),
                    path: path
                )

                slabStyles.append(slice.parentStyle)

                if element.isFullyDismissed(at: date) {
                    return nil
                } else {
                    return element
                }
            }.reversed()
            copy.tail = copy.tail.mutated(to: date, isAtRest: &isAtRest, slabStyles: slabStyles, path: path)
        }

        print("isAtRest: \(isAtRest)")

        return result
    }
}

extension StackNode.Element where Kind == Live {
    /// will only be called on a presented or partially presented leaf
    @MainActor
    func mutated(to date: Date, isAtRest: inout Bool, slabStyles: SlabStyles, path: [PathElement]) -> Self {
        updated { copy in
            copy.leaf = leaf.mutated(to: date, slabStyles: slabStyles, path: path)

            if timing.presentationDate + style.transitionDuration > date {
                isAtRest = false
            }

            if let dismissalDate = timing.dismissalDate,
               dismissalDate + style.transitionDuration > date {
                isAtRest = false
            }

            print(timing)
            print("")
        }
    }
}

extension TabsNode where Kind == Live {
    @MainActor
    func mutated(to date: Date, isAtRest: inout Bool, slabStyles: SlabStyles, path: [PathElement]) -> Self {
        let leftStyle: SlabStyle
        let rightStyle: SlabStyle
        switch selection {
            case .lhs:
                leftStyle = .identity
                rightStyle = .hidden
            case .rhs:
                leftStyle = .hidden
                rightStyle = .identity
        }

        return updated { copy in
            copy.lhs = lhs.mutated(
                to: date,
                isAtRest: &isAtRest,
                slabStyles: slabStyles.appending(style).appending(leftStyle),
                path: path + [.enterTab(.lhs)]
            )
            copy.rhs = rhs.mutated(
                to: date,
                isAtRest: &isAtRest,
                slabStyles: slabStyles.appending(style).appending(rightStyle),
                path: path + [.enterTab(.rhs)]
            )
            copy.background = background.mutated(
                to: date,
                slabStyles: slabStyles,
                path: path
            )
        }
    }
}

extension Tree<Live> {
    var orderedSlabs: [Slab] {
        switch self {
            case let ._leaf(leaf): return leaf.payload.asArray

            case let ._stack(stack):
                return stack.tail.orderedSlabs + stack.elements.flatMap(\.leaf.payload.asArray)

            case let ._replacement(replacement):
                return replacement.payload + replacement.tree.orderedSlabs

            case let ._tabs(tabs):
                return tabs.background.payload.asArray + tabs.lhs.orderedSlabs + tabs.rhs.orderedSlabs

            case let ._ghost(tree):
                return tree.orderedSlabs
        }
    }
}
