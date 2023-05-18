import Foundation

@propertyWrapper
public struct Associative<Operation>: Hashable where Operation: AssociativeOperation {
    let operation: Operation
    public var wrappedValue: Operation.Value

    public init(_ operation: Operation) {
        self.operation = operation
        self.wrappedValue = Operation.identity
    }

    public var projectedValue: [Operation.Value] {
        get { [wrappedValue] }
        set { wrappedValue = Operation.reduce(newValue) }
    }
}

public protocol AssociativeOperation: Hashable {
    associatedtype Value: Hashable

    static var identity: Value { get }
    static var operation: (Value, Value) -> Value { get }
}

extension AssociativeOperation {
    static func reduce(_ lhs: Value, _ rhs: Value) -> Value {
        operation(lhs, rhs)
    }

    static func reduce(_ values: [Value]) -> Value {
        values.reduce(into: identity) {
            $0 = operation($0, $1)
        }
    }
}
