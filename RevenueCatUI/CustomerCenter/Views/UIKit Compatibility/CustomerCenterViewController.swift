//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterViewController.swift
//
//  Created by Will Taylor on 12/6/24.

import RevenueCat
import SwiftUI

#if canImport(UIKit) && os(iOS)

/// A UIKit ViewController for displaying a customer support common tasks
@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public class CustomerCenterViewController: UIHostingController<CustomerCenterView> {

    /// Create a view controller to handle common customer support tasks
    /// - Parameters:
    ///   - customerCenterActionHandler: An optional `CustomerCenterActionHandler` to handle actions
    ///   from the Customer Center.
    public init(
        customerCenterActionHandler: CustomerCenterActionHandler? = nil
    ) {
        let view = CustomerCenterView(
            customerCenterActionHandler: customerCenterActionHandler
        )
        super.init(rootView: view)
    }

    @available(*, unavailable, message: "Use init(customerCenterActionHandler:mode:) instead.")
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#endif
