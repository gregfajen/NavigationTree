import Foundation

public enum TabIndex: Hashable, Sendable {
    case lhs, rhs
}

public struct TabsNode<Kind: KindProtocol>: TreeProtocol {
    public let id = "tabs"

    public var selection: TabIndex
    public var lhs: Tree<Kind>
    public var rhs: Tree<Kind>
    public var style: SlabStyle
    public var background: Leaf

    public init(
        _ lhs: Tree<Kind>,
        _ rhs: Tree<Kind>,
        style: SlabStyle,
        background: Leaf,
        selection: TabIndex
    ) {
        self.lhs = lhs
        self.rhs = rhs
        self.style = style
        self.background = background
        self.selection = selection
    }

    var blueprint: TabsBlueprint {
        TabsBlueprint(
            lhs.blueprint,
            rhs.blueprint,
            style: style,
            background: background.blueprint,
            selection: selection
        )
    }

    subscript(_ index: TabIndex) -> Tree<Kind> {
        get {
            switch index {
                case .lhs: return lhs
                case .rhs: return rhs
            }
        }
        set {
            switch index {
                case .lhs: lhs = newValue
                case .rhs: rhs = newValue
            }
        }
    }

    public func updated(with closure: (inout Self) -> Void) -> Self {
        var copy = self
        closure(&copy)
        return copy
    }
}

public struct TabsBlueprint: CompleteBlueprint {
    public let lhs: Blueprint
    public let rhs: Blueprint
    public let style: SlabStyle
    public let background: LeafBlueprint
    public var selection: TabIndex

    public init(
        _ lhs: some CompleteBlueprint,
        _ rhs: some CompleteBlueprint,
        style: SlabStyle = .identity,
        background: LeafBlueprint = .clear,
        selection: TabIndex = .lhs
    ) {
        self.lhs = lhs.case
        self.rhs = rhs.case
        self.style = style
        self.background = background
        self.selection = selection
    }

    public var `case`: Blueprint { .tabs(self) }
}
