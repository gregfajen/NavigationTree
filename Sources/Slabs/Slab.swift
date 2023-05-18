import AsyncAlgorithms
import SwiftUI
import Trees

#if os(macOS)
    import Cocoa
#else
    import UIKit
#endif

class SlabViewController: NativeViewController {
    let hitInterceptor: (CGPoint, PresentationContext) -> Bool
    let innerController: NativeViewController

    let contextStream: AsyncStream<PresentationContext>
    var context: PresentationContext = .unset
    var contextTask: Task<Void, Never>?

    init(
        label _: String,
        makeController: () -> NativeViewController,
        hitInterceptor: @escaping (CGPoint, PresentationContext) -> Bool,
        contextStream: AsyncStream<PresentationContext>
    ) {
        self.innerController = makeController()
        self.hitInterceptor = hitInterceptor
        self.contextStream = contextStream

        super.init(nibName: nil, bundle: nil)

        self.contextTask = Task { [weak self] in
            for await context in contextStream {
                if Task.isCancelled { return }
                self?.context = context
            }
        }
    }

    override func loadView() {
        addChild(innerController)
        view = SlabView(subview: innerController.view) { [unowned self] point in
            hitInterceptor(point, context)
        }
        innerController.didMove(toParent: self)

        view.alpha = 0
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SlabView: UIView {
    let hitInterceptor: (CGPoint) -> Bool

    init(
        subview: UIView,
        hitInterceptor: @escaping (CGPoint) -> Bool

    ) {
        self.hitInterceptor = hitInterceptor

        super.init(frame: UIScreen.main.bounds)

        addSubview(subview)
        subview.frame = bounds
        subview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard hitInterceptor(point) else {
            return nil
        }

        return super.hitTest(point, with: event)
    }
}

@MainActor
public final class Slab: Hashable, Identifiable {
    public let id = UUID()
    public let label: String

    let proxy: SlabProxy
    let controller: SlabViewController

    var makeStyle: (PresentationContext) -> SlabStyle = { _ in SlabStyle(opacity: 0) } {
        didSet { updateController() }
    }

    @AlwaysEqual
    var contextChannel: CurrentValueChannel<PresentationContext>

    var context: PresentationContext {
        get { contextChannel.value }
        set {
            contextChannel.value = newValue
            updateController()
        }
    }

    var path: [PathElement] {
        get { proxy.path }
        set { proxy.path = newValue }
    }

    @AlwaysEqual
    var slabAdjustmentChannel: CurrentValueChannel<SlabAdjustmentState>

    private init(
        label: String,
        channel: CurrentValueChannel<SlabAdjustmentState>,
        hitInterceptor: @escaping (CGPoint, PresentationContext) -> Bool,
        makeController: @escaping () -> NativeViewController
    ) {
        let contextChannel = CurrentValueChannel<PresentationContext>(initialValue: .unset)

        self.label = label
        self.contextChannel = contextChannel
        self.slabAdjustmentChannel = channel
        self.controller = SlabViewController(
            label: label,
            makeController: makeController,
            hitInterceptor: hitInterceptor,
            contextStream: AsyncStream(contextChannel)
        )
        controller.view.alpha = 0
        self.proxy = SlabProxy()
        proxy.slab = self
    }

    private convenience init(
        label: String,
        hitInterceptor: @escaping (CGPoint, PresentationContext) -> Bool,
        @ViewBuilder content: @escaping () -> some View
    ) {
        let channel = CurrentValueChannel<SlabAdjustmentState>(initialValue: .default)

        #if os(macOS)
            self.init(channel: channel) {
                NSHostingController(
                    rootView: SlabAdjustmentView(content: content(), stateStream: AsyncStream(channel))
                )
            }
        #else
            self.init(
                label: label,
                channel: channel,
                hitInterceptor: hitInterceptor
            ) {
                let controller = UIHostingController(
                    rootView: SlabAdjustmentView(content: content(), stateStream: AsyncStream(channel))
                )
                controller.view.backgroundColor = .clear
                return controller
            }
        #endif
    }

    convenience init(blueprint: LeafBlueprint) {
        self.init(
            label: blueprint.id,
            hitInterceptor: blueprint.hitInterceptor
        ) {
            blueprint.body()
        }
    }

    deinit {
        print("")
    }

    func updateController() {
        if context.isUnset {
            controller.view.alpha = 0
            return
        }

        let style = makeStyle(context)
        let view: NativeView = controller.view

        view.frame.origin = CGPoint(x: style.offset.width, y: style.offset.height)

        #if os(iOS)
            view.isUserInteractionEnabled = style.isInteractive

            view.alpha = style.opacity

            view.layer.cornerRadius = style.cornerRadius
            view.layer.masksToBounds = style.cornerRadius > 0
        #endif

        let state = SlabAdjustmentState(
            proxy: proxy,
            blur: style.blur,
            topInset: context.topInset,
            bottomInset: context.bottomInset + style.bottomInset
        )

        if state != slabAdjustmentChannel.value {
            slabAdjustmentChannel.value = state
        }
    }

    public nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public nonisolated static func == (lhs: Slab, rhs: Slab) -> Bool {
        lhs === rhs
    }
}
