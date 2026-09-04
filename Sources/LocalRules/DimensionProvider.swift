//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DimensionProvider.swift
//
//  Created by Rick van der Linden on 7/28/26.
//

import Foundation

/// A dimension exposed to the local rules engine.
///
/// This keeps providers independent from the RulesEngine representation.
enum DimensionValue: Equatable, Sendable {

    case string(String)
    case bool(Bool)
    case int(Int64)
    case double(Double)

    /// A date that can be compared and ordered by local rules.
    ///
    /// Dates are exposed to the rules engine as Unix epoch milliseconds.
    case date(Date)

    /// A named group of values that rules can read through using a dot path.
    ///
    /// Unlike a record inside ``objectList(_:)``, reading an object does not
    /// change the rule's evaluation scope.
    indirect case object([String: DimensionValue])

    /// A collection of records that can be inspected by local rules.
    ///
    /// Records are only expressible inside a collection. Collection operators
    /// evaluate each record in its own scope, so a record must contain every
    /// value needed to evaluate it, unless the predicate reaches the snapshot
    /// with `rc.rootVar`.
    case objectList([[String: DimensionValue]])
}

/// Supplies part of the root scope of dimensions.
///
/// Implementations may observe or persist state internally, but values are
/// pulled only when a rules evaluation requests a new snapshot.
protocol DimensionProvider: Sendable {

    /// Identifies this provider in diagnostics. It is not part of the evaluated scope.
    var name: String { get }

    /// Returns the complete current set of root dimensions owned by this provider.
    ///
    /// Keys are snake-case names such as `app_version`. The resolver merges
    /// every provider into one root and recursively ignores empty,
    /// whitespace-only, or `.`-containing keys. Missing individual values must
    /// be omitted. Throwing is reserved for a systemic failure to produce the
    /// provider's dimensions.
    ///
    /// `date` is the common reference date for the evaluation. It does not
    /// indicate when the underlying values were observed.
    func dimensions(at date: Date) async throws -> [String: DimensionValue]
}
