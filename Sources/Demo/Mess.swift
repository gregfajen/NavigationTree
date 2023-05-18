import AsyncAlgorithms
import Combine
import ComposableArchitecture
import Dependencies
import NavigationTree
import PresentationStyles
import SwiftUI

struct OldTabBar: View {
    let store: StoreOf<DemoFeature> = _store

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ButtonStack {
                Button("left") {
                    viewStore.send(.selectTab(.lhs))
                }

                Button("right") {
                    viewStore.send(.selectTab(.rhs))
                }
            }
        }
    }
}

struct TabShape: Shape {
    let cornerRadius: Double

    func path(in rect: CGRect) -> Path {
        Path { path in
            let y = rect.origin.y
            let w = rect.size.width
            let h = rect.size.height
            let r = cornerRadius

            path.move(to: CGPoint(x: 0, y: y - r))

            path.addArc(
                center: CGPoint(x: r, y: y - r),
                radius: r,
                startAngle: .degrees(180),
                endAngle: .degrees(90),
                clockwise: true
            )

            path.addArc(
                center: CGPoint(x: w - r, y: y - r),
                radius: r,
                startAngle: .degrees(90),
                endAngle: .degrees(0),
                clockwise: true
            )

            path.addLine(to: CGPoint(x: w, y: y + h))
            path.addLine(to: CGPoint(x: 0, y: y + h))
            path.closeSubpath()
        }
    }
}

struct TabButton: View {
    let store: Store<Bool, Void>

    let unselected: String
    let selected: String

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            Button {
                viewStore.send(())
            } label: {
                Image(systemName: viewStore.state ? selected : unselected)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .foregroundColor(.white)
                    .animation(.linear, value: viewStore.state)
                    .padding(16)
            }
        }
    }
}

struct NewTabBar: View {
    let store: Store<TabIndex, TabIndex>

    init() {
        self.store = _store.scope(state: \.selectedTab, action: DemoFeature.Action.selectTab)
    }

    var body: some View {
        HStack(spacing: 32) {
            TabButton(
                store: makeStore(for: .lhs),
                unselected: "person.circle",
                selected: "person.circle.fill"
            )

            TabButton(
                store: makeStore(for: .rhs),
                unselected: "list.bullet.circle",
                selected: "list.bullet.circle.fill"
            )
        }
    }

    func makeStore(for index: TabIndex) -> Store<Bool, Void> {
        store.scope {
            $0 == index
        } action: {
            index
        }
    }
}

struct TabOverlay: View {
    var body: some View {
        VStack {
            Spacer()
                .allowsHitTesting(false)

            ZStack {
                TabShape(cornerRadius: 24)
                    .fill(.black)
                    .frame(height: 80)

                NewTabBar()
            }

            .frame(height: 80)
            .background {
                Color.black
                    .ignoresSafeArea()
            }
        }
    }
}

struct ButtonStack<Buttons: View>: View {
    let buttons: Buttons

    init(@ViewBuilder buttons: () -> Buttons) {
        self.buttons = buttons()
    }

    var body: some View {
        VStack(spacing: 20) {
            buttons
        }
        .frame(maxWidth: 240)
        .buttonStyle(DemoButtonStyle())
    }
}

struct DemoButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
            .background(Color.white)
            .cornerRadius(12)
    }
}

struct MainView: View {
    let store: StoreOf<DemoFeature> = _store

    var destinationStore: Store<DemoFeature.Destination?, DemoFeature.Action> {
        store.scope(state: \.mainDestination)
    }

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ZStack {
                Color.gray.ignoresSafeArea()

                Color.white.opacity(0.3)

                ButtonStack {
                    Button("Present Child") {
                        viewStore.send(.presentChild)
                    }

                    Button("Go to Tabs") {
                        viewStore.send(.goToTabs)
                    }
                }
            }
        }
        .presenting(
            case: /.child,
            of: destinationStore,
            dismissAction: .dismiss,
            tag: "child",
            style: BasicPush(transitionDuration: 0.25)
        ) {
            ChildView(store: store)
        }
    }
}

struct ChildView: View {
    let store: StoreOf<DemoFeature>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ZStack {
                Color.blue.ignoresSafeArea()

                Color.white.opacity(0.3)

                ButtonStack {
                    Button("Dismiss") {
                        viewStore.send(.dismiss)
                    }

                    Button("Go to Tabs") {
                        viewStore.send(.goToTabs)
                    }
                }
            }
        }
    }
}
