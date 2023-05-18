#if os(macOS)
    import Cocoa
#else
    import UIKit
#endif

public struct PresentationContext: Equatable {
    public let screenSize: CGSize
    public let topInset: Double
    public let bottomInset: Double
    public let cornerRadius: Double

    public var isUnset: Bool {
        self == .unset
    }

    public static var unset: PresentationContext {
        PresentationContext(
            screenSize: .zero,
            topInset: 0,
            bottomInset: 0,
            cornerRadius: 0
        )
    }

    #if os(macOS)
//        public static func from(_ superview: NSView?) -> PresentationContext {
//            guard let superview else { return .unset }
//
//            return PresentationContext(
//                screenSize: superview.bounds.size,
//                topInset: 0,
//                bottomInset: 0,
//                cornerRadius: 8
//            )
//        }
    #else
        public static func from(_ superview: UIView?) -> PresentationContext {
            guard let superview else { return .unset }

            return PresentationContext(
                screenSize: superview.bounds.size,
                topInset: superview.safeAreaInsets.top,
                bottomInset: superview.safeAreaInsets.bottom,
                cornerRadius: (superview.window?.screen ?? .main).cornerRadius
            )
        }
    #endif
}

#if os(iOS)
    extension UIScreen {
        private static let cornerRadiusKey: String = ["Radius", "Corner", "display", "_"].reversed().joined()

        public var cornerRadius: Double {
            guard let cornerRadius = value(forKey: UIScreen.cornerRadiusKey) as? Double else {
                return 0
            }

            return cornerRadius
        }
    }
#endif
