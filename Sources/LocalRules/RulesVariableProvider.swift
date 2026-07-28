//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RulesVariableProvider.swift
//
//  Created by Rick van der Linden on 7/28/26.
//

import Foundation

/// SDK-owned roots that may be evaluated locally by the rules engine.
enum RulesVariableNamespace: String, CaseIterable, Sendable {

    case device
    case session
    case client
}

/// A scalar value exposed to the local rules engine.
///
/// This keeps providers independent from the RulesEngine representation.
enum RulesVariableValue: Equatable, Sendable {

    case string(String)
    case bool(Bool)
    case int(Int64)
    case double(Double)
}

/// Supplies one current subtree of on-device rules variables.
///
/// Implementations may observe or persist state internally, but values are
/// pulled only when a rules evaluation requests a new snapshot.
protocol RulesVariableProvider: Sendable {

    /// Stable identifier used only for configuration diagnostics.
    var identifier: String { get }

    /// Root namespace containing the returned variables.
    var namespace: RulesVariableNamespace { get }

    /// Returns the complete current set of scalar values relative to ``namespace``.
    ///
    /// Keys are lowercase snake-case names such as `app_version`. The resolver
    /// adds the provider's namespace. Missing individual values must be
    /// omitted. Throwing is reserved for a systemic failure to produce the
    /// provider's values.
    ///
    /// `date` is the common reference date for the evaluation. It does not
    /// indicate when the underlying values were observed.
    func variables(at date: Date) async throws -> [String: RulesVariableValue]
}
