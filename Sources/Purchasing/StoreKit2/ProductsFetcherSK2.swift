//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ProductsManagerSK2.swift
//
//  Created by Andrés Boedo on 7/23/21.

import Foundation
import StoreKit

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
actor ProductsFetcherSK2 {

    private let installmentsInfoFactory: InstallmentsInfoFactoryType

    enum Error: Swift.Error {

        case productsRequestError(innerError: Swift.Error)

    }

    init(installmentsInfoFactory: InstallmentsInfoFactoryType = InstallmentsInfoFactory()) {
        self.installmentsInfoFactory = installmentsInfoFactory
    }

    /// - Throws: `ProductsFetcherSK2.Error`
    func products(identifiers: Set<String>) async throws -> Set<SK2StoreProduct> {
        let resolvedIdentifiers = CompoundProductIdentifierResolver.resolve(
            identifiers,
            supportsBillingPlans: Self.areProductsWithBillingPlansSupported
        )

        let products = try await self.storeKitProducts(identifiers: resolvedIdentifiers.storeKitProductIdentifiers)
        return self.populateSK2CompoundProductsIfSupported(
            requestedIdentifiers: resolvedIdentifiers.compoundProductIdentifiers,
            products: products
        )
    }

}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
private extension ProductsFetcherSK2 {

    func storeKitProducts(identifiers: Set<String>) async throws -> Set<SK2StoreProduct> {
        do {
            let storeKitProducts = try await TimingUtil.measureAndLogIfTooSlow(
                threshold: .productRequest,
                message: Strings.storeKit.sk2_product_request_too_slow
            ) {
                try await StoreKit.Product.products(for: identifiers)
            }

            Logger.rcSuccess(Strings.storeKit.store_product_request_received_response)
            return Set(storeKitProducts.map { SK2StoreProduct(sk2Product: $0) })
        } catch {
            throw Error.productsRequestError(innerError: error)
        }
    }

    static func areProductsWithBillingPlansSupported(compoundIdentifier: CompoundProductIdentifier) -> Bool {
        if #available(iOS 26.4, tvOS 26.4, watchOS 26.4, macOS 26.4, visionOS 26.4, *) {
            return true
        } else {
            Logger.warn(
                StoreKitStrings.sk2_billing_plans_are_unavailable_on_this_os_version(
                    compoundProductIdentifier: compoundIdentifier
                )
            )
            return false
        }
    }

    // swiftlint:disable:next function_body_length
    func populateSK2CompoundProductsIfSupported(
        requestedIdentifiers: Set<CompoundProductIdentifier>,
        products: Set<SK2StoreProduct>
    ) -> Set<SK2StoreProduct> {
        // Billing plans were introduced with Xcode 26.5, which shipped with Swift version 6.3.2.
        #if compiler(>=6.3.2)
        if #available(iOS 26.4, tvOS 26.4, watchOS 26.4, macOS 26.4, visionOS 26.4, *) {
            let requestedIdentifiersWithPlanIdentifiers = requestedIdentifiers.filter {
                $0.productPlanIdentifier != nil
            }
            guard !requestedIdentifiersWithPlanIdentifiers.isEmpty else {
                return products
            }

            let productsByStoreKitProductIdentifier = products.dictionaryWithKeys({ $0.productIdentifier })
            var productsIncludingBillingPlanProducts = products

            // When the user requests a compound product ID but not the base product ID,
            // we only want to return the compound product.
            func removeBaseProductIfNotRequested(_ product: SK2StoreProduct) {
                guard Self.shouldRemoveBaseSK2Product(
                    productIdentifier: product.productIdentifier,
                    requestedIdentifiers: requestedIdentifiers
                ) else {
                    return
                }

                productsIncludingBillingPlanProducts.remove(product)
            }

            for compoundProductIdentifier in requestedIdentifiersWithPlanIdentifiers {
                let storeKitProductIdentifier = compoundProductIdentifier.storeKitProductIdentifier
                guard let productFromStoreKit = productsByStoreKitProductIdentifier[storeKitProductIdentifier] else {
                    continue
                }

                guard let requestedBillingPlanType = compoundProductIdentifier.sk2BillingPlanType else {
                    // Unrecognized billing plan type. Return no products for this request.
                    Logger.warn(
                        StoreKitStrings.sk2_no_billing_plan_found(compoundProductIdentifier: compoundProductIdentifier)
                    )
                    removeBaseProductIfNotRequested(productFromStoreKit)
                    continue
                }
                guard let pricingTerms = productFromStoreKit.underlyingSK2Product.subscription?.pricingTerms else {
                    Logger.warn(
                        StoreKitStrings.sk2_no_pricing_terms_found(compoundProductIdentifier: compoundProductIdentifier)
                    )
                    removeBaseProductIfNotRequested(productFromStoreKit)
                    continue
                }

                if let requestedPricingTerms = pricingTerms.first(
                    where: { $0.billingPlanType == requestedBillingPlanType }
                ) {
                    let installmentsInfo: InstallmentsInfo? = installmentsInfoFactory.buildInstallmentsInfo(
                        from: productFromStoreKit.underlyingSK2Product,
                        billingPlanType: requestedBillingPlanType,
                        pricingTerms: requestedPricingTerms
                    )

                    let billingPlanProduct = SK2StoreProduct(
                        sk2Product: productFromStoreKit.underlyingSK2Product,
                        compoundProductIdentifier: compoundProductIdentifier,
                        installmentsInfo: installmentsInfo
                    )
                    productsIncludingBillingPlanProducts.insert(billingPlanProduct)
                    removeBaseProductIfNotRequested(productFromStoreKit)
                } else {
                    // The requested billing plan isn't available for this user. Return no products for this request.
                    Logger.warn(
                        StoreKitStrings.sk2_user_not_eligible_for_billing_plan(
                            compoundProductIdentifier: compoundProductIdentifier
                        )
                    )
                    removeBaseProductIfNotRequested(productFromStoreKit)
                }
            }

            return productsIncludingBillingPlanProducts
        } else {
            return products
        }

        #else
        // Billing plans aren't supported.
        return products
        #endif
    }
}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
extension ProductsFetcherSK2 {

    /// Returns `true` when StoreKit returned the base product only as an intermediate lookup result
    /// for a requested compound product identifier.
    ///
    /// StoreKit can only fetch the base product identifier. If the caller requested `product:monthly`
    /// without also requesting `product`, the base product should be replaced by the billing-plan
    /// product so the response only contains products matching the original request.
    static func shouldRemoveBaseSK2Product(
        productIdentifier: String,
        requestedIdentifiers: Set<CompoundProductIdentifier>
    ) -> Bool {
        return !requestedIdentifiers.contains {
            $0.productPlanIdentifier == nil
                && $0.storeKitProductIdentifier == productIdentifier
        }
    }

}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
extension ProductsFetcherSK2.Error: CustomNSError {

    var errorUserInfo: [String: Any] {
        switch self {
        case let .productsRequestError(inner):
            return [
                NSUnderlyingErrorKey: inner,
                NSLocalizedDescriptionKey: self.localizedDescription
            ]
        }
    }

    var localizedDescription: String {
        switch self {
        case let .productsRequestError(innerError): return "Products request error: \(innerError.localizedDescription)"
        }
    }
}
