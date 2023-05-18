import CustomDump
@testable import Trees
import XCTest
import XCTestDynamicOverlay

final class TraversalTests: XCTestCase {
    func testDescend() throws {
        let initial = Tree<Blueprint>.leaf("parent").presenting("child")
        let goal = Tree<Blueprint>.leaf("parent")

        var current = initial
        let revert = try current.traverse(path: .descend)
        XCTAssert(current == goal)

        revert(&current)
        XCTAssert(current == initial)
    }
}
