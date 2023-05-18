import Foundation

public struct SelectTabMutation: _MutationProtocol {
    let selection: TabIndex

    var `case`: Mutation {
        .selectTab(self)
    }

    func apply(
        to zipper: inout Zipper<some KindProtocol>,
        at _: Date
    ) throws {
        guard case let ._tabs(tabs) = zipper.tree else {
            throw MutationError.mutationNotApplicable
        }

        zipper.tree = ._tabs(tabs.updated(with: { tabs in
            tabs.selection = selection
        }))
    }
}
