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

/// Roots containing dimensions that may be evaluated locally by the rules engine.
enum DimensionNamespace: String, CaseIterable, Sendable {

    case custom
    case device
    case store
    case session
    case client
}

/// A scalar dimension exposed to the local rules engine.
///
/// This keeps providers independent from the RulesEngine representation.
enum DimensionValue: Equatable, Sendable {

    case string(String)
    case bool(Bool)
    case int(Int64)
    case double(Double)
}

/// Supplies one current subtree of dimensions.
///
/// Implementations may observe or persist state internally, but values are
/// pulled only when a rules evaluation requests a new snapshot.
protocol DimensionProvider: Sendable {

    /// Root namespace containing the returned dimensions.
    var namespace: DimensionNamespace { get }

    /// Returns the complete current set of scalar dimensions relative to ``namespace``.
    ///
    /// Keys are lower camel-case names such as `appVersion`. The resolver
    /// adds the provider's namespace. Missing individual values must be
    /// omitted. Throwing is reserved for a systemic failure to produce the
    /// provider's dimensions.
    ///
    /// `date` is the common reference date for the evaluation. It does not
    /// indicate when the underlying values were observed.
    func dimensions(at date: Date) async throws -> [String: DimensionValue]
}
