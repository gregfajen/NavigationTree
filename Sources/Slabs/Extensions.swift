import Foundation

extension Sequence where Element: Hashable {
    var asSet: Set<Element> { Set(self) }
}

extension Optional {
    var asArray: [Wrapped] {
        if let self {
            return [self]
        } else {
            return []
        }
    }
}

extension RangeReplaceableCollection {
    mutating func append(_ newElement: Element?) {
        if let newElement {
            append(newElement)
        }
    }
}

extension Set {
    func doesNotContain(_ member: Element) -> Bool {
        !contains(member)
    }
}
