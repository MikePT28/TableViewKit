import Foundation

enum ArrayChanges<Element> {
    case inserts([Int], [Element])
    case deletes([Int], [Element])
    case updates([Int])
    case moves([(Int, Int)])
    case beginUpdates
    case endUpdates
}

/// An observable array. It will notify any kind of changes.
public class ObservableArray<T>: MutableCollection, RandomAccessCollection, RangeReplaceableCollection,
    ExpressibleByArrayLiteral {

    /// The type of the elements of an array literal.
    public typealias Element = T

    var array: [T]

    var callback: ((ArrayChanges<T>) -> Void)?

    /// Creates an empty `ObservableArray`
    public required init() {
        self.array = []
    }

    /// Creates an `ObservableArray` with the contents of `array`
    ///
    /// - parameter array: The initial content
    public init(array: [T]) {
        self.array = array
    }

    /// Creates an instance initialized with the given elements.
    ///
    /// - parameter elements: An array of elements
    public required init(arrayLiteral elements: Element...) {
        self.array = elements
    }

    /// Returns an iterator over the elements of the collection.
    public func makeIterator() -> Array<T>.Iterator {
        return array.makeIterator()
    }

    /// The position of the first element in a nonempty collection.
    public var startIndex: Int {
        return array.startIndex
    }

    /// The position of the last element in a nonempty collection.
    public var endIndex: Int {
        return array.endIndex
    }

    /// Returns the position immediately after the given index.
    ///
    /// - parameter i: A valid index of the collection. i must be less than endIndex.
    ///
    /// - returns:  The index value immediately after i.
    public func index(after index: Int) -> Int {
        return array.index(after: index)
    }

    /// A Boolean value indicating whether the collection is empty.
    public var isEmpty: Bool {
        return array.isEmpty
    }

    /// The number of elements in the collection.
    public var count: Int {
        return array.count
    }

    /// Accesses the element at the specified position.
    ///
    /// - parameter index:
    public subscript(index: Int) -> T {
        get {
            return array[index]
        }
        set {
            array[index] = newValue
        }
    }

    /// Replace its content with a new array
    ///
    /// - parameter array: The new array
    public func replace(with array: [T], shouldPerformDiff: Bool = true) {
        guard shouldPerformDiff else {
            self.array = array
            return
        }

        let diff = Array.diff(between: self.array,
                              and: array,
                              subrange: 0..<self.array.count,
                              where: compare)
        self.array = array
        notifyChanges(with: diff)
    }

    /// Replaces the specified subrange of elements with the given collection.
    ///
    /// - parameter subrange: The subrange that must be replaced
    /// - parameter newElements: The new elements that must be replaced
    // swiftlint:disable:next line_length
    public func replaceSubrange<C>(_ subrange: Range<Int>, with newElements: C) where C : Collection, C.Iterator.Element == T {
        let temp = Array(newElements)
        let diff = Array.diff(between: self.array,
                              and: temp,
                              subrange: subrange,
                              where: compare)
        self.array.replaceSubrange(subrange, with: newElements)
        notifyChanges(with: diff)
    }

    public func insert(contentsOf newElements: [T], at index: Int) {
        array.insert(contentsOf: newElements, at: index)

        let diff = Diff(inserts: Array(index..<index + newElements.count), insertsElement: newElements)
        notifyChanges(with: diff)

    }

    /// Append `newElement` to the array.
    public func append(contentsOf newElements: [T]) {
        insert(contentsOf: newElements, at: array.count)
    }

    /// Remove all elements from the array.
    public func removeAll() {
        let temp = array
        array.removeAll()
        let diff = Diff(deletes: Array(0..<temp.count), deletesElement: temp)
        notifyChanges(with: diff)
    }

    private func compare(lhs: T, rhs: T) -> Bool {
        if let lhs = lhs as? AnyEquatable {
            return lhs.equals(rhs)
        }
        return false
    }

    private func notifyChanges(with diff: Diff<T>) {
        callback?(.beginUpdates)
        if !diff.moves.isEmpty { callback?(.moves(diff.moves)) }
        if !diff.deletes.isEmpty { callback?(.deletes(diff.deletes, diff.deletesElement)) }
        if !diff.inserts.isEmpty { callback?(.inserts(diff.inserts, diff.insertsElement)) }
        callback?(.endUpdates)
    }

}
