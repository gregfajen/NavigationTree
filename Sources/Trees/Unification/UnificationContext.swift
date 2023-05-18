import Foundation

public struct UnificationContext<Actual: KindProtocol> where Actual.PresentationPayload == PresentationTiming {
    public typealias Desired = Blueprint
    typealias Mutations = [Mutation]

    let date: Date
    public internal(set) var actual: Zipper<Actual>
    public internal(set) var desired: Zipper<Desired>

    /// for sanity checking
    /// we expect that `actual.stack.count - actualStackCountOffset == desired.stack.count - desiredStackCountOffset` at
    /// each invocation of
    /// `unify()`
    var actualStackCountOffset = 0
    var desiredStackCountOffset = 0

    public init(actual: Tree<Actual>, desired: Tree<Desired>, date: Date) {
        self.actual = .init(actual)
        self.desired = .init(desired)
        self.date = date
    }
}
