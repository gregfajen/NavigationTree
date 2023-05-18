import AsyncAlgorithms
import Combine
import Trees

#if os(macOS)
    import Cocoa

    typealias NativeView = NSView
    typealias NativeViewController = NSViewController
#else
    import UIKit

    typealias NativeView = UIView
    typealias NativeViewController = UIViewController
#endif

@MainActor
final class SlabHostController: NativeViewController {
    @Streamed
    var actualState: State

    @Streamed
    var context: PresentationContext = .unset

    private let desiredStateStream: AsyncStream<Tree<Blueprint>>

    var slabs = [Slab]()

    var subscriptions = Set<AnyCancellable>()

    init<S>(
        initial blueprint: any CompleteBlueprint,
        desiredStateStream: S
    ) where S: AsyncSequence, S.Element == Blueprint {
        let initialTree = Live.makeTree(from: blueprint)
        self.actualState = State(tree: initialTree)
        self.desiredStateStream = desiredStateStream
            .map(Blueprint.makeTree)
            .asStream()

        super.init(nibName: nil, bundle: nil)

        setup()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    #if os(macOS)
        override func viewWillAppear() {
            fatalError()
        }
    #else
        override func willMove(toParent parent: UIViewController?) {
            context = .from(parent?.view)
        }
    #endif

    func setup() {
        Task { [weak self] in
            for await tree in desiredStateStream {
                if Task.isCancelled { return }
                self?.received(desiredTree: tree)
            }
        }
        .eraseToAnyCancellable()
        .store(in: &subscriptions)

        Task { [unowned self] in
            for await orderedSlabs in $actualState.map(\.tree.orderedSlabs) {
                if Task.isCancelled {
                    return
                }

                updateSlabs(orderedSlabs)
            }
        }
        .eraseToAnyCancellable()
        .store(in: &subscriptions)

        Task { [weak self] in
            for await _ in AsyncTimerSequence.repeating(every: .milliseconds(8)) {
                guard !Task.isCancelled, let self else { return }
                if !actualState.isAtRest {
                    self.actualState.update(to: .now)
                }
            }
        }
        .eraseToAnyCancellable()
        .store(in: &subscriptions)

        Task { [weak self] in
            for await _ in $context {
                self?.updateSlabContexts()
            }
        }
        .eraseToAnyCancellable()
        .store(in: &subscriptions)
    }

    func received(desiredTree: Tree<Blueprint>) {
        actualState.unify(with: desiredTree)
    }

    func updateSlabs(_ newSlabs: [Slab]) {
        let oldSlabs = slabs
        guard newSlabs != oldSlabs else { return }

        let addedSlabs = newSlabs.filter(oldSlabs.asSet.doesNotContain)
        let removedSlabs = oldSlabs.filter(newSlabs.asSet.doesNotContain)

        #if os(macOS)
            for slab in removedSlabs {
                slab.controller.view.removeFromSuperview()
            }

            for slab in addedSlabs {
                slab.context = context

                let controller = slab.controller
                addChild(controller)

                controller.view.alpha = 0
                controller.view.frame = view.bounds
                controller.view.autoresizingMask = [.width, .height]
            }

            var previous: Slab?
            for (index, slab) in newSlabs.enumerated() {
                if let previous {
                    view.addSubview(
                        slab.controller.view,
                        positioned: .above,
                        relativeTo: previous.controller.view
                    )
                } else {
                    view.addSubview(
                        slab.controller.view,
                        positioned: .below,
                        relativeTo: view.subviews.first
                    )
                }

                previous = slab
            }
        #else
            for slab in removedSlabs {
                let controller = slab.controller
                controller.willMove(toParent: nil)
                controller.view.removeFromSuperview()
                controller.didMove(toParent: nil)
            }

            for slab in addedSlabs {
                slab.context = context

                let controller = slab.controller
                addChild(controller)

                controller.view.frame = view.bounds
                controller.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                controller.didMove(toParent: self)
            }

            for (index, slab) in newSlabs.enumerated() {
                view.insertSubview(slab.controller.view, at: index)
            }
        #endif

        let labels = newSlabs.map(\.label)
        print("SLABS: \(labels)")

        slabs = newSlabs
    }

    func updateSlabContexts() {
        for slab in actualState.tree.orderedSlabs {
            slab.context = context
        }
    }
}

extension Task {
    func eraseToAnyCancellable() -> AnyCancellable {
        AnyCancellable {
            self.cancel()
        }
    }
}

public extension AsyncSequence {
    func asStream() -> AsyncStream<Element> {
        AsyncStream(self)
    }
}
