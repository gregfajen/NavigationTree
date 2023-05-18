import Foundation
import Trees

public struct Overlay: PresentationStyle {
    public let transitionDuration: TimeInterval = 0

    public init() { }

    public func transitionSlice(for _: Double) -> TransitionSlice {
        TransitionSlice()
    }

    public struct TransitionSlice: PresentationStyleSlice {
        public var childIsVisible: Bool { true }

        public func parentStyle(context _: PresentationContext) -> SlabStyle {
            .identity
        }

        public func childStyle(context _: PresentationContext) -> SlabStyle {
            .identity
        }
    }
}
