//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallLoadingKey.swift
//
//  Created by RevenueCat on 5/12/26.

import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct PaywallLoadingKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension EnvironmentValues {

    var isPaywallLoading: Bool {
        get { self[PaywallLoadingKey.self] }
        set { self[PaywallLoadingKey.self] = newValue }
    }

}

#endif
