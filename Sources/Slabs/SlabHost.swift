import Foundation
import SwiftUI
import Trees

#if os(macOS)
    import Cocoa

    @MainActor
    struct SlabHost: NSViewControllerRepresentable {
        let controller: SlabHostController

        public func makeNSViewController(context _: Context) -> NSViewController {
            controller
        }

        public func updateNSViewController(_: NSViewController, context _: Context) { }
    }

#else
    import UIKit

    @MainActor
    struct SlabHost: UIViewControllerRepresentable {
        let controller: SlabHostController

        public func makeUIViewController(context _: Context) -> UIViewController {
            controller
        }

        public func updateUIViewController(_: UIViewController, context _: Context) { }
    }

#endif

extension SlabHost {
    init<S>(
        initial blueprint: any CompleteBlueprint,
        desiredStateStream: S
    ) where S: AsyncSequence, S.Element == Blueprint {
        self.controller = SlabHostController(
            initial: blueprint,
            desiredStateStream: desiredStateStream
        )
    }
}
