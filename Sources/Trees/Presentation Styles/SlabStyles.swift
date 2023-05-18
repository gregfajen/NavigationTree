import Foundation

/// a list of closures
public struct SlabStyles {
    var closures: [(PresentationContext) -> SlabStyle]

    public static let identity = SlabStyles(closures: [])

    public mutating func append(_ closure: @escaping (PresentationContext) -> SlabStyle) {
        self = appending(closure)
    }

    public func appending(_ closure: @escaping (PresentationContext) -> SlabStyle) -> SlabStyles {
        var copy = self
        copy.closures.append(closure)
        return copy
    }

    public func appending(_ style: SlabStyle) -> SlabStyles {
        var copy = self
        copy.closures.append { _ in style }
        return copy
    }

    public func callAsFunction(context: PresentationContext) -> SlabStyle {
        SlabStyle(closures.map { $0(context) })
    }
}

extension SlabStyles: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: (PresentationContext) -> SlabStyle...) {
        self.closures = elements
    }
}
