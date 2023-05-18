import Foundation

public struct EitherSlice: PresentationStyleSlice {
    let isPresented: Bool

    public init(isPresented: Bool) {
        self.isPresented = isPresented
    }

    public var childIsVisible: Bool { isPresented }

    public func parentStyle(context _: PresentationContext) -> SlabStyle {
        isPresented ? .hidden : .identity
    }

    public func childStyle(context _: PresentationContext) -> SlabStyle {
        isPresented ? .identity : .hidden
    }
}
