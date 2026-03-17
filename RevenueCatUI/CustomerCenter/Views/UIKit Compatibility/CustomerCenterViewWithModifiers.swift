//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterViewWithModifiers.swift
//

import SwiftUI

#if os(iOS)

/// A type specific view wrapper to avoid needing to wrap CustomerCenterView in AnyView when
/// applying restore interception modifiers from UIKit.
@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct CustomerCenterViewWithModifiers: View {

    let customerCenterView: CustomerCenterView
    let restoreInitiated: CustomerCenterView.RestoreInitiatedHandler

    var body: some View {
        customerCenterView
            .onCustomerCenterRestoreInitiated(restoreInitiated)
    }

}

#endif
