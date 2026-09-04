//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ExternalPurchaseFlow.swift
//
//  Created by Antonio Pallares on 4/9/26.

import Foundation

/// The shape of an external purchase, pairing the type of token to request with the style of disclosure notice
/// the customer must be shown first.
///
/// The two values always travel together, and which pair applies depends on the storefront, so they are
/// configured rather than decided where they are used.
internal struct ExternalPurchaseFlow: Hashable, Sendable {

    let tokenType: ExternalPurchaseTokenType
    let noticeType: ExternalPurchaseNoticeType

}

extension ExternalPurchaseFlow {

    /// The customer pays without leaving the app, in a web view or native experience the app presents.
    static let inApp: Self = .init(tokenType: .inApp, noticeType: .withinApp)

    /// The customer leaves the app to complete the transaction on the developer's website.
    static let linkOut: Self = .init(tokenType: .linkOut, noticeType: .browser)

}
