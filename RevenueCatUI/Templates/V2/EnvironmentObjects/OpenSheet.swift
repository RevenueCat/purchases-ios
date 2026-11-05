//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OpenSheet.swift
//
//  Created by Mark Villacampa on 05/06/25.

import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct OpenSheetActionKey: EnvironmentKey {
    static let defaultValue: (SheetViewModel) -> Void = { _ in }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension EnvironmentValues {
    var openSheet: (SheetViewModel) -> Void {
        get { self[OpenSheetActionKey.self] }
        set { self[OpenSheetActionKey.self] = newValue }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct SessionPurchaseResultKey: EnvironmentKey {
    static let defaultValue: PaywallPurchaseResult? = nil
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension EnvironmentValues {
    /// The latest purchase result of this paywall session. A sheet watches it to close itself after a purchase,
    /// since a purchase made from inside it only requests a dismissal of the whole paywall. Unlike a Boolean, it
    /// changes for every purchase, not just the first.
    var sessionPurchaseResult: PaywallPurchaseResult? {
        get { self[SessionPurchaseResultKey.self] }
        set { self[SessionPurchaseResultKey.self] = newValue }
    }
}

#endif
