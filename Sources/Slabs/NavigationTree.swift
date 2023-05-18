import SwiftUI
import Trees

@MainActor
public struct NavigationTree: View {
    let host: SlabHost

    private init(host: SlabHost) {
        self.host = host
    }

    public init(
        initial blueprint: any CompleteBlueprint,
        desiredStateStream: AsyncStream<Blueprint>
    ) {
        self.host = SlabHost(
            initial: blueprint,
            desiredStateStream: desiredStateStream // AsyncStream(desiredStateStream)
        )
    }

    public var body: some View {
        host.ignoresSafeArea()
    }
}
