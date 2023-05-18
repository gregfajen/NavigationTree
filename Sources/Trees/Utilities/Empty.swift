import Foundation

public struct Empty: Hashable, ExpressibleByNilLiteral {
    public init(nilLiteral _: ()) { }
}
