//
//  ObjectValue.swift
//
//  Created by Antonio Pallares.
//

import Foundation

extension RulesEngine {

    /// The storage behind `Value.object`, keyed by UTF-16 code unit.
    ///
    /// A Swift `[String: Value]` keys by canonical equivalence, so `é`
    /// (U+00E9) and `e` followed by a combining acute (U+0301) are one key: an
    /// object holding both spellings silently keeps one, and a path spelled
    /// either way resolves against the other. JS and Kotlin compare keys by
    /// code unit and keep the two apart, which is what `jsStringEquals`
    /// already does everywhere else the engine compares strings.
    struct ObjectValue {

        private var storage: [ObjectKey: Value]

        init() {
            self.storage = [:]
        }

        /// Widens a Swift dictionary. Keys it already merged stay merged, so
        /// callers that must keep every spelling build an `ObjectValue` from
        /// the start.
        init(_ dictionary: [String: Value]) {
            self.storage = .init(minimumCapacity: dictionary.count)
            for (key, value) in dictionary {
                self[key] = value
            }
        }

        subscript(key: String) -> Value? {
            get { self.storage[ObjectKey(string: key)] }
            set { self.storage[ObjectKey(string: key)] = newValue }
        }

        var count: Int { self.storage.count }
        var isEmpty: Bool { self.storage.isEmpty }
        var keys: [String] { self.storage.keys.map(\.string) }

        var first: (key: String, value: Value)? {
            self.storage.first.map { ($0.key.string, $0.value) }
        }
    }
}

extension RulesEngine.ObjectValue: Equatable, Hashable, Sendable {}

extension RulesEngine.ObjectValue: Sequence {

    func makeIterator() -> AnyIterator<(key: String, value: RulesEngine.Value)> {
        var iterator = self.storage.makeIterator()
        return AnyIterator {
            iterator.next().map { ($0.key.string, $0.value) }
        }
    }
}

extension RulesEngine.ObjectValue: ExpressibleByDictionaryLiteral {

    typealias Key = String
    typealias Value = RulesEngine.Value

    init(dictionaryLiteral elements: (String, RulesEngine.Value)...) {
        self.init()
        for (key, value) in elements {
            self[key] = value
        }
    }
}

private struct ObjectKey: Hashable {

    let string: String

    static func == (lhs: ObjectKey, rhs: ObjectKey) -> Bool {
        RulesEngine.jsStringEquals(lhs.string, rhs.string)
    }

    func hash(into hasher: inout Hasher) {
        for unit in string.utf16 {
            hasher.combine(unit)
        }
    }
}
