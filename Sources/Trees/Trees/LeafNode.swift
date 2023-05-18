import SwiftUI

public struct LeafNode<Kind: KindProtocol>: TreeProtocol {
    public typealias Payload = Kind.LeafPayload

    public var id: String { blueprint.id }

    public let blueprint: LeafBlueprint
    public var payload: Payload

    public init(blueprint: LeafBlueprint, payload: Payload) {
        self.blueprint = blueprint
        self.payload = payload
    }
}

extension LeafNode {
    var asBlueprintNode: LeafNode<Blueprint> {
        LeafNode<Blueprint>(blueprint: blueprint, payload: nil)
    }
}
