import AsyncAlgorithms
import Dependencies
import Foundation

public class CurrentValueChannel<Value>: AsyncSequence {
    public typealias Element = Value

    let channel = AsyncChannel<Value>()

    public var value: Value {
        didSet {
            Task { [channel] in
                await channel.send(value)
            }
        }
    }

    public init(initialValue: Value) {
        self.value = initialValue

        Task { [channel] in
            await channel.send(value)
        }
    }

    public var stream: AsyncStream<Value> {
        AsyncStream(channel)
    }

    public func makeAsyncIterator() -> AsyncChannel<Value>.Iterator {
        channel.makeAsyncIterator()
    }
}
