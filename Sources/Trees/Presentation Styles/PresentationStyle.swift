import Foundation

public protocol PresentationStyle: Hashable, Sendable {
    associatedtype TransitionSlice: PresentationStyleSlice
    associatedtype PresentedSlice: PresentationStyleSlice = TransitionSlice
    associatedtype DismissedSlice: PresentationStyleSlice = TransitionSlice

    var transitionDuration: TimeInterval { get }

    var presentedSlice: PresentedSlice { get }
    var dismissedSlice: DismissedSlice { get }
    func transitionSlice(for isPresented: Double) -> TransitionSlice

    func isEqual(to other: some PresentationStyle) -> Bool
}

public extension PresentationStyle {
    func slice(at date: Date, timing: PresentationTiming) -> PresentationStyleSlice {
        let isPresented = timing.isPresented(at: date, transitionDuration: transitionDuration)

        switch isPresented {
            case ...0: return dismissedSlice
            case 1...: return presentedSlice
            default: return transitionSlice(for: isPresented)
        }
    }
}

public extension PresentationStyle where PresentedSlice == TransitionSlice {
    var presentedSlice: TransitionSlice {
        transitionSlice(for: 1)
    }
}

public extension PresentationStyle where DismissedSlice == TransitionSlice {
    var dismissedSlice: TransitionSlice {
        transitionSlice(for: 0)
    }
}

public extension PresentationStyle {
    func isEqual(to other: some PresentationStyle) -> Bool {
        guard let other = other as? Self else { return false }

        return self == other
    }
}
