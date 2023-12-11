//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallFooterViewController.swift
//
//  Created by Antonio Rico Diez on 4/12/23.
//

#if canImport(UIKit) && !os(tvOS) && !os(watchOS)

import RevenueCat
import SwiftUI
import UIKit

/// A view controller for displaying `PaywallData` for an `Offering` in a footer format.
/// This is used by the RevenueCathybrid SDKs in order to get a View of the footer.
///
/// Consumers should normally use ``PaywallViewController`` instead.
///
/// - Seealso: ``PaywallView`` for `SwiftUI`.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
@objc(RCPaywallFooterViewController)
public final class PaywallFooterViewController: PaywallViewController {

    override var mode: PaywallViewMode {
        return .footer
    }

}

#endif
