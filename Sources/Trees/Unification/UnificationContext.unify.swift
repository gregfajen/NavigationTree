import Foundation

func unify<Kind>(
    _ initial: Tree<Kind>,
    _ goal: Tree<Blueprint>
) throws -> [Mutation] where Kind: KindProtocol, Kind.PresentationPayload == PresentationTiming {
    var context = UnificationContext(actual: initial, desired: goal, date: .now)
    let diff = try context.unify()

    return diff
}

extension UnificationContext {
    public mutating func unify() throws -> [Mutation] {
        var mutations = Mutations()
        try unify(&mutations)
        return mutations
    }

    @discardableResult
    mutating func push(
        _ pathElement: PathElement,
        onActualOnly: Bool = false,
        onDesiredOnly: Bool = false
    ) throws -> Mutation {
        precondition(!(onActualOnly && onDesiredOnly))

        if !onDesiredOnly {
            try actual.push(pathElement)
        } else {
            desiredStackCountOffset += 1
        }

        if !onActualOnly {
            try desired.push(pathElement)
        } else {
            actualStackCountOffset += 1
        }

        let mutation = PushPathMutation(pathElement: pathElement)
        return mutation.case
    }

    @discardableResult
    mutating func pop(
        onActualOnly: Bool = false,
        onDesiredOnly: Bool = false
    ) throws -> Mutation {
        precondition(!(onActualOnly && onDesiredOnly))

        if !onDesiredOnly {
            try actual.pop()
        } else {
            desiredStackCountOffset -= 1
        }

        if !onActualOnly {
            try desired.pop()
        } else {
            actualStackCountOffset -= 1
        }

        let mutation = PopPathMutation()
        return mutation.case
    }

    mutating func unify(_ mutations: inout Mutations) throws {
        let initialStackCount = desired.stack.count - desiredStackCountOffset
        precondition(actual.stack.count - actualStackCountOffset == initialStackCount)
        precondition(desired.stack.count - desiredStackCountOffset == initialStackCount)

        if actual.tree.isEqual(to: desired.tree) {
            return
        }

        switch (actual.tree, desired.tree) {
            case let (._stack(actualStack), ._stack(desiredStack)):
                let dismissals = try handleDismissals(actualStack: actualStack, desiredStack: desiredStack)
                mutations.append(contentsOf: dismissals)

                let push = try push(.descend)
                mutations.append(push)
                try unify(&mutations)
                let pop = try pop()
                mutations.append(pop)

                let presentations = try handlePresentations(actualStack: actualStack, desiredStack: desiredStack)
                mutations.append(contentsOf: presentations)

            case let (._stack(actualStack), _):
                for element in actualStack.elements.reversed() {
                    let mutation = DismissMutation(expectedID: element.presentationBlueprint.child.id)
                    try mutation.apply(to: &actual, at: date)
                    mutations.append(mutation.case)
                }

                desired.tree = ._stack(StackNode(presenting: [], over: desired.tree))

                let push = try push(.descend)
                try unify(&mutations)
                let pop = try pop()

            case let (_, ._stack(desiredStack)):
                let push = try push(.descend, onDesiredOnly: true)
                try unify(&mutations)
                let pop = try pop(onDesiredOnly: true)

                for (index, element) in desiredStack.elements.enumerated() {
                    let mutation = PresentMutation(blueprint: element.presentationBlueprint, at: index)
                    try mutation.apply(to: &actual, at: date)
                    mutations.append(mutation.case)
                }

            case (._replacement, _):
                let mutation = ReplaceMutation(blueprint: desired.tree.blueprint)
                try mutation.apply(to: &desired, at: date)

                let pushMutation = try push(.descend)
                mutations.append(pushMutation)

                // keep on diffin'
                try unify(&mutations)

                let popMutation = try pop()
                mutations.append(popMutation)

            case (._leaf, ._leaf),
                 (._tabs, ._leaf),
                 (._leaf, ._tabs):
                let mutation = ReplaceMutation(blueprint: desired.tree.blueprint)
                try mutation.apply(to: &actual, at: date)
                try mutation.apply(to: &desired, at: date)
                mutations.append(mutation.case)

            case let (._tabs(actualTabs), ._tabs(desiredTabs)):
                if actualTabs.selection != desiredTabs.selection {
                    let selectMutation = SelectTabMutation(selection: desiredTabs.selection)
                    try selectMutation.apply(to: &actual, at: date)
                    mutations.append(selectMutation.case)
                }

                func handleBranch(_ index: TabIndex) throws {
                    let pushMutation = try push(.enterTab(index))
                    mutations.append(pushMutation)
                    try unify(&mutations)
                    let popMutation = try pop()
                    mutations.append(popMutation)
                }

                try handleBranch(.lhs)
                try handleBranch(.rhs)

            default:
                fatalError()
        }

        assert(actual.stack.count - actualStackCountOffset == initialStackCount)
        assert(desired.stack.count - desiredStackCountOffset == initialStackCount)
//        assert(actual.tree.isEqual(to: desired.tree))
    }

    mutating func handleDismissals(
        actualStack: StackNode<Actual>,
        desiredStack: StackNode<Desired>
    ) throws -> Mutations {
        let desiredLeaves = Set(desiredStack.elements.map(\.leaf.blueprint))
        let leavesToDismiss = actualStack.elements.map(\.leaf.blueprint).filter(desiredLeaves.doesNotContain)
        if leavesToDismiss.isEmpty {
            return []
        }

        let leaf = leavesToDismiss.last!
        let mutation = DismissMutation(expectedID: leaf.id)

        try mutation.apply(to: &actual, at: date)
        try mutation.apply(to: &desired, at: date)
        return [mutation.case]
    }

    mutating func handlePresentations(
        actualStack: StackNode<Actual>,
        desiredStack: StackNode<Desired>
    ) throws -> Mutations {
        let actualLeaves = actualStack.elements.map(\.leaf.blueprint).asSet
        let leavesToPresent = desiredStack.elements.enumerated()
            .filter { !actualLeaves.contains($0.element.leaf.blueprint) }

        if leavesToPresent.isEmpty {
            return []
        }

        var mutations = Mutations()
        for (index, element) in leavesToPresent {
            let mutation = PresentMutation(blueprint: element.presentationBlueprint, at: index)
            try mutation.apply(to: &actual, at: date)
            mutations.append(mutation.case)
        }

        return mutations
    }
}

extension Sequence where Element: Hashable {
    var asSet: Set<Element> {
        Set(self)
    }
}

extension Sequence where Element: Hashable {
    func doesNotContain(_ element: Element) -> Bool {
        !contains(element)
    }
}
