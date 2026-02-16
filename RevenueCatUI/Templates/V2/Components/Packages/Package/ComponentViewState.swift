//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ComponentViewState.swift
//
//  Created by Josh Holtz on 10/26/24.

import Foundation
import SwiftUI

#if !os(tvOS) // For Paywalls V2

enum ComponentViewState {
    case `default`
    case selected
}

struct ComponentViewStateKey: EnvironmentKey {

    static let defaultValue: ComponentViewState = .default

}

/// Environment key for the current package ID within a PackageComponent context.
/// This is used for evaluating `package` conditions in component overrides.
struct CurrentPackageIdKey: EnvironmentKey {

    static let defaultValue: String? = nil

}

extension EnvironmentValues {

    var componentViewState: ComponentViewState {
        get { self[ComponentViewStateKey.self] }
        set { self[ComponentViewStateKey.self] = newValue }
    }

    /// The package identifier of the enclosing PackageComponent, if any.
    /// Used for evaluating `package` conditions in conditional configurability.
    var currentPackageId: String? {
        get { self[CurrentPackageIdKey.self] }
        set { self[CurrentPackageIdKey.self] = newValue }
    }

}

#endif
