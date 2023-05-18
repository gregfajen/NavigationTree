import ComposableArchitecture
import NavigationTree
import PresentationStyles
import SwiftUI
import Trees

struct ProfileFeature: ReducerProtocol {
    enum Destination {
        case child
    }

    struct State: Equatable {
        var destination: Destination?
    }

    enum Action: Hashable {
        case dismiss
        case presentChild
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
            case .dismiss:
                state.destination = nil
                return .none

            case .presentChild:
                state.destination = .child
                return .none
        }
    }
}

struct Profile: View {
    let store: StoreOf<ProfileFeature>
    let presentationStore: Store<ProfileFeature.Destination?, ProfileFeature.Action>

    init() {
        self.store = _store.scope(state: \.profileState, action: DemoFeature.Action.profileAction)
        self.presentationStore = store.scope(state: \.destination)
    }

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ZStack {
                Color.pink.ignoresSafeArea()

                LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                    .opacity(0.5)

                Color.white.ignoresSafeArea().opacity(0.3)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Group {
                            ProfileCore()
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
                .onTapGesture {
                    viewStore.send(.presentChild)
                }
            }
            .compositingGroup()
            .hueRotation(.degrees(190))
            .safeAreaInset(edge: .bottom, content: {
                Spacer().frame(height: 80)
            })
            .presenting(
                case: /.child,
                of: presentationStore,
                dismissAction: .dismiss,
                tag: "child",
                style: BasicPush()

            ) {
                ZStack {
                    Color.purple.ignoresSafeArea()

                    ButtonStack {
                        Button("Dismiss") {
                            viewStore.send(.dismiss)
                        }
                    }
                }
            }
        }
    }
}

struct ProfileCore: View {
    var body: some View {
        HStack {
            Avatar(size: 120)
                .colorInvert()
                .saturation(0)
                .brightness(-0.1)
                .contrast(1.5)
                .blendMode(.overlay)

            Spacer()
        }
        .padding(.top, 40)
        .padding(.bottom, 30)

        HStack {
            Text("Profile")
                .font(.system(size: 80, weight: .heavy))
                .foregroundColor(.white)
                .opacity(0.5)
                .padding(.vertical, -10)

            Spacer()
        }
        .padding(.bottom, 10)

        LazyVGrid(columns: .init(repeating: GridItem(spacing: 16), count: 2), spacing: 16) {
            ForEach(0 ... 10, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 24)
                    .fill(.white)
                    .aspectRatio(1, contentMode: .fit)
                    .opacity(0.3)
            }
        }
    }
}

struct Profile_Previews: PreviewProvider {
    static var previews: some View {
        Profile()
    }
}
