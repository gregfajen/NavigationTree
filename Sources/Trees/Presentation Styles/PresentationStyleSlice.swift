import Foundation

public protocol PresentationStyleSlice {
    var childIsVisible: Bool { get }

    func parentStyle(context: PresentationContext) -> SlabStyle
    func childStyle(context: PresentationContext) -> SlabStyle
}
