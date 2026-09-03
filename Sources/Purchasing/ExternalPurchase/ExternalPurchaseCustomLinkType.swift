//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ExternalPurchaseCustomLinkType.swift
//
//  Created by Antonio Pallares on 9/3/26.

import Foundation

/// Errors produced by ``ExternalPurchaseCustomLinkType``.
internal enum ExternalPurchaseError: Error, Hashable {

    /// StoreKit's external purchase custom link API does not exist on this OS version.
    case apiUnavailable

}

/// The part of StoreKit's `ExternalPurchaseCustomLink` that the SDK uses.
///
/// Exists so that callers can be unit tested without StoreKit, and so that the OS availability check lives in one
/// place instead of at every call site.
///
/// The calls are meant to be made in order: ``canMakePayments``, then ``isEligible()``, and the notice only in
/// response to a deliberate customer interaction.
internal protocol ExternalPurchaseCustomLinkType {

    /// Whether StoreKit's external purchase custom link API exists on the current OS version.
    ///
    /// Callers do not need to check this before the other members, which already account for it. It is here so a
    /// caller can tell an old OS apart from an app that is genuinely not eligible.
    var isAPIAvailable: Bool { get }

    /// Whether the customer is allowed to make payments at all.
    var canMakePayments: Bool { get }

    /// Whether the app can use the external purchase API at runtime.
    ///
    /// This accounts for the customer's storefront, so the SDK does not determine the region itself. Returns
    /// `false` when the API is unavailable. When this is `false`, the remaining calls throw.
    func isEligible() async -> Bool

    /// Requests an external purchase token of the given type.
    ///
    /// - Returns: The Base64URL encoded token value, or `nil` when there is no active token of that type. A `nil`
    /// return is distinct from an error: it means StoreKit had nothing to give, not that the request failed.
    func token(for tokenType: ExternalPurchaseTokenType) async throws -> String?

    /// Displays the system disclosure notice and reports what the customer chose.
    ///
    /// Must be called in response to a deliberate customer interaction, such as tapping a button.
    ///
    /// The system does not display the sheet at all if the customer has already seen it and chose not to see it
    /// again, in which case this returns ``ExternalPurchaseNoticeResult/continued`` with no interaction and
    /// essentially no delay. Callers cannot rely on this taking any time.
    func showNotice(type: ExternalPurchaseNoticeType) async throws -> ExternalPurchaseNoticeResult

}
