import SwiftUI
import Trees

struct SlabAdjustmentState: Equatable {
    var proxy: SlabProxy?
    var blur: Double
    var topInset: Double
    var bottomInset: Double

    init(proxy: SlabProxy? = nil, blur: Double, topInset: Double, bottomInset: Double) {
        if blur >= 0 {
            precondition(proxy != nil)
            precondition(proxy?.slab != nil)
        }
        self.proxy = proxy
        self.blur = blur
        self.topInset = topInset
        self.bottomInset = bottomInset
    }

    static let `default` = SlabAdjustmentState(
        proxy: nil,
        blur: -1,
        topInset: 0,
        bottomInset: 0
    )
}

struct SlabAdjustmentView<Content: View>: View {
    let content: Content
    let stateStream: AsyncStream<SlabAdjustmentState>

    @State
    var state = SlabAdjustmentState.default

    var hasProxy: Bool {
        state.proxy?.slab != nil
    }

    var body: some View {
        content
            .environment(\.slabProxy, state.proxy)
            .safeAreaInset(edge: .top) { Spacer().frame(height: state.topInset) }
            .safeAreaInset(edge: .bottom) { Spacer().frame(height: state.bottomInset) }
            .compositingGroup()
            .blur(radius: state.blur)
            .ignoresSafeArea()
            .task {
                for await newState in stateStream {
                    state = newState
                }
            }
    }
}
