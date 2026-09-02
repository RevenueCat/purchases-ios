//
//  Scope.swift
//
//  Created by Antonio Pallares.
//

import Foundation

extension RulesEngine {

    /// Evaluation scope pairing the active data (`current`) with the predicate's
    /// original root. Iteration operators rebind `current` to each item while
    /// preserving `root` for custom operators that need top-level data inside
    /// nested predicates.
    struct Scope {

        /// Data the enclosing expression reads from. Iteration operators replace this with the current item.
        let current: Value
        /// Data the predicate started with, never replaced.
        let root: Value
        /// Names bound by enclosing `rc.let` calls. Unlike `current`, these
        /// survive iteration, which is what lets an inner predicate still see
        /// a value captured outside the loop.
        let bindings: [String: Value]

        init(root: Value) {
            self.root = root
            self.current = root
            self.bindings = [:]
        }

        func scoped(to current: Value) -> Scope {
            Scope(current: current, root: root, bindings: bindings)
        }

        /// Adds names visible from here down. An inner `rc.let` reusing a name
        /// shadows the outer one.
        func binding(_ names: [String: Value]) -> Scope {
            Scope(
                current: current,
                root: root,
                bindings: bindings.merging(names) { _, inner in inner }
            )
        }

        private init(current: Value, root: Value, bindings: [String: Value]) {
            self.current = current
            self.root = root
            self.bindings = bindings
        }
    }
}
