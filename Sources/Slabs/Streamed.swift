import AsyncAlgorithms
import Foundation

@propertyWrapper
public struct Streamed<Value> {
    let wrapper: Wrapper

    public var wrappedValue: Value {
        get { wrapper.value }
        set { wrapper.value = newValue }
    }

    public var projectedValue: AsyncStream<Value> {
        AsyncStream(wrapper.channel)
    }

    public init(wrappedValue: Value) {
        self.wrapper = Wrapper(wrappedValue)
    }

    final class Wrapper {
        let channel: AsyncChannel<Value>
        var value: Value {
            didSet {
                send(value)
            }
        }

        init(_ value: Value) {
            self.channel = AsyncChannel()
            self.value = value
            send(value)
        }

        private func send(_ value: Value) {
            Task {
                await channel.send(value)
            }
        }
    }
}
