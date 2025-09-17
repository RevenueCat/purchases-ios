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

extension EnvironmentValues {

    var componentViewState: ComponentViewState {
        get { self[ComponentViewStateKey.self] }
        set { self[ComponentViewStateKey.self] = newValue }
    }

}

#endif
