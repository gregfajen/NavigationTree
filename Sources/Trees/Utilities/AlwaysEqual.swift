import Foundation

@propertyWrapper
public struct AlwaysEqual<T>: Hashable {
    public var wrappedValue: T

    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }

    public init<V>(wrappedValue: @escaping () -> V) where T == () -> V {
        self.wrappedValue = wrappedValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(true)
    }

    public static func == (_: Self, _: Self) -> Bool {
        true
    }
}

extension AlwaysEqual: Sendable where T: Sendable { }
