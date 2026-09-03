//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ExternalPurchaseNotice.swift
//
//  Created by Antonio Pallares on 9/3/26.

import Foundation

/// The style of disclosure notice to display before routing a customer to an external purchase.
internal enum ExternalPurchaseNoticeType: Hashable, Sendable {

    /// The app goes to the background and promotes offers in a destination outside of the app.
    case browser

    /// The app promotes offers in a web view or native experience within the app.
    case withinApp

}

/// What the customer chose when shown the disclosure notice.
internal enum ExternalPurchaseNoticeResult: Hashable, Sendable {

    /// The customer chose to continue to the external purchase.
    case continued

    /// The customer chose not to continue.
    case cancelled

}
