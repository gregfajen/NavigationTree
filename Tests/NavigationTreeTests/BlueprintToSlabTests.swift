import CustomDump
@testable import Slabs
import SwiftUI
@testable import Trees
import XCTest
import XCTestDynamicOverlay

@MainActor
final class BlueprintToSlabTests: XCTestCase {
    func testMakeTreeFromLeafBlueprint() throws {
        let leaf = Live.makeTree(from: "hello" as LeafBlueprint)
        XCTAssert(leaf.blueprint.id == "hello")
    }

    func testThatDismissDoesNotRemoveSlab() throws {
        let parentBlueprint: LeafBlueprint = "parent"
        let childBlueprint: LeafBlueprint = "child"

        var isAtRest = true
        let initialTree = Live
            .makeTree(from: parentBlueprint)
            .presenting(
                blueprint: childBlueprint,
                payload: Slab(blueprint: childBlueprint),
                at: .now
            )
            .mutated(isAtRest: &isAtRest)
        let initialSlabs = initialTree.orderedSlabs
        XCTAssert(isAtRest == false)
        XCTAssert(initialSlabs.count == 2)

        let dismissMutation = DismissMutation(expectedID: "child")
        var zipper = Zipper(initialTree)
        try dismissMutation.apply(to: &zipper, at: .now)

        let finalSlabs = zipper.tree
            .orderedSlabs
        XCTAssert(finalSlabs.count == 2)
    }

    func testThatMutateRemovesPresentedSlab() throws {
        let parentBlueprint: LeafBlueprint = "parent"
        let childBlueprint: LeafBlueprint = "child"

        var isAtRest1 = true
        let initialTree = Live
            .makeTree(from: parentBlueprint)
            .presenting(
                blueprint: childBlueprint,
                payload: Slab(blueprint: childBlueprint),
                at: .now
            )
            .mutated(isAtRest: &isAtRest1)
        let initialSlabs = initialTree.orderedSlabs
        XCTAssert(initialSlabs.count == 2)
        XCTAssert(isAtRest1 == false)

        let dismissMutation = DismissMutation(expectedID: "child")
        var zipper = Zipper(initialTree)
        try dismissMutation.apply(to: &zipper, at: .now)

        let intermediateSlabs = zipper.tree.orderedSlabs
        XCTAssert(intermediateSlabs.count == 2)

        var isAtRest2 = true
        let finalSlabs = zipper.tree
            .mutated(to: .distantFuture, isAtRest: &isAtRest2)
            .orderedSlabs
        XCTAssert(finalSlabs.count == 1)
        XCTAssert(isAtRest2 == true)
    }

    func testThatReplaceDoesNotRemoveSlab() throws {
        let oldBlueprint: LeafBlueprint = "old"
        let newBlueprint: LeafBlueprint = "new"

        var isAtRest1 = true
        let initialTree = Live
            .makeTree(from: oldBlueprint)
            .mutated(isAtRest: &isAtRest1)
        let initialSlabs = initialTree.orderedSlabs
        XCTAssert(isAtRest1 == true)
        XCTAssert(initialSlabs.count == 1)

        var isAtRest2 = true
        let replaceMutation = ReplaceMutation(blueprint: newBlueprint)
        var zipper = Zipper(initialTree)
        try replaceMutation
            .apply(to: &zipper, at: .now)
        let finalTree = zipper.tree.mutated(to: .now, isAtRest: &isAtRest2)
        let finalSlabs = finalTree.orderedSlabs
        XCTAssert(isAtRest2 == false)
        XCTAssert(finalSlabs.count == 2)

        XCTAssert(finalSlabs.first == initialSlabs.first)
    }

    func testThatMutateRemovesReplacedSlabs() throws {
        let oldBlueprint: LeafBlueprint = "old"
        let newBlueprint: LeafBlueprint = "new"

        var isAtRest1 = true
        let initialTree = Live
            .makeTree(from: oldBlueprint)
            .mutated(isAtRest: &isAtRest1)
        let initialSlabs = initialTree.orderedSlabs
        XCTAssert(isAtRest1 == true)
        XCTAssert(initialSlabs.count == 1)

        var isAtRest2 = true
        let replaceMutation = ReplaceMutation(blueprint: newBlueprint)
        var zipper = Zipper(initialTree)
        try replaceMutation
            .apply(to: &zipper, at: .now)
        let finalTree = zipper.tree.mutated(to: .distantFuture, isAtRest: &isAtRest2)
        let finalSlabs = finalTree.orderedSlabs
        XCTAssert(isAtRest2 == true)
        XCTAssert(finalSlabs.count == 1)

        XCTAssert(finalSlabs.first != initialSlabs.first)
    }
}

extension LeafBlueprint: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = LeafBlueprint(id: value) { EmptyView() }
    }
}
