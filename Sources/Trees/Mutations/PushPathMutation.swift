import Foundation

public struct PushPathMutation: _MutationProtocol {
    let pathElements: [PathElement]

    init(pathElement: PathElement) {
        self.pathElements = [pathElement]
    }

    init(pathElements: [PathElement]) {
        self.pathElements = pathElements
    }

    var `case`: Mutation { .push(self) }

    func apply(to zipper: inout Zipper<some KindProtocol>, at _: Date) throws {
        for element in pathElements {
            try zipper.push(element)
        }
    }
}
