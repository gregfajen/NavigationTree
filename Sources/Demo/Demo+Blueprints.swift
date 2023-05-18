import NavigationTree
import PresentationStyles
import SwiftUI

extension Demo {
    static var splashBlueprint: LeafBlueprint {
        LeafBlueprint(id: "splash") {
            ZStack {
                Color.white.ignoresSafeArea()

                ProgressView()
                    .tint(.blue)
            }
        }
    }

    static func mainBlueprint() -> LeafBlueprint {
        LeafBlueprint(id: "main") {
            MainView()
        }
    }

    static var tabsBlueprint: some CompleteBlueprint {
        StackBlueprint(
            elements: [
                PresentationBlueprint(
                    child: tabOverlay,
                    style: Overlay()
                ),
            ],
            tail: TabsBlueprint(leftTab, rightTab)
        )

//        tabOverlay

//        fatalError()
//        CompletePresentationBlueprint(
//            presentationBlueprint: PresentationBlueprint(
//                child: tabOverlay,
//                style: Overlay()
//            ),
//            tailBlueprint: TabsBlueprint(leftTab, rightTab)
//        )
    }

    static var tabOverlay: LeafBlueprint {
        LeafBlueprint(id: "overlay") {
            TabOverlay()
        } hitInterceptor: { point, context in
            CGRect(
                x: 0,
                y: context.screenSize.height - 80 - context.bottomInset,
                width: 10000,
                height: 80
            )
            .contains(point)
        }
    }

    static var leftTab: LeafBlueprint {
        LeafBlueprint(id: "profile") {
            ZStack {
                Profile()
            }
        }
    }

    static var rightTab: LeafBlueprint {
        LeafBlueprint(id: "rhs") {
            ZStack {
                Color.blue.ignoresSafeArea()

                VStack {
                    Text("rhs")
                    OldTabBar()
                }
            }
        }
    }
}
