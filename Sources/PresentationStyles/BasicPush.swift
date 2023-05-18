import Foundation
import Trees

public struct BasicPush: PresentationStyle {
    public var transitionDuration: TimeInterval

    public init(transitionDuration: TimeInterval = 3) {
        self.transitionDuration = transitionDuration
    }

    public var dismissedSlice: EitherSlice {
        EitherSlice(isPresented: false)
    }

    public var presentedSlice: EitherSlice {
        EitherSlice(isPresented: true)
    }

    public func transitionSlice(for isPresented: Double) -> TransitionSlice {
        print("isPresented: \(isPresented)")
        return TransitionSlice(isPresented: isPresented)
    }

    public struct TransitionSlice: PresentationStyleSlice {
        let isPresented: Double

        public var childIsVisible: Bool { true }

        public func parentStyle(context: PresentationContext) -> SlabStyle {
            SlabStyle(
                isInteractive: false,
                opacity: 1 - isPresented,
                offset: CGSize(
                    width: context.screenSize.width * isPresented * -0.5,
                    height: 0
                ),
                blur: 20 * isPresented
            )
        }

        public func childStyle(context: PresentationContext) -> SlabStyle {
            SlabStyle(
                isInteractive: false,
                offset: CGSize(
                    width: context.screenSize.width * (1 - isPresented),
                    height: 0
                ),
                cornerRadius: context.cornerRadius
            )
        }
    }
}
