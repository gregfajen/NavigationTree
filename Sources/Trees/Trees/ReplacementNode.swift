import Foundation

public struct ReplacementNode<Kind: KindProtocol>: TreeProtocol {
    public var tree: Tree<Kind>
    public let payload: Kind.ReplacementPayload
    public let start: Date
    public let transitionDuration: TimeInterval = 0.25

    init(tree: Tree<Kind>, payload: Kind.ReplacementPayload, start: Date) {
        self.tree = tree
        self.payload = payload
        self.start = start
    }

    public func isFullyDismissed(at date: Date) -> Bool {
        start + transitionDuration < date
    }
}
