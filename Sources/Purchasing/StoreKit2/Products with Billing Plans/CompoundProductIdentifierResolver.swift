//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CompoundProductIdentifierResolver.swift
//
//  Created by Will Taylor on 5/26/2026.
//

import Foundation

/// Converts SDK-facing product identifier strings into the identifiers that StoreKit can request.
///
/// The SDK can receive identifiers that include both a StoreKit product ID and an optional billing-plan ID,
/// such as `com.revenuecat.subscription:monthly`. StoreKit product lookups only accept the base product ID, so
/// this resolver centralizes parsing, invalid identifier logging, billing-plan filtering, and conversion to
/// StoreKit-facing product identifiers.
internal enum CompoundProductIdentifierResolver {

    /// The result of resolving SDK-facing product identifiers.
    internal struct ResolvedIdentifiers {
        let compoundProductIdentifiers: Set<CompoundProductIdentifier>

        /// Base product identifiers that can be requested from StoreKit.
        let storeKitProductIdentifiers: Set<String>

        init(compoundProductIdentifiers: Set<CompoundProductIdentifier>) {
            self.compoundProductIdentifiers = compoundProductIdentifiers
            self.storeKitProductIdentifiers = Set(compoundProductIdentifiers.map(\.storeKitProductIdentifier))
        }
    }

    /// Parses and filters SDK-facing product identifiers.
    ///
    /// Invalid identifiers are dropped and logged once. Base product identifiers are always retained. Billing-plan
    /// identifiers are retained only when `supportsBillingPlans` returns `true`, which lets SK1 and SK2 use the same
    /// parsing logic while keeping their StoreKit-specific support rules and warning messages separate.
    ///
    /// - Parameters:
    ///   - identifiers: SDK-facing product identifiers requested by the caller.
    ///   - supportsBillingPlans: StoreKit-specific policy called for identifiers with a product plan.
    /// - Returns: Parsed compound identifiers and their StoreKit-requestable base identifiers.
    static func resolve(
        _ identifiers: Set<String>,
        supportsBillingPlans: (CompoundProductIdentifier) -> Bool
    ) -> ResolvedIdentifiers {
        var invalidProductIdentifiers: Set<String> = []

        let compoundProductIdentifiers: Set<CompoundProductIdentifier> = Set(
            identifiers.compactMap { identifier in
                guard let compoundIdentifier = CompoundProductIdentifier(
                    compoundProductIdentifier: identifier
                ) else {
                    invalidProductIdentifiers.insert(identifier)
                    return nil
                }

                guard compoundIdentifier.productPlanIdentifier != nil else {
                    return compoundIdentifier
                }

                return supportsBillingPlans(compoundIdentifier)
                    ? compoundIdentifier
                    : nil
            }
        )

        if !invalidProductIdentifiers.isEmpty {
            Logger.warn(Strings.storeKit.invalid_product_identifiers(identifiers: invalidProductIdentifiers))
        }

        return .init(compoundProductIdentifiers: compoundProductIdentifiers)
    }

}
