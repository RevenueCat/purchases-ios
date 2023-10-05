//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PackageButtonStyle.swift
//
//  Created by Nacho Soto on 7/29/23.

import SwiftUI

/// A `ButtonStyle` suitable to be used for a package selection button.
/// Features:
/// - Automatic handling of disabled state
/// - Replaces itself with a loading indicator if it's the selected package.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
struct PackageButtonStyle: ButtonStyle {

    var fadeDuringPurchases: Bool = true

    @EnvironmentObject
    private var purchaseHandler: PurchaseHandler

    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration
            .label
            .contentShape(Rectangle())
            .opacity(
                self.fadeDuringPurchases && self.purchaseHandler.actionInProgress
                ? Constants.purchaseInProgressButtonOpacity
                : 1
            )
    }

}
