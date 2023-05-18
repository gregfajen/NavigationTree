import Foundation

public struct SlabStyle: Hashable {
    @Associative(.isInteractive)
    public var isInteractive

    @Associative(.opacity)
    public var opacity

    @Associative(.offset)
    public var offset

    @Associative(.blur)
    public var blur

    @Associative(.cornerRadius)
    public var cornerRadius
    
    @Associative(.bottomInset)
    public var bottomInset

    public init(
        isInteractive: Bool = IsInteractiveOperation.identity,
        opacity: Double = OpacityOperation.identity,
        offset: CGSize = OffsetOperation.identity,
        blur: Double = BlurOperation.identity,
        cornerRadius: Double = CornerRadiusOperation.identity,
        bottomInset: Double = BottomInsetOperation.identity
    ) {
        self.isInteractive = isInteractive
        self.opacity = opacity
        self.offset = offset
        self.blur = blur
        self.cornerRadius = cornerRadius
        self.bottomInset = bottomInset
    }

    init(
        isInteractive: [Bool],
        opacity: [Double],
        offset: [CGSize],
        blur: [Double],
        cornerRadius: [Double],
        bottomInset: [Double]
    ) {
        self.$isInteractive = isInteractive
        self.$opacity = opacity
        self.$offset = offset
        self.$blur = blur
        self.$cornerRadius = cornerRadius
        self.$bottomInset = bottomInset
    }

    init(_ styles: some Sequence<SlabStyle>) {
        self.init(
            isInteractive: styles.map(\.isInteractive),
            opacity: styles.map(\.opacity),
            offset: styles.map(\.offset),
            blur: styles.map(\.blur),
            cornerRadius: styles.map(\.cornerRadius),
            bottomInset: styles.map(\.bottomInset)
        )
    }

    public static let identity = SlabStyle(
        isInteractive: true,
        opacity: 1
    )

    public static let hidden = SlabStyle(
        isInteractive: false,
        opacity: 0
    )
}

public struct IsInteractiveOperation: AssociativeOperation {
    public static let identity = true
    public static let operation: (Bool, Bool) -> Bool = {
        $0 && $1
    }
}

public extension AssociativeOperation where Self == IsInteractiveOperation {
    static var isInteractive: IsInteractiveOperation { .init() }
}

public struct OpacityOperation: AssociativeOperation {
    public static let identity = 1.0
    public static let operation: (Double, Double) -> Double = { $0 * $1 }
}

public extension AssociativeOperation where Self == OpacityOperation {
    static var opacity: OpacityOperation { .init() }
}

public struct OffsetOperation: AssociativeOperation {
    public static let identity = CGSize.zero
    public static let operation: (CGSize, CGSize) -> CGSize = {
        CGSize(width: $0.width + $1.width, height: $0.height + $1.height)
    }
}

public extension AssociativeOperation where Self == OffsetOperation {
    static var offset: OffsetOperation { .init() }
}

public struct BlurOperation: AssociativeOperation {
    public static let identity = 0.0
    public static let operation: (Double, Double) -> Double = { $0 + $1 }
}

public extension AssociativeOperation where Self == BlurOperation {
    static var blur: BlurOperation { .init() }
}

public struct CornerRadiusOperation: AssociativeOperation {
    public static let identity = 0.0
    public static let operation: (Double, Double) -> Double = { $0 + $1 }
}



public extension AssociativeOperation where Self == CornerRadiusOperation {
    static var cornerRadius: CornerRadiusOperation { .init() }
}

public struct BottomInsetOperation: AssociativeOperation {
    public static let identity = 0.0
    public static let operation: (Double, Double) -> Double = { $0 + $1 }
}

public extension AssociativeOperation where Self == BottomInsetOperation {
    static var bottomInset: BottomInsetOperation { .init() }
}

extension CGSize: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(width)
        hasher.combine(height)
    }
}
