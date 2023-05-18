import Foundation

/// a blueprint from which we can construct a `Tree`
public protocol CompleteBlueprint: BlueprintProtocol {
    var `case`: Blueprint { get }

    func isEqual(to other: some CompleteBlueprint) -> Bool
}

public extension CompleteBlueprint {
    func isEqual(to other: some CompleteBlueprint) -> Bool {
        guard let other = other as? Self else { return false }
        return self == other
    }
}
