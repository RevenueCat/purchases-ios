//
//  RulesEngineUtils.swift
//
//  Created by Antonio Pallares.
//

import Foundation

extension RulesEngine {

    /// Helpers shared by more than one operator, so none of them owns another.
    enum RulesEngineUtils {

        /// The one place the engine measures a string, in UTF-16 code units
        /// rather than Swift grapheme clusters (JS `String.length` parity).
        ///
        /// `rc.length` returns this and `rc.indexOf` reports positions through
        /// it, so every length and position handed back to a rule is stated in
        /// the same unit and a later change to that unit moves them together.
        static func stringLength(_ string: String) -> Int {
            string.utf16.count
        }
    }
}
