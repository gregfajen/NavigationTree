import Foundation

public struct PresentationTiming: Hashable {
    public private(set) var presentationDate: Date
    public private(set) var dismissalDate: Date?

    public init(presentationDate: Date, dismissalDate: Date? = nil) {
        self.presentationDate = presentationDate
        self.dismissalDate = dismissalDate
    }

    func isPresented(at date: Date, transitionDuration: TimeInterval) -> Double {
        let isPresented = clamp((date - presentationDate) / transitionDuration)
        guard let dismissalDate else { return isPresented }

        let isDismissed = clamp((date - dismissalDate) / transitionDuration)
        return isPresented * (1 - isDismissed)
    }
}

public func clamp(_ value: Double, lowerBound: Double = 0, upperBound: Double = 1) -> Double {
    if value < lowerBound { return lowerBound }
    if value > upperBound { return upperBound }
    return value
}

public func - (lhs: Date, rhs: Date) -> TimeInterval {
    lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
}
