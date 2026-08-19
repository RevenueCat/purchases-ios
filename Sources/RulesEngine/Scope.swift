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

        init(root: Value) {
            self.root = root
            self.current = root
        }

        func scoped(to current: Value) -> Scope {
            Scope(current: current, root: root)
        }

        private init(current: Value, root: Value) {
            self.current = current
            self.root = root
        }
    }
}
