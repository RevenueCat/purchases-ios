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
//  Created by Josh Holtz on 10/2/24.

import Foundation
import SwiftUI

#if PAYWALL_COMPONENTS

public enum ComponentViewState {
    case normal
    case selected
}

struct ComponentViewStateKey: EnvironmentKey {

    static let defaultValue: ComponentViewState = .normal

}

extension EnvironmentValues {

    var componentViewState: ComponentViewState {
        get { self[ComponentViewStateKey.self] }
        set { self[ComponentViewStateKey.self] = newValue }
    }

}

#endif
