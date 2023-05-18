import SwiftUI

public struct LeafBlueprint: Hashable, Identifiable, CompleteBlueprint {
    public let id: String

    @AlwaysEqual
    public var body: @Sendable @MainActor () -> AnyView

    @AlwaysEqual
    public var hitInterceptor: @Sendable (CGPoint, PresentationContext) -> Bool

    public init(
        id: String,
        @ViewBuilder body: @escaping () -> some View
    ) {
        self.id = id
        self._body = AlwaysEqual {
            AnyView(erasing: body())
        }
        self.hitInterceptor = { _, _ in true }
    }

    public init(
        id: String,
        @ViewBuilder body: @escaping () -> some View,
        hitInterceptor: @Sendable @escaping (CGPoint, PresentationContext) -> Bool
    ) {
        self.id = id
        self._body = AlwaysEqual {
            AnyView(erasing: body())
        }
        self.hitInterceptor = hitInterceptor
    }

    public var `case`: Blueprint { .leaf(self) }
}

public extension LeafBlueprint {
    static func mock(_ id: String) -> LeafBlueprint {
        self.init(id: id) {
            EmptyView()
        }
    }
}

public extension LeafBlueprint {
    static var clear: LeafBlueprint {
        LeafBlueprint(id: "clear") {
            Color.clear
        }
    }

    static var black: LeafBlueprint {
        LeafBlueprint(id: "black") {
            Color.black.ignoresSafeArea()
        }
    }
}
