import Foundation

public struct StackNode<Kind: KindProtocol>: TreeProtocol {
    public var elements: [Element]
    public var tail: Tree<Kind>

    public init(presenting elements: [Element], over tail: Tree<Kind>) {
        if case ._stack = tail {
            fatalError()
        }

        self.elements = elements
        self.tail = tail
    }

    public init(presenting element: Element, over tail: Tree<Kind>) {
        self.init(presenting: [element], over: tail)
    }

    /// returns a simplified stack by removing fully dismissed nodes
    public func at(_ date: Date) -> Self {
        updated { copy in
            copy.elements = copy.elements.filter { element in
                !element.isFullyDismissed(at: date)
            }
            copy.tail = copy.tail.at(date)
        }
    }

    func appending(_ element: Element) -> Self {
        updated { copy in
            copy.elements.append(element)
        }
    }

    func appending(contentsOf elements: [Element]) -> Self {
        updated { copy in
            copy.elements.append(contentsOf: elements)
        }
    }

    var isEmpty: Bool {
        elements.isEmpty
    }

    public func isFullyDismissed(at date: Date) -> Bool {
        elements.allSatisfy { element in
            element.isFullyDismissed(at: date)
        }
    }

    public func updated(with closure: (inout Self) -> Void) -> Self {
        var copy = self
        closure(&copy)
        return copy
    }

    var blueprint: StackBlueprint {
        StackBlueprint(elements: elements.map(\.presentationBlueprint), tail: tail.blueprint)
    }
}

extension StackNode where Kind == Mock {
    var asBlueprintStack: StackNode<Blueprint> {
        StackNode<Blueprint>(
            presenting: elements.map(\.asBlueprintElement),
            over: tail.asBlueprintTree
        )
    }
}

public extension StackNode {
    struct Element: Hashable {
        public typealias Timing = Kind.PresentationPayload

        public var leaf: Leaf
        @AlwaysEqual public var style: any PresentationStyle
        public var timing: Timing

        public init(leaf: Leaf, style: any PresentationStyle, timing: Timing) {
            self.leaf = leaf
            self.style = style
            self.timing = timing
        }
    }
}

extension StackNode.Element {
    var presentationBlueprint: PresentationBlueprint {
        PresentationBlueprint(
            child: leaf.blueprint,
            style: style
        )
    }

    func dismissed(at date: Date) -> Self {
        guard let timing = timing as? PresentationTiming else {
            return self
        }

        return updated { copy in
            copy.timing = Kind.presentationTiming(
                presentationDate: timing.presentationDate,
                dismissalDate: timing.dismissalDate ?? date
            )
        }
    }

    public func isFullyDismissed(at date: Date) -> Bool {
        guard let timing = timing as? PresentationTiming,
              let dismissalDate = timing.dismissalDate else {
            return false
        }

        return dismissalDate + style.transitionDuration < date
    }

    var asBlueprintElement: StackNode<Blueprint>.Element {
        StackNode<Blueprint>.Element(
            leaf: LeafNode(blueprint: leaf.blueprint, payload: nil),
            style: style,
            timing: nil
        )
    }

    public func updated(with closure: (inout Self) -> Void) -> Self {
        var copy = self
        closure(&copy)
        return copy
    }

    func isEqual(to other: StackNode<some KindProtocol>.Element) -> Bool {
        leaf.blueprint.isEqual(to: other.leaf.blueprint)
    }
}
