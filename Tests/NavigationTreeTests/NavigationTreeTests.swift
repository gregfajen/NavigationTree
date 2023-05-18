import CustomDump
@testable import Trees
import XCTest
import XCTestDynamicOverlay

extension String {
    @usableFromInline
    func indent(by indent: Int) -> String {
        let indentation = String(repeating: " ", count: indent)
        return indentation + replacingOccurrences(of: "\n", with: "\n\(indentation)")
    }
}

func expectationFailure<T>(
    expected: T,
    actual: T,
    message: String,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    let difference = CustomDump.diff(
        expected,
        actual,
        format: .proportional
    )
    .map {
        "\($0.indent(by: 4))\n\n(Expected: −, Actual: +)"

    } ?? """
    \(message)

    Expected:
    \(String(describing: expected).indent(by: 2))

    Actual:
    \(String(describing: actual).indent(by: 2))
    """

    XCTFail("""
    \(message): …

    \(difference)
    """, file: file, line: line)
}

extension Tree where Kind.PresentationPayload == PresentationTiming {
    var inDistantFuture: Self {
        at(.distantFuture)
    }
}

final class NavigationTreeTests: XCTestCase {
    typealias DesiredTree = Tree<Blueprint>
    typealias DesiredBlueprint = Zipper<Blueprint>
    typealias ActualTree = Tree<Mock>
    typealias ActualZipper = Zipper<Mock>

    func startingWith(
        _ initial: ActualZipper,
        expecting expected: DesiredBlueprint,
        message: String = "\(#function)",
        file: StaticString = #filePath,
        line: UInt = #line,
        verify mutation: (inout ActualZipper) throws -> Void
    ) throws {
        var result = initial
        try mutation(&result)

        XCTAssert(initial.stack.isEmpty, "initial zipper has dangling paths on its stack")
        XCTAssert(expected.stack.isEmpty, "expected zipper has dangling paths on its stack")

        let resultTree = result.tree.inDistantFuture.asBlueprintTree
        let expectedTree = expected.tree

        if resultTree != expectedTree {
            expectationFailure(expected: expectedTree, actual: resultTree, message: message, file: file, line: line)
        }
    }

    func startingWith(
        _ actualTree: ActualTree,
        endingWith desiredTree: DesiredTree,
        file: StaticString = #filePath,
        line: UInt = #line,
        expect expectedMutations: [Mutation]
    ) throws {
        let initial = Zipper(actualTree)
        let goal = Zipper(desiredTree)

        let diffedMutations = try unify(actualTree, desiredTree).simplify()
        if expectedMutations != diffedMutations {
            expectationFailure(
                expected: expectedMutations,
                actual: diffedMutations,
                message: "Diffed mutations did not match expected mutations",
                file: file,
                line: line
            )
        }

        try startingWith(
            initial,
            expecting: goal,
            message: "Diffed mutations failed to reach goal",
            file: file,
            line: line
        ) { current in
            try diffedMutations.apply(to: &current, at: .now)
        }

        try startingWith(
            initial,
            expecting: goal,
            message: "Expected mutations failed to reach goal",
            file: file,
            line: line
        ) { current in
            try expectedMutations.apply(to: &current, at: .now)
        }
    }

//    func testPresentationMutation() throws {
//        let mutation = PresentMutation(headID: "child")
//
//        let initial = Zipper(.leaf("parent"))
//        let goal = Zipper(.leaf("parent").presenting("child"))
//
//        try startingWith(initial,
//                         endingWith: goal) { zipper in
//            try mutation.apply(to: &zipper)
//        }
//    }

    func testPresentChild() throws {
        let initial = ActualTree.leaf("parent")
        let goal = DesiredTree.leaf("parent").presenting("child")

        try startingWith(
            initial,
            endingWith: goal,
            expect: [
                .present("child"),
            ]
        )
    }

    func testDismissChild() throws {
        let initial = ActualTree.leaf("parent").presenting("child")
        let goal = DesiredTree.leaf("parent")

        try! startingWith(
            initial,
            endingWith: goal,
            expect: [
                .dismiss("child"),
            ]
        )
    }

    func testPresentChildAndGrandchild() throws {
        let initial = ActualTree.leaf("parent")
        let goal = DesiredTree.leaf("parent").presenting("child").presenting("grandchild")

        try startingWith(
            initial,
            endingWith: goal,
            expect: [
                .present("child"),
                .present("grandchild", at: 1),
            ]
        )
    }

    func testPresentGrandchild() throws {
        let initial = ActualTree.leaf("parent").presenting("child")
        let goal = DesiredTree.leaf("parent").presenting("child").presenting("grandchild")

        try startingWith(
            initial,
            endingWith: goal,
            expect: [
                .present("grandchild", at: 1),
            ]
        )
    }

    func testDismissJustChild() throws {
        let initial = ActualTree.leaf("parent").presenting("child").presenting("grandchild")
        let goal = DesiredTree.leaf("parent").presenting("grandchild")

        try startingWith(
            initial,
            endingWith: goal,
            expect: [
                .dismiss("child"),
            ]
        )
    }

    func testDismissJustGrandchild() throws {
        let initial = ActualTree.leaf("parent").presenting("child").presenting("grandchild")
        let goal = DesiredTree.leaf("parent").presenting("child")

        try startingWith(
            initial,
            endingWith: goal,
            expect: [
                .dismiss("grandchild"),
            ]
        )
    }

    func testDismissGrandchildAndChild() throws {
        let initial = ActualTree.leaf("parent").presenting("child").presenting("grandchild")
        let goal = DesiredTree.leaf("parent")

        try startingWith(
            initial,
            endingWith: goal,
            expect: [
                .dismiss("grandchild"),
                .dismiss("child"),
            ]
        )
    }

    func testPresentChildUnderGrandchild() throws {
        let initial = ActualTree.leaf("parent").presenting("grandchild")
        let goal = DesiredTree.leaf("parent").presenting("child").presenting("grandchild")

        try startingWith(
            initial,
            endingWith: goal,
            expect: [
                //                .descend(to: "child", in: goal),
                .present("child"),
//                .pop(),
            ]
        )
    }

    func testReplaceChild() throws {
        let initial = ActualTree.leaf("parent").presenting("old child")
        let goal = DesiredTree.leaf("parent").presenting("new child")

        try startingWith(
            initial,
            endingWith: goal,
            expect: [
                .dismiss("old child"),
                .present("new child"),
            ]
        )
    }

    func testChangeRoot() throws {
        let initial = ActualTree.leaf("old parent")
        let goal = DesiredTree.leaf("new parent")

        try startingWith(
            initial,
            endingWith: goal,
            expect: [
                .replaceTree(with: goal.blueprint),
            ]
        )
    }

    func testChangeRootAndPresent() throws {
        let initial = ActualTree.leaf("old parent")
        let goal = DesiredTree.leaf("new parent").presenting("child")

        try startingWith(
            initial,
            endingWith: goal,
            expect: [
                .replaceTree(with: DesiredTree.leaf("new parent").blueprint),
                .present("child"),
            ]
        )
    }

    func testChangeRootAndPresentMany() throws {
        let initial = ActualTree.leaf("old parent")
        let goal = DesiredTree.leaf("new parent").presenting("child").presenting("grandchild")

        try startingWith(
            initial,
            endingWith: goal,
            expect: [
                .replaceTree(with: DesiredTree.leaf("new parent").blueprint),
                .present("child"),
                .present("grandchild", at: 1),
            ]
        )
    }

    func testChangeRootAndDismiss() throws {
        let initial = ActualTree.leaf("old parent").presenting("child")
        let goal = DesiredTree.leaf("new parent")

        try startingWith(
            initial,
            endingWith: goal,
            expect: [
                .dismiss("child"),
//                .descend(),
                .replaceTree(with: goal.blueprint),
//                .pop(),
            ]
        )
    }

    func testChangeToTabs() throws {
        let initial = ActualTree.leaf("splash")
        let tabs = TabsNode<Blueprint>(.leaf("left"), .leaf("right"))
        let goal = DesiredTree._tabs(tabs)

        try startingWith(
            initial,
            endingWith: goal,
            expect: [
                .replaceTree(with: goal.blueprint),
            ]
        )
    }

    func testChangeFromTabs() throws {
        let tabs = TabsNode<Mock>(.leaf("left"), .leaf("right"))
        let initial = ActualTree._tabs(tabs)
        let goal = DesiredTree.leaf("login")

        try startingWith(
            initial,
            endingWith: goal,
            expect: [
                .replaceTree(with: goal.blueprint),
            ]
        )
    }

    func testPresentInLeftTab() throws {
        let initial = ActualTree.tabs(.leaf("left"), .leaf("right"))
        let goal = DesiredTree.tabs(.leaf("left").presenting("child"), .leaf("right"))

        try startingWith(
            initial,
            endingWith: goal,
            expect: [
                .enterTab(.lhs),
                .present("child"),
                .pop(),
            ]
        )
    }

    func testPresentInRightTab() throws {
        let initial = ActualTree.tabs(.leaf("left"), .leaf("right"))
        let goal = DesiredTree.tabs(.leaf("left"), .leaf("right").presenting("child"))

        try startingWith(
            initial,
            endingWith: goal,
            expect: [
                .enterTab(.rhs),
                .present("child"),
                .pop(),
            ]
        )
    }

    func testPresentOverTabs() throws {
        let initial = ActualTree.tabs(.leaf("left"), .leaf("right"))
        let goal = DesiredTree.tabs(.leaf("left"), .leaf("right")).presenting("child")

        try startingWith(
            initial,
            endingWith: goal,
            expect: [
                .present("child"),
            ]
        )
    }

    func testChangeSelectedTab() throws {
        let left: LeafBlueprint = "left"
        let right: LeafBlueprint = "right"

        var tabBlueprint = TabsBlueprint(left, right)
        let initial = Mock.makeTree(from: tabBlueprint)

        tabBlueprint.selection = .rhs
        let goal = Blueprint.makeTree(from: tabBlueprint)

        try startingWith(
            ._tabs(initial),
            endingWith: ._tabs(goal),
            expect: [
                .selectTab(.rhs),
            ]
        )
    }
}
