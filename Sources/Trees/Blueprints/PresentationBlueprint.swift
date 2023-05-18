import Foundation

public struct PresentationBlueprint: BlueprintProtocol {
    public let child: LeafBlueprint

    @AlwaysEqual
    public var style: any PresentationStyle

    var transitionDuration: TimeInterval { style.transitionDuration }

    public init(child: LeafBlueprint, style: some PresentationStyle) {
        self.child = child
        self.style = style
    }
}
