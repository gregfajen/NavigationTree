import Foundation

public struct StackBlueprint: CompleteBlueprint {
    public var elements: [PresentationBlueprint]
    public var tail: any CompleteBlueprint

    public init(elements: [PresentationBlueprint], tail: any CompleteBlueprint) {
        self.elements = elements
        self.tail = tail
    }

    public var `case`: Blueprint {
        .stack(self)
    }

    public static func == (lhs: StackBlueprint, rhs: StackBlueprint) -> Bool {
        lhs.elements == rhs.elements && lhs.tail.isEqual(to: rhs.tail)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(elements)
        hasher.combine(tail)
    }
}
