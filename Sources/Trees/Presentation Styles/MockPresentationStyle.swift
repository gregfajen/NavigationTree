import Foundation

struct MockPresentationStyle: PresentationStyle {
    var transitionDuration: TimeInterval

    init(transitionDuration: TimeInterval = 0.25) {
        self.transitionDuration = transitionDuration
    }

    func transitionSlice(for isPresented: Double) -> EitherSlice {
        EitherSlice(isPresented: isPresented > 0)
    }
}
